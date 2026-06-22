#!/usr/bin/env python3
"""Stage and validate Lorehold deck variants before battle testing.

This tool intentionally writes only to local Hermes SQLite staging tables.
It does not write PostgreSQL and it does not promote a deck to production.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER = "Lorehold, the Historian"
COMMANDER_COLORS = {"R", "W"}

SECTION_HEADERS = {
    "artifact",
    "artifacts",
    "commander",
    "commanders",
    "creature",
    "creatures",
    "deck",
    "decklist",
    "draw",
    "enchantment",
    "enchantments",
    "instant",
    "instants",
    "land",
    "lands",
    "mainboard",
    "maybeboard",
    "planeswalker",
    "planeswalkers",
    "protection",
    "ramp",
    "removal",
    "sideboard",
    "sorceries",
    "sorcery",
    "spell",
    "spells",
    "tutor",
    "wincon",
    "wincons",
    "wipe",
}

ROLE_TO_TAG = {
    "attack_limit": "protection",
    "attack_tax": "protection",
    "board_wipe": "board_wipe",
    "counter": "protection",
    "draw_cards": "draw",
    "draw_engine": "draw",
    "extra_turn": "wincon",
    "finisher": "wincon",
    "indestructible": "protection",
    "phase_out": "protection",
    "ramp_engine": "ramp",
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "recursion": "engine",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "silence_opponents": "protection",
    "topdeck_manipulation": "draw",
    "tutor": "tutor",
    "wincon": "wincon",
}

TAG_PRIORITY = {
    "board_wipe": 10,
    "wincon": 20,
    "engine": 30,
    "draw": 40,
    "removal": 50,
    "ramp": 60,
    "tutor": 70,
    "protection": 80,
    "land": 900,
    "creature": 910,
    "unknown": 999,
}


@dataclass(frozen=True)
class ParsedCard:
    quantity: int
    name: str
    line_number: int


@dataclass(frozen=True)
class DeckBlock:
    name: str
    source: str
    source_url: str
    archetype: str
    cards: list[ParsedCard]

    @property
    def input_quantity(self) -> int:
        return sum(card.quantity for card in self.cards)


def normalize_name(value: str | None) -> str:
    text = str(value or "").strip()
    text = text.replace("\u2018", "'").replace("\u2019", "'")
    text = re.sub(r"\s+", " ", text)
    return text.lower()


def clean_card_name(raw: str) -> str:
    text = raw.strip().lstrip("-*\u2022").strip()
    text = re.sub(r"^\d+\s*x?\s+", "", text, flags=re.I).strip()
    text = re.sub(r"\s+\[[^\]]+\]\s*$", "", text).strip()
    text = re.sub(r"\s+\([A-Z0-9]{2,6}\)\s*\d*\s*$", "", text).strip()
    text = re.sub(r"\s+#\d+\s*$", "", text).strip()
    return re.sub(r"\s+", " ", text)


def parse_card_line(raw: str, line_number: int) -> ParsedCard | None:
    text = raw.strip().lstrip("-*\u2022").strip()
    if not text or text.startswith("#"):
        return None
    if text.lower().rstrip(":") in SECTION_HEADERS:
        return None
    if ":" in text:
        key = text.split(":", 1)[0].strip().lower()
        if key in {"archetype", "arqu\u00e9tipo", "arquetipo", "commander", "deck", "fonte", "name", "source", "url"}:
            return None
    match = re.match(r"^(?P<qty>\d+)\s*x?\s+(?P<name>.+)$", text, flags=re.I)
    if match:
        quantity = max(1, int(match.group("qty")))
        name = clean_card_name(match.group("name"))
    else:
        quantity = 1
        name = clean_card_name(text)
    if not name or normalize_name(name).rstrip(":") in SECTION_HEADERS:
        return None
    return ParsedCard(quantity=quantity, name=name, line_number=line_number)


def parse_deck_blocks(
    text: str,
    *,
    default_name: str = "Lorehold Variant",
    default_source: str = "manual-variant",
    default_archetype: str = "battle-variant",
) -> list[DeckBlock]:
    raw_blocks: list[dict[str, Any]] = []
    current: dict[str, Any] = {
        "name": default_name,
        "source": default_source,
        "source_url": "",
        "archetype": default_archetype,
        "lines": [],
    }
    saw_header = False

    for line_number, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        header = re.match(r"^(?:={2,}|#{2,})\s*(.+?)\s*(?:={2,})?$", line)
        if header:
            if current["lines"] or saw_header:
                raw_blocks.append(current)
            saw_header = True
            current = {
                "name": header.group(1).strip(),
                "source": default_source,
                "source_url": "",
                "archetype": default_archetype,
                "lines": [],
            }
            continue
        meta = re.match(r"^(Source|Fonte|URL|Archetype|Arqu[e\u00e9]tipo|Name|Deck)\s*:\s*(.+)$", line, flags=re.I)
        if meta:
            key = meta.group(1).lower()
            value = meta.group(2).strip()
            if key in {"source", "fonte"}:
                current["source"] = value
            elif key == "url":
                current["source_url"] = value
            elif key in {"archetype", "arqu\u00e9tipo", "arquetipo"}:
                current["archetype"] = value
            elif key in {"name", "deck"}:
                current["name"] = value
            continue
        current["lines"].append((line_number, raw))

    if current["lines"] or not raw_blocks:
        raw_blocks.append(current)

    parsed: list[DeckBlock] = []
    for index, block in enumerate(raw_blocks, start=1):
        cards_by_name: dict[str, ParsedCard] = {}
        for line_number, raw in block["lines"]:
            card = parse_card_line(raw, line_number)
            if not card:
                continue
            existing = cards_by_name.get(normalize_name(card.name))
            if existing:
                cards_by_name[normalize_name(card.name)] = ParsedCard(
                    quantity=existing.quantity + card.quantity,
                    name=existing.name,
                    line_number=existing.line_number,
                )
            else:
                cards_by_name[normalize_name(card.name)] = card
        if not cards_by_name:
            continue
        name = str(block["name"] or default_name)
        if name == default_name and len(raw_blocks) > 1:
            name = f"{default_name} #{index}"
        parsed.append(
            DeckBlock(
                name=name,
                source=str(block["source"] or default_source),
                source_url=str(block["source_url"] or ""),
                archetype=str(block["archetype"] or default_archetype),
                cards=sorted(cards_by_name.values(), key=lambda card: normalize_name(card.name)),
            )
        )
    return parsed


def ensure_tables(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS lorehold_variant_decks (
            deck_hash TEXT PRIMARY KEY,
            deck_name TEXT NOT NULL,
            source TEXT NOT NULL,
            source_url TEXT,
            archetype TEXT,
            commander TEXT NOT NULL,
            input_quantity INTEGER NOT NULL,
            total_quantity INTEGER NOT NULL,
            main_quantity INTEGER NOT NULL,
            commander_quantity INTEGER NOT NULL,
            unique_cards INTEGER NOT NULL,
            validation_status TEXT NOT NULL,
            issue_count INTEGER NOT NULL,
            warning_count INTEGER NOT NULL,
            raw_input_sha256 TEXT NOT NULL,
            report_json TEXT NOT NULL,
            report_path TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS lorehold_variant_deck_cards (
            deck_hash TEXT NOT NULL,
            card_name TEXT NOT NULL,
            input_name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            is_commander INTEGER NOT NULL,
            oracle_status TEXT NOT NULL,
            oracle_name TEXT,
            oracle_hash TEXT,
            color_identity_json TEXT NOT NULL DEFAULT '[]',
            cmc REAL,
            type_line TEXT,
            commander_legal INTEGER NOT NULL DEFAULT 0,
            is_basic_land INTEGER NOT NULL DEFAULT 0,
            battle_rule_count INTEGER NOT NULL DEFAULT 0,
            executable_rule_count INTEGER NOT NULL DEFAULT 0,
            functional_tag TEXT NOT NULL DEFAULT 'unknown',
            functional_tags_json TEXT NOT NULL DEFAULT '[]',
            issues_json TEXT NOT NULL DEFAULT '[]',
            warnings_json TEXT NOT NULL DEFAULT '[]',
            PRIMARY KEY (deck_hash, normalized_name),
            FOREIGN KEY (deck_hash) REFERENCES lorehold_variant_decks(deck_hash)
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS lorehold_variant_target_backups (
            backup_id TEXT PRIMARY KEY,
            target_deck_id INTEGER NOT NULL,
            source_variant_hash TEXT,
            deck_rows_json TEXT NOT NULL,
            deck_meta_json TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    conn.commit()


def deck_hash(deck: DeckBlock) -> str:
    payload = [
        {
            "name": normalize_name(card.name),
            "quantity": card.quantity,
        }
        for card in sorted(deck.cards, key=lambda item: normalize_name(item.name))
    ]
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def oracle_hash(row: sqlite3.Row | None) -> str | None:
    if not row:
        return None
    payload = {
        "name": row["name"],
        "type_line": row["type_line"] or "",
        "oracle_text": row["oracle_text"] or "",
        "cmc": row["cmc"],
        "color_identity": parse_json(row["color_identity_json"], []),
    }
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest()


def parse_json(value: Any, fallback: Any) -> Any:
    if value is None:
        return fallback
    if isinstance(value, (dict, list)):
        return value
    try:
        return json.loads(str(value))
    except Exception:
        return fallback


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, sort_keys=True, separators=(",", ":"))


def load_oracle(conn: sqlite3.Connection, name: str) -> sqlite3.Row | None:
    normalized = normalize_name(name)
    row = conn.execute(
        """
        SELECT normalized_name, name, mana_cost, colors_json, color_identity_json,
               type_line, oracle_text, cmc, power, toughness, keywords_json, scryfall_id,
               source, updated_at
        FROM card_oracle_cache
        WHERE normalized_name=?
        ORDER BY CASE WHEN normalized_name=? THEN 0 ELSE 1 END
        LIMIT 1
        """,
        (normalized, normalized),
    ).fetchone()
    if row:
        return row
    if "//" in normalized:
        first_face = normalize_name(normalized.split("//", 1)[0])
        return conn.execute(
            """
            SELECT normalized_name, name, mana_cost, colors_json, color_identity_json,
                   type_line, oracle_text, cmc, power, toughness, keywords_json, scryfall_id,
                   source, updated_at
            FROM card_oracle_cache
            WHERE normalized_name=?
            LIMIT 1
            """,
            (first_face,),
        ).fetchone()
    return None


def load_existing_deck_card_metadata(conn: sqlite3.Connection, oracle_name: str) -> sqlite3.Row | None:
    return conn.execute(
        """
        SELECT *
        FROM deck_cards
        WHERE lower(card_name)=lower(?)
        ORDER BY CASE WHEN deck_id=6 THEN 0 ELSE 1 END, deck_id
        LIMIT 1
        """,
        (oracle_name,),
    ).fetchone()


def load_battle_rules(conn: sqlite3.Connection, oracle_name: str) -> list[sqlite3.Row]:
    return conn.execute(
        """
        SELECT *
        FROM battle_card_rules
        WHERE normalized_name=? OR lower(card_name)=lower(?)
        ORDER BY
          CASE review_status WHEN 'verified' THEN 0 WHEN 'active' THEN 1 ELSE 2 END,
          CASE execution_status WHEN 'auto' THEN 0 WHEN 'executable' THEN 1 ELSE 2 END,
          logical_rule_key
        """,
        (normalize_name(oracle_name), oracle_name),
    ).fetchall()


def functional_tags_from_rules(rules: list[sqlite3.Row], oracle: sqlite3.Row | None) -> list[str]:
    tags: set[str] = set()
    for rule in rules:
        role = parse_json(rule["deck_role_json"], {})
        effect = parse_json(rule["effect_json"], {})
        for value in (
            role.get("category") if isinstance(role, dict) else None,
            role.get("role") if isinstance(role, dict) else None,
            effect.get("effect") if isinstance(effect, dict) else None,
        ):
            normalized = ROLE_TO_TAG.get(str(value or "").strip().lower(), str(value or "").strip().lower())
            if normalized:
                tags.add(normalized)
    if not tags and oracle:
        type_line = str(oracle["type_line"] or "").lower()
        oracle_text = str(oracle["oracle_text"] or "").lower()
        if "land" in type_line:
            tags.add("land")
        elif "destroy all" in oracle_text or "exile all" in oracle_text:
            tags.add("board_wipe")
        elif "search your library" in oracle_text:
            tags.add("tutor")
        elif "draw" in oracle_text:
            tags.add("draw")
        elif "add " in oracle_text or "treasure" in oracle_text:
            tags.add("ramp")
        elif "destroy target" in oracle_text or "exile target" in oracle_text:
            tags.add("removal")
        elif "you win the game" in oracle_text:
            tags.add("wincon")
        elif "creature" in type_line:
            tags.add("creature")
    if not tags:
        tags.add("unknown")
    return sorted(tags, key=lambda tag: (TAG_PRIORITY.get(tag, 500), tag))


def card_rule_payload(rules: list[sqlite3.Row]) -> list[dict[str, Any]]:
    payload: list[dict[str, Any]] = []
    for rule in rules:
        payload.append(
            {
                "logical_rule_key": rule["logical_rule_key"],
                "effect_json": parse_json(rule["effect_json"], {}),
                "deck_role_json": parse_json(rule["deck_role_json"], {}),
                "source": rule["source"],
                "confidence": rule["confidence"],
                "review_status": rule["review_status"],
                "execution_status": rule["execution_status"],
                "rule_version": rule["rule_version"],
                "oracle_hash": rule["oracle_hash"],
            }
        )
    return payload


def is_basic_land(oracle: sqlite3.Row | None) -> bool:
    if not oracle:
        return False
    type_line = str(oracle["type_line"] or "")
    return "Basic" in type_line and "Land" in type_line


def validate_deck(conn: sqlite3.Connection, deck: DeckBlock, raw_input_sha256: str) -> dict[str, Any]:
    commander_key = normalize_name(COMMANDER)
    deck_key = deck_hash(deck)
    issues: list[str] = []
    warnings: list[str] = []
    cards_report: list[dict[str, Any]] = []
    total_input_quantity = deck.input_quantity
    commander_quantity = 0
    main_quantity = 0
    singleton_seen: dict[str, str] = {}

    for parsed in deck.cards:
        oracle = load_oracle(conn, parsed.name)
        oracle_status = "matched" if oracle else "missing"
        oracle_name = str(oracle["name"]) if oracle else parsed.name
        normalized_oracle = normalize_name(oracle_name)
        color_identity = parse_json(oracle["color_identity_json"], []) if oracle else []
        type_line = str(oracle["type_line"] or "") if oracle else ""
        card_issues: list[str] = []
        card_warnings: list[str] = []
        is_commander = normalized_oracle == commander_key or normalize_name(parsed.name) == commander_key
        basic_land = is_basic_land(oracle)

        if not oracle:
            card_issues.append("oracle_missing")
        if not is_commander and not basic_land and parsed.quantity > 1:
            card_issues.append("singleton_violation")
        if normalized_oracle in singleton_seen and not basic_land:
            card_issues.append("duplicate_name_after_oracle_normalization")
        singleton_seen[normalized_oracle] = parsed.name

        off_colors = sorted(set(str(item) for item in color_identity) - COMMANDER_COLORS)
        commander_legal = bool(oracle and not off_colors)
        if off_colors:
            card_issues.append("off_color_identity:" + ",".join(off_colors))

        rules = load_battle_rules(conn, oracle_name) if oracle else []
        executable_rules = [
            rule
            for rule in rules
            if str(rule["execution_status"]).lower() in {"auto", "executable"}
            and str(rule["review_status"]).lower() in {"verified", "active"}
        ]
        if oracle and not executable_rules:
            card_warnings.append("no_verified_executable_battle_rule")

        tags = functional_tags_from_rules(rules, oracle)
        if is_commander:
            commander_quantity += parsed.quantity
        else:
            main_quantity += parsed.quantity

        if card_issues:
            issues.extend(f"{oracle_name}:{issue}" for issue in card_issues)
        if card_warnings:
            warnings.extend(f"{oracle_name}:{warning}" for warning in card_warnings)

        cards_report.append(
            {
                "input_name": parsed.name,
                "card_name": oracle_name,
                "normalized_name": normalized_oracle,
                "quantity": parsed.quantity,
                "line_number": parsed.line_number,
                "is_commander": is_commander,
                "oracle_status": oracle_status,
                "oracle_hash": oracle_hash(oracle),
                "color_identity": color_identity,
                "cmc": oracle["cmc"] if oracle else None,
                "type_line": type_line,
                "commander_legal": commander_legal,
                "is_basic_land": basic_land,
                "battle_rule_count": len(rules),
                "executable_rule_count": len(executable_rules),
                "functional_tags": tags,
                "issues": card_issues,
                "warnings": card_warnings,
            }
        )

    if commander_quantity == 0:
        commander_oracle = load_oracle(conn, COMMANDER)
        if not commander_oracle:
            issues.append("commander_oracle_missing")
        else:
            commander_rules = load_battle_rules(conn, COMMANDER)
            commander_tags = functional_tags_from_rules(commander_rules, commander_oracle)
            cards_report.append(
                {
                    "input_name": COMMANDER,
                    "card_name": COMMANDER,
                    "normalized_name": commander_key,
                    "quantity": 1,
                    "line_number": None,
                    "is_commander": True,
                    "oracle_status": "injected_commander",
                    "oracle_hash": oracle_hash(commander_oracle),
                    "color_identity": parse_json(commander_oracle["color_identity_json"], []),
                    "cmc": commander_oracle["cmc"],
                    "type_line": commander_oracle["type_line"],
                    "commander_legal": True,
                    "is_basic_land": False,
                    "battle_rule_count": len(commander_rules),
                    "executable_rule_count": len(
                        [
                            rule
                            for rule in commander_rules
                            if str(rule["execution_status"]).lower() in {"auto", "executable"}
                        ]
                    ),
                    "functional_tags": commander_tags,
                    "issues": [],
                    "warnings": [],
                }
            )
        total_quantity = total_input_quantity + 1
    else:
        total_quantity = total_input_quantity

    if commander_quantity not in (0, 1):
        issues.append(f"commander_quantity_invalid:{commander_quantity}")
    if total_quantity != 100:
        issues.append(f"expected_100_total_cards_found_{total_quantity}")
    if main_quantity != 99:
        issues.append(f"expected_99_main_cards_found_{main_quantity}")

    validation_status = "valid" if not issues else "invalid"
    report = {
        "deck_hash": deck_key,
        "deck_name": deck.name,
        "source": deck.source,
        "source_url": deck.source_url,
        "archetype": deck.archetype,
        "commander": COMMANDER,
        "input_quantity": total_input_quantity,
        "total_quantity": total_quantity,
        "main_quantity": main_quantity,
        "commander_quantity": commander_quantity,
        "unique_cards": len(cards_report),
        "validation_status": validation_status,
        "issues": issues,
        "warnings": warnings,
        "raw_input_sha256": raw_input_sha256,
        "cards": sorted(cards_report, key=lambda item: (not item["is_commander"], item["card_name"])),
    }
    return report


def stage_report(conn: sqlite3.Connection, report: dict[str, Any], report_path: str | None = None) -> None:
    ensure_tables(conn)
    now = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    deck_hash_value = str(report["deck_hash"])
    conn.execute(
        """
        INSERT INTO lorehold_variant_decks (
            deck_hash, deck_name, source, source_url, archetype, commander,
            input_quantity, total_quantity, main_quantity, commander_quantity,
            unique_cards, validation_status, issue_count, warning_count,
            raw_input_sha256, report_json, report_path, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(deck_hash) DO UPDATE SET
            deck_name=excluded.deck_name,
            source=excluded.source,
            source_url=excluded.source_url,
            archetype=excluded.archetype,
            input_quantity=excluded.input_quantity,
            total_quantity=excluded.total_quantity,
            main_quantity=excluded.main_quantity,
            commander_quantity=excluded.commander_quantity,
            unique_cards=excluded.unique_cards,
            validation_status=excluded.validation_status,
            issue_count=excluded.issue_count,
            warning_count=excluded.warning_count,
            raw_input_sha256=excluded.raw_input_sha256,
            report_json=excluded.report_json,
            report_path=excluded.report_path,
            updated_at=excluded.updated_at
        """,
        (
            deck_hash_value,
            report["deck_name"],
            report["source"],
            report.get("source_url") or "",
            report.get("archetype") or "",
            report["commander"],
            report["input_quantity"],
            report["total_quantity"],
            report["main_quantity"],
            report["commander_quantity"],
            report["unique_cards"],
            report["validation_status"],
            len(report["issues"]),
            len(report["warnings"]),
            report["raw_input_sha256"],
            stable_json(report),
            report_path or "",
            now,
            now,
        ),
    )
    conn.execute("DELETE FROM lorehold_variant_deck_cards WHERE deck_hash=?", (deck_hash_value,))
    for card in report["cards"]:
        tags = card.get("functional_tags") or ["unknown"]
        conn.execute(
            """
            INSERT INTO lorehold_variant_deck_cards (
                deck_hash, card_name, input_name, normalized_name, quantity,
                is_commander, oracle_status, oracle_name, oracle_hash,
                color_identity_json, cmc, type_line, commander_legal,
                is_basic_land, battle_rule_count, executable_rule_count,
                functional_tag, functional_tags_json, issues_json, warnings_json
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                deck_hash_value,
                card["card_name"],
                card["input_name"],
                card["normalized_name"],
                card["quantity"],
                1 if card["is_commander"] else 0,
                card["oracle_status"],
                card["card_name"],
                card.get("oracle_hash") or "",
                stable_json(card.get("color_identity") or []),
                card.get("cmc"),
                card.get("type_line") or "",
                1 if card.get("commander_legal") else 0,
                1 if card.get("is_basic_land") else 0,
                int(card.get("battle_rule_count") or 0),
                int(card.get("executable_rule_count") or 0),
                tags[0],
                stable_json(tags),
                stable_json(card.get("issues") or []),
                stable_json(card.get("warnings") or []),
            ),
        )
    conn.commit()


