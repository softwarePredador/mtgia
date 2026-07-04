#!/usr/bin/env python3
"""Build a diagnostic-only Lorehold 607 pressure-payoff tradeoff candidate.

This does not mutate deck 607 and does not stage a production deck. It writes a
candidate JSON/decklist that can be consumed by the strategy matrix or variant
stager to learn the structural cost of adding the pressure payoff package.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence

from lorehold_strategy_profile import (
    STRATEGY_VERSION,
    commander_intent_alignment,
    strategy_tags_for_card,
)
from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_RESOLVER = (
    REPORT_DIR / "lorehold_pressure_safe_cut_pool_resolver_20260704_current.json"
)
DEFAULT_STEM = "lorehold_pressure_tradeoff_diagnostic_variant_20260704_current"

ADD_ROLE_OVERRIDES = {
    "monastery mentor": ["creature", "token_maker"],
    "young pyromancer": ["creature", "token_maker"],
    "guttersnipe": ["creature", "wincon"],
    "storm-kiln artist": ["creature", "ramp"],
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def json_list(value: object) -> list[Any]:
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def card_roles(row: Mapping[str, Any]) -> list[str]:
    roles: list[str] = []
    for item in json_list(row.get("functional_tags_json")):
        value = item.get("tag") if isinstance(item, dict) else item
        if value and str(value) not in roles:
            roles.append(str(value))
    if row.get("functional_tag") and str(row["functional_tag"]) not in roles:
        roles.append(str(row["functional_tag"]))
    if "Land" in str(row.get("type_line") or "") and "land" not in roles:
        roles.append("land")
    return roles or ["unknown"]


def load_deck_rows(conn: sqlite3.Connection, deck_id: int) -> dict[str, dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM deck_cards WHERE deck_id=? ORDER BY is_commander DESC, card_name",
        (deck_id,),
    ).fetchall()
    return {normalize_name(row["card_name"]): dict(row) for row in rows}


def load_oracle_row(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    conn.row_factory = sqlite3.Row
    row = conn.execute(
        """
        SELECT normalized_name, name, mana_cost, color_identity_json, type_line,
               oracle_text, cmc, scryfall_id
        FROM card_oracle_cache
        WHERE normalized_name=?
        LIMIT 1
        """,
        (normalize_name(card_name),),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"oracle row missing for add card: {card_name}")
    return dict(row)


def deck_card_to_final_card(row: Mapping[str, Any]) -> dict[str, Any]:
    roles = card_roles(row)
    return {
        "card_name": row.get("card_name"),
        "normalized_name": normalize_name(row.get("card_name")),
        "quantity": int(row.get("quantity") or 1),
        "roles": roles,
        "is_commander": bool(row.get("is_commander")),
        "is_land": "land" in roles or "Land" in str(row.get("type_line") or ""),
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line") or "",
        "oracle_text": row.get("oracle_text") or "",
    }


def oracle_to_final_card(row: Mapping[str, Any]) -> dict[str, Any]:
    normalized = normalize_name(row.get("name"))
    roles = list(ADD_ROLE_OVERRIDES.get(normalized, ["creature"]))
    return {
        "card_name": row.get("name"),
        "normalized_name": normalized,
        "quantity": 1,
        "roles": roles,
        "is_commander": False,
        "is_land": "Land" in str(row.get("type_line") or ""),
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line") or "",
        "oracle_text": row.get("oracle_text") or "",
    }


def apply_tradeoff(
    base_cards: Sequence[Mapping[str, Any]],
    add_cards: Sequence[Mapping[str, Any]],
    cut_names: Sequence[str],
) -> list[dict[str, Any]]:
    cut_keys = {normalize_name(name) for name in cut_names}
    base_by_key = {normalize_name(row.get("card_name")): row for row in base_cards}
    missing_cuts = sorted(name for name in cut_names if normalize_name(name) not in base_by_key)
    if missing_cuts:
        raise RuntimeError(f"cut cards missing from base deck: {missing_cuts}")
    add_keys = {normalize_name(row.get("card_name")) for row in add_cards}
    already_present = sorted(key for key in add_keys if key in base_by_key and key not in cut_keys)
    if already_present:
        raise RuntimeError(f"add cards already present in base deck: {already_present}")
    final = [
        deck_card_to_final_card(row)
        for key, row in base_by_key.items()
        if key not in cut_keys
    ]
    final.extend(dict(card) for card in add_cards)
    quantity_total = sum(int(card.get("quantity") or 1) for card in final)
    commander_count = sum(
        int(card.get("quantity") or 1) for card in final if card.get("is_commander")
    )
    if quantity_total != 100:
        raise RuntimeError(f"candidate quantity_total={quantity_total}, expected 100")
    if commander_count != 1:
        raise RuntimeError(f"candidate commander_count={commander_count}, expected 1")
    return sorted(
        final,
        key=lambda card: (
            not bool(card.get("is_commander")),
            bool(card.get("is_land")),
            str(card.get("card_name") or "").lower(),
        ),
    )


def role_counts(cards: Sequence[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for card in cards:
        quantity = int(card.get("quantity") or 1)
        for role in card.get("roles") or []:
            counts[str(role)] += quantity
    return dict(sorted(counts.items()))


def strategy_package_counts(cards: Sequence[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for card in cards:
        for tag in strategy_tags_for_card(card):
            counts[tag] += 1
    return dict(sorted(counts.items()))


def candidate_hash(cards: Sequence[Mapping[str, Any]]) -> str:
    payload = [
        {"card_name": card.get("card_name"), "quantity": int(card.get("quantity") or 1)}
        for card in cards
    ]
    encoded = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def display_card_name(card_name: object) -> str:
    name = str(card_name or "")
    parts = [part.strip() for part in name.split(" // ")]
    if len(parts) == 2 and parts[0] == parts[1]:
        return parts[0]
    return name


def render_decklist_text(cards: Sequence[Mapping[str, Any]]) -> str:
    return "\n".join(
        f"{int(card.get('quantity') or 1)} {display_card_name(card.get('card_name'))}"
        for card in cards
    ) + "\n"


def build_report(
    *,
    resolver_report: Mapping[str, Any],
    base_rows: Sequence[Mapping[str, Any]],
    add_rows: Sequence[Mapping[str, Any]],
    resolver_path: Path,
    source_db: Path,
) -> dict[str, Any]:
    adds = [str(name) for name in resolver_report.get("primary_adds") or []]
    cuts = [
        str(row.get("card_name") or "")
        for row in (
            (resolver_report.get("diagnostic_tradeoff_cut_plan") or {}).get(
                "selected_cuts"
            )
            or []
        )
        if row.get("card_name")
    ]
    add_cards = [oracle_to_final_card(row) for row in add_rows]
    final_deck = apply_tradeoff(base_rows, add_cards, cuts)
    hash_value = candidate_hash(final_deck)
    return {
        "generated_at": utc_now(),
        "status": "generated_diagnostic_only_candidate",
        "artifact_type": "lorehold_pressure_tradeoff_diagnostic_variant",
        "source_db": rel(source_db),
        "resolver_report": rel(resolver_path),
        "strategy_version": STRATEGY_VERSION,
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "diagnostic_only": True,
        "promotion_eligible": False,
        "natural_battle_gate_allowed": False,
        "candidate_key": "candidate_607_pressure_payoff_diagnostic_tradeoff_v1",
        "candidate_name": "Lorehold 607 Pressure Payoff Diagnostic Tradeoff v1",
        "candidate_archetype": "607-pressure-payoff-diagnostic-tradeoff",
        "candidate_hash": hash_value,
        "base_deck_id": 607,
        "added": adds,
        "removed": cuts,
        "row_count": len(final_deck),
        "quantity_total": sum(int(card.get("quantity") or 1) for card in final_deck),
        "lands": sum(
            int(card.get("quantity") or 1)
            for card in final_deck
            if card.get("is_land")
        ),
        "nonlands": sum(
            int(card.get("quantity") or 1)
            for card in final_deck
            if not card.get("is_land")
        ),
        "role_counts": role_counts(final_deck),
        "strategy_package_counts": strategy_package_counts(final_deck),
        "commander_intent_alignment": commander_intent_alignment(final_deck),
        "method_notes": [
            "This candidate is a diagnostic pressure tradeoff copy, not a promotion candidate.",
            "The cut-pool resolver found zero gate-ready seed-safe cuts.",
            "Any battle run from this candidate must be interpreted as learning only until a seed-safe cut plan and structure matrix pass.",
        ],
        "final_deck": final_deck,
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        "# Lorehold Pressure Payoff Diagnostic Tradeoff Variant",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Candidate hash: `{report['candidate_hash']}`",
        f"- Diagnostic only: `{str(report['diagnostic_only']).lower()}`",
        f"- Promotion eligible: `{str(report['promotion_eligible']).lower()}`",
        f"- Natural battle gate allowed: `{str(report['natural_battle_gate_allowed']).lower()}`",
        f"- Resolver report: `{report['resolver_report']}`",
        f"- Quantity total: `{report['quantity_total']}`",
        f"- Lands: `{report['lands']}`",
        "",
        "## Swaps",
        "",
        "| In | Out |",
        "| --- | --- |",
    ]
    for add, cut in zip(report.get("added") or [], report.get("removed") or []):
        lines.append(f"| {add} | {cut} |")
    lines.extend(["", "## Strategy Package Counts", ""])
    for key, value in report.get("strategy_package_counts", {}).items():
        lines.append(f"- `{key}`: {value}")
    lines.extend(["", "## Commander Intent", ""])
    alignment = report.get("commander_intent_alignment") or {}
    lines.append(f"- Score: `{alignment.get('score')}`")
    lines.append(f"- Status: `{alignment.get('status')}`")
    lines.append(
        "- Risks: " + (", ".join(alignment.get("risks") or []) or "none")
    )
    lines.extend(["", "## Method Notes", ""])
    for note in report.get("method_notes") or []:
        lines.append(f"- {note}")
    lines.extend(["", "## Final Decklist", ""])
    lines.append("```")
    lines.append(render_decklist_text(report.get("final_deck") or []).rstrip())
    lines.append("```")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resolver", type=Path, default=DEFAULT_RESOLVER)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=607)
    parser.add_argument("--stem", default=DEFAULT_STEM)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    resolver_report = read_json(args.resolver)
    adds = [str(name) for name in resolver_report.get("primary_adds") or []]
    with sqlite3.connect(args.source_db) as conn:
        base_rows = list(load_deck_rows(conn, args.deck_id).values())
        add_rows = [load_oracle_row(conn, name) for name in adds]
    report = build_report(
        resolver_report=resolver_report,
        base_rows=base_rows,
        add_rows=add_rows,
        resolver_path=args.resolver,
        source_db=args.source_db,
    )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    decklist_path = REPORT_DIR / f"{args.stem}.decklist.txt"
    json_path.write_text(
        json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(report), encoding="utf-8")
    decklist_path.write_text(render_decklist_text(report["final_deck"]), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": report["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "decklist": str(decklist_path),
                "candidate_hash": report["candidate_hash"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
