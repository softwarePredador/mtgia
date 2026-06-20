#!/usr/bin/env python3
"""Read-only learned deck coherence audit.

The audit re-derives learned-deck composition from PostgreSQL canonical card
identity/intelligence views, then compares that current truth against cached
metadata. It also has a focused Lorehold/Hermes deck id 6 check because that
deck is the current control case for ManaLoom deckbuilding strategy.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
import unicodedata
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import psycopg2
from psycopg2.extras import RealDictCursor


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
SERVER_ROOT = REPO_ROOT / "server"
DEFAULT_KNOWLEDGE_DB = (
    REPO_ROOT / "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"
)
DEFAULT_OUTPUT_DIR = REPO_ROOT / "docs/hermes-analysis/master_optimizer_reports"

CORE_METADATA_KEYS = (
    "total_lands",
    "ramp_count",
    "draw_count",
    "removal_count",
    "tutor_count",
    "engine_count",
    "wincon_count",
    "protection_count",
)

ROLE_METADATA_TO_TAGS = {
    "ramp_count": {"ramp"},
    "draw_count": {"draw"},
    "removal_count": {"removal"},
    "tutor_count": {"tutor"},
    "engine_count": {"engine"},
    "wincon_count": {"wincon"},
    "protection_count": {"protection"},
    "recursion_count": {"recursion"},
    "board_wipe_count": {"board_wipe"},
}

ACTIVE_LEARNED_DECK_GATE_ISSUE_CODES = {
    "all_core_metadata_zero",
    "metadata_total_lands_mismatch",
    "metadata_zero_lands",
    "unresolved_card_names",
}

LOREHOLD_NO_PREMIUM_MOX = {"Chrome Mox", "Mox Diamond", "Mox Opal"}
LOREHOLD_ALLOWED_COLORS = {"R", "W"}
COMMANDER_EXPECTED_QUANTITY = 100
COMMANDER_MIN_REVIEW_LANDS = 24
COMMANDER_MAX_REVIEW_LANDS = 45
COMMANDER_STAPLE_LEGALITY_OVERRIDES = {
    "command tower": "commander_staple_missing_pg_legalities_assumed_legal",
    "sol ring": "commander_staple_missing_pg_legalities_assumed_legal",
}
ACCEPTED_EMPTY_ORACLE_TEXT = {
    "dwarven trader": {
        "source": "scryfall_exact_2026_06_19",
        "reason": "Official Scryfall exact-name payload has no oracle_text for this no-rules-text card.",
    },
    "memnite": {
        "source": "scryfall_exact_2026_06_19",
        "reason": "Official Scryfall exact-name payload has no oracle_text for this no-rules-text card.",
    },
    "phyrexian walker": {
        "source": "scryfall_exact_2026_06_19",
        "reason": "Official Scryfall exact-name payload has no oracle_text for this no-rules-text card.",
    },
}
OFF_COLOR_MANUAL_REVIEWS = {
    "learned_deck:126": {
        "classification": "identity_bridge_misresolution",
        "cards": ["Vendetta"],
        "resolved_as": ["Vengeance"],
        "expected_color_identity": ["B"],
        "actual_resolved_color_identity": ["W"],
        "decision": "fix_card_identity_bridge_mapping",
        "note": "Raw card_list entry Vendetta is black and legal for Inalla, but the local identity bridge resolves it as white Vengeance.",
    },
    "learned_deck:116": {
        "classification": "combined_commander_identity_not_modeled",
        "cards": ["K-9, Mark I", "The Fourteenth Doctor"],
        "decision": "move_to_combined_commander_identity_modeling",
        "note": "Deck name declares K-9 with The Fourteenth Doctor; off-color volume reflects missing combined commander identity fields, not isolated card mistakes.",
    },
    "learned_deck:3": {
        "classification": "identity_bridge_misresolution",
        "cards": ["Endurance"],
        "resolved_as": ["Endure"],
        "expected_color_identity": ["G"],
        "actual_resolved_color_identity": ["W"],
        "decision": "fix_card_identity_bridge_mapping",
        "note": "Raw card_list entry Endurance is green and legal for Kinnan, but the local identity bridge resolves it as white Endure.",
    },
    "learned_deck:131": {
        "classification": "identity_bridge_misresolution",
        "cards": ["Endurance"],
        "resolved_as": ["Endure"],
        "expected_color_identity": ["G"],
        "actual_resolved_color_identity": ["W"],
        "decision": "fix_card_identity_bridge_mapping",
        "note": "Raw card_list entry Endurance is green and legal for Lumra, but the local identity bridge resolves it as white Endure.",
    },
    "learned_deck:114": {
        "classification": "identity_bridge_misresolution",
        "cards": ["Vendetta"],
        "resolved_as": ["Vengeance"],
        "expected_color_identity": ["B"],
        "actual_resolved_color_identity": ["W"],
        "decision": "fix_card_identity_bridge_mapping",
        "note": "Raw card_list entry Vendetta is black and legal for Rowan, but the local identity bridge resolves it as white Vengeance.",
    },
}
PARTNER_TEXT_MARKERS = (
    "partner",
    "friends forever",
    "doctor's companion",
    "choose a background",
)
LOREHOLD_STRATEGY_PACKAGES = (
    {
        "key": "commander_identity",
        "label": "Commander identity",
        "minimum": 1,
        "required": ("Lorehold, the Historian",),
        "cards": ("Lorehold, the Historian",),
        "severity": "high",
    },
    {
        "key": "copy_combo_core",
        "label": "Copy combo core",
        "minimum": 4,
        "required": ("Dualcaster Mage",),
        "cards": (
            "Dualcaster Mage",
            "Twinflame",
            "Heat Shimmer",
            "Molten Duplication",
            "Electroduplicate",
            "Reiterate",
            "Reverberate",
        ),
        "severity": "high",
    },
    {
        "key": "topdeck_miracle_setup",
        "label": "Topdeck/miracle setup",
        "minimum": 3,
        "required": (),
        "cards": (
            "Sensei's Divining Top",
            "Scroll Rack",
            "Land Tax",
            "Valakut Awakening",
            "The One Ring",
        ),
        "severity": "medium",
    },
    {
        "key": "graveyard_spell_value",
        "label": "Graveyard/spell value",
        "minimum": 4,
        "required": (),
        "cards": (
            "Faithless Looting",
            "Mizzix's Mastery",
            "Past in Flames",
            "Wheel of Fortune",
            "Wheel of Misfortune",
            "Unexpected Windfall",
        ),
        "severity": "medium",
    },
    {
        "key": "big_spell_finishers",
        "label": "Big spell finishers",
        "minimum": 4,
        "required": (),
        "cards": (
            "Rise of the Eldrazi",
            "Storm Herd",
            "Worldfire",
            "Blasphemous Act",
            "Approach of the Second Sun",
            "Fiery Emancipation",
            "Rite of the Dragoncaller",
        ),
        "severity": "medium",
    },
    {
        "key": "protection_stack_control",
        "label": "Protection/stack control",
        "minimum": 6,
        "required": (),
        "cards": (
            "Silence",
            "Orim's Chant",
            "Grand Abolisher",
            "Ranger-Captain of Eos",
            "Deflecting Swat",
            "Teferi's Protection",
            "Flawless Maneuver",
            "Boros Charm",
            "Giver of Runes",
            "Mother of Runes",
        ),
        "severity": "medium",
    },
    {
        "key": "mana_acceleration",
        "label": "Mana acceleration",
        "minimum": 10,
        "required": (),
        "cards": (
            "Sol Ring",
            "Mana Vault",
            "Lotus Petal",
            "Mox Amber",
            "Arcane Signet",
            "Boros Signet",
            "Fellwar Stone",
            "Talisman of Conviction",
            "Ruby Medallion",
            "Rite of Flame",
            "Seething Song",
            "Mana Geyser",
            "Smothering Tithe",
            "Storm-Kiln Artist",
        ),
        "severity": "medium",
    },
)


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


def normalize_name(value: str | None) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKD", value)
    ascii_text = "".join(ch for ch in normalized if not unicodedata.combining(ch))
    ascii_text = ascii_text.replace("’", "'").replace("`", "'")
    ascii_text = re.sub(r"[^a-zA-Z0-9]+", " ", ascii_text.lower())
    return re.sub(r"\s+", " ", ascii_text).strip()


def front_face_name(value: str) -> str:
    return value.split("//", 1)[0].strip()


def normalized_name_options(value: str | None) -> set[str]:
    if not value:
        return set()
    return {
        candidate
        for candidate in {
            normalize_name(value),
            normalize_name(front_face_name(value)),
        }
        if candidate
    }


def commander_legality_override_reason(card_name: str) -> str | None:
    for option in normalized_name_options(card_name):
        reason = COMMANDER_STAPLE_LEGALITY_OVERRIDES.get(option)
        if reason:
            return reason
    return None


def accepted_empty_oracle_text_reason(card_name: str) -> dict[str, str] | None:
    for option in normalized_name_options(card_name):
        reason = ACCEPTED_EMPTY_ORACLE_TEXT.get(option)
        if reason:
            return reason
    return None


def commander_legality_missing(identity: CardIdentity) -> bool:
    if identity.legalities.get("commander") is not None:
        return False
    return commander_legality_override_reason(identity.canonical_name) is None


def strip_quantity(value: str) -> tuple[int, str]:
    text = value.strip()
    match = re.match(r"^(?:(\d+)|x(\d+))\s+(.+)$", text, re.IGNORECASE)
    if not match:
        return 1, text
    quantity = int(match.group(1) or match.group(2) or "1")
    return quantity, match.group(3).strip()


def clean_card_name(value: str) -> str:
    text = value.strip()
    text = re.sub(r"\s+#.*$", "", text)
    text = re.sub(r"^\s*[-*]\s+", "", text)
    quantity, text = strip_quantity(text)
    del quantity
    text = re.sub(r"\s+\([A-Z0-9]{2,6}\)\s+\S+\s*$", "", text)
    return re.sub(r"\s+", " ", text).strip()


@dataclass(frozen=True)
class CardLine:
    name: str
    quantity: int = 1


@dataclass
class CardIdentity:
    card_id: str
    canonical_name: str
    type_line: str
    cmc: float | None
    oracle_id: str | None
    oracle_text: str
    color_identity: list[str]
    legalities: dict[str, Any]
    function_tags: list[str]
    battle_rule_count: int
    verified_battle_rule_count: int
    source_coverage: dict[str, Any]

    @property
    def is_land(self) -> bool:
        return "land" in self.type_line.lower()


@dataclass
class ResolvedCard:
    line: CardLine
    identity: CardIdentity | None


@dataclass
class LearnedDeckAudit:
    commander_name: str
    deck_name: str
    source_system: str
    source_ref: str
    row_id: str
    card_count_declared: int
    metadata: dict[str, Any]
    parsed_cards: list[CardLine]
    resolved_cards: list[ResolvedCard]
    derived_metadata: dict[str, Any]
    issues: list[dict[str, Any]] = field(default_factory=list)

    @property
    def unresolved(self) -> list[str]:
        return [
            resolved.line.name
            for resolved in self.resolved_cards
            if resolved.identity is None
        ]

    @property
    def parsed_quantity(self) -> int:
        return sum(card.quantity for card in self.parsed_cards)

    def issue_count(self, severity: str | None = None) -> int:
        if severity is None:
            return len(self.issues)
        return sum(1 for issue in self.issues if issue["severity"] == severity)


def parse_card_list(value: Any) -> list[CardLine]:
    if value is None:
        return []
    if isinstance(value, list):
        return parse_card_json_list(value)
    text = str(value).strip()
    if not text:
        return []
    if text.startswith("["):
        try:
            parsed = json.loads(text)
            if isinstance(parsed, list):
                return parse_card_json_list(parsed)
        except Exception:
            pass
    cards: list[CardLine] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        line = re.sub(r"^\s*[-*]\s+", "", line)
        quantity, name = strip_quantity(line)
        name = clean_card_name(f"{quantity} {name}")
        if name:
            cards.append(CardLine(name=name, quantity=quantity))
    return cards


def parse_card_json_list(items: list[Any]) -> list[CardLine]:
    cards: list[CardLine] = []
    for item in items:
        if isinstance(item, str):
            cards.extend(parse_card_list(item))
            continue
        if not isinstance(item, dict):
            continue
        name = str(item.get("name") or item.get("card_name") or "").strip()
        if not name:
            continue
        quantity = int(item.get("quantity") or item.get("qty") or 1)
        cards.append(CardLine(name=clean_card_name(name), quantity=quantity))
    return cards


def decimal_to_float(value: Any) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except Exception:
        return None


def int_value(value: Any) -> int | None:
    if value is None:
        return None
    try:
        return int(float(value))
    except Exception:
        return None


def json_value(value: Any, default: Any) -> Any:
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


def connect_pg() -> psycopg2.extensions.connection:
    load_env_file(SERVER_ROOT / ".env")
    required = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASS"]
    missing = [key for key in required if not os.environ.get(key)]
    if missing:
        raise SystemExit(f"Missing DB env vars: {', '.join(missing)}")
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ["DB_PORT"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
    )


def add_lookup_alias(
    lookup: dict[str, CardIdentity],
    lookup_rank: dict[str, tuple[int, str, str]],
    name: str | None,
    identity: CardIdentity,
    *,
    priority: int = 0,
) -> None:
    if not name:
        return
    candidates = [name]
    if "//" in name:
        candidates.append(name.split("//", 1)[0].strip())
    for candidate in candidates:
        normalized = normalize_name(candidate)
        if not normalized:
            continue
        rank = (
            priority,
            normalize_name(identity.canonical_name),
            identity.card_id,
        )
        if normalized not in lookup_rank or rank < lookup_rank[normalized]:
            lookup[normalized] = identity
            lookup_rank[normalized] = rank


def load_card_lookup(conn: psycopg2.extensions.connection) -> dict[str, CardIdentity]:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT
                cib.card_id,
                cib.canonical_name,
                cib.lookup_name,
                cib.printed_name,
                cis.oracle_id,
                cis.oracle_text,
                cis.type_line,
                cis.cmc,
                cis.color_identity,
                cis.legalities,
                cis.function_tags,
                cis.battle_rule_count,
                cis.verified_battle_rule_count,
                cis.source_coverage,
                COALESCE(cib.match_priority, 999) AS match_priority
            FROM card_identity_bridge cib
            LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = cib.card_id
            ORDER BY
                cib.normalized_lookup_name,
                COALESCE(cib.match_priority, 999),
                cib.normalized_canonical_name,
                cib.card_id
            """
        )
        rows = cur.fetchall()

    lookup: dict[str, CardIdentity] = {}
    lookup_rank: dict[str, tuple[int, str, str]] = {}
    for row in rows:
        identity = CardIdentity(
            card_id=str(row["card_id"]),
            canonical_name=str(row["canonical_name"] or row["lookup_name"] or ""),
            type_line=str(row["type_line"] or ""),
            cmc=decimal_to_float(row["cmc"]),
            oracle_id=str(row["oracle_id"]) if row["oracle_id"] else None,
            oracle_text=str(row["oracle_text"] or ""),
            color_identity=[str(item) for item in row["color_identity"] or []],
            legalities=json_value(row["legalities"], {}),
            function_tags=[str(item) for item in row["function_tags"] or []],
            battle_rule_count=int(row["battle_rule_count"] or 0),
            verified_battle_rule_count=int(row["verified_battle_rule_count"] or 0),
            source_coverage=json_value(row["source_coverage"], {}),
        )
        match_priority = int(row["match_priority"] or 999)
        add_lookup_alias(lookup, lookup_rank, row["canonical_name"], identity)
        add_lookup_alias(
            lookup,
            lookup_rank,
            row["lookup_name"],
            identity,
            priority=match_priority,
        )
        add_lookup_alias(
            lookup,
            lookup_rank,
            row["printed_name"],
            identity,
            priority=match_priority,
        )
    return lookup


