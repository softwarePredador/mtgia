#!/usr/bin/env python3
"""Materialize one global Commander add/cut hypothesis in an isolated DB copy.

This is a candidate-copy step, not promotion. It copies the Hermes SQLite DB,
applies one review-only pair from a global Commander candidate report inside
the copy, validates deck shape, and proves the source DB hash did not change.
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

from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import connect, deck_hash, deck_rows, get_deck_summary, normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_PAIR_REPORT = REPORT_DIR / "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_candidate_copy_materializer_20260705_kaalia_nonland_top_pair"
HASH_COLUMNS = ("deck_hash", "semantics_hash", "ruleset_hash")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


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


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def table_columns(conn: sqlite3.Connection, table: str) -> list[str]:
    return [str(row[1]) for row in conn.execute(f"PRAGMA table_info({table})")]


def load_top_pair(
    pair_report: Path,
    *,
    deck_id: str | None = None,
    add: str | None = None,
    cut: str | None = None,
) -> dict[str, Any]:
    payload = read_json(pair_report)
    source_report_db = str(payload.get("source_db") or "")
    pools = payload.get("nonland_pools") or payload.get("deck_cut_pools") or []
    for pool in pools:
        if not isinstance(pool, Mapping):
            continue
        if deck_id and str(pool.get("deck_id")) != str(deck_id):
            continue
        candidates = {
            normalize_name(str(row.get("card_name"))): row
            for row in pool.get("top_candidates", [])
            if isinstance(row, Mapping)
        }
        cuts = {
            normalize_name(str(row.get("card_name"))): row
            for row in pool.get("top_cut_candidates", [])
            if isinstance(row, Mapping)
        }
        for pair in pool.get("pair_hypotheses", []):
            if not isinstance(pair, Mapping):
                continue
            pair_add = str(pair.get("add") or "")
            pair_cut = str(pair.get("cut") or "")
            if add and normalize_name(pair_add) != normalize_name(add):
                continue
            if cut and normalize_name(pair_cut) != normalize_name(cut):
                continue
            return {
                "deck_id": str(pool.get("deck_id")),
                "deck_name": pool.get("deck_name"),
                "commander": pool.get("commander"),
                "role": pair.get("role") or pool.get("role"),
                "add": pair_add,
                "cut": pair_cut,
                "pair": dict(pair),
                "candidate": candidates.get(normalize_name(pair_add), {}),
                "cut_candidate": cuts.get(normalize_name(pair_cut), {}),
                "source_pool_status": pool.get("status"),
                "source_report_db": source_report_db,
                "blocked_cut_candidates": list(pool.get("blocked_cut_candidates") or []),
            }
    raise RuntimeError(f"no matching pair found in {pair_report}")


def source_db_report_path(source_db: Path) -> str:
    return rel(source_db.resolve())


def validate_source_db_for_pair(
    conn: sqlite3.Connection,
    *,
    source_db: Path,
    pair: Mapping[str, Any],
    deck_id: int,
    allow_chained_source: bool,
) -> dict[str, Any]:
    expected_source = str(pair.get("source_report_db") or "")
    actual_source = source_db_report_path(source_db)
    source_matches = not expected_source or actual_source == expected_source
    if not source_matches and not allow_chained_source:
        raise RuntimeError(
            "source DB does not match pair report source_db; "
            f"expected {expected_source}, got {actual_source}. "
            "Rerun the candidate model for this source DB or pass --allow-chained-source explicitly."
        )

    deck_names = {normalize_name(str(row["card_name"])) for row in deck_rows(conn, deck_id)}
    protected_cards = [
        str(row.get("card_name") or "")
        for row in pair.get("blocked_cut_candidates", [])
        if isinstance(row, Mapping) and str(row.get("card_name") or "").strip()
    ]
    missing_protected = [
        card for card in protected_cards if normalize_name(card) not in deck_names
    ]
    if missing_protected:
        raise RuntimeError(
            "source DB is stale or already mutated; protected blocked cut cards are absent: "
            + ", ".join(missing_protected)
        )
    return {
        "expected_source_db": expected_source,
        "actual_source_db": actual_source,
        "source_matches_pair_report": source_matches,
        "allow_chained_source": allow_chained_source,
        "protected_blocked_cut_cards": protected_cards,
        "missing_protected_blocked_cut_cards": missing_protected,
    }


def oracle_row(conn: sqlite3.Connection, card_name: str) -> sqlite3.Row:
    row = conn.execute(
        """
        SELECT *
        FROM card_oracle_cache
        WHERE normalized_name=? OR lower(name)=lower(?)
        ORDER BY name
        LIMIT 1
        """,
        (normalize_name(card_name), card_name),
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
          CASE WHEN COALESCE(functional_tags_json, '[]') NOT IN ('', '[]') THEN 1 ELSE 0 END DESC,
          CASE WHEN COALESCE(semantic_tags_v2_json, '[]') NOT IN ('', '[]') THEN 1 ELSE 0 END DESC,
          CASE WHEN COALESCE(battle_rules_json, '[]') NOT IN ('', '[]') THEN 1 ELSE 0 END DESC,
          deck_id DESC
        LIMIT 1
        """,
        (card_name, exclude_deck_id),
    ).fetchall()
    return rows[0] if rows else None