def load_staged_report(conn: sqlite3.Connection, selector: str) -> dict[str, Any]:
    ensure_tables(conn)
    row = conn.execute(
        """
        SELECT report_json
        FROM lorehold_variant_decks
        WHERE deck_hash=? OR lower(deck_name)=lower(?)
        ORDER BY updated_at DESC
        LIMIT 1
        """,
        (selector, selector),
    ).fetchone()
    if not row:
        raise SystemExit(f"Variant not found in staging: {selector}")
    return parse_json(row["report_json"], {})


def battle_rules_json_for_card(conn: sqlite3.Connection, card_name: str) -> str:
    rules = load_battle_rules(conn, card_name)
    return stable_json(card_rule_payload(rules))


def backup_target_deck(conn: sqlite3.Connection, target_deck_id: int, source_variant_hash: str | None) -> str:
    ensure_tables(conn)
    now = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    rows = [dict(row) for row in conn.execute("SELECT * FROM deck_cards WHERE deck_id=? ORDER BY id", (target_deck_id,))]
    meta = [
        dict(row)
        for row in conn.execute("SELECT * FROM decks WHERE id=? LIMIT 1", (target_deck_id,))
    ]
    digest = hashlib.sha256(stable_json({"rows": rows, "meta": meta, "created_at": now}).encode("utf-8")).hexdigest()[:12]
    backup_id = f"variant_target_{target_deck_id}_{dt.datetime.now(dt.UTC).strftime('%Y%m%dT%H%M%SZ')}_{digest}"
    conn.execute(
        """
        INSERT INTO lorehold_variant_target_backups (
            backup_id, target_deck_id, source_variant_hash,
            deck_rows_json, deck_meta_json, created_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (backup_id, target_deck_id, source_variant_hash or "", stable_json(rows), stable_json(meta), now),
    )
    conn.commit()
    return backup_id


def materialize_variant(conn: sqlite3.Connection, report: dict[str, Any], target_deck_id: int) -> str:
    if report.get("validation_status") != "valid":
        raise SystemExit(
            "Refusing to materialize invalid variant. "
            f"Issues: {', '.join(report.get('issues') or [])}"
        )
    backup_id = backup_target_deck(conn, target_deck_id, str(report["deck_hash"]))
    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (target_deck_id,))
    conn.execute(
        """
        INSERT INTO decks (id, deck_name, archetype, total_cards, notes)
        VALUES (?, ?, ?, 100, ?)
        ON CONFLICT(id) DO UPDATE SET
            deck_name=excluded.deck_name,
            archetype=excluded.archetype,
            total_cards=excluded.total_cards,
            notes=excluded.notes
        """,
        (
            target_deck_id,
            f"VARIANT {report['deck_name']}",
            report.get("archetype") or "battle-variant",
            f"lorehold_variant_hash={report['deck_hash']} backup_id={backup_id}",
        ),
    )
    for card in report["cards"]:
        oracle = load_oracle(conn, card["card_name"])
        existing = load_existing_deck_card_metadata(conn, card["card_name"])
        rules_json = battle_rules_json_for_card(conn, card["card_name"])
        tags = card.get("functional_tags") or ["unknown"]
        conn.execute(
            """
            INSERT INTO deck_cards (
                deck_id, card_name, quantity, functional_tag, tag_confidence,
                is_commander, is_partner, cmc, type_line, oracle_text, card_id,
                functional_tags_json, semantic_tags_v2_json, battle_rules_json,
                deck_hash, semantics_hash, sync_run_id, ruleset_hash
            )
            VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                target_deck_id,
                card["card_name"],
                int(card["quantity"]),
                tags[0],
                0.8,
                1 if card["is_commander"] else 0,
                card.get("cmc"),
                card.get("type_line") or "",
                oracle["oracle_text"] if oracle else "",
                existing["card_id"] if existing and "card_id" in existing.keys() else "",
                stable_json(tags),
                existing["semantic_tags_v2_json"] if existing and "semantic_tags_v2_json" in existing.keys() else "[]",
                rules_json,
                report["deck_hash"],
                existing["semantics_hash"] if existing and "semantics_hash" in existing.keys() else "",
                "lorehold_variant_stager",
                hashlib.sha256(rules_json.encode("utf-8")).hexdigest(),
            ),
        )
    conn.commit()
    return backup_id


