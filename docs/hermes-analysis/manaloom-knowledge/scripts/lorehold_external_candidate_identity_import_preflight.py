#!/usr/bin/env python3
"""Preflight missing external Lorehold candidates before any deck test.

The external material scout tells us which cards are not in protected 607 and
which are absent from the current local Lorehold deck pool. This script checks
whether those cards already have local Oracle identity, Commander legality,
format-staple metadata, and verified battle-rule coverage. It does not import
cards, write SQLite, or mutate deck 607.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
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
DEFAULT_SCOUT_REPORT = REPORT_DIR / "lorehold_external_material_evidence_scout_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_external_candidate_identity_import_preflight_20260705_current"

MATERIAL_CLASSIFICATIONS = {
    "external_missing_from_local_deck_pool",
    "rule_known_external_not_in_lorehold_candidate_pool",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_list(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def material_candidates(scout_report: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in as_list(scout_report.get("candidate_classifications")):
        if not isinstance(row, Mapping):
            continue
        if row.get("classification") not in MATERIAL_CLASSIFICATIONS:
            continue
        rows.append(dict(row))
    return sorted(rows, key=lambda row: normalize_name(str(row.get("card_name") or "")))


def query_by_name(
    conn: sqlite3.Connection,
    table: str,
    name_column: str,
    names: list[str],
    columns: list[str],
    extra_where: str = "",
    extra_params: tuple[Any, ...] = (),
) -> dict[str, list[dict[str, Any]]]:
    if not names or not sqlite_connection_has_table(conn, table):
        return {normalize_name(name): [] for name in names}
    normalized = [normalize_name(name) for name in names]
    placeholders = ",".join("?" for _ in normalized)
    column_sql = ", ".join(columns)
    where_tail = f" AND {extra_where}" if extra_where else ""
    rows = conn.execute(
        f"""
        SELECT {column_sql}
        FROM {table}
        WHERE lower({name_column}) IN ({placeholders}){where_tail}
        ORDER BY lower({name_column})
        """,
        (*normalized, *extra_params),
    ).fetchall()
    result: dict[str, list[dict[str, Any]]] = {normalize_name(name): [] for name in names}
    for row in rows:
        key = normalize_name(row[name_column])
        result.setdefault(key, []).append(dict(row))
    return result


def preflight_status(row: Mapping[str, Any]) -> tuple[str, list[str]]:
    blockers: list[str] = []
    legal = row.get("commander_legal_status") == "legal"
    oracle_ready = bool(row.get("oracle_identity_ready"))
    verified_rules = int(row.get("verified_auto_rule_count") or 0)
    route_types = set(as_list(row.get("route_types")))
    actionability = str(row.get("source_actionability") or "")

    if not legal:
        blockers.append("commander_legality_not_confirmed")
        return "blocked_commander_legality_not_confirmed", blockers
    if not oracle_ready:
        blockers.append("oracle_identity_missing")
        if "combo_package" in route_types:
            blockers.append("combo_runtime_unavailable_until_identity_exists")
            return "identity_import_required_before_combo_runtime", blockers
        return "identity_import_required", blockers
    if "archetype_fork" in route_types or actionability == "archetype_fork_only_requires_full_shell_contract":
        blockers.append("full_shell_contract_required")
        if verified_rules == 0:
            blockers.append("verified_battle_rule_missing")
        return "shell_contract_required_not_one_for_one_cut", blockers
    if verified_rules == 0:
        blockers.append("verified_battle_rule_missing")
        return "runtime_rule_or_manual_review_required", blockers
    if "combo_package" in route_types:
        blockers.append("package_cut_safety_missing")
        return "combo_material_ready_but_cut_safety_missing", blockers
    blockers.append("safe_cut_contract_missing")
    return "identity_ready_needs_cut_safety_contract", blockers


def build_rows(conn: sqlite3.Connection, scout_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    names = [str(row["card_name"]) for row in scout_rows if row.get("card_name")]
    oracle_rows = query_by_name(
        conn,
        "card_oracle_cache",
        "name",
        names,
        [
            "name",
            "card_id",
            "mana_cost",
            "color_identity_json",
            "type_line",
            "oracle_text",
            "cmc",
            "scryfall_id",
        ],
    )
    legality_rows = query_by_name(
        conn,
        "card_legalities",
        "card_name",
        names,
        ["card_name", "format", "status", "scryfall_id"],
        "format = ?",
        ("commander",),
    )
    staple_rows = query_by_name(
        conn,
        "format_staples",
        "card_name",
        names,
        ["card_name", "format", "category", "archetype", "edhrec_rank", "is_banned"],
        "format = ?",
        ("commander",),
    )
    rule_rows = query_by_name(
        conn,
        "battle_card_rules",
        "card_name",
        names,
        ["card_name", "logical_rule_key", "review_status", "execution_status"],
    )

    output: list[dict[str, Any]] = []
    by_name = {normalize_name(str(row["card_name"])): row for row in scout_rows}
    for name in sorted(names, key=normalize_name):
        norm = normalize_name(name)
        scout = by_name[norm]
        oracle = oracle_rows.get(norm, [])
        legalities = legality_rows.get(norm, [])
        staples = staple_rows.get(norm, [])
        rules = rule_rows.get(norm, [])
        verified_rules = [
            rule
            for rule in rules
            if rule.get("review_status") == "verified" and rule.get("execution_status") == "auto"
        ]
        base = {
            "card_name": name,
            "source_classification": scout.get("classification"),
            "source_actionability": scout.get("actionability"),
            "source_keys": as_list(scout.get("source_keys")),
            "route_types": as_list(scout.get("route_types")),
            "oracle_identity_ready": bool(oracle),
            "oracle_name": oracle[0].get("name") if oracle else None,
            "card_id": oracle[0].get("card_id") if oracle else None,
            "scryfall_id": oracle[0].get("scryfall_id") if oracle else None,
            "color_identity_json": oracle[0].get("color_identity_json") if oracle else None,
            "type_line": oracle[0].get("type_line") if oracle else None,
            "cmc": oracle[0].get("cmc") if oracle else None,
            "commander_legal_status": legalities[0].get("status") if legalities else "unknown",
            "format_staple_rank": staples[0].get("edhrec_rank") if staples else None,
            "format_staple_category": staples[0].get("category") if staples else None,
            "format_staple_banned": bool(staples and int(staples[0].get("is_banned") or 0)),
            "battle_rule_count": len(rules),
            "verified_auto_rule_count": len(verified_rules),
            "battle_rules": rules,
        }
        status, blockers = preflight_status(base)
        base["preflight_status"] = status
        base["blockers"] = blockers
        base["deck_test_allowed_now"] = False
        output.append(base)
    return output


def build_payload(
    conn: sqlite3.Connection,
    *,
    db_path: Path,
    scout_report: Mapping[str, Any],
    scout_path: Path,
) -> dict[str, Any]:
    scout_rows = material_candidates(scout_report)
    rows = build_rows(conn, scout_rows)
    identity_missing = [row for row in rows if not row["oracle_identity_ready"]]
    identity_ready = [row for row in rows if row["oracle_identity_ready"]]
    runtime_missing = [
        row
        for row in rows
        if row["oracle_identity_ready"] and row["verified_auto_rule_count"] == 0
    ]
    runtime_review_rows = [
        row for row in rows if row["preflight_status"] == "runtime_rule_or_manual_review_required"
    ]
    shell_rows = [row for row in rows if row["preflight_status"] == "shell_contract_required_not_one_for_one_cut"]
    status = "external_identity_preflight_blocks_gate_keep_607"
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_external_candidate_identity_import_preflight",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_db": str(db_path),
        "source_reports": {"external_material_scout": rel(scout_path)},
        "status": status,
        "summary": {
            "current_baseline": "deck_607",
            "material_candidate_count": len(rows),
            "commander_legal_count": sum(1 for row in rows if row["commander_legal_status"] == "legal"),
            "oracle_identity_ready_count": len(identity_ready),
            "oracle_identity_missing_count": len(identity_missing),
            "identity_ready_without_verified_rule_count": len(runtime_missing),
            "runtime_or_manual_review_required_count": len(runtime_review_rows),
            "shell_contract_required_count": len(shell_rows),
            "format_staple_candidate_count": sum(1 for row in rows if row["format_staple_rank"] is not None),
            "gate_ready_now_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "recommended_next_action": "resolve_oracle_identity_then_split_runtime_shell_and_cut_safety_queues",
        },
        "preflight_rows": rows,
        "queues": {
            "identity_import_required": [
                row["card_name"]
                for row in rows
                if row["preflight_status"].startswith("identity_import_required")
            ],
            "runtime_or_manual_review_required": [row["card_name"] for row in runtime_review_rows],
            "shell_contract_required": [row["card_name"] for row in shell_rows],
            "cut_safety_contract_required": [
                row["card_name"]
                for row in rows
                if row["preflight_status"] == "identity_ready_needs_cut_safety_contract"
            ],
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "resolve missing Oracle identities before local materialization",
                "separate full-shell archetype forks from single-card candidate work",
                "add or review battle runtime only after identity is resolved",
                "rerun cut-safety only after the candidate has identity and route classification",
            ],
            "reason": (
                "The external material queue is legal in Commander, but it is not "
                "deck-test ready: several cards lack local Oracle identity, several "
                "identity-ready cards lack runtime/manual-review coverage, and the "
                "archetype-fork lanes are not one-for-one cuts from 607."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold External Candidate Identity Import Preflight",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- Deck 607 mutated: `{payload['deck_607_mutated']}`",
        "",
        "## Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in [
        "material_candidate_count",
        "commander_legal_count",
        "oracle_identity_ready_count",
        "oracle_identity_missing_count",
        "identity_ready_without_verified_rule_count",
        "runtime_or_manual_review_required_count",
        "shell_contract_required_count",
        "format_staple_candidate_count",
        "gate_ready_now_count",
    ]:
        lines.append(f"| `{key}` | `{summary[key]}` |")
    lines.extend(
        [
            "",
            "## Preflight Rows",
            "",
            "| Card | Status | Oracle | Commander | Rules | Route |",
            "| --- | --- | ---: | --- | ---: | --- |",
        ]
    )
    for row in payload["preflight_rows"]:
        routes = ",".join(row.get("route_types") or [])
        lines.append(
            f"| {row['card_name']} | `{row['preflight_status']}` | "
            f"`{row['oracle_identity_ready']}` | `{row['commander_legal_status']}` | "
            f"`{row['verified_auto_rule_count']}` | `{routes}` |"
        )
    lines.extend(["", "## Queues", ""])
    for queue_name, cards in payload["queues"].items():
        card_list = ", ".join(cards) if cards else "-"
        lines.append(f"- `{queue_name}`: {card_list}")
    decision = payload["decision"]
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{decision['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{decision['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{decision['promotion_allowed']}`",
            f"- Reason: {decision['reason']}",
            "",
            "## Next Actions",
            "",
        ]
    )
    for action in decision["next_actions"]:
        lines.append(f"- {action}")
    return "\n".join(lines) + "\n"


def open_readonly_db(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--scout-report", type=Path, default=DEFAULT_SCOUT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    scout_report = read_json(args.scout_report)
    with open_readonly_db(args.db) as conn:
        payload = build_payload(
            conn,
            db_path=args.db,
            scout_report=scout_report,
            scout_path=args.scout_report,
        )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "promotion_allowed": payload["summary"]["promotion_allowed"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
