#!/usr/bin/env python3
"""Build a read-only accessibility matrix for Lorehold 607 candidates.

This auditor separates concepts that are easy to collapse in the app:
Commander legality, collection ownership, format-staple discovery, bracket
budget, current deck presence, and promotion evidence. A card can pass some
layers and still be blocked for the protected 607 shell.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sqlite3
from collections.abc import Mapping, Sequence
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import (
    normalize_name,
    resolve_default_knowledge_db,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_DECK_ID = 607
DEFAULT_CARDS = ("Mana Vault", "The One Ring")
DEFAULT_COLLECTION = SCRIPT_DIR / "user_collection.csv"
DEFAULT_BRACKET_POLICY = REPO_ROOT / "server" / "lib" / "edh_bracket_policy.dart"
DEFAULT_STAPLE_POLICY_REPORT = REPORT_DIR / "lorehold_staple_policy_synthesis_20260704_learning.json"
DEFAULT_MANA_FOUNDATION_REPORT = REPORT_DIR / "lorehold_mana_foundation_audit_20260704_learning.json"
BOROS_COLORS = {"R", "W"}
BRACKET_GAME_CHANGER_LIMITS = {1: 0, 2: 0, 3: 3, 4: 999, 5: 999}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def parse_json_list(value: Any) -> list[str]:
    if value in (None, ""):
        return []
    if isinstance(value, list):
        return [str(item) for item in value]
    try:
        parsed = json.loads(str(value))
    except json.JSONDecodeError:
        return []
    if isinstance(parsed, list):
        return [str(item) for item in parsed]
    return []


def load_game_changer_names(policy_path: Path) -> set[str]:
    if not policy_path.exists():
        return set()
    text = policy_path.read_text(encoding="utf-8")
    match = re.search(
        r"officialGameChangerNamesForBracketPolicy\s*=\s*<String>\{(?P<body>.*?)\};",
        text,
        re.DOTALL,
    )
    if not match:
        return set()
    names = set()
    for raw in re.findall(r"'((?:\\'|[^'])*)'", match.group("body")):
        names.add(normalize_name(raw.replace("\\'", "'")))
    return names


def load_collection(path: Path) -> dict[str, dict[str, Any]]:
    if not path.exists():
        return {}
    out: dict[str, dict[str, Any]] = {}
    with path.open(newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            english_name = (row.get("Card (EN)") or row.get("card_name") or "").strip()
            if not english_name:
                continue
            quantity = as_int(row.get("Quantidade") or row.get("quantity"), 0)
            key = normalize_name(english_name)
            current = out.setdefault(
                key,
                {
                    "card_name": english_name,
                    "quantity": 0,
                    "printings": [],
                },
            )
            current["quantity"] += quantity
            current["printings"].append(
                {
                    "set": row.get("Edicao (Sigla)") or row.get("set") or "",
                    "collector_number": row.get("Card #") or "",
                    "language_name": row.get("Card (PT)") or "",
                    "quantity": quantity,
                }
            )
    return out


def row_dict(row: sqlite3.Row | None) -> dict[str, Any]:
    return dict(row) if row else {}


def oracle_lookup(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {}
    row = conn.execute(
        """
        SELECT name, mana_cost, colors_json, color_identity_json, type_line,
               oracle_text, cmc, scryfall_id, card_id
        FROM card_oracle_cache
        WHERE normalized_name = ?
           OR lower(name) = lower(?)
        LIMIT 1
        """,
        (normalize_name(card_name), card_name),
    ).fetchone()
    return row_dict(row)


def commander_legality(conn: sqlite3.Connection, card_name: str) -> str | None:
    if not sqlite_connection_has_table(conn, "card_legalities"):
        return None
    row = conn.execute(
        """
        SELECT status
        FROM card_legalities
        WHERE lower(card_name) = lower(?)
          AND lower(format) = 'commander'
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return str(row["status"]) if row else None