def restore_backup(conn: sqlite3.Connection, backup_id: str) -> None:
    ensure_tables(conn)
    row = conn.execute(
        "SELECT * FROM lorehold_variant_target_backups WHERE backup_id=?",
        (backup_id,),
    ).fetchone()
    if not row:
        raise SystemExit(f"Backup not found: {backup_id}")
    target_deck_id = int(row["target_deck_id"])
    deck_rows = parse_json(row["deck_rows_json"], [])
    deck_meta = parse_json(row["deck_meta_json"], [])
    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (target_deck_id,))
    conn.execute("DELETE FROM decks WHERE id=?", (target_deck_id,))
    for meta in deck_meta:
        conn.execute(
            "INSERT INTO decks (id, deck_name, archetype, total_cards, notes) VALUES (?, ?, ?, ?, ?)",
            (
                meta.get("id"),
                meta.get("deck_name"),
                meta.get("archetype"),
                meta.get("total_cards"),
                meta.get("notes"),
            ),
        )
    for item in deck_rows:
        columns = [
            "deck_id",
            "card_name",
            "quantity",
            "functional_tag",
            "tag_confidence",
            "is_commander",
            "is_partner",
            "cmc",
            "type_line",
            "oracle_text",
            "card_id",
            "functional_tags_json",
            "semantic_tags_v2_json",
            "battle_rules_json",
            "deck_hash",
            "semantics_hash",
            "sync_run_id",
            "ruleset_hash",
        ]
        values = [item.get(column) for column in columns]
        placeholders = ",".join("?" for _ in columns)
        conn.execute(
            f"INSERT INTO deck_cards ({','.join(columns)}) VALUES ({placeholders})",
            values,
        )
    conn.commit()