def active_rules_for_card(conn: sqlite3.Connection, card_name: str) -> list[dict[str, Any]]:
    table_names = {str(row["name"]) for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    if "battle_card_rules" not in table_names:
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


def build_added_row(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    card_name: str,
    role: str,
    columns: list[str],
    sync_run_id: str,
) -> dict[str, Any]:
    oracle = oracle_row(conn, card_name)
    existing = existing_deck_card_row(conn, card_name, exclude_deck_id=deck_id)
    values = {column: None for column in columns}
    if existing is not None:
        values.update({column: existing[column] for column in columns})

    functional_tags = {str(tag) for tag in json_list(values.get("functional_tags_json")) if str(tag).strip()}
    if role:
        functional_tags.add(role)
    values.update(
        {
            "deck_id": deck_id,
            "card_name": oracle["name"] if "name" in oracle.keys() and oracle["name"] else card_name,
            "quantity": 1,
            "functional_tag": role or values.get("functional_tag") or "candidate",
            "tag_confidence": values.get("tag_confidence") or "candidate_copy",
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
        values["functional_tags_json"] = stable_json(sorted(functional_tags))
    if "semantic_tags_v2_json" in columns:
        values["semantic_tags_v2_json"] = stable_json(json_list(values.get("semantic_tags_v2_json")))
    if "battle_rules_json" in columns:
        existing_rules = json_list(values.get("battle_rules_json"))
        values["battle_rules_json"] = stable_json(existing_rules or active_rules_for_card(conn, card_name))
    if "sync_run_id" in columns:
        values["sync_run_id"] = sync_run_id
    for column in HASH_COLUMNS:
        if column in columns:
            values[column] = None
    return values


def materialize_swap(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    add: str,
    cut: str,
    role: str,
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

    candidate_rows.append(
        build_added_row(
            conn,
            deck_id=deck_id,
            card_name=add,
            role=role,
            columns=columns,
            sync_run_id=sync_run_id,
        )
    )

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
        "role": role,
        "row_count": len(candidate_rows),
        "total_cards": sum(int(row.get("quantity") or 1) for row in candidate_rows),
        "active_rule_count_for_add": len(active_rules_for_card(conn, add)),
    }


def nonbasic_singleton_violations(rows: list[sqlite3.Row]) -> list[str]:
    violations: list[str] = []
    for row in rows:
        quantity = int(row["quantity"] or 1)
        type_line = str(row["type_line"] or "")
        if quantity <= 1 or type_line.startswith("Basic Land"):
            continue
        violations.append(str(row["card_name"]))
    return violations


def validate_candidate_structure(
    conn: sqlite3.Connection,
    *,
    deck_id: int,
    add: str,
    cut: str,
    role: str,
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
    added_tags = set()
    if add_rows:
        added_tags = set(json_list(add_rows[0]["functional_tags_json"])) | {str(add_rows[0]["functional_tag"] or "")}
    violations = nonbasic_singleton_violations(rows)
    checks = {
        "total_cards_100": int(summary["cards"]) == 100,
        "commander_count_1": commander_count == 1,
        "add_present_once": len(add_rows) == 1 and int(add_rows[0]["quantity"] or 1) == 1,
        "cut_absent": not cut_rows,
        "added_role_present": not role or role in added_tags,
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


def materialize_candidate_db(
    *,
    source_db: Path,
    candidate_db: Path,
    deck_id: int,
    add: str,
    cut: str,
    role: str,
    sync_run_id: str,
) -> dict[str, Any]:
    candidate_db.parent.mkdir(parents=True, exist_ok=True)
    if candidate_db.exists():
        candidate_db.unlink()
    shutil.copy2(source_db, candidate_db)
    with connect(candidate_db) as conn:
        swap_meta = materialize_swap(
            conn,
            deck_id=deck_id,
            add=add,
            cut=cut,
            role=role,
            sync_run_id=sync_run_id,
        )
        validation = validate_candidate_structure(conn, deck_id=deck_id, add=add, cut=cut, role=role)
        candidate_hash = deck_hash(conn, deck_id)
    return {
        "candidate_db": rel(candidate_db),
        "swap_meta": swap_meta,
        "structure_validation": validation,
        "candidate_deck_hash": candidate_hash,
    }


def build_payload(
    *,
    source_db: Path = DEFAULT_SQLITE_DB,
    pair_report: Path = DEFAULT_PAIR_REPORT,
    out_prefix: Path = DEFAULT_OUT_PREFIX,
    deck_id: str | None = "619",
    add: str | None = None,
    cut: str | None = None,
    allow_chained_source: bool = False,
) -> dict[str, Any]:
    pair = load_top_pair(pair_report, deck_id=deck_id, add=add, cut=cut)
    deck_id_int = int(pair["deck_id"])
    add_name = str(pair["add"])
    cut_name = str(pair["cut"])
    role = str(pair.get("role") or "")
    candidate_dir = out_prefix.parent / f"{out_prefix.name}_candidate"
    candidate_db = candidate_dir / "knowledge_candidate.db"
    sync_run_id = out_prefix.name

    with connect(source_db) as conn:
        source_pair_guard = validate_source_db_for_pair(
            conn,
            source_db=source_db,
            pair=pair,
            deck_id=deck_id_int,
            allow_chained_source=allow_chained_source,
        )
        source_summary_before = get_deck_summary(conn, deck_id_int)
        source_hash_before = deck_hash(conn, deck_id_int)

    materialized = materialize_candidate_db(
        source_db=source_db,
        candidate_db=candidate_db,
        deck_id=deck_id_int,
        add=add_name,
        cut=cut_name,
        role=role,
        sync_run_id=sync_run_id,
    )

    with connect(source_db) as conn:
        source_summary_after = get_deck_summary(conn, deck_id_int)
        source_hash_after = deck_hash(conn, deck_id_int)

    source_unchanged = source_hash_before == source_hash_after and source_summary_before == source_summary_after
    structure_status = materialized["structure_validation"]["status"]
    status = (
        "candidate_materialized_structure_ready_next_gate_closed"
        if structure_status == "pass" and source_unchanged
        else "candidate_materialized_structure_failed"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_candidate_copy_materializer",
        "status": status,
        "postgres_writes": False,
        "source_db_mutated": False,
        "source_db": rel(source_db),
        "source_reports": [rel(pair_report)],
        "candidate_db": materialized["candidate_db"],
        "summary": {
            "deck_id": deck_id_int,
            "commander": pair.get("commander"),
            "role": role,
            "add": add_name,
            "cut": cut_name,
            "source_unchanged": source_unchanged,
            "source_deck_hash_before": source_hash_before,
            "source_deck_hash_after": source_hash_after,
            "candidate_deck_hash": materialized["candidate_deck_hash"],
            "source_candidate_hash_differs": source_hash_before != materialized["candidate_deck_hash"],
            "promotion_allowed": False,
            "allow_battle_gate_now": False,
            "allow_next_strategy_matrix": status == "candidate_materialized_structure_ready_next_gate_closed",
            "source_matches_pair_report": source_pair_guard["source_matches_pair_report"],
        },
        "source_pair_guard": source_pair_guard,
        "model_pair": pair,
        "materialization": materialized["swap_meta"],
        "structure_validation": materialized["structure_validation"],
        "source_deck_summary_before": source_summary_before,
        "source_deck_summary_after": source_summary_after,
        "policy": {
            "candidate_scope": "The swap exists only inside the copied Hermes SQLite candidate DB.",
            "promotion_gate": "Promotion stays closed until structure, strategy matrix, battle gate, and replay trace pass.",
            "source_boundary": "Source DB and PostgreSQL are not mutated by this materializer.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    validation = payload["structure_validation"]
    lines = [
        "# Global Commander Candidate Copy Materializer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- commander: `{summary['commander']}`",
        f"- candidate: `+{summary['add']} / -{summary['cut']}`",
        f"- role: `{summary['role']}`",
        f"- candidate_db: `{payload['candidate_db']}`",
        f"- source_unchanged: `{str(summary['source_unchanged']).lower()}`",
        f"- source_matches_pair_report: `{str(summary['source_matches_pair_report']).lower()}`",
        f"- source_candidate_hash_differs: `{str(summary['source_candidate_hash_differs']).lower()}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- allow_battle_gate_now: `{str(summary['allow_battle_gate_now']).lower()}`",
        f"- allow_next_strategy_matrix: `{str(summary['allow_next_strategy_matrix']).lower()}`",
        f"- allow_chained_source: `{str(payload['source_pair_guard']['allow_chained_source']).lower()}`",
        f"- protected_blocked_cut_cards: `{payload['source_pair_guard']['protected_blocked_cut_cards']}`",
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
    lines.extend(["", "## Policy", ""])
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
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--pair-report", type=Path, default=DEFAULT_PAIR_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--deck-id", default="619")
    parser.add_argument("--add")
    parser.add_argument("--cut")
    parser.add_argument(
        "--allow-chained-source",
        action="store_true",
        help="Allow source DB to differ from the pair report source_db; protected blocked cuts still must be present.",
    )
    args = parser.parse_args()
    payload = build_payload(
        source_db=args.source_db,
        pair_report=args.pair_report,
        out_prefix=args.out_prefix,
        deck_id=args.deck_id,
        add=args.add,
        cut=args.cut,
        allow_chained_source=args.allow_chained_source,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "candidate_db": payload["candidate_db"],
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0 if str(payload["status"]).startswith("candidate_materialized_structure_ready") else 1


if __name__ == "__main__":
    raise SystemExit(main())
