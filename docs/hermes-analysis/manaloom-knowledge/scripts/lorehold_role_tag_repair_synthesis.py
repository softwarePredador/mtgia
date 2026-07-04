#!/usr/bin/env python3
"""Repair Lorehold 607 role/tag watch rows with auditable evidence.

This script targets only the current protected Lorehold deck 607 role/tag watch
cards surfaced by `lorehold_card_value_priority_synthesis`. By default it is
read-only and emits a report plus exact SQL. With `--apply-sqlite`, it applies
the updates to the local Hermes SQLite lab database only.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

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

REPAIR_PLAN = [
    {
        "card_name": "Deflecting Swat",
        "recommended_primary": "protection",
        "recommended_tags": ["protection", "redirect_removal"],
        "lane": "stack_or_spell_protection",
        "reason": (
            "Oracle and PG031 rule model a free commander-window target redirect, "
            "not card draw."
        ),
        "required_rule_tokens": ["redirect", "control_commander"],
    },
    {
        "card_name": "Emeria's Call // Emeria, Shattered Skyclave",
        "recommended_primary": "protection",
        "recommended_tags": ["protection", "board_development", "token_maker"],
        "lane": "pressure_protection",
        "reason": (
            "The spell creates a board while granting indestructible until next "
            "turn; it should not remain unknown."
        ),
        "required_rule_tokens": ["token_maker", "indestructible"],
    },
    {
        "card_name": "Promise of Loyalty",
        "recommended_primary": "board_wipe",
        "recommended_tags": ["board_wipe", "protection", "interaction"],
        "lane": "pressure_protection",
        "reason": (
            "The effect is a selective creature wipe with a vow attack restriction, "
            "not card draw."
        ),
        "required_rule_tokens": ["sacrifice", "vow"],
    },
    {
        "card_name": "Redirect Lightning",
        "recommended_primary": "protection",
        "recommended_tags": ["protection", "redirect_removal", "interaction"],
        "lane": "stack_or_spell_protection",
        "reason": (
            "Oracle and PG081 model changing the target of a single-target spell "
            "or ability; the earlier draw tag is stale forensic lineage."
        ),
        "required_rule_tokens": ["redirect", "single_target"],
    },
    {
        "card_name": "Tragic Arrogance",
        "recommended_primary": "board_wipe",
        "recommended_tags": ["board_wipe", "removal", "interaction"],
        "lane": "board_wipes",
        "reason": (
            "The active rule is a controller-selected nonland permanent sacrifice "
            "wipe; unknown blocks same-lane cuts."
        ),
        "required_rule_tokens": ["sacrifice", "nonland"],
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def json_list(value: Any) -> list[Any]:
    if isinstance(value, list):
        return value
    if value in (None, ""):
        return []
    try:
        payload = json.loads(str(value))
    except Exception:
        return []
    return payload if isinstance(payload, list) else []


def canonical_tags(tags: list[Any]) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for value in tags:
        tag = normalize_name(str(value or ""))
        if not tag or tag in seen:
            continue
        seen.add(tag)
        out.append(tag)
    return out


def tags_json(tags: list[str]) -> str:
    return json.dumps(tags, ensure_ascii=True, separators=(",", ":"))


def sql_quote(value: Any) -> str:
    return "'" + str(value).replace("'", "''") + "'"


def load_deck_row(conn: sqlite3.Connection, deck_id: int, card_name: str) -> dict[str, Any] | None:
    row = conn.execute(
        """
        SELECT id, deck_id, card_name, quantity, functional_tag, functional_tags_json,
               card_id, type_line, oracle_text, cmc, is_commander
        FROM deck_cards
        WHERE deck_id = ?
          AND card_name = ?
        LIMIT 1
        """,
        (deck_id, card_name),
    ).fetchone()
    return dict(row) if row else None


def load_oracle(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {}
    row = conn.execute(
        """
        SELECT name, mana_cost, type_line, oracle_text, color_identity_json, cmc, card_id
        FROM card_oracle_cache
        WHERE normalized_name = ?
           OR lower(name) = lower(?)
        LIMIT 1
        """,
        (normalize_name(card_name), card_name),
    ).fetchone()
    return dict(row) if row else {}


def load_rules(conn: sqlite3.Connection, card_name: str) -> list[dict[str, Any]]:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return []
    rows = conn.execute(
        """
        SELECT logical_rule_key, effect_json, deck_role_json, source, confidence,
               review_status, execution_status, notes
        FROM battle_card_rules
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        ORDER BY logical_rule_key
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    out: list[dict[str, Any]] = []
    for row in rows:
        item = dict(row)
        for field in ("effect_json", "deck_role_json"):
            try:
                payload = json.loads(item[field] or "{}")
            except Exception:
                payload = {}
            item[field] = payload if isinstance(payload, Mapping) else {}
        out.append(item)
    return out