def write_reports(reports: list[dict[str, Any]], output_dir: Path = DEFAULT_REPORT_DIR) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now(dt.UTC).strftime("%Y%m%d_%H%M%S")
    json_path = output_dir / f"lorehold_variant_staging_{stamp}.json"
    md_path = output_dir / f"lorehold_variant_staging_{stamp}.md"
    payload = {
        "generated_at": dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "variant_count": len(reports),
        "valid_count": sum(1 for report in reports if report["validation_status"] == "valid"),
        "invalid_count": sum(1 for report in reports if report["validation_status"] != "valid"),
        "reports": reports,
    }
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True), encoding="utf-8")
    lines = [
        "# Lorehold Variant Staging Report",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Variants: `{payload['variant_count']}`",
        f"- Valid: `{payload['valid_count']}`",
        f"- Invalid: `{payload['invalid_count']}`",
        "",
        "| Status | Deck | Hash | Total | Main | Commander | Issues | Warnings |",
        "|---|---|---:|---:|---:|---:|---:|---:|",
    ]
    for report in reports:
        lines.append(
            "| {status} | {name} | `{hash}` | {total} | {main} | {commander} | {issues} | {warnings} |".format(
                status=report["validation_status"],
                name=str(report["deck_name"]).replace("|", "\\|"),
                hash=str(report["deck_hash"])[:12],
                total=report["total_quantity"],
                main=report["main_quantity"],
                commander=report["commander_quantity"],
                issues=len(report["issues"]),
                warnings=len(report["warnings"]),
            )
        )
    for report in reports:
        lines.extend(["", f"## {report['deck_name']}", ""])
        lines.append(f"- Hash: `{report['deck_hash']}`")
        lines.append(f"- Status: `{report['validation_status']}`")
        lines.append(f"- Totals: total `{report['total_quantity']}`, main `{report['main_quantity']}`, commander-in-list `{report['commander_quantity']}`")
        if report["issues"]:
            lines.append("- Issues:")
            lines.extend(f"  - `{issue}`" for issue in report["issues"][:40])
        if report["warnings"]:
            lines.append("- Warnings:")
            lines.extend(f"  - `{warning}`" for warning in report["warnings"][:40])
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return json_path, md_path