def format_staple(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "format_staples"):
        return {}
    row = conn.execute(
        """
        SELECT card_name, archetype, category, color_identity, edhrec_rank,
               is_banned, scryfall_id
        FROM format_staples
        WHERE lower(card_name) = lower(?)
          AND lower(format) = 'commander'
        ORDER BY coalesce(edhrec_rank, 999999)
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return row_dict(row)


def deck_presence(conn: sqlite3.Connection, deck_id: int, card_name: str) -> dict[str, Any]:
    row = conn.execute(
        """
        SELECT deck_id, card_name, quantity, functional_tag, functional_tags_json,
               is_commander, cmc, type_line
        FROM deck_cards
        WHERE deck_id = ?
          AND lower(card_name) = lower(?)
        LIMIT 1
        """,
        (deck_id, card_name),
    ).fetchone()
    return row_dict(row)


def deck_game_changer_count(
    conn: sqlite3.Connection,
    deck_id: int,
    game_changer_names: set[str],
) -> int:
    rows = conn.execute(
        "SELECT card_name, quantity FROM deck_cards WHERE deck_id = ?",
        (deck_id,),
    ).fetchall()
    total = 0
    for row in rows:
        if normalize_name(str(row["card_name"])) in game_changer_names:
            total += as_int(row["quantity"], 1)
    return total


def active_battle_rule_count(conn: sqlite3.Connection, card_name: str) -> int:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return 0
    rows = conn.execute(
        """
        SELECT execution_status, review_status
        FROM battle_card_rules
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    active = 0
    for row in rows:
        execution = str(row["execution_status"] or "")
        review = str(row["review_status"] or "")
        if execution in {"auto", "active", "verified"} and review in {"active", "verified", "reviewed"}:
            active += 1
    return active


def candidate_policy_rows(report: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    rows = report.get("candidate_staple_backlog")
    if not isinstance(rows, list):
        return {}
    return {
        normalize_name(str(row.get("card_name"))): row
        for row in rows
        if isinstance(row, Mapping) and row.get("card_name")
    }


def mana_foundation_candidate_rows(report: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    rows = report.get("candidate_staples")
    if not isinstance(rows, list):
        return {}
    return {
        normalize_name(str(row.get("card_name"))): row
        for row in rows
        if isinstance(row, Mapping) and row.get("card_name")
    }


def color_identity_allowed(color_identity: Sequence[str]) -> bool:
    return set(color_identity).issubset(BOROS_COLORS)


def bracket_layer(
    *,
    card_name: str,
    bracket: int,
    current_game_changers: int,
    official_game_changer: bool,
) -> dict[str, Any]:
    limit = BRACKET_GAME_CHANGER_LIMITS.get(bracket, 999)
    remaining = max(limit - current_game_changers, 0)
    allowed = not official_game_changer or remaining > 0
    return {
        "target_bracket": bracket,
        "official_game_changer": official_game_changer,
        "current_deck_game_changers": current_game_changers,
        "game_changer_limit": limit,
        "remaining_game_changer_budget": remaining,
        "allowed_by_bracket": allowed,
        "reason": (
            "not_a_game_changer"
            if not official_game_changer
            else "game_changer_budget_available"
            if allowed
            else "game_changer_budget_exhausted_or_bracket_excludes_game_changers"
        ),
    }


def current_607_accessibility_result(row: Mapping[str, Any]) -> str:
    if not row["rules_layer"]["commander_legal"]:
        return "not_legal_for_commander"
    if not row["rules_layer"]["color_identity_allowed"]:
        return "off_color_for_lorehold"
    if not row["bracket_layer"]["allowed_by_bracket"]:
        return "legal_but_blocked_by_bracket"
    if row["deck_layer"]["present_in_607"]:
        return "already_in_protected_607"
    promotion = str(row["promotion_layer"].get("decision") or "")
    blocked = promotion.startswith("blocked") or promotion.startswith("reject")
    if row["collection_layer"]["owned"] and blocked:
        return "legal_owned_but_promotion_blocked_current_607"
    if not row["collection_layer"]["owned"] and blocked:
        return "legal_not_owned_and_promotion_blocked_current_607"
    if row["collection_layer"]["owned"]:
        return "legal_owned_requires_named_cut_and_gate"
    return "legal_not_owned_requires_collection_and_gate"


def build_card_row(
    *,
    conn: sqlite3.Connection,
    deck_id: int,
    card_name: str,
    collection: Mapping[str, Mapping[str, Any]],
    game_changer_names: set[str],
    current_game_changers: int,
    target_bracket: int,
    staple_policy: Mapping[str, Any],
    mana_foundation: Mapping[str, Any],
) -> dict[str, Any]:
    oracle = oracle_lookup(conn, card_name)
    legality = commander_legality(conn, card_name)
    staple = format_staple(conn, card_name)
    deck_row = deck_presence(conn, deck_id, card_name)
    collection_row = dict(collection.get(normalize_name(card_name)) or {})
    color_identity = parse_json_list(oracle.get("color_identity_json"))
    official_game_changer = normalize_name(card_name) in game_changer_names
    policy_row = dict(candidate_policy_rows(staple_policy).get(normalize_name(card_name)) or {})
    foundation_row = dict(mana_foundation_candidate_rows(mana_foundation).get(normalize_name(card_name)) or {})

    row: dict[str, Any] = {
        "card_name": card_name,
        "rules_layer": {
            "commander_status": legality,
            "commander_legal": legality == "legal",
            "color_identity": color_identity,
            "color_identity_allowed": color_identity_allowed(color_identity),
            "type_line": oracle.get("type_line"),
            "mana_cost": oracle.get("mana_cost"),
        },
        "collection_layer": {
            "owned": as_int(collection_row.get("quantity"), 0) > 0,
            "owned_quantity": as_int(collection_row.get("quantity"), 0),
            "printings": collection_row.get("printings") or [],
        },
        "discovery_layer": {
            "format_staple_present": bool(staple),
            "format_staple_rank": as_int(staple.get("edhrec_rank"), 0) if staple else None,
            "format_staple_archetype": staple.get("archetype") if staple else None,
            "official_game_changer": official_game_changer,
            "format_staples_gap": official_game_changer and not bool(staple),
            "battle_rule_active_count": active_battle_rule_count(conn, card_name),
        },
        "bracket_layer": bracket_layer(
            card_name=card_name,
            bracket=target_bracket,
            current_game_changers=current_game_changers,
            official_game_changer=official_game_changer,
        ),
        "deck_layer": {
            "deck_id": deck_id,
            "present_in_607": bool(deck_row),
            "quantity": as_int(deck_row.get("quantity"), 0) if deck_row else 0,
            "functional_tag": deck_row.get("functional_tag") if deck_row else None,
        },
        "promotion_layer": {
            "decision": policy_row.get("decision") or foundation_row.get("current_decision"),
            "decision_reasons": policy_row.get("decision_reasons")
            or foundation_row.get("decision_reasons")
            or [],
            "policy_class": policy_row.get("policy_class"),
            "lane": policy_row.get("lane"),
            "current_shell_decision": foundation_row.get("one_ring_current_shell_decision")
            or foundation_row.get("mana_vault_over_arcane_signet")
            or {},
        },
    }
    row["current_607_accessibility"] = current_607_accessibility_result(row)
    return row


def build_matrix(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    card_names: Sequence[str],
    collection_path: Path,
    bracket_policy_path: Path,
    staple_policy_report_path: Path,
    mana_foundation_report_path: Path,
    target_bracket: int,
) -> dict[str, Any]:
    collection = load_collection(collection_path)
    game_changer_names = load_game_changer_names(bracket_policy_path)
    staple_policy = read_json(staple_policy_report_path)
    mana_foundation = read_json(mana_foundation_report_path)
    current_game_changers = deck_game_changer_count(conn, deck_id, game_changer_names)
    rows = [
        build_card_row(
            conn=conn,
            deck_id=deck_id,
            card_name=card_name,
            collection=collection,
            game_changer_names=game_changer_names,
            current_game_changers=current_game_changers,
            target_bracket=target_bracket,
            staple_policy=staple_policy,
            mana_foundation=mana_foundation,
        )
        for card_name in card_names
    ]
    result_counts: dict[str, int] = {}
    for row in rows:
        key = str(row["current_607_accessibility"])
        result_counts[key] = result_counts.get(key, 0) + 1
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_accessibility_layer_matrix",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "collection_source": rel(collection_path),
        "target_bracket": target_bracket,
        "source_reports": {
            "bracket_policy": rel(bracket_policy_path),
            "staple_policy": rel(staple_policy_report_path),
            "mana_foundation": rel(mana_foundation_report_path),
        },
        "summary": {
            "cards_reviewed": len(rows),
            "current_deck_game_changers": current_game_changers,
            "owned_cards": sum(1 for row in rows if row["collection_layer"]["owned"]),
            "format_staples_gaps": sum(1 for row in rows if row["discovery_layer"]["format_staples_gap"]),
            "promotion_blocked_cards": sum(
                1
                for row in rows
                if str(row["promotion_layer"].get("decision") or "").startswith(("blocked", "reject"))
            ),
            "result_counts": result_counts,
        },
        "cards": rows,
        "decision": {
            "keep_607": True,
            "reason": (
                "Legality, ownership, staple discovery, bracket budget, and 607 promotion are distinct layers. "
                "No reviewed card is allowed to enter protected 607 from legality or ownership alone."
            ),
            "app_contract_note": (
                "Do not label a card as simply accessible unless the UI also says which layer passed: "
                "legal, owned, bracket-allowed, discoverable, or promotion-ready."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Accessibility Layer Matrix",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- target_bracket: `{payload['target_bracket']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- cards reviewed: `{summary['cards_reviewed']}`",
        f"- owned cards: `{summary['owned_cards']}`",
        f"- format_staples gaps: `{summary['format_staples_gaps']}`",
        f"- promotion blocked cards: `{summary['promotion_blocked_cards']}`",
        f"- result counts: `{json.dumps(summary['result_counts'], sort_keys=True)}`",
        "",
        "## Layer Matrix",
        "",
        "| Card | Legal | Owned | Format staple | Game Changer | Bracket allowed | In 607 | Promotion decision | Current 607 result |",
        "| --- | --- | ---: | --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["cards"]:
        lines.append(
            "| {card} | `{legal}` | {owned} | `{staple}` | `{gc}` | `{bracket}` | `{in_deck}` | `{decision}` | `{result}` |".format(
                card=row["card_name"],
                legal=row["rules_layer"]["commander_legal"],
                owned=row["collection_layer"]["owned_quantity"],
                staple=row["discovery_layer"]["format_staple_present"],
                gc=row["discovery_layer"]["official_game_changer"],
                bracket=row["bracket_layer"]["allowed_by_bracket"],
                in_deck=row["deck_layer"]["present_in_607"],
                decision=row["promotion_layer"].get("decision") or "unknown",
                result=row["current_607_accessibility"],
            )
        )
    lines.extend(
        [
            "",
            "## App Contract Note",
            "",
            f"- {payload['decision']['app_contract_note']}",
            f"- decision: {payload['decision']['reason']}",
        ]
    )
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
    parser.add_argument("--cards", default=",".join(DEFAULT_CARDS))
    parser.add_argument("--collection", type=Path, default=DEFAULT_COLLECTION)
    parser.add_argument("--bracket-policy", type=Path, default=DEFAULT_BRACKET_POLICY)
    parser.add_argument("--staple-policy-report", type=Path, default=DEFAULT_STAPLE_POLICY_REPORT)
    parser.add_argument("--mana-foundation-report", type=Path, default=DEFAULT_MANA_FOUNDATION_REPORT)
    parser.add_argument("--target-bracket", type=int, default=4)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_accessibility_layer_matrix",
    )
    args = parser.parse_args()
    card_names = [card.strip() for card in args.cards.split(",") if card.strip()]
    with connect(args.db) as conn:
        payload = build_matrix(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            card_names=card_names,
            collection_path=args.collection,
            bracket_policy_path=args.bracket_policy,
            staple_policy_report_path=args.staple_policy_report,
            mana_foundation_report_path=args.mana_foundation_report,
            target_bracket=args.target_bracket,
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": "ok",
                "json": str(json_path),
                "markdown": str(md_path),
                "result_counts": payload["summary"]["result_counts"],
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