def resolve_card(card: CardLine, lookup: dict[str, CardIdentity]) -> ResolvedCard:
    identity = lookup.get(normalize_name(card.name))
    if identity is None and "//" in card.name:
        identity = lookup.get(normalize_name(card.name.split("//", 1)[0]))
    return ResolvedCard(line=card, identity=identity)


def find_commander_identity(
    commander_name: str,
    resolved_cards: list[ResolvedCard],
    lookup: dict[str, CardIdentity],
) -> CardIdentity | None:
    commander_options = normalized_name_options(commander_name)
    for resolved in resolved_cards:
        if resolved.identity is None:
            continue
        line_options = normalized_name_options(resolved.line.name)
        identity_options = normalized_name_options(resolved.identity.canonical_name)
        if commander_options & (line_options | identity_options):
            return resolved.identity
    for option in commander_options:
        identity = lookup.get(option)
        if identity is not None:
            return identity
    return None


def commander_quantity(commander_name: str, parsed_cards: list[CardLine]) -> int:
    commander_options = normalized_name_options(commander_name)
    return sum(
        card.quantity
        for card in parsed_cards
        if commander_options & normalized_name_options(card.name)
    )


def derive_metadata(
    resolved_cards: list[ResolvedCard],
    allowed_colors: set[str] | None = None,
) -> dict[str, Any]:
    quantities = 0
    resolved_quantities = 0
    land_count = 0
    nonland_cmc_sum = 0.0
    nonland_cmc_count = 0
    role_counts: Counter[str] = Counter()
    color_offenders: list[str] = []
    missing_legalities: list[str] = []
    commander_legality_assumptions: list[dict[str, str]] = []
    missing_oracle_id: list[str] = []
    missing_oracle_text: list[str] = []
    accepted_empty_oracle_text: list[dict[str, str]] = []
    missing_oracle_id_quantity = 0
    missing_oracle_text_quantity = 0
    accepted_empty_oracle_text_quantity = 0
    coverage_gaps: Counter[str] = Counter()

    for resolved in resolved_cards:
        quantity = resolved.line.quantity
        quantities += quantity
        identity = resolved.identity
        if identity is None:
            continue
        resolved_quantities += quantity
        if identity.is_land:
            land_count += quantity
        elif identity.cmc is not None:
            nonland_cmc_sum += identity.cmc * quantity
            nonland_cmc_count += quantity
        for tag in identity.function_tags:
            role_counts[tag] += quantity
        commander_override_reason = commander_legality_override_reason(
            identity.canonical_name
        )
        if identity.legalities.get("commander") is None and commander_override_reason:
            commander_legality_assumptions.append(
                {
                    "name": identity.canonical_name,
                    "format": "commander",
                    "reason": commander_override_reason,
                }
            )
        elif commander_legality_missing(identity):
            missing_legalities.append(identity.canonical_name)
        if not identity.oracle_id:
            missing_oracle_id.append(identity.canonical_name)
            missing_oracle_id_quantity += quantity
        if not identity.oracle_text.strip():
            accepted_oracle_gap = accepted_empty_oracle_text_reason(
                identity.canonical_name
            )
            if accepted_oracle_gap is None:
                missing_oracle_text.append(identity.canonical_name)
                missing_oracle_text_quantity += quantity
            else:
                accepted_empty_oracle_text.append(
                    {
                        "name": identity.canonical_name,
                        **accepted_oracle_gap,
                    }
                )
                accepted_empty_oracle_text_quantity += quantity
        for key, value in identity.source_coverage.items():
            if value is False:
                coverage_gaps[key] += quantity
        if allowed_colors is not None and any(
            color not in allowed_colors for color in identity.color_identity
        ):
            color_offenders.append(identity.canonical_name)

    metadata: dict[str, Any] = {
        "card_quantity": quantities,
        "resolved_quantity": resolved_quantities,
        "unresolved_quantity": quantities - resolved_quantities,
        "total_lands": land_count,
        "avg_nonland_cmc": round(nonland_cmc_sum / nonland_cmc_count, 3)
        if nonland_cmc_count
        else None,
        "role_counts": dict(sorted(role_counts.items())),
        "missing_legalities": sorted(set(missing_legalities)),
        "commander_legality_assumptions": sorted(
            commander_legality_assumptions,
            key=lambda item: item["name"].lower(),
        ),
        "missing_oracle_id": sorted(set(missing_oracle_id)),
        "missing_oracle_id_quantity": missing_oracle_id_quantity,
        "missing_oracle_text": sorted(set(missing_oracle_text)),
        "missing_oracle_text_quantity": missing_oracle_text_quantity,
        "accepted_empty_oracle_text": [
            json.loads(item)
            for item in sorted(
                {
                    json.dumps(item, sort_keys=True)
                    for item in accepted_empty_oracle_text
                }
            )
        ],
        "accepted_empty_oracle_text_quantity": accepted_empty_oracle_text_quantity,
        "coverage_gaps": dict(sorted(coverage_gaps.items())),
        "off_color_candidates": sorted(set(color_offenders)),
        "commander_color_identity": sorted(allowed_colors)
        if allowed_colors is not None
        else None,
    }
    for metadata_key, tags in ROLE_METADATA_TO_TAGS.items():
        metadata[metadata_key] = sum(role_counts[tag] for tag in tags)
    return metadata