def rule_text(rules: list[Mapping[str, Any]], oracle: Mapping[str, Any]) -> str:
    chunks = [
        str(oracle.get("type_line") or ""),
        str(oracle.get("oracle_text") or ""),
    ]
    for rule in rules:
        chunks.append(json.dumps(rule.get("effect_json") or {}, sort_keys=True))
        chunks.append(json.dumps(rule.get("deck_role_json") or {}, sort_keys=True))
        chunks.append(str(rule.get("notes") or ""))
    return "\n".join(chunks).lower()


def active_rule_count(rules: list[Mapping[str, Any]]) -> int:
    return sum(
        1
        for rule in rules
        if str(rule.get("execution_status") or "") in {"auto", "active", "verified"}
        and str(rule.get("review_status") or "") in {"active", "verified", "reviewed"}
    )


def repair_candidate(conn: sqlite3.Connection, deck_id: int, plan: Mapping[str, Any]) -> dict[str, Any]:
    name = str(plan["card_name"])
    deck_row = load_deck_row(conn, deck_id, name)
    oracle = load_oracle(conn, name)
    rules = load_rules(conn, name)
    text = rule_text(rules, oracle)
    current_tags = canonical_tags(json_list(deck_row.get("functional_tags_json")) if deck_row else [])
    current_primary = normalize_name(str((deck_row or {}).get("functional_tag") or ""))
    recommended_tags = canonical_tags(list(plan["recommended_tags"]))
    blockers: list[str] = []
    if deck_row is None:
        blockers.append("missing_deck_row")
    if active_rule_count(rules) == 0:
        blockers.append("missing_active_battle_rule")
    for token in plan.get("required_rule_tokens") or []:
        if str(token).lower() not in text:
            blockers.append(f"missing_rule_token:{token}")
    if "unknown" in recommended_tags or not plan.get("recommended_primary"):
        blockers.append("invalid_recommended_tags")
    needs_update = bool(deck_row) and (
        current_primary != plan["recommended_primary"] or current_tags != recommended_tags
    )
    return {
        "card_name": name,
        "lane": plan["lane"],
        "reason": plan["reason"],
        "current_primary": current_primary,
        "current_tags": current_tags,
        "recommended_primary": plan["recommended_primary"],
        "recommended_tags": recommended_tags,
        "needs_update": needs_update,
        "blockers": blockers,
        "active_rule_count": active_rule_count(rules),
        "oracle": {
            "type_line": oracle.get("type_line"),
            "oracle_text": oracle.get("oracle_text"),
            "card_id": oracle.get("card_id"),
        },
        "battle_rule_evidence": [
            {
                "logical_rule_key": rule.get("logical_rule_key"),
                "execution_status": rule.get("execution_status"),
                "review_status": rule.get("review_status"),
                "category": (rule.get("deck_role_json") or {}).get("category"),
                "effect": (rule.get("deck_role_json") or {}).get("effect")
                or (rule.get("effect_json") or {}).get("effect"),
                "battle_model_scope": (rule.get("deck_role_json") or {}).get("battle_model_scope")
                or (rule.get("effect_json") or {}).get("battle_model_scope"),
            }
            for rule in rules
        ],
        "deck_row_id": deck_row.get("id") if deck_row else None,
        "card_id": deck_row.get("card_id") if deck_row else None,
    }


def update_statement(row: Mapping[str, Any], *, deck_id: int, rollback: bool = False) -> str:
    primary = row["current_primary"] if rollback else row["recommended_primary"]
    tags = row["current_tags"] if rollback else row["recommended_tags"]
    where = [
        f"deck_id = {as_int(deck_id)}",
        f"card_name = {sql_quote(row['card_name'])}",
    ]
    if row.get("card_id"):
        where.append(f"card_id = {sql_quote(row['card_id'])}")
    return (
        "UPDATE deck_cards\n"
        f"SET functional_tag = {sql_quote(primary)},\n"
        f"    functional_tags_json = {sql_quote(tags_json(list(tags)))}\n"
        "WHERE "
        + "\n  AND ".join(where)
        + ";"
    )


