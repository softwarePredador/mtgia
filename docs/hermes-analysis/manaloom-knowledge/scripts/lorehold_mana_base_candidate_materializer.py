#!/usr/bin/env python3
"""Materialize the best Lorehold 607 mana-base hypothesis in an isolated DB.

This script never mutates the source Hermes DB or PostgreSQL. It creates a
candidate copy of the local knowledge DB, applies one model-ready land swap to
deck 607 inside that copy, and emits structure evidence. A successful result is
ready for the next preflight step, not promotion.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import lorehold_mana_base_safe_cut_model as safe_cut_model
from master_optimizer_common import (
    connect,
    deck_hash,
    deck_rows,
    get_deck_summary,
    normalize_name,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
KNOWLEDGE_DB = SCRIPT_DIR / "knowledge.db"

DEFAULT_DECK_ID = 607
DEFAULT_PAIR_SOURCE_REPORT = (
    REPORT_DIR / "lorehold_mana_base_decision_integrator_20260705_after_plateau_turbulent_current.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_mana_base_candidate_materializer_20260705_plateau_turbulent_current"

HASH_COLUMNS = ("deck_hash", "semantics_hash", "ruleset_hash")


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, sort_keys=True)


def json_list(value: Any) -> list[Any]:
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(str(value or "[]"))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def table_columns(conn: sqlite3.Connection, table: str) -> list[str]:
    return [str(row[1]) for row in conn.execute(f"PRAGMA table_info({table})")]


def load_best_pair(pair_source_path: Path, *, add: str | None = None, cut: str | None = None) -> dict[str, Any]:
    model = read_json(pair_source_path)
    blocked_pairs = [
        row
        for row in model.get("annotated_model_ready_pairs") or []
        if isinstance(row, Mapping) and row.get("learning_status") == "blocked_exact_tested_decision"
    ]
    if add and cut:
        for row in blocked_pairs:
            if normalize_name(str(row.get("add"))) == normalize_name(add) and normalize_name(
                str(row.get("cut"))
            ) == normalize_name(cut):
                raise RuntimeError(f"pair blocked by prior decision report in {pair_source_path}: +{add} / -{cut}")

    best_next = model.get("best_next_pair")
    if isinstance(best_next, Mapping):
        pairs = [dict(best_next)]
    else:
        pairs = [
            row
            for row in model.get("annotated_model_ready_pairs") or []
            if isinstance(row, Mapping)
            and row.get("learning_status") == "eligible_for_materialization_after_prior_decision_filter"
        ]
    if not pairs:
        pairs = [
            row
            for row in model.get("top_model_ready_pairs") or []
            if isinstance(row, Mapping) and row.get("status") == "model_ready_for_candidate_materialization"
        ]
    if add or cut:
        pairs = [
            row
            for row in pairs
            if (not add or normalize_name(str(row.get("add"))) == normalize_name(add))
            and (not cut or normalize_name(str(row.get("cut"))) == normalize_name(cut))
        ]
    if not pairs:
        raise RuntimeError(f"no model-ready pair found in {pair_source_path}")
    return dict(pairs[0])


def active_rules_for_card(conn: sqlite3.Connection, card_name: str) -> list[dict[str, Any]]:
    if "battle_card_rules" not in {
        str(row["name"])
        for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
    }:
        return []
    columns = table_columns(conn, "battle_card_rules")
    wanted = [
        column
        for column in (
            "logical_rule_key",
            "effect_json",
            "deck_role_json",
            "source",
            "confidence",
            "review_status",
            "execution_status",
            "rule_version",
            "oracle_hash",
        )
        if column in columns
    ]
    if not wanted or "normalized_name" not in columns:
        return []
    rows = conn.execute(
        f"""
        SELECT {", ".join(wanted)}
        FROM battle_card_rules
        WHERE normalized_name=?
          AND review_status IN ('verified', 'active', 'needs_review')
          AND execution_status NOT IN ('disabled', 'review_only')
        ORDER BY logical_rule_key
        """,
        (normalize_name(card_name),),
    ).fetchall()
    return [dict(row) for row in rows]


def oracle_row(conn: sqlite3.Connection, card_name: str) -> sqlite3.Row:
    row = conn.execute(
        "SELECT * FROM card_oracle_cache WHERE normalized_name=?",
        (normalize_name(card_name),),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"missing card_oracle_cache row for {card_name}")
    return row


def existing_deck_card_row(conn: sqlite3.Connection, card_name: str, *, exclude_deck_id: int) -> sqlite3.Row | None:
    rows = conn.execute(
        """
        SELECT *
        FROM deck_cards
        WHERE lower(card_name)=lower(?)
          AND deck_id<>?
        ORDER BY
          CASE WHEN functional_tag='land' THEN 1 ELSE 0 END DESC,
          CASE WHEN COALESCE(semantic_tags_v2_json, '[]') NOT IN ('', '[]') THEN 1 ELSE 0 END DESC,
          CASE WHEN COALESCE(battle_rules_json, '[]') NOT IN ('', '[]') THEN 1 ELSE 0 END DESC,
          deck_id DESC
        LIMIT 1
        """,
        (card_name, exclude_deck_id),
    ).fetchall()
    return rows[0] if rows else None


def build_added_land_row(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    card_name: str,
    columns: list[str],
    sync_run_id: str,
) -> dict[str, Any]:
    oracle = oracle_row(conn, card_name)
    existing = existing_deck_card_row(conn, card_name, exclude_deck_id=deck_id)
    values = {column: None for column in columns}
    if existing is not None:
        values.update({column: existing[column] for column in columns})

    values.update(
        {
            "deck_id": deck_id,
            "card_name": oracle["name"] if "name" in oracle.keys() and oracle["name"] else card_name,
            "quantity": 1,
            "functional_tag": "land",
            "tag_confidence": None,
            "is_commander": 0,
            "is_partner": 0,
            "cmc": oracle["cmc"] if "cmc" in oracle.keys() else 0.0,
            "type_line": oracle["type_line"] if "type_line" in oracle.keys() else "",
            "oracle_text": oracle["oracle_text"] if "oracle_text" in oracle.keys() else "",
        }
    )
    if "card_id" in columns and "card_id" in oracle.keys():
        values["card_id"] = oracle["card_id"]
    if "functional_tags_json" in columns:
        values["functional_tags_json"] = stable_json(["land"])
    if "semantic_tags_v2_json" in columns:
        semantic_tags = json_list(values.get("semantic_tags_v2_json"))
        values["semantic_tags_v2_json"] = stable_json(semantic_tags)
    if "battle_rules_json" in columns:
        values["battle_rules_json"] = stable_json(active_rules_for_card(conn, card_name))
    if "sync_run_id" in columns:
        values["sync_run_id"] = sync_run_id
    for column in HASH_COLUMNS:
        if column in columns:
            values[column] = None
    return values


def materialize_land_swap(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    add: str,
    cut: str,
    sync_run_id: str,
) -> dict[str, Any]:
    source_rows = deck_rows(conn, deck_id)
    columns = [column for column in table_columns(conn, "deck_cards") if column != "id"]
    by_name = {normalize_name(str(row["card_name"])): row for row in source_rows}
    add_key = normalize_name(add)
    cut_key = normalize_name(cut)

    if cut_key not in by_name:
        raise RuntimeError(f"cut card not found in deck {deck_id}: {cut}")
    if add_key in by_name:
        raise RuntimeError(f"add card already exists in deck {deck_id}: {add}")
    if int(by_name[cut_key]["is_commander"] or 0):
        raise RuntimeError(f"cannot cut commander card: {cut}")

    candidate_rows: list[dict[str, Any]] = []
    for row in source_rows:
        if normalize_name(str(row["card_name"])) == cut_key:
            continue
        candidate_rows.append({column: row[column] for column in columns})

    added_row = build_added_land_row(
        conn,
        deck_id=deck_id,
        card_name=add,
        columns=columns,
        sync_run_id=sync_run_id,
    )
    candidate_rows.append(added_row)

    conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (deck_id,))
    placeholders = ",".join("?" for _ in columns)
    for row in candidate_rows:
        conn.execute(
            f"INSERT INTO deck_cards ({','.join(columns)}) VALUES ({placeholders})",
            [row.get(column) for column in columns],
        )
    conn.commit()

    return {
        "deck_id": deck_id,
        "add": add,
        "cut": cut,
        "row_count": len(candidate_rows),
        "total_cards": sum(int(row.get("quantity") or 1) for row in candidate_rows),
        "active_rule_count_for_add": len(active_rules_for_card(conn, add)),
    }


def nonbasic_singleton_violations(rows: list[sqlite3.Row]) -> list[str]:
    violations: list[str] = []
    for row in rows:
        quantity = int(row["quantity"] or 1)
        type_line = str(row["type_line"] or "")
        if quantity <= 1:
            continue
        if type_line.startswith("Basic Land"):
            continue
        violations.append(str(row["card_name"]))
    return violations


def validate_candidate_structure(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    add: str,
    cut: str,
) -> dict[str, Any]:
    rows = deck_rows(conn, deck_id)
    summary = get_deck_summary(conn, deck_id)
    add_rows = [row for row in rows if normalize_name(str(row["card_name"])) == normalize_name(add)]
    cut_rows = [row for row in rows if normalize_name(str(row["card_name"])) == normalize_name(cut)]
    commander_count = sum(int(row["quantity"] or 1) for row in rows if int(row["is_commander"] or 0))
    unresolved = [
        str(row["card_name"])
        for row in rows
        if not str(row["type_line"] or "").strip() and not str(row["oracle_text"] or "").strip()
    ]
    violations = nonbasic_singleton_violations(rows)
    checks = {
        "total_cards_100": int(summary["cards"]) == 100,
        "land_quantity_34": int(summary["lands"]) == 34,
        "commander_count_1": commander_count == 1,
        "add_present_once": len(add_rows) == 1 and int(add_rows[0]["quantity"] or 1) == 1,
        "cut_absent": not cut_rows,
        "nonbasic_singleton_ok": not violations,
        "unresolved_card_rows_0": not unresolved,
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "deck_summary": summary,
        "commander_count": commander_count,
        "checks": checks,
        "nonbasic_singleton_violations": violations,
        "unresolved_card_rows": unresolved,
    }


def mana_base_counts(db_path: Path, deck_id: int) -> dict[str, int]:
    features = [
        safe_cut_model.land_features(row, in_deck_607=True)
        for row in safe_cut_model.deck_land_rows(db_path, deck_id)
    ]
    return safe_cut_model.mana_base_counts(features)


def materialize_candidate_db(
    *,
    source_db: Path,
    candidate_db: Path,
    deck_id: int,
    add: str,
    cut: str,
    sync_run_id: str,
) -> dict[str, Any]:
    candidate_db.parent.mkdir(parents=True, exist_ok=True)
    if candidate_db.exists():
        candidate_db.unlink()
    shutil.copy2(source_db, candidate_db)

    with connect(candidate_db) as conn:
        swap_meta = materialize_land_swap(
            conn,
            deck_id=deck_id,
            add=add,
            cut=cut,
            sync_run_id=sync_run_id,
        )
        validation = validate_candidate_structure(conn, deck_id=deck_id, add=add, cut=cut)
        candidate_hash = deck_hash(conn, deck_id)
    return {
        "candidate_db": rel(candidate_db),
        "swap_meta": swap_meta,
        "structure_validation": validation,
        "candidate_deck_hash": candidate_hash,
    }


def build_payload(
    *,
    source_db: Path = KNOWLEDGE_DB,
    deck_id: int = DEFAULT_DECK_ID,
    safe_cut_model_path: Path = DEFAULT_PAIR_SOURCE_REPORT,
    out_prefix: Path = DEFAULT_OUT_PREFIX,
    add: str | None = None,
    cut: str | None = None,
) -> dict[str, Any]:
    pair = load_best_pair(safe_cut_model_path, add=add, cut=cut)
    add_name = str(pair["add"])
    cut_name = str(pair["cut"])
    candidate_dir = out_prefix.parent / f"{out_prefix.name}_candidate"
    candidate_db = candidate_dir / "knowledge_candidate.db"
    sync_run_id = out_prefix.name

    with connect(source_db) as conn:
        source_summary_before = get_deck_summary(conn, deck_id)
        source_hash_before = deck_hash(conn, deck_id)
    source_counts_before = mana_base_counts(source_db, deck_id)

    materialized = materialize_candidate_db(
        source_db=source_db,
        candidate_db=candidate_db,
        deck_id=deck_id,
        add=add_name,
        cut=cut_name,
        sync_run_id=sync_run_id,
    )

    with connect(source_db) as conn:
        source_summary_after = get_deck_summary(conn, deck_id)
        source_hash_after = deck_hash(conn, deck_id)
    source_counts_after = mana_base_counts(source_db, deck_id)
    candidate_counts = mana_base_counts(candidate_db, deck_id)

    structure_status = materialized["structure_validation"]["status"]
    source_unchanged = source_hash_before == source_hash_after and source_counts_before == source_counts_after
    status = (
        "candidate_materialized_structure_ready_battle_gate_closed"
        if structure_status == "pass" and source_unchanged
        else "candidate_materialized_structure_failed"
    )

    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_base_candidate_materializer",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_db": rel(source_db),
        "source_reports": [rel(safe_cut_model_path)],
        "candidate_db": materialized["candidate_db"],
        "summary": {
            "deck_id": deck_id,
            "add": add_name,
            "cut": cut_name,
            "source_unchanged": source_unchanged,
            "source_deck_hash_before": source_hash_before,
            "source_deck_hash_after": source_hash_after,
            "candidate_deck_hash": materialized["candidate_deck_hash"],
            "source_candidate_hash_differs": source_hash_before != materialized["candidate_deck_hash"],
            "promotion_allowed": False,
            "allow_battle_gate_now": False,
            "allow_next_preflight": status == "candidate_materialized_structure_ready_battle_gate_closed",
        },
        "model_pair": pair,
        "materialization": materialized["swap_meta"],
        "structure_validation": materialized["structure_validation"],
        "mana_base_counts": {
            "source_before": source_counts_before,
            "source_after": source_counts_after,
            "candidate": candidate_counts,
            "delta_candidate_minus_source": {
                key: int(candidate_counts.get(key, 0)) - int(source_counts_before.get(key, 0))
                for key in sorted(set(source_counts_before) | set(candidate_counts))
            },
        },
        "source_deck_summary_before": source_summary_before,
        "source_deck_summary_after": source_summary_after,
        "policy": {
            "baseline": "Deck 607 remains the protected baseline.",
            "candidate_scope": "The swap exists only inside the copied Hermes SQLite candidate DB.",
            "promotion_gate": "Promotion stays closed until miracle-access preflight, equal battle gate, replay trace, and same-lane decision review pass.",
        },
        "decision": {
            "current_best_baseline": "deck_607",
            "candidate": f"+{add_name} / -{cut_name}",
            "promotion_allowed": False,
            "reason": (
                "The candidate preserves 100 cards, 34 lands, one commander, and source DB immutability, "
                "but has not passed battle or replay evidence."
            ),
            "next_action": "run miracle-access preflight and an equal battle gate using the candidate DB while keeping deck 607 as fixed protected baseline",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    validation = payload["structure_validation"]
    counts = payload["mana_base_counts"]
    lines = [
        "# Lorehold Mana Base Candidate Materializer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- candidate: `+{summary['add']} / -{summary['cut']}`",
        f"- candidate_db: `{payload['candidate_db']}`",
        f"- source_unchanged: `{str(summary['source_unchanged']).lower()}`",
        f"- source_candidate_hash_differs: `{str(summary['source_candidate_hash_differs']).lower()}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- allow_battle_gate_now: `{str(summary['allow_battle_gate_now']).lower()}`",
        f"- allow_next_preflight: `{str(summary['allow_next_preflight']).lower()}`",
        "",
        "## Structure Validation",
        "",
        f"- status: `{validation['status']}`",
        f"- deck_summary: `{json.dumps(validation['deck_summary'], sort_keys=True)}`",
        "",
        "| Check | Pass |",
        "| --- | --- |",
    ]
    for key, value in validation["checks"].items():
        lines.append(f"| `{key}` | `{str(value).lower()}` |")
    lines.extend(
        [
            "",
            "## Mana Base Delta",
            "",
            f"- source_before: `{json.dumps(counts['source_before'], sort_keys=True)}`",
            f"- candidate: `{json.dumps(counts['candidate'], sort_keys=True)}`",
            f"- delta_candidate_minus_source: `{json.dumps(counts['delta_candidate_minus_source'], sort_keys=True)}`",
            "",
            "## Decision",
            "",
            f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`",
            f"- candidate: `{payload['decision']['candidate']}`",
            f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`",
            f"- reason: {payload['decision']['reason']}",
            f"- next_action: `{payload['decision']['next_action']}`",
            "",
            "## Policy",
            "",
        ]
    )
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
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
    parser.add_argument("--db", type=Path, default=KNOWLEDGE_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument(
        "--safe-cut-model",
        "--pair-source-report",
        dest="safe_cut_model",
        type=Path,
        default=DEFAULT_PAIR_SOURCE_REPORT,
    )
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--add", default=None)
    parser.add_argument("--cut", default=None)
    args = parser.parse_args()

    payload = build_payload(
        source_db=args.db,
        deck_id=args.deck_id,
        safe_cut_model_path=args.safe_cut_model,
        out_prefix=args.out_prefix,
        add=args.add,
        cut=args.cut,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": rel(json_path),
                "markdown": rel(md_path),
                "candidate_db": payload["candidate_db"],
            },
            sort_keys=True,
        )
    )
    return 0 if payload["status"] == "candidate_materialized_structure_ready_battle_gate_closed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