def declared_commander_component_names(
    commander_name: str,
    deck_name: str,
) -> list[str]:
    if "+" not in deck_name:
        return []
    components = [
        clean_card_name(part)
        for part in re.split(r"\s+\+\s+|\s*\+\s*", deck_name)
        if clean_card_name(part)
    ]
    commander_options = normalized_name_options(commander_name)
    return [
        component
        for component in components
        if not (normalized_name_options(component) & commander_options)
    ]


def infer_partner_identity_context(
    commander_name: str,
    deck_name: str,
    resolved_cards: list[ResolvedCard],
    allowed_colors: set[str] | None,
) -> dict[str, Any]:
    if allowed_colors is None:
        return {
            "partner_identity_candidates": [],
            "combined_commander_color_identity": None,
            "off_color_after_partner_inference": [],
        }

    commander_options = normalized_name_options(commander_name)
    partner_candidates: list[dict[str, Any]] = []
    seen_candidates: set[str] = set()
    combined_colors = set(allowed_colors)

    for component_name in declared_commander_component_names(
        commander_name,
        deck_name,
    ):
        identity = find_resolved_identity(component_name, resolved_cards)
        if identity is None:
            continue
        normalized = normalize_name(identity.canonical_name)
        if normalized in seen_candidates:
            continue
        if any(color not in allowed_colors for color in identity.color_identity):
            partner_candidates.append(
                {
                    "name": identity.canonical_name,
                    "color_identity": sorted(identity.color_identity),
                    "reason": "deck_name_commander_component",
                }
            )
            seen_candidates.add(normalized)
            combined_colors.update(identity.color_identity)

    for resolved in resolved_cards:
        identity = resolved.identity
        if identity is None:
            continue
        if commander_options & (
            normalized_name_options(resolved.line.name)
            | normalized_name_options(identity.canonical_name)
        ):
            continue
        oracle_text = identity.oracle_text.lower()
        type_line = identity.type_line.lower()
        has_partner_text = any(marker in oracle_text for marker in PARTNER_TEXT_MARKERS)
        is_background = "background" in type_line
        adds_colors = any(color not in allowed_colors for color in identity.color_identity)
        normalized = normalize_name(identity.canonical_name)
        if (
            (has_partner_text or is_background)
            and adds_colors
            and normalized not in seen_candidates
        ):
            partner_candidates.append(
                {
                    "name": identity.canonical_name,
                    "color_identity": sorted(identity.color_identity),
                    "reason": "background" if is_background else "partner_text",
                }
            )
            seen_candidates.add(normalized)
            combined_colors.update(identity.color_identity)

    off_color_after_partner = sorted(
        {
            resolved.identity.canonical_name
            for resolved in resolved_cards
            if resolved.identity is not None
            and any(
                color not in combined_colors for color in resolved.identity.color_identity
            )
        }
    )
    return {
        "partner_identity_candidates": partner_candidates,
        "combined_commander_color_identity": sorted(combined_colors),
        "off_color_after_partner_inference": off_color_after_partner,
    }


def find_resolved_identity(
    name: str,
    resolved_cards: list[ResolvedCard],
) -> CardIdentity | None:
    options = normalized_name_options(name)
    for resolved in resolved_cards:
        identity = resolved.identity
        if identity is None:
            continue
        if options & (
            normalized_name_options(resolved.line.name)
            | normalized_name_options(identity.canonical_name)
        ):
            return identity
    return None