def render_sql(candidates: list[Mapping[str, Any]], *, deck_id: int, rollback: bool = False) -> str:
    rows = [row for row in candidates if row.get("needs_update") and not row.get("blockers")]
    header = "BEGIN;\n"
    body = "\n\n".join(update_statement(row, deck_id=deck_id, rollback=rollback) for row in rows)
    return f"{header}{body}\nCOMMIT;\n" if body else "-- No eligible updates.\n"


def render_precheck_sql(deck_id: int, candidates: list[Mapping[str, Any]]) -> str:
    names = ", ".join(sql_quote(row["card_name"]) for row in candidates)
    return (
        "SELECT deck_id, card_name, quantity, functional_tag, functional_tags_json, card_id\n"
        "FROM deck_cards\n"
        f"WHERE deck_id = {deck_id}\n"
        f"  AND card_name IN ({names})\n"
        "ORDER BY card_name;\n"
    )


def render_postcheck_sql(deck_id: int, candidates: list[Mapping[str, Any]]) -> str:
    selects = []
    for row in candidates:
        selects.append(
            "SELECT "
            f"{sql_quote(row['card_name'])} AS expected_card_name, "
            f"{sql_quote(row['recommended_primary'])} AS expected_primary, "
            f"{sql_quote(tags_json(list(row['recommended_tags'])))} AS expected_tags"
        )
    expected = "\nUNION ALL\n".join(selects)
    return (
        "WITH expected AS (\n"
        f"{expected}\n"
        ")\n"
        "SELECT e.expected_card_name, dc.functional_tag, dc.functional_tags_json,\n"
        "       CASE WHEN dc.functional_tag = e.expected_primary\n"
        "             AND replace(dc.functional_tags_json, ' ', '') = e.expected_tags\n"
        "            THEN 'ok' ELSE 'mismatch' END AS status\n"
        "FROM expected e\n"
        "LEFT JOIN deck_cards dc\n"
        f"  ON dc.deck_id = {deck_id}\n"
        " AND dc.card_name = e.expected_card_name\n"
        "ORDER BY e.expected_card_name;\n"
    )


