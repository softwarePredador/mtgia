#!/usr/bin/env python3
"""Audit global Commander deck treatment readiness across PostgreSQL and Hermes.

This is a read-only governance audit. It does not promote decks, mutate
PostgreSQL, mutate Hermes SQLite, or run battle gates. Lorehold deck 607 remains
the pilot/baseline, but this audit checks whether the same deckbuilding contract
can be applied globally without mixing product decks, registered variants, and
test fixtures.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SQLITE_DB = SCRIPT_DIR / "knowledge.db"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"

if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))


TEST_EMAIL_RE = re.compile(
    r"("
    r"(^|[._+-])qa|(^|[._+-])test|runtime|fixture|smoke|e2e|"
    r"example\.(com|net|org|invalid)|test\.local|@t\.com|mltest|decktest|"
    r"functional_tags|semantic_v2|iphone15|sm_a135m|m2006_|poll_|inc_|"
    r"copilot\.audit|corpus\.builder|optimization\.validation\.bot|"
    r"profile_community|learned_lorehold|audit_|gen_|flow_|probe_"
    r")",
    re.IGNORECASE,
)

TEST_NAME_RE = re.compile(
    r"^("
    r"QA|Test|Runtime|Semantic v2|Deck incremental|AI Generated|ML Test Deck|"
    r"Optimize Flow|Debate Test|Private Deck|Imported Deck|Updated Deck|"
    r"Cop?ia de Test|Cópia de Test|Commander Only Validation|"
    r"Resolution Validation|Profile Community Runtime|Incomplete |Flow |Probe "
    r")",
    re.IGNORECASE,
)

BASIC_LAND_NAMES = {
    "Plains",
    "Island",
    "Swamp",
    "Mountain",
    "Forest",
    "Wastes",
    "Snow-Covered Plains",
    "Snow-Covered Island",
    "Snow-Covered Swamp",
    "Snow-Covered Mountain",
    "Snow-Covered Forest",
}

LIMITED_EXTRA_COPY_LIMITS = {
    "Nazgûl": 9,
    "Seven Dwarves": 7,
}


@dataclass(frozen=True)
class DeckRow:
    source: str
    deck_id: str
    name: str
    format: str
    user_email: str = ""
    user_id: str = ""
    archetype: str = ""
    row_count: int = 0
    total_quantity: int = 0
    commander_count: int = 0
    null_card_rows: int = 0
    nonbasic_duplicate_rows: int = 0
    illegal_rows: int = 0
    unknown_legality_rows: int = 0
    off_color_rows: int = 0
    commander_names: tuple[str, ...] = ()


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def normalize_format(value: str) -> str:
    return (value or "").strip().lower()


def classify_deck(row: DeckRow) -> str:
    email = (row.user_email or "").strip()
    name = (row.name or "").strip()

    if row.source == "hermes":
        if name.startswith("VARIANT Lorehold"):
            return "hermes_lorehold_variant"
        if name.startswith("VARIANT "):
            return "hermes_registered_variant"
        if "lorehold" in name.lower():
            return "hermes_lorehold_baseline"
        return "hermes_lab"

    if name.startswith("PG REGISTERED "):
        return "registered_pg_variant"
    if not email:
        return "system_or_registered"
    if TEST_EMAIL_RE.search(email) or TEST_NAME_RE.search(name):
        return "test_or_fixture"
    return "user_product"


def validate_commander_shape(row: DeckRow) -> tuple[str, list[str]]:
    issues: list[str] = []
    fmt = normalize_format(row.format)
    if fmt != "commander":
        issues.append("not_commander_format")
        return "out_of_scope", issues

    if row.null_card_rows:
        issues.append("unresolved_card_id")
    if row.total_quantity != 100:
        issues.append("quantity_not_100")
    if row.commander_count == 0:
        issues.append("missing_commander")
    elif row.commander_count == 1:
        pass
    else:
        issues.append("partner_or_multi_commander_requires_profile")
    if row.nonbasic_duplicate_rows:
        issues.append("nonbasic_duplicate_quantity")
    if row.illegal_rows:
        issues.append("illegal_card_rows")
    if row.off_color_rows:
        issues.append("off_color_rows")

    if issues:
        return "needs_repair", issues
    if row.unknown_legality_rows:
        return "ready_with_legality_warnings", ["unknown_legality_rows"]
    return "structure_ready", []


def summarize(
    rows: Iterable[DeckRow],
    *,
    postgres_required: bool = True,
    postgres_loaded: bool | None = None,
) -> dict[str, Any]:
    rows = list(rows)
    postgres_rows = [row for row in rows if row.source == "postgres"]
    if postgres_loaded is None:
        postgres_loaded = bool(postgres_rows)
    scope_counts: Counter[str] = Counter()
    status_counts: dict[str, Counter[str]] = defaultdict(Counter)
    issue_counts: Counter[str] = Counter()
    commander_counts: Counter[str] = Counter()
    sample_issues_by_scope: dict[str, list[dict[str, Any]]] = defaultdict(list)

    for row in rows:
        scope = classify_deck(row)
        status, issues = validate_commander_shape(row)
        scope_counts[scope] += 1
        status_counts[scope][status] += 1
        for commander in row.commander_names:
            commander_counts[commander] += 1
        for issue in issues:
            issue_counts[f"{scope}:{issue}"] += 1
        if issues and len(sample_issues_by_scope[scope]) < 30:
            sample_issues_by_scope[scope].append(
                _issue_sample(row=row, scope=scope, issues=issues)
            )

    product_ready = status_counts["user_product"]["structure_ready"] + status_counts["user_product"][
        "ready_with_legality_warnings"
    ]
    product_total = scope_counts["user_product"]
    registered_ready = status_counts["registered_pg_variant"]["structure_ready"] + status_counts[
        "registered_pg_variant"
    ]["ready_with_legality_warnings"]
    registered_total = scope_counts["registered_pg_variant"]

    action_items: list[str] = []
    if product_ready < product_total:
        action_items.append(
            "offer_owner_reviewed_repair_without_mutation_before_global_promotion"
        )
    if registered_ready < registered_total:
        action_items.append("repair_registered_pg_variants_before_using_as_global_baselines")
    if issue_counts:
        action_items.append("use_issue_counts_to_prioritize_card_id_legal_shape_repairs")
    source_blockers: list[str] = []
    if postgres_required and not postgres_loaded:
        source_blockers.append("postgres_product_truth_not_loaded")

    promotion_blockers: list[str] = []
    if product_ready < product_total:
        promotion_blockers.append("product_decks_need_owner_reviewed_repair")
    if registered_ready < registered_total:
        promotion_blockers.append("registered_pg_variants_need_repair")
    promotion_blockers.extend(source_blockers)

    scope_priority = [
        "user_product",
        "registered_pg_variant",
        "hermes_registered_variant",
        "hermes_lorehold_baseline",
        "hermes_lorehold_variant",
        "test_or_fixture",
        "system_or_registered",
        "hermes_lab",
    ]
    sample_issues: list[dict[str, Any]] = []
    for scope in scope_priority:
        sample_issues.extend(sample_issues_by_scope.get(scope, []))
    for scope in sorted(set(sample_issues_by_scope) - set(scope_priority)):
        sample_issues.extend(sample_issues_by_scope[scope])

    return {
        "generated_at": utc_now(),
        "status": "fail" if source_blockers else "pass",
        "contract": rel(COMMANDER_CONTRACT),
        "total_decks": len(rows),
        "source_coverage": {
            "postgres_required": postgres_required,
            "postgres_loaded": postgres_loaded,
            "postgres_deck_count": len(postgres_rows),
            "hermes_deck_count": sum(row.source == "hermes" for row in rows),
            "product_truth_status": (
                "loaded"
                if postgres_loaded
                else "not_requested"
                if not postgres_required
                else "missing"
            ),
        },
        "classification": {
            "postgres_deck_count": len(postgres_rows),
            "postgres_classified_count": len(postgres_rows),
            "all_postgres_decks_classified": postgres_loaded,
            "user_product_total": product_total,
            "user_product_structure_ready": product_ready,
            "user_product_needs_owner_review": product_total - product_ready,
        },
        "promotion": {
            "allowed": not promotion_blockers,
            "blockers": promotion_blockers,
            "automatic_mutation_performed": False,
        },
        "scope_counts": dict(sorted(scope_counts.items())),
        "status_counts_by_scope": {scope: dict(counter) for scope, counter in sorted(status_counts.items())},
        "issue_counts": dict(sorted(issue_counts.items())),
        "top_commanders": [
            {"commander": name, "deck_count": count}
            for name, count in commander_counts.most_common(30)
        ],
        "sample_issues": sample_issues,
        "sample_issues_by_scope": dict(sample_issues_by_scope),
        "action_items": action_items,
        "method": {
            "postgres_is_product_truth": True,
            "hermes_is_lab_cache": True,
            "lorehold_607_role": "pilot_and_protected_baseline_not_global_template",
            "incomplete_deck_policy": "preserve_owner_intent_and_offer_reviewed_repair",
            "core_floors_are_diagnostic_only": True,
            "automatic_rebuild_allowed": False,
            "automatic_exclusion_allowed": False,
            "promotion_requires": [
                "resolved_card_ids",
                "commander_shape",
                "commander_intent_profile",
                "reference_or_learned_source_lane",
                "strategy_matrix",
                "battle_gate_with_drawn_cast_used_evidence",
            ],
        },
    }


def _issue_sample(*, row: DeckRow, scope: str, issues: list[str]) -> dict[str, Any]:
    return {
        "source": row.source,
        "scope_class": scope,
        "deck_id": row.deck_id,
        "name": row.name,
        "rows": row.row_count,
        "quantity": row.total_quantity,
        "commander_count": row.commander_count,
        "issues": issues,
        "commanders": list(row.commander_names),
    }


def _fetch_pg_rows() -> list[DeckRow]:
    from db_helper import connect

    sql = """
    WITH commander_colors AS (
      SELECT
        dc.deck_id,
        array_agg(DISTINCT color) FILTER (WHERE color IS NOT NULL) AS colors
      FROM deck_cards dc
      JOIN cards c ON c.id = dc.card_id
      LEFT JOIN LATERAL unnest(COALESCE(c.color_identity, ARRAY[]::text[])) AS color ON TRUE
      WHERE dc.is_commander = TRUE
      GROUP BY dc.deck_id
    ), deck_rollup AS (
      SELECT
        d.id::text AS deck_id,
        COALESCE(u.email, '') AS user_email,
        COALESCE(d.user_id::text, '') AS user_id,
        d.name,
        d.format,
        COALESCE(d.archetype, '') AS archetype,
        COUNT(dc.id)::int AS row_count,
        COALESCE(SUM(dc.quantity), 0)::int AS total_quantity,
        COALESCE(SUM(dc.quantity) FILTER (WHERE dc.is_commander), 0)::int AS commander_count,
        COUNT(*) FILTER (WHERE dc.card_id IS NULL)::int AS null_card_rows,
        COUNT(*) FILTER (
          WHERE dc.quantity > 1
            AND c.id IS NOT NULL
            AND NOT (
              c.name = ANY(%(basic_land_names)s)
              OR c.type_line ILIKE '%%Basic Land%%'
              OR c.oracle_text ILIKE '%%A deck can have any number of cards named%%'
              OR (
                c.name = ANY(%(limited_extra_copy_names)s)
                AND dc.quantity <= CASE
                  WHEN c.name = 'Nazgûl' THEN 9
                  WHEN c.name = 'Seven Dwarves' THEN 7
                  ELSE 1
                END
              )
            )
        )::int AS nonbasic_duplicate_rows,
        COUNT(*) FILTER (
          WHERE c.id IS NOT NULL
            AND cl.status IS NOT NULL
            AND cl.status NOT IN ('legal', 'restricted')
        )::int AS illegal_rows,
        COUNT(*) FILTER (
          WHERE c.id IS NOT NULL
            AND cl.status IS NULL
        )::int AS unknown_legality_rows,
        COUNT(*) FILTER (
          WHERE c.id IS NOT NULL
            AND dc.is_commander IS NOT TRUE
            AND COALESCE(array_length(c.color_identity, 1), 0) > 0
            AND NOT COALESCE(c.color_identity <@ COALESCE(cc.colors, ARRAY[]::text[]), FALSE)
        )::int AS off_color_rows,
        COALESCE(array_agg(c.name ORDER BY c.name) FILTER (WHERE dc.is_commander AND c.name IS NOT NULL), ARRAY[]::text[]) AS commander_names
      FROM decks d
      LEFT JOIN users u ON u.id = d.user_id
      LEFT JOIN deck_cards dc ON dc.deck_id = d.id
      LEFT JOIN cards c ON c.id = dc.card_id
      LEFT JOIN card_legalities cl ON cl.card_id = c.id AND lower(cl.format) = 'commander'
      LEFT JOIN commander_colors cc ON cc.deck_id = d.id
      WHERE d.deleted_at IS NULL
        AND lower(d.format) = 'commander'
      GROUP BY d.id, u.email
    )
    SELECT *
    FROM deck_rollup
    ORDER BY name, deck_id
    """
    rows: list[DeckRow] = []
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                sql,
                {
                    "basic_land_names": list(BASIC_LAND_NAMES),
                    "limited_extra_copy_names": list(LIMITED_EXTRA_COPY_LIMITS),
                },
            )
            columns = [desc[0] for desc in cur.description]
            for raw in cur.fetchall():
                data = dict(zip(columns, raw))
                rows.append(
                    DeckRow(
                        source="postgres",
                        deck_id=str(data["deck_id"]),
                        user_email=data["user_email"] or "",
                        user_id=data["user_id"] or "",
                        name=data["name"] or "",
                        format=data["format"] or "",
                        archetype=data["archetype"] or "",
                        row_count=int(data["row_count"] or 0),
                        total_quantity=int(data["total_quantity"] or 0),
                        commander_count=int(data["commander_count"] or 0),
                        null_card_rows=int(data["null_card_rows"] or 0),
                        nonbasic_duplicate_rows=int(data["nonbasic_duplicate_rows"] or 0),
                        illegal_rows=int(data["illegal_rows"] or 0),
                        unknown_legality_rows=int(data["unknown_legality_rows"] or 0),
                        off_color_rows=int(data["off_color_rows"] or 0),
                        commander_names=tuple(data["commander_names"] or ()),
                    )
                )
    return rows


def _fetch_hermes_rows(sqlite_db: Path) -> list[DeckRow]:
    if not sqlite_db.exists():
        return []
    rows: list[DeckRow] = []
    with sqlite3.connect(sqlite_db) as conn:
        conn.row_factory = sqlite3.Row
        for row in conn.execute(
            """
            SELECT
              d.id AS deck_id,
              COALESCE(d.deck_name, '') AS name,
              COALESCE(d.archetype, '') AS archetype,
              COUNT(dc.card_name) AS row_count,
              COALESCE(SUM(dc.quantity), 0) AS total_quantity,
              SUM(CASE WHEN dc.is_commander = 1 THEN 1 ELSE 0 END) AS commander_count,
              SUM(CASE WHEN dc.card_id IS NULL OR TRIM(dc.card_id) = '' THEN 1 ELSE 0 END) AS null_card_rows,
              GROUP_CONCAT(CASE WHEN dc.is_commander = 1 THEN dc.card_name ELSE NULL END, '||') AS commander_names
            FROM decks d
            LEFT JOIN deck_cards dc ON dc.deck_id = d.id
            GROUP BY d.id
            ORDER BY d.id
            """
        ):
            commanders = tuple(
                name for name in str(row["commander_names"] or "").split("||") if name
            )
            rows.append(
                DeckRow(
                    source="hermes",
                    deck_id=str(row["deck_id"]),
                    name=row["name"],
                    format="commander",
                    archetype=row["archetype"],
                    row_count=int(row["row_count"] or 0),
                    total_quantity=int(row["total_quantity"] or 0),
                    commander_count=int(row["commander_count"] or 0),
                    null_card_rows=int(row["null_card_rows"] or 0),
                    commander_names=commanders,
                )
            )
    return rows


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Deck Contract Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        f"- Total decks audited: `{payload['total_decks']}`",
        f"- PostgreSQL product truth: `{payload['source_coverage']['product_truth_status']}`",
        f"- PostgreSQL decks classified: `{payload['classification']['postgres_classified_count']}/{payload['classification']['postgres_deck_count']}`",
        f"- Product decks needing owner review: `{payload['classification']['user_product_needs_owner_review']}`",
        f"- Promotion allowed: `{str(payload['promotion']['allowed']).lower()}`",
        f"- Automatic mutation performed: `{str(payload['promotion']['automatic_mutation_performed']).lower()}`",
        "",
        "## Governance",
        "",
        "- Incomplete decks preserve owner intent and only receive reviewed repair suggestions.",
        "- Core floors are diagnostic only; they do not authorize rebuild or exclusion.",
        f"- Promotion blockers: `{', '.join(payload['promotion']['blockers']) or 'none'}`",
        "",
        "## Scope Counts",
        "",
        "| Scope | Decks |",
        "| --- | ---: |",
    ]
    for scope, count in payload["scope_counts"].items():
        lines.append(f"| `{scope}` | {count} |")

    lines.extend(["", "## Status By Scope", "", "| Scope | Status | Decks |", "| --- | --- | ---: |"])
    for scope, counter in payload["status_counts_by_scope"].items():
        for status, count in sorted(counter.items()):
            lines.append(f"| `{scope}` | `{status}` | {count} |")

    lines.extend(["", "## Issue Counts", "", "| Issue | Count |", "| --- | ---: |"])
    for issue, count in payload["issue_counts"].items():
        lines.append(f"| `{issue}` | {count} |")

    lines.extend(["", "## Top Commanders", "", "| Commander | Decks |", "| --- | ---: |"])
    for row in payload["top_commanders"][:15]:
        lines.append(f"| `{row['commander']}` | {row['deck_count']} |")

    lines.extend(["", "## Sample Issues", "", "| Scope | Source | Deck | Quantity | Commanders | Issues |", "| --- | --- | --- | ---: | ---: | --- |"])
    for row in payload["sample_issues"][:40]:
        lines.append(
            "| `{scope}` | `{source}` | `{name}` (`{deck_id}`) | {quantity} | {commander_count} | `{issues}` |".format(
                scope=row["scope_class"],
                source=row["source"],
                name=str(row["name"]).replace("|", "/"),
                deck_id=row["deck_id"],
                quantity=row["quantity"],
                commander_count=row["commander_count"],
                issues=", ".join(row["issues"]),
            )
        )

    lines.extend(["", "## Action Items", ""])
    for item in payload["action_items"] or ["none"]:
        lines.append(f"- `{item}`")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_deck_contract_audit_20260701",
    )
    parser.add_argument("--skip-postgres", action="store_true")
    parser.add_argument("--skip-hermes", action="store_true")
    args = parser.parse_args()

    rows: list[DeckRow] = []
    postgres_loaded = False
    if not args.skip_postgres:
        if os.environ.get("MANALOOM_PG_WRAPPER_MODE") != "read-only":
            print(
                json.dumps(
                    {
                        "status": "fail",
                        "error": "postgres_read_requires_new_server_read_only_wrapper",
                    }
                )
            )
            return 2
        rows.extend(_fetch_pg_rows())
        postgres_loaded = True
    if not args.skip_hermes:
        rows.extend(_fetch_hermes_rows(args.sqlite_db))

    payload = summarize(
        rows,
        postgres_required=not args.skip_postgres,
        postgres_loaded=postgres_loaded,
    )
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