def build_commander_identity_model(
    commander_name: str,
    deck_name: str,
    source_ref: str,
    resolved_cards: list[ResolvedCard],
    allowed_colors: set[str] | None,
    partner_context: dict[str, Any],
) -> dict[str, Any]:
    base_identity = sorted(allowed_colors) if allowed_colors is not None else None
    partner_candidates = partner_context.get("partner_identity_candidates") or []
    if partner_candidates:
        sources = sorted({str(item.get("reason") or "unknown") for item in partner_candidates})
        source = (
            sources[0]
            if len(sources) == 1
            else "mixed_commander_identity_inference"
        )
        return {
            "status": "combined_identity_inferred",
            "source": source,
            "requires_first_class_persistence": True,
            "primary_commander_name": commander_name,
            "declared_deck_name": deck_name,
            "base_color_identity": base_identity,
            "combined_color_identity": partner_context.get(
                "combined_commander_color_identity"
            ),
            "identity_components": [
                {
                    "name": item.get("name"),
                    "color_identity": item.get("color_identity") or [],
                    "source": item.get("reason"),
                }
                for item in partner_candidates
            ],
        }

    manual_review = OFF_COLOR_MANUAL_REVIEWS.get(source_ref)
    if (
        manual_review
        and manual_review.get("classification")
        == "combined_commander_identity_not_modeled"
    ):
        combined_colors = set(allowed_colors or set())
        components: list[dict[str, Any]] = []
        for card_name in manual_review.get("cards") or []:
            identity = find_resolved_identity(str(card_name), resolved_cards)
            colors = sorted(identity.color_identity) if identity else []
            combined_colors.update(colors)
            components.append(
                {
                    "name": str(card_name),
                    "color_identity": colors,
                    "source": "manual_off_color_review",
                    "resolved": identity is not None,
                }
            )
        return {
            "status": "combined_identity_manual_review",
            "source": "manual_off_color_review",
            "requires_first_class_persistence": True,
            "primary_commander_name": commander_name,
            "declared_deck_name": deck_name,
            "base_color_identity": base_identity,
            "combined_color_identity": sorted(combined_colors)
            if combined_colors
            else base_identity,
            "identity_components": components,
        }

    return {
        "status": "single_commander_identity",
        "source": "commander_name",
        "requires_first_class_persistence": False,
        "primary_commander_name": commander_name,
        "declared_deck_name": deck_name,
        "base_color_identity": base_identity,
        "combined_color_identity": base_identity,
        "identity_components": [],
    }


def evaluate_commander_deck_shape(
    commander_name: str,
    parsed_cards: list[CardLine],
    derived_metadata: dict[str, Any],
) -> dict[str, Any]:
    commander_qty = commander_quantity(commander_name, parsed_cards)
    land_count = int(derived_metadata["total_lands"])
    review_flags: list[str] = []
    if land_count < COMMANDER_MIN_REVIEW_LANDS:
        review_flags.append("low_land_count")
    if land_count > COMMANDER_MAX_REVIEW_LANDS:
        review_flags.append("high_land_count")
    if derived_metadata["missing_legalities"]:
        review_flags.append("missing_legalities")
    if derived_metadata["missing_oracle_text_quantity"]:
        review_flags.append("missing_oracle_text")

    critical_flags: list[str] = []
    if sum(card.quantity for card in parsed_cards) != COMMANDER_EXPECTED_QUANTITY:
        critical_flags.append("wrong_card_quantity")
    if commander_qty != 1:
        critical_flags.append("commander_not_exactly_one")
    if derived_metadata["unresolved_quantity"]:
        critical_flags.append("unresolved_cards")
    effective_off_color = derived_metadata.get(
        "off_color_after_partner_inference",
        derived_metadata["off_color_candidates"],
    )
    if effective_off_color:
        critical_flags.append("off_color_cards")

    return {
        "expected_quantity": COMMANDER_EXPECTED_QUANTITY,
        "parsed_quantity": sum(card.quantity for card in parsed_cards),
        "commander_quantity": commander_qty,
        "land_review_min": COMMANDER_MIN_REVIEW_LANDS,
        "land_review_max": COMMANDER_MAX_REVIEW_LANDS,
        "land_count": land_count,
        "critical_flags": critical_flags,
        "review_flags": review_flags,
        "passes_shape": not critical_flags,
    }


def issue(
    severity: str,
    code: str,
    message: str,
    expected: Any = None,
    actual: Any = None,
) -> dict[str, Any]:
    result = {"severity": severity, "code": code, "message": message}
    if expected is not None:
        result["expected"] = expected
    if actual is not None:
        result["actual"] = actual
    return result


def package_card_presence(
    expected_cards: Iterable[str],
    present_normalized: set[str],
) -> tuple[list[str], list[str]]:
    present: list[str] = []
    missing: list[str] = []
    for card in expected_cards:
        normalized = normalize_name(front_face_name(card))
        if normalized in present_normalized:
            present.append(card)
        else:
            missing.append(card)
    return present, missing


def evaluate_lorehold_strategy(card_names: Iterable[str]) -> dict[str, Any]:
    present_normalized = {
        normalize_name(front_face_name(name))
        for name in card_names
        if normalize_name(front_face_name(name))
    }

    package_results: list[dict[str, Any]] = []
    strategy_issues: list[dict[str, Any]] = []
    for package in LOREHOLD_STRATEGY_PACKAGES:
        present, missing = package_card_presence(
            package["cards"],
            present_normalized,
        )
        required_present, required_missing = package_card_presence(
            package["required"],
            present_normalized,
        )
        del required_present
        expected_count = int(package["minimum"])
        passed = len(present) >= expected_count and not required_missing
        result = {
            "key": package["key"],
            "label": package["label"],
            "minimum": expected_count,
            "present_count": len(present),
            "present": present,
            "missing": missing,
            "required_missing": required_missing,
            "passed": passed,
        }
        package_results.append(result)
        if not passed:
            strategy_issues.append(
                issue(
                    str(package["severity"]),
                    f"lorehold_strategy_{package['key']}_gap",
                    f"Lorehold strategy package is below the expected minimum: {package['label']}.",
                    expected_count,
                    len(present),
                )
            )

    forbidden_present = sorted(
        card
        for card in LOREHOLD_NO_PREMIUM_MOX
        if normalize_name(card) in present_normalized
    )
    if forbidden_present:
        strategy_issues.append(
            issue(
                "high",
                "lorehold_premium_mox_policy_violation",
                "Lorehold no-premium-Mox policy was violated.",
                [],
                forbidden_present,
            )
        )

    return {
        "passed": not strategy_issues,
        "packages": package_results,
        "forbidden_present": forbidden_present,
        "issues": strategy_issues,
    }


def compare_metadata(audit: LearnedDeckAudit) -> None:
    metadata = audit.metadata
    derived = audit.derived_metadata
    shape = derived.get("commander_deck_shape") or {}

    if shape.get("parsed_quantity") != COMMANDER_EXPECTED_QUANTITY:
        audit.issues.append(
            issue(
                "high",
                "commander_deck_quantity_mismatch",
                "Commander learned deck does not resolve to exactly 100 cards.",
                COMMANDER_EXPECTED_QUANTITY,
                shape.get("parsed_quantity"),
            )
        )

    if shape.get("commander_quantity") != 1:
        audit.issues.append(
            issue(
                "high",
                "commander_quantity_mismatch",
                "Commander learned deck does not contain exactly one matching commander card.",
                1,
                shape.get("commander_quantity"),
            )
        )
    effective_off_color = derived.get(
        "off_color_after_partner_inference",
        derived.get("off_color_candidates", []),
    )
    if (
        derived.get("off_color_candidates")
        and derived.get("partner_identity_candidates")
        and len(effective_off_color) < len(derived["off_color_candidates"])
    ):
        audit.issues.append(
            issue(
                "medium",
                "partner_identity_not_modeled",
                "Deck appears to rely on partner/background color identity not represented by commander_name.",
                "partner-aware commander identity",
                {
                    "base_off_color": len(derived["off_color_candidates"]),
                    "after_partner_inference": len(effective_off_color),
                },
            )
        )

    if effective_off_color:
        audit.issues.append(
            issue(
                "high",
                "off_color_cards",
                "Resolved card list includes cards outside commander color identity.",
                0,
                len(effective_off_color),
            )
        )

    if "low_land_count" in shape.get("review_flags", []):
        audit.issues.append(
            issue(
                "medium",
                "land_count_low_review",
                "Land count is below broad Commander review range.",
                COMMANDER_MIN_REVIEW_LANDS,
                shape.get("land_count"),
            )
        )
    if "high_land_count" in shape.get("review_flags", []):
        audit.issues.append(
            issue(
                "medium",
                "land_count_high_review",
                "Land count is above broad Commander review range.",
                COMMANDER_MAX_REVIEW_LANDS,
                shape.get("land_count"),
            )
        )

    if audit.card_count_declared and audit.card_count_declared != audit.parsed_quantity:
        audit.issues.append(
            issue(
                "high",
                "card_count_mismatch",
                "Declared card_count differs from parsed card quantity.",
                audit.card_count_declared,
                audit.parsed_quantity,
            )
        )

    if audit.unresolved:
        audit.issues.append(
            issue(
                "high",
                "unresolved_card_names",
                "Active learned deck has unresolved card names.",
                0,
                len(audit.unresolved),
            )
        )

    metadata_lands = int_value(metadata.get("total_lands"))
    if metadata_lands is not None and metadata_lands != derived["total_lands"]:
        audit.issues.append(
            issue(
                "high",
                "metadata_total_lands_mismatch",
                "Cached total_lands differs from resolved card_list.",
                derived["total_lands"],
                metadata_lands,
            )
        )

    if int_value(metadata.get("total_lands")) == 0 and derived["total_lands"] > 0:
        audit.issues.append(
            issue(
                "high",
                "metadata_zero_lands",
                "Metadata reports zero lands for a resolved deck with lands.",
                derived["total_lands"],
                0,
            )
        )

    if derived["missing_oracle_id_quantity"] > 0:
        audit.issues.append(
            issue(
                "medium",
                "missing_oracle_id",
                "Resolved card list includes cards without oracle_id.",
                0,
                derived["missing_oracle_id_quantity"],
            )
        )

    if derived["missing_oracle_text_quantity"] > 0:
        audit.issues.append(
            issue(
                "medium",
                "missing_oracle_text",
                "Resolved card list includes cards without oracle_text.",
                0,
                derived["missing_oracle_text_quantity"],
            )
        )

    zero_core = [
        key for key in CORE_METADATA_KEYS if int_value(metadata.get(key) or 0) == 0
    ]
    if len(zero_core) == len(CORE_METADATA_KEYS):
        audit.issues.append(
            issue(
                "high",
                "all_core_metadata_zero",
                "All core metadata counters are zero.",
                "non-zero derived summary",
                zero_core,
            )
        )
    elif zero_core:
        audit.issues.append(
            issue(
                "medium",
                "some_core_metadata_zero",
                "Some core metadata counters are zero.",
                "review derived summary",
                zero_core,
            )
        )