def apply_sqlite_repair(conn: sqlite3.Connection, candidates: list[Mapping[str, Any]], deck_id: int) -> int:
    eligible = [row for row in candidates if row.get("needs_update") and not row.get("blockers")]
    with conn:
        for row in eligible:
            params: list[Any] = [
                row["recommended_primary"],
                tags_json(list(row["recommended_tags"])),
                deck_id,
                row["card_name"],
            ]
            where = "deck_id = ? AND card_name = ?"
            if row.get("card_id"):
                where += " AND card_id = ?"
                params.append(row["card_id"])
            cur = conn.execute(
                f"""
                UPDATE deck_cards
                SET functional_tag = ?,
                    functional_tags_json = ?
                WHERE {where}
                """,
                params,
            )
            if cur.rowcount != 1:
                raise RuntimeError(f"expected one row update for {row['card_name']}, got {cur.rowcount}")
    return len(eligible)


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    apply_sqlite: bool,
) -> dict[str, Any]:
    before_candidates = [repair_candidate(conn, deck_id, plan) for plan in REPAIR_PLAN]
    blocker_count = sum(1 for row in before_candidates if row["blockers"])
    eligible_count = sum(1 for row in before_candidates if row["needs_update"] and not row["blockers"])
    updated_count = 0
    source_db_mutated = False
    if apply_sqlite:
        if blocker_count:
            raise RuntimeError(f"role-tag repair blocked by {blocker_count} candidate blocker(s)")
        updated_count = apply_sqlite_repair(conn, before_candidates, deck_id)
        source_db_mutated = updated_count > 0
    after_candidates = [repair_candidate(conn, deck_id, plan) for plan in REPAIR_PLAN]
    remaining_updates = sum(1 for row in after_candidates if row["needs_update"])
    remaining_blockers = sum(1 for row in after_candidates if row["blockers"])
    if remaining_blockers:
        status = "role_tag_repair_blocked"
    elif apply_sqlite and remaining_updates == 0:
        status = "role_tag_repair_applied"
    elif eligible_count > 0:
        status = "role_tag_repair_ready"
    else:
        status = "role_tag_repair_already_applied"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_role_tag_repair_synthesis",
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "postgres_writes": False,
        "source_db_mutated": source_db_mutated,
        "status": status,
        "summary": {
            "target_count": len(REPAIR_PLAN),
            "blocker_count_before": blocker_count,
            "eligible_update_count_before": eligible_count,
            "updated_count": updated_count,
            "remaining_update_count": remaining_updates,
            "remaining_blocker_count": remaining_blockers,
        },
        "before_repair": before_candidates,
        "after_repair": after_candidates,
        "sql": {
            "precheck": render_precheck_sql(deck_id, before_candidates),
            "apply_sqlite": render_sql(before_candidates, deck_id=deck_id, rollback=False),
            "rollback_sqlite": render_sql(before_candidates, deck_id=deck_id, rollback=True),
            "postcheck": render_postcheck_sql(deck_id, after_candidates),
        },
        "decision": {
            "safe_to_use_for_same_lane_cuts": remaining_updates == 0 and remaining_blockers == 0,
            "reason": (
                "The five current watch cards now have explicit primary roles and ordered "
                "multi-tags aligned to active battle rules and Oracle text."
                if remaining_updates == 0 and remaining_blockers == 0
                else "Role/tag repairs must be applied before using these cards for automated same-lane cuts."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Role/Tag Repair Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        f"- source_db_mutated: `{str(payload['source_db_mutated']).lower()}`",
        "",
        "## Summary",
        "",
        f"- targets: `{summary['target_count']}`",
        f"- blockers before: `{summary['blocker_count_before']}`",
        f"- eligible updates before: `{summary['eligible_update_count_before']}`",
        f"- updated count: `{summary['updated_count']}`",
        f"- remaining updates: `{summary['remaining_update_count']}`",
        f"- remaining blockers: `{summary['remaining_blocker_count']}`",
        "",
        "## Repairs",
        "",
        "| Card | Before | After | Recommended Tags | Evidence |",
        "| --- | --- | --- | --- | --- |",
    ]
    after_by_name = {row["card_name"]: row for row in payload["after_repair"]}
    for row in payload["before_repair"]:
        after = after_by_name.get(row["card_name"], row)
        evidence = "; ".join(
            f"{item.get('category')}:{item.get('effect')}" for item in row.get("battle_rule_evidence") or []
        )
        lines.append(
            "| {card} | `{before}` | `{after}` | `{tags}` | {evidence} |".format(
                card=row["card_name"],
                before=row["current_primary"],
                after=after["current_primary"],
                tags=",".join(row["recommended_tags"]),
                evidence=evidence or "-",
            )
        )
    lines.extend(["", "## Apply SQL", "", "```sql", payload["sql"]["apply_sqlite"].rstrip(), "```"])
    lines.extend(["", "## Rollback SQL", "", "```sql", payload["sql"]["rollback_sqlite"].rstrip(), "```"])
    decision = payload["decision"]
    lines.extend(["", "## Decision", ""])
    lines.append(f"- safe_to_use_for_same_lane_cuts: `{str(decision['safe_to_use_for_same_lane_cuts']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path, Path, Path, Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    precheck_path = out_prefix.with_name(out_prefix.name + "_precheck.sql")
    apply_path = out_prefix.with_name(out_prefix.name + "_apply_sqlite.sql")
    rollback_path = out_prefix.with_name(out_prefix.name + "_rollback_sqlite.sql")
    postcheck_path = out_prefix.with_name(out_prefix.name + "_postcheck.sql")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    precheck_path.write_text(payload["sql"]["precheck"], encoding="utf-8")
    apply_path.write_text(payload["sql"]["apply_sqlite"], encoding="utf-8")
    rollback_path.write_text(payload["sql"]["rollback_sqlite"], encoding="utf-8")
    postcheck_path.write_text(payload["sql"]["postcheck"], encoding="utf-8")
    return json_path, md_path, precheck_path, apply_path, rollback_path, postcheck_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--apply-sqlite", action="store_true")
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_role_tag_repair_synthesis",
    )
    args = parser.parse_args()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            apply_sqlite=args.apply_sqlite,
        )
    paths = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "updated_count": payload["summary"]["updated_count"],
                "json": str(paths[0]),
                "markdown": str(paths[1]),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