def run_from_input(args: argparse.Namespace) -> int:
    input_path = Path(args.input)
    text = input_path.read_text(encoding="utf-8", errors="replace")
    raw_input_sha256 = hashlib.sha256(text.encode("utf-8")).hexdigest()
    decks = parse_deck_blocks(
        text,
        default_name=args.name,
        default_source=args.source,
        default_archetype=args.archetype,
    )
    if not decks:
        raise SystemExit("No deck cards parsed. Use lines like: 1 Sol Ring")
    with sqlite3.connect(args.sqlite_db) as conn:
        conn.row_factory = sqlite3.Row
        ensure_tables(conn)
        reports = [validate_deck(conn, deck, raw_input_sha256) for deck in decks]
        json_path, md_path = write_reports(reports, Path(args.report_dir))
        if args.apply:
            for report in reports:
                stage_report(conn, report, str(md_path))
        materialized_backup = None
        if args.materialize:
            selected = None
            selector = normalize_name(args.materialize)
            for report in reports:
                if selector in {normalize_name(report["deck_name"]), normalize_name(report["deck_hash"])}:
                    selected = report
                    break
            if not selected:
                selected = load_staged_report(conn, args.materialize)
            materialized_backup = materialize_variant(conn, selected, args.target_deck_id)

    print(f"variants={len(reports)} valid={sum(1 for r in reports if r['validation_status'] == 'valid')} invalid={sum(1 for r in reports if r['validation_status'] != 'valid')}")
    print(f"json_report={json_path}")
    print(f"md_report={md_path}")
    if args.apply:
        print("staging=applied")
    else:
        print("staging=dry_run")
    if materialized_backup:
        print(f"materialized_target_deck_id={args.target_deck_id}")
        print(f"backup_id={materialized_backup}")
    if args.fail_on_invalid and any(report["validation_status"] != "valid" for report in reports):
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Stage and validate Lorehold deck variants")
    parser.add_argument("input", nargs="?", help="Text file containing one or more Lorehold deck variants")
    parser.add_argument("--sqlite-db", default=str(DEFAULT_DB))
    parser.add_argument("--apply", action="store_true", help="Write variant staging rows to local SQLite")
    parser.add_argument("--materialize", help="Deck name or hash to materialize into deck_cards")
    parser.add_argument("--target-deck-id", type=int, default=606)
    parser.add_argument("--restore-backup", help="Restore a prior materialization backup id")
    parser.add_argument("--name", default="Lorehold Variant")
    parser.add_argument("--source", default="manual-variant")
    parser.add_argument("--archetype", default="battle-variant")
    parser.add_argument("--report-dir", default=str(DEFAULT_REPORT_DIR))
    parser.add_argument("--fail-on-invalid", action="store_true")
    args = parser.parse_args()

    with sqlite3.connect(args.sqlite_db) as conn:
        conn.row_factory = sqlite3.Row
        ensure_tables(conn)
        if args.restore_backup:
            restore_backup(conn, args.restore_backup)
            print(f"restore_backup=ok backup_id={args.restore_backup}")
            return 0

    if not args.input:
        raise SystemExit("input is required unless --restore-backup is used")
    return run_from_input(args)


if __name__ == "__main__":
    raise SystemExit(main())