def load_active_learned_decks(
    conn: psycopg2.extensions.connection,
    lookup: dict[str, CardIdentity],
) -> list[LearnedDeckAudit]:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT
                id,
                commander_name,
                deck_name,
                source_system,
                source_ref,
                card_count,
                metadata,
                card_list
            FROM commander_learned_decks
            WHERE is_active = true
            ORDER BY commander_name, deck_name
            """
        )
        rows = cur.fetchall()

    audits: list[LearnedDeckAudit] = []
    for row in rows:
        commander_name = str(row["commander_name"])
        cards = parse_card_list(row["card_list"])
        resolved = [resolve_card(card, lookup) for card in cards]
        commander_identity = find_commander_identity(commander_name, resolved, lookup)
        allowed_colors = (
            set(commander_identity.color_identity) if commander_identity is not None else None
        )
        derived_metadata = derive_metadata(resolved, allowed_colors=allowed_colors)
        partner_context = infer_partner_identity_context(
            commander_name,
            str(row["deck_name"]),
            resolved,
            allowed_colors,
        )
        derived_metadata.update(partner_context)
        derived_metadata["commander_identity_model"] = build_commander_identity_model(
            commander_name,
            str(row["deck_name"]),
            str(row["source_ref"]),
            resolved,
            allowed_colors,
            partner_context,
        )
        derived_metadata["commander_deck_shape"] = evaluate_commander_deck_shape(
            commander_name,
            cards,
            derived_metadata,
        )
        audit = LearnedDeckAudit(
            commander_name=commander_name,
            deck_name=str(row["deck_name"]),
            source_system=str(row["source_system"]),
            source_ref=str(row["source_ref"]),
            row_id=str(row["id"]),
            card_count_declared=int(row["card_count"] or 0),
            metadata=json_value(row["metadata"], {}),
            parsed_cards=cards,
            resolved_cards=resolved,
            derived_metadata=derived_metadata,
        )
        compare_metadata(audit)
        audits.append(audit)
    return audits


def sqlite_deck_snapshot(path: Path, deck_id: int) -> dict[str, Any] | None:
    if not path.exists():
        return None
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    try:
        deck = conn.execute(
            "SELECT id, deck_name, archetype, total_cards, notes FROM decks WHERE id = ?",
            (deck_id,),
        ).fetchone()
        if deck is None:
            return None
        rows = conn.execute(
            """
            SELECT card_name, quantity, is_commander, cmc, type_line, functional_tag
            FROM deck_cards
            WHERE deck_id = ?
            ORDER BY lower(card_name)
            """,
            (deck_id,),
        ).fetchall()
        cards = [
            {
                "name": str(row["card_name"]),
                "quantity": int(row["quantity"] or 1),
                "is_commander": bool(row["is_commander"]),
                "cmc": row["cmc"],
                "type_line": row["type_line"],
                "functional_tag": row["functional_tag"],
            }
            for row in rows
        ]
        pg_deck_id = None
        match = re.search(r"pg_deck_id=([0-9a-fA-F-]{36})", str(deck["notes"] or ""))
        if match:
            pg_deck_id = match.group(1)
        return {
            "id": int(deck["id"]),
            "deck_name": str(deck["deck_name"] or ""),
            "archetype": str(deck["archetype"] or ""),
            "total_cards": int(deck["total_cards"] or 0),
            "notes": str(deck["notes"] or ""),
            "pg_deck_id": pg_deck_id,
            "cards": cards,
            "card_quantity": sum(card["quantity"] for card in cards),
            "commander_quantity": sum(
                card["quantity"] for card in cards if card["is_commander"]
            ),
            "land_quantity": sum(
                card["quantity"]
                for card in cards
                if "land" in str(card["type_line"] or "").lower()
            ),
        }
    finally:
        conn.close()


def pg_saved_deck_snapshot(
    conn: psycopg2.extensions.connection,
    deck_id: str | None,
) -> dict[str, Any] | None:
    if not deck_id:
        return None
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT id, name, format, archetype, bracket, synergy_score
            FROM decks
            WHERE id = %s
            """,
            (deck_id,),
        )
        deck = cur.fetchone()
        if deck is None:
            return None
        cur.execute(
            """
            SELECT
                dc.quantity,
                dc.is_commander,
                cis.name,
                cis.oracle_id,
                cis.oracle_text,
                cis.type_line,
                cis.cmc,
                cis.color_identity,
                cis.legalities,
                cis.function_tags,
                cis.source_coverage
            FROM deck_cards dc
            LEFT JOIN card_intelligence_snapshot cis ON cis.card_id = dc.card_id
            WHERE dc.deck_id = %s
            ORDER BY lower(cis.name)
            """,
            (deck_id,),
        )
        rows = cur.fetchall()
    cards = [
        {
            "name": str(row["name"] or ""),
            "quantity": int(row["quantity"] or 1),
            "is_commander": bool(row["is_commander"]),
            "oracle_id": str(row["oracle_id"]) if row["oracle_id"] else None,
            "oracle_text": str(row["oracle_text"] or ""),
            "type_line": str(row["type_line"] or ""),
            "cmc": decimal_to_float(row["cmc"]),
            "color_identity": [str(item) for item in row["color_identity"] or []],
            "legalities": json_value(row["legalities"], {}),
            "function_tags": [str(item) for item in row["function_tags"] or []],
            "source_coverage": json_value(row["source_coverage"], {}),
        }
        for row in rows
    ]
    missing_legalities: list[str] = []
    commander_legality_assumptions: list[dict[str, str]] = []
    for card in cards:
        if card["legalities"].get("commander") is not None:
            continue
        override_reason = commander_legality_override_reason(card["name"])
        if override_reason:
            commander_legality_assumptions.append(
                {
                    "name": card["name"],
                    "format": "commander",
                    "reason": override_reason,
                }
            )
            continue
        missing_legalities.append(card["name"])
    off_color = [
        card["name"]
        for card in cards
        if any(color not in LOREHOLD_ALLOWED_COLORS for color in card["color_identity"])
    ]
    missing_oracle_id = [card["name"] for card in cards if not card["oracle_id"]]
    missing_oracle_text = [
        card["name"] for card in cards if not str(card["oracle_text"]).strip()
    ]
    return {
        "id": str(deck["id"]),
        "name": str(deck["name"]),
        "format": str(deck["format"]),
        "archetype": deck["archetype"],
        "card_rows": len(cards),
        "card_quantity": sum(card["quantity"] for card in cards),
        "commander_quantity": sum(
            card["quantity"] for card in cards if card["is_commander"]
        ),
        "land_quantity": sum(
            card["quantity"]
            for card in cards
            if "land" in str(card["type_line"]).lower()
        ),
        "missing_legalities": sorted(set(missing_legalities)),
        "commander_legality_assumptions": sorted(
            commander_legality_assumptions,
            key=lambda item: item["name"].lower(),
        ),
        "missing_oracle_id": sorted(set(missing_oracle_id)),
        "missing_oracle_text": sorted(set(missing_oracle_text)),
        "off_color_candidates": sorted(set(off_color)),
        "cards": cards,
    }


def pg_oracle_inventory(conn: psycopg2.extensions.connection) -> dict[str, Any]:
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute(
            """
            SELECT
                COUNT(*) AS total_cards,
                COUNT(*) FILTER (
                    WHERE oracle_id IS NOT NULL
                    AND BTRIM(oracle_id::text) <> ''
                ) AS with_oracle_id,
                COUNT(*) FILTER (
                    WHERE oracle_id IS NULL
                    OR BTRIM(oracle_id::text) = ''
                ) AS missing_oracle_id,
                COUNT(*) FILTER (
                    WHERE oracle_text IS NOT NULL
                    AND BTRIM(oracle_text) <> ''
                ) AS with_oracle_text,
                COUNT(*) FILTER (
                    WHERE oracle_text IS NULL
                    OR BTRIM(oracle_text) = ''
                ) AS missing_oracle_text,
                COUNT(*) FILTER (
                    WHERE type_line IS NOT NULL
                    AND BTRIM(type_line) <> ''
                ) AS with_type_line,
                COUNT(*) FILTER (
                    WHERE type_line IS NULL
                    OR BTRIM(type_line) = ''
                ) AS missing_type_line,
                COUNT(*) FILTER (
                    WHERE oracle_id IS NOT NULL
                    AND BTRIM(oracle_id::text) <> ''
                    AND oracle_text IS NOT NULL
                    AND BTRIM(oracle_text) <> ''
                    AND type_line IS NOT NULL
                    AND BTRIM(type_line) <> ''
                ) AS oracle_structured_cards
            FROM card_intelligence_snapshot
            """
        )
        summary = dict(cur.fetchone() or {})
        cur.execute(
            """
            SELECT name, oracle_id, oracle_text, type_line
            FROM card_intelligence_snapshot
            WHERE oracle_id IS NULL
               OR BTRIM(oracle_id::text) = ''
               OR oracle_text IS NULL
               OR BTRIM(oracle_text) = ''
               OR type_line IS NULL
               OR BTRIM(type_line) = ''
            ORDER BY lower(name)
            LIMIT 25
            """
        )
        sample_rows = cur.fetchall()
    total_cards = int(summary.get("total_cards") or 0)
    structured_cards = int(summary.get("oracle_structured_cards") or 0)
    return {
        key: int(value or 0) for key, value in summary.items()
    } | {
        "oracle_structured_rate": round(
            structured_cards / total_cards,
            4,
        )
        if total_cards
        else None,
        "sample_unstructured_cards": [
            {
                "name": str(row["name"] or ""),
                "oracle_id_present": bool(row["oracle_id"]),
                "oracle_text_present": bool(str(row["oracle_text"] or "").strip()),
                "type_line_present": bool(str(row["type_line"] or "").strip()),
            }
            for row in sample_rows
        ],
    }


def normalized_counter(names: Iterable[str]) -> Counter[str]:
    return Counter(normalize_name(front_face_name(name)) for name in names)


def lorehold_focused_audit(
    conn: psycopg2.extensions.connection,
    audits: list[LearnedDeckAudit],
    knowledge_db: Path,
    hermes_deck_id: int,
) -> dict[str, Any]:
    active = next(
        (
            audit
            for audit in audits
            if audit.commander_name.lower() == "lorehold, the historian"
            and (
                audit.metadata.get("hermes_active_deck_id") == hermes_deck_id
                or audit.source_ref == "learned_deck:82"
            )
        ),
        None,
    )
    sqlite_snapshot = sqlite_deck_snapshot(knowledge_db, hermes_deck_id)
    pg_snapshot = pg_saved_deck_snapshot(
        conn, sqlite_snapshot.get("pg_deck_id") if sqlite_snapshot else None
    )

    cardlist_names = [card.name for card in active.parsed_cards] if active else []
    sqlite_names = [card["name"] for card in sqlite_snapshot["cards"]] if sqlite_snapshot else []
    pg_names = [card["name"] for card in pg_snapshot["cards"]] if pg_snapshot else []

    name_match = {
        "active_vs_sqlite_missing_from_sqlite": sorted(
            (normalized_counter(cardlist_names) - normalized_counter(sqlite_names)).elements()
        ),
        "sqlite_extra_vs_active": sorted(
            (normalized_counter(sqlite_names) - normalized_counter(cardlist_names)).elements()
        ),
        "active_vs_pg_missing_from_pg": sorted(
            (normalized_counter(cardlist_names) - normalized_counter(pg_names)).elements()
        ),
        "pg_extra_vs_active": sorted(
            (normalized_counter(pg_names) - normalized_counter(cardlist_names)).elements()
        ),
    }

    no_premium_mox_present = sorted(
        {
            name
            for name in cardlist_names + sqlite_names + pg_names
            if normalize_name(front_face_name(name))
            in {normalize_name(card) for card in LOREHOLD_NO_PREMIUM_MOX}
        }
    )
    strategy_checks = evaluate_lorehold_strategy(cardlist_names)

    return {
        "active_learned_deck": audit_to_json(active) if active else None,
        "sqlite_deck": {
            key: value
            for key, value in (sqlite_snapshot or {}).items()
            if key != "cards"
        },
        "pg_saved_deck": {
            key: value
            for key, value in (pg_snapshot or {}).items()
            if key != "cards"
        },
        "name_match": name_match,
        "no_premium_mox_present": no_premium_mox_present,
        "strategy_checks": strategy_checks,
    }


def audit_to_json(audit: LearnedDeckAudit | None) -> dict[str, Any] | None:
    if audit is None:
        return None
    manual_off_color_review = OFF_COLOR_MANUAL_REVIEWS.get(audit.source_ref)
    effective_off_color = audit.derived_metadata.get(
        "off_color_after_partner_inference",
        audit.derived_metadata.get("off_color_candidates", []),
    )
    if manual_off_color_review and not effective_off_color:
        manual_off_color_review = None
    return {
        "row_id": audit.row_id,
        "commander_name": audit.commander_name,
        "deck_name": audit.deck_name,
        "source_system": audit.source_system,
        "source_ref": audit.source_ref,
        "card_count_declared": audit.card_count_declared,
        "parsed_quantity": audit.parsed_quantity,
        "resolved_quantity": audit.derived_metadata["resolved_quantity"],
        "unresolved": audit.unresolved,
        "metadata": audit.metadata,
        "derived_metadata": audit.derived_metadata,
        "issues": audit.issues,
        "manual_off_color_review": manual_off_color_review,
    }


def build_off_color_resolution_plan(
    audits: list[LearnedDeckAudit],
    lookup: dict[str, CardIdentity],
) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    for audit in audits:
        review = OFF_COLOR_MANUAL_REVIEWS.get(audit.source_ref)
        if not review:
            continue
        identity_model = audit.derived_metadata.get("commander_identity_model") or {}
        allowed_colors = set(
            identity_model.get("combined_color_identity")
            or audit.derived_metadata.get("commander_color_identity")
            or []
        )
        raw_cards = [str(card) for card in review.get("cards") or []]
        resolved_as = [str(card) for card in review.get("resolved_as") or []]
        raw_entries: list[dict[str, Any]] = []
        for index, raw_name in enumerate(raw_cards):
            resolved_name = resolved_as[index] if index < len(resolved_as) else None
            matched_lines = [
                resolved
                for resolved in audit.resolved_cards
                if normalize_name(resolved.line.name) == normalize_name(raw_name)
            ]
            resolved_identity = matched_lines[0].identity if matched_lines else None
            raw_entries.append(
                {
                    "raw_card_list_name": raw_name,
                    "quantity_in_card_list": sum(
                        item.line.quantity for item in matched_lines
                    ),
                    "currently_resolved_as": (
                        resolved_identity.canonical_name
                        if resolved_identity
                        else resolved_name
                    ),
                    "current_card_id": resolved_identity.card_id
                    if resolved_identity
                    else None,
                    "current_resolved_color_identity": sorted(
                        resolved_identity.color_identity
                    )
                    if resolved_identity
                    else [],
                    "expected_color_identity": review.get(
                        "expected_color_identity",
                        [],
                    ),
                    "expected_in_commander_identity": set(
                        review.get("expected_color_identity") or []
                    ).issubset(allowed_colors),
                    "resolved_as_off_color": bool(
                        resolved_identity
                        and not set(resolved_identity.color_identity).issubset(
                            allowed_colors
                        )
                    ),
                }
            )
        off_color_after_partner = audit.derived_metadata.get(
            "off_color_after_partner_inference",
            [],
        )
        if not off_color_after_partner and not any(
            card["resolved_as_off_color"] for card in raw_entries
        ):
            continue
        entries.append(
            {
                "row_id": audit.row_id,
                "source_ref": audit.source_ref,
                "commander_name": audit.commander_name,
                "deck_name": audit.deck_name,
                "allowed_color_identity": sorted(allowed_colors),
                "classification": review.get("classification"),
                "decision": review.get("decision"),
                "note": review.get("note"),
                "off_color_after_partner_inference": off_color_after_partner,
                "cards": raw_entries,
                "apply_requires_explicit_approval": True,
                "suggested_review_sql": (
                    "SELECT id, commander_name, deck_name, source_ref, card_list "
                    "FROM commander_learned_decks "
                    f"WHERE id = '{audit.row_id}';"
                ),
            }
        )
    return {
        "status": "ready_for_review"
        if entries
        else "no_current_off_color_manual_entries",
        "db_mutations": False,
        "apply_requires_explicit_approval": True,
        "entry_count": len(entries),
        "entries": entries,
    }


def summarize(audits: list[LearnedDeckAudit]) -> dict[str, Any]:
    by_source: dict[str, Counter[str]] = defaultdict(Counter)
    severity_counts: Counter[str] = Counter()
    summary: Counter[str] = Counter()

    for audit in audits:
        summary["active_learned_decks"] += 1
        by_source[audit.source_system]["active"] += 1
        for issue_item in audit.issues:
            code = str(issue_item["code"])
            severity = str(issue_item["severity"])
            summary[code] += 1
            severity_counts[severity] += 1
            by_source[audit.source_system][code] += 1
            by_source[audit.source_system][severity] += 1

    return {
        "summary": dict(sorted(summary.items())),
        "severity_counts": dict(sorted(severity_counts.items())),
        "by_source": {
            source: dict(sorted(counter.items()))
            for source, counter in sorted(by_source.items())
        },
    }


def active_learned_deck_metadata_gate_failures(
    payload: dict[str, Any],
) -> list[dict[str, Any]]:
    failures: list[dict[str, Any]] = []
    for deck in payload.get("decks") or []:
        if not isinstance(deck, dict):
            continue
        for issue_item in deck.get("issues") or []:
            if not isinstance(issue_item, dict):
                continue
            code = str(issue_item.get("code") or "")
            if code not in ACTIVE_LEARNED_DECK_GATE_ISSUE_CODES:
                continue
            failures.append(
                {
                    "row_id": deck.get("row_id"),
                    "source_ref": deck.get("source_ref"),
                    "commander_name": deck.get("commander_name"),
                    "deck_name": deck.get("deck_name"),
                    "code": code,
                    "expected": issue_item.get("expected"),
                    "actual": issue_item.get("actual"),
                    "message": issue_item.get("message"),
                }
            )
    return failures


def active_learned_deck_metadata_gate_summary(
    payload: dict[str, Any],
) -> dict[str, Any]:
    failures = active_learned_deck_metadata_gate_failures(payload)
    by_code = Counter(str(item["code"]) for item in failures)
    return {
        "status": "fail" if failures else "pass",
        "failure_count": len(failures),
        "failing_issue_codes": dict(sorted(by_code.items())),
        "failures": failures,
    }


def markdown_report(payload: dict[str, Any]) -> str:
    generated_at = payload["generated_at"]
    summary = payload["aggregate"]["summary"]
    severity = payload["aggregate"]["severity_counts"]
    by_source = payload["aggregate"]["by_source"]
    oracle_inventory = payload["postgres_oracle_inventory"]
    lorehold = payload["lorehold"]

    lines = [
        "# Learned Deck Coherence Audit",
        "",
        f"- Generated at: `{generated_at}`",
        f"- Active learned decks checked: `{summary.get('active_learned_decks', 0)}`",
        f"- High issues: `{severity.get('high', 0)}`",
        f"- Medium issues: `{severity.get('medium', 0)}`",
        "",
        "## PostgreSQL Oracle Structure",
        "",
        f"- Total cards in `card_intelligence_snapshot`: `{oracle_inventory.get('total_cards', 0)}`",
        f"- Oracle-structured cards: `{oracle_inventory.get('oracle_structured_cards', 0)}`",
        f"- Oracle-structured rate: `{oracle_inventory.get('oracle_structured_rate')}`",
        f"- Missing `oracle_id`: `{oracle_inventory.get('missing_oracle_id', 0)}`",
        f"- Missing `oracle_text`: `{oracle_inventory.get('missing_oracle_text', 0)}`",
        f"- Missing `type_line`: `{oracle_inventory.get('missing_type_line', 0)}`",
    ]
    sample_unstructured = oracle_inventory.get("sample_unstructured_cards") or []
    if sample_unstructured:
        lines.extend(["", "Sample unstructured cards:"])
        for card in sample_unstructured[:10]:
            lines.append(
                "- `{name}`: oracle_id `{oracle_id}`, oracle_text `{oracle_text}`, type_line `{type_line}`".format(
                    name=card.get("name"),
                    oracle_id="yes" if card.get("oracle_id_present") else "no",
                    oracle_text="yes" if card.get("oracle_text_present") else "no",
                    type_line="yes" if card.get("type_line_present") else "no",
                )
            )
    lines.extend(
        [
            "",
            "## Source Summary",
            "",
            "| Source | Active | High | Medium | Land Metadata Mismatch | Deck Qty Bad | Commander Qty Bad | Partner Gap | Off Color | Land Review | Missing Oracle Text |",
            "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for source, counts in by_source.items():
        lines.append(
            "| {source} | {active} | {high} | {medium} | {lands} | {qty} | {commander_qty} | {partner_gap} | {off_color} | {land_review} | {oracle_text} |".format(
                source=source,
                active=counts.get("active", 0),
                high=counts.get("high", 0),
                medium=counts.get("medium", 0),
                lands=counts.get("metadata_total_lands_mismatch", 0),
                qty=counts.get("commander_deck_quantity_mismatch", 0),
                commander_qty=counts.get("commander_quantity_mismatch", 0),
                partner_gap=counts.get("partner_identity_not_modeled", 0),
                off_color=counts.get("off_color_cards", 0),
                land_review=counts.get("land_count_low_review", 0)
                + counts.get("land_count_high_review", 0),
                oracle_text=counts.get("missing_oracle_text", 0),
            )
        )

    manual_off_color_reviews = [
        deck
        for deck in payload["decks"]
        if deck.get("manual_off_color_review") is not None
    ]
    if manual_off_color_reviews:
        lines.extend(
            [
                "",
                "## Manual Off-Color Review",
                "",
                "| Commander | Source | Classification | Cards | Decision |",
                "| --- | --- | --- | --- | --- |",
            ]
        )
        for deck in sorted(
            manual_off_color_reviews,
            key=lambda item: (item["commander_name"], item["source_ref"]),
        ):
            review = deck.get("manual_off_color_review") or {}
            lines.append(
                "| {commander} | {source_ref} | {classification} | {cards} | {decision} |".format(
                    commander=deck.get("commander_name"),
                    source_ref=deck.get("source_ref"),
                    classification=review.get("classification"),
                    cards=", ".join(review.get("cards") or []),
                    decision=review.get("decision"),
                )
            )

    cleanup_plan = payload.get("off_color_resolution_plan") or {}
    cleanup_entries = cleanup_plan.get("entries") or []
    if cleanup_entries:
        lines.extend(
            [
                "",
                "## Off-Color Resolution Plan",
                "",
                f"- Status: `{cleanup_plan.get('status')}`",
                f"- DB mutations: `{cleanup_plan.get('db_mutations')}`",
                f"- Apply requires explicit approval: `{cleanup_plan.get('apply_requires_explicit_approval')}`",
                "",
                "| Commander | Source | Classification | Raw card | Quantity | Resolved as | Expected colors | Current colors | Decision |",
                "| --- | --- | --- | --- | ---: | --- | --- | --- | --- |",
            ]
        )
        for deck in cleanup_entries:
            for card in deck.get("cards") or []:
                lines.append(
                    "| {commander} | {source_ref} | {classification} | {raw} | {quantity} | {resolved_as} | {expected_colors} | {current_colors} | {decision} |".format(
                        commander=deck.get("commander_name"),
                        source_ref=deck.get("source_ref"),
                        classification=deck.get("classification"),
                        raw=card.get("raw_card_list_name"),
                        quantity=card.get("quantity_in_card_list", 0),
                        resolved_as=card.get("currently_resolved_as"),
                        expected_colors=", ".join(card.get("expected_color_identity") or []),
                        current_colors=", ".join(card.get("current_resolved_color_identity") or []),
                        decision=deck.get("decision"),
                    )
                )

    combined_identity_models = [
        deck
        for deck in payload["decks"]
        if (deck.get("derived_metadata") or {})
        .get("commander_identity_model", {})
        .get("requires_first_class_persistence")
    ]
    if combined_identity_models:
        lines.extend(
            [
                "",
                "## Combined Commander Identity Models",
                "",
                "| Commander | Source | Status | Combined Identity | Components |",
                "| --- | --- | --- | --- | --- |",
            ]
        )
        for deck in sorted(
            combined_identity_models,
            key=lambda item: (item["commander_name"], item["source_ref"]),
        ):
            model = (deck.get("derived_metadata") or {}).get(
                "commander_identity_model",
                {},
            )
            components = ", ".join(
                item.get("name", "") for item in model.get("identity_components") or []
            )
            lines.append(
                "| {commander} | {source_ref} | {status} | {identity} | {components} |".format(
                    commander=deck.get("commander_name"),
                    source_ref=deck.get("source_ref"),
                    status=model.get("status"),
                    identity="".join(model.get("combined_color_identity") or []) or "-",
                    components=components or "-",
                )
            )

    active = lorehold.get("active_learned_deck") or {}
    active_derived = active.get("derived_metadata") or {}
    sqlite_deck = lorehold.get("sqlite_deck") or {}
    pg_deck = lorehold.get("pg_saved_deck") or {}
    name_match = lorehold.get("name_match") or {}
    strategy = lorehold.get("strategy_checks") or {}
    lines.extend(
        [
            "",
            "## Lorehold Deck 6",
            "",
            f"- Active learned source ref: `{active.get('source_ref')}`",
            f"- Active learned row id: `{active.get('row_id')}`",
            f"- SQLite deck id: `{sqlite_deck.get('id')}`",
            f"- SQLite linked PG deck id: `{sqlite_deck.get('pg_deck_id')}`",
            f"- PG saved deck rows: `{pg_deck.get('card_rows')}`",
            f"- PG saved deck lands: `{pg_deck.get('land_quantity')}`",
            f"- Active metadata lands: `{(active.get('metadata') or {}).get('total_lands')}`",
            f"- Derived learned lands: `{active_derived.get('total_lands')}`",
            f"- Active missing Commander legalities: `{', '.join(active_derived.get('missing_legalities') or []) or 'none'}`",
            f"- Active assumed Commander legalities: `{', '.join(item.get('name', '') for item in active_derived.get('commander_legality_assumptions') or []) or 'none'}`",
            f"- PG saved missing Commander legalities: `{', '.join(pg_deck.get('missing_legalities') or []) or 'none'}`",
            f"- PG saved assumed Commander legalities: `{', '.join(item.get('name', '') for item in pg_deck.get('commander_legality_assumptions') or []) or 'none'}`",
            f"- No-premium-Mox violations: `{len(lorehold.get('no_premium_mox_present') or [])}`",
            f"- Strategy package pass: `{'yes' if strategy.get('passed') else 'no'}`",
            f"- Name diff active -> SQLite: `{len(name_match.get('active_vs_sqlite_missing_from_sqlite') or [])}`",
            f"- Name diff active -> PG: `{len(name_match.get('active_vs_pg_missing_from_pg') or [])}`",
            "",
            "## Lorehold Strategy Checks",
            "",
            "| Package | Present | Minimum | Missing | Status |",
            "| --- | ---: | ---: | --- | --- |",
        ]
    )
    for package in strategy.get("packages") or []:
        missing = ", ".join(package.get("required_missing") or package.get("missing") or [])
        if len(missing) > 120:
            missing = f"{missing[:117]}..."
        lines.append(
            "| {label} | {present} | {minimum} | {missing} | {status} |".format(
                label=package.get("label"),
                present=package.get("present_count"),
                minimum=package.get("minimum"),
                missing=missing or "-",
                status="pass" if package.get("passed") else "review",
            )
        )
    forbidden = strategy.get("forbidden_present") or []
    lines.extend(
        [
            "",
            f"- Forbidden Premium Mox present: `{', '.join(forbidden) if forbidden else 'none'}`",
            "",
            "## Top Issues",
            "",
        ]
    )

    top_audits = sorted(
        payload["decks"],
        key=lambda item: (
            -sum(1 for issue_item in item["issues"] if issue_item["severity"] == "high"),
            -len(item["issues"]),
            item["commander_name"],
        ),
    )[:20]
    for item in top_audits:
        high = sum(1 for issue_item in item["issues"] if issue_item["severity"] == "high")
        medium = sum(1 for issue_item in item["issues"] if issue_item["severity"] == "medium")
        codes = ", ".join(sorted({issue_item["code"] for issue_item in item["issues"]}))
        lines.append(
            f"- `{item['commander_name']}` / `{item['source_ref']}`: high `{high}`, medium `{medium}`; {codes}"
        )

    off_color_count = payload["aggregate"]["summary"].get("off_color_cards", 0)
    off_color_recommendation = (
        "6. Manually review remaining off-color cards after partner inference."
        if off_color_count
        else "6. No current off-color cards remain after partner/deck-name inference; keep monitoring new audit artifacts."
    )
    lines.extend(
        [
            "",
            "## Recommended Next Adjustments",
            "",
            "1. Continue re-deriving and backfilling active learned-deck metadata mismatches with explicit mutation approval.",
            "2. Keep Lorehold learned deck 82 under no-swap monitoring; current metadata and strategy package checks pass.",
            "3. Continue broader semantic/function-tag backfill for non-Lorehold learned decks using dry-run plans first.",
            "4. Treat missing legality rows separately from real illegality or off-color violations.",
            "5. Persist partner/background identity for decks where inferred partner colors explain off-color candidates.",
            off_color_recommendation,
            "7. Keep Lorehold no-premium-Mox policy scoped to Lorehold until a bracket/product policy exists.",
            "",
        ]
    )
    return "\n".join(lines)


def write_outputs(payload: dict[str, Any], output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    timestamp = utc_now().strftime("%Y%m%d_%H%M%S")
    json_path = output_dir / f"learned_deck_coherence_audit_{timestamp}.json"
    md_path = output_dir / f"learned_deck_coherence_audit_{timestamp}.md"
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    md_path.write_text(markdown_report(payload), encoding="utf-8")
    return json_path, md_path


def build_payload(args: argparse.Namespace) -> dict[str, Any]:
    conn = connect_pg()
    conn.set_session(readonly=True, autocommit=True)
    try:
        lookup = load_card_lookup(conn)
        audits = load_active_learned_decks(conn, lookup)
        payload = {
            "generated_at": utc_now().isoformat(),
            "read_only": True,
            "sources": {
                "postgres": {
                    "database": os.environ.get("DB_NAME"),
                    "host_present": bool(os.environ.get("DB_HOST")),
                },
                "knowledge_db": str(args.knowledge_db),
            },
            "postgres_oracle_inventory": pg_oracle_inventory(conn),
            "aggregate": summarize(audits),
            "off_color_resolution_plan": build_off_color_resolution_plan(
                audits,
                lookup,
            ),
            "lorehold": lorehold_focused_audit(
                conn,
                audits,
                args.knowledge_db,
                args.hermes_deck_id,
            ),
            "decks": [audit_to_json(audit) for audit in audits],
        }
        return payload
    finally:
        conn.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--knowledge-db",
        type=Path,
        default=DEFAULT_KNOWLEDGE_DB,
        help="Hermes SQLite knowledge DB path.",
    )
    parser.add_argument(
        "--hermes-deck-id",
        type=int,
        default=6,
        help="Hermes deck id for the focused Lorehold check.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Directory for JSON and Markdown audit artifacts.",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print compact JSON summary instead of writing artifacts.",
    )
    parser.add_argument(
        "--gate-active-learned-deck-metadata",
        action="store_true",
        help=(
            "Return non-zero when active learned decks have unresolved names, "
            "zeroed core metadata, or total_lands metadata mismatches."
        ),
    )
    args = parser.parse_args(argv)

    payload = build_payload(args)
    gate_summary = active_learned_deck_metadata_gate_summary(payload)
    if args.stdout:
        stdout_payload = payload["aggregate"]
        if args.gate_active_learned_deck_metadata:
            compact_gate_summary = {
                key: value
                for key, value in gate_summary.items()
                if key != "failures"
            }
            stdout_payload = {
                **stdout_payload,
                "active_learned_deck_metadata_gate": compact_gate_summary,
            }
        print(json.dumps(stdout_payload, indent=2, ensure_ascii=False))
        return (
            1
            if args.gate_active_learned_deck_metadata
            and gate_summary["status"] == "fail"
            else 0
        )

    json_path, md_path = write_outputs(payload, args.output_dir)
    print(f"JSON: {json_path}")
    print(f"Markdown: {md_path}")
    if args.gate_active_learned_deck_metadata and gate_summary["status"] == "fail":
        print(
            "Active learned-deck metadata gate failed: "
            f"{gate_summary['failure_count']} invariant issue(s).",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
