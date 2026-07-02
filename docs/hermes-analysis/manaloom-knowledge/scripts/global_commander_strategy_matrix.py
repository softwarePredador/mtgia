#!/usr/bin/env python3
"""Build a global Commander readiness matrix from the frozen deck contract.

This report is read-only. It does not generate decks, mutate PostgreSQL, mutate
Hermes SQLite, or run battle gates. Its job is to identify which commanders have
structure-ready deck candidates and which source lanes are present before the
project spends battle/optimizer time on them.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import (
    DEFAULT_SQLITE_DB,
    REPO_ROOT,
    classify_deck,
    rel,
    validate_commander_shape,
    _fetch_hermes_rows,
    _fetch_pg_rows,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"

READY_SCOPES = {
    "user_product",
    "registered_pg_variant",
    "hermes_registered_variant",
    "hermes_lorehold_baseline",
    "hermes_lorehold_variant",
}

PRODUCT_SCOPES = {"user_product", "registered_pg_variant"}
LAB_SCOPES = {"hermes_registered_variant", "hermes_lorehold_baseline", "hermes_lorehold_variant"}
SOURCE_LANE_FIELDS = (
    "reference_profile_count",
    "reference_card_stats_count",
    "reference_deck_count",
    "reference_deck_analysis_count",
    "learned_deck_count",
    "card_usage_count",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_commander(value: str) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def empty_source_signals() -> dict[str, int]:
    return {field: 0 for field in SOURCE_LANE_FIELDS}


def source_lane_count(signals: dict[str, int]) -> int:
    return sum(1 for field in SOURCE_LANE_FIELDS if int(signals.get(field) or 0) > 0)


def readiness_status(*, ready_count: int, product_ready_count: int, source_lanes: int, blocked_count: int) -> str:
    if ready_count > 0 and source_lanes > 0:
        return "ready_for_strategy_matrix"
    if ready_count > 0:
        return "structure_ready_source_missing"
    if blocked_count > 0:
        return "blocked_before_global_promotion"
    if product_ready_count > 0:
        return "product_ready_without_matrix_input"
    return "no_ready_candidate"


def collect_deck_matrix_rows(*, sqlite_db: Path, skip_postgres: bool, skip_hermes: bool) -> list[dict[str, Any]]:
    rows = []
    if not skip_postgres:
        rows.extend(_fetch_pg_rows())
    if not skip_hermes:
        rows.extend(_fetch_hermes_rows(sqlite_db))

    matrix_rows: list[dict[str, Any]] = []
    for row in rows:
        scope = classify_deck(row)
        status, issues = validate_commander_shape(row)
        if scope not in READY_SCOPES and scope != "user_product":
            continue
        commander = row.commander_names[0] if row.commander_names else ""
        matrix_rows.append(
            {
                "source": row.source,
                "scope": scope,
                "status": status,
                "issues": issues,
                "deck_id": row.deck_id,
                "deck_name": row.name,
                "user_email_present": bool(row.user_email),
                "commander": commander,
                "commander_key": normalize_commander(commander),
                "quantity": row.total_quantity,
                "commander_count": row.commander_count,
            }
        )
    return matrix_rows


def fetch_source_signals(commander_keys: set[str]) -> dict[str, dict[str, int]]:
    signals = {key: empty_source_signals() for key in commander_keys if key}
    if not signals:
        return signals

    from db_helper import connect

    keys = sorted(signals)
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT lower(regexp_replace(trim(commander_name), '\\s+', ' ', 'g')) AS commander_key,
                       count(*)::int AS profile_count
                FROM commander_reference_profiles
                WHERE commander_name IS NOT NULL
                  AND lower(regexp_replace(trim(commander_name), '\\s+', ' ', 'g')) = ANY(%s)
                  AND profile_json IS NOT NULL
                  AND profile_json::text <> '{}'
                GROUP BY 1
                """,
                (keys,),
            )
            for commander_key, count in cur.fetchall():
                signals.setdefault(commander_key, empty_source_signals())["reference_profile_count"] = int(count or 0)

            cur.execute(
                """
                SELECT commander_name_normalized AS commander_key,
                       count(*) FILTER (WHERE unresolved IS NOT TRUE)::int AS card_stats_count
                FROM commander_reference_card_stats
                WHERE commander_name_normalized = ANY(%s)
                GROUP BY 1
                """,
                (keys,),
            )
            for commander_key, count in cur.fetchall():
                signals.setdefault(commander_key, empty_source_signals())["reference_card_stats_count"] = int(count or 0)

            cur.execute(
                """
                SELECT commander_name_normalized AS commander_key,
                       count(*) FILTER (WHERE accepted IS TRUE)::int AS deck_count
                FROM commander_reference_decks
                WHERE commander_name_normalized = ANY(%s)
                GROUP BY 1
                """,
                (keys,),
            )
            for commander_key, count in cur.fetchall():
                signals.setdefault(commander_key, empty_source_signals())["reference_deck_count"] = int(count or 0)

            cur.execute(
                """
                SELECT commander_name_normalized AS commander_key,
                       COALESCE(sum(accepted_deck_count), 0)::int AS analysis_count
                FROM commander_reference_deck_analysis
                WHERE commander_name_normalized = ANY(%s)
                GROUP BY 1
                """,
                (keys,),
            )
            for commander_key, count in cur.fetchall():
                signals.setdefault(commander_key, empty_source_signals())[
                    "reference_deck_analysis_count"
                ] = int(count or 0)

            cur.execute(
                """
                SELECT commander_name_normalized AS commander_key,
                       count(*) FILTER (WHERE is_active IS TRUE)::int AS learned_count
                FROM commander_learned_decks
                WHERE commander_name_normalized = ANY(%s)
                GROUP BY 1
                """,
                (keys,),
            )
            for commander_key, count in cur.fetchall():
                signals.setdefault(commander_key, empty_source_signals())["learned_deck_count"] = int(count or 0)

            cur.execute(
                """
                SELECT commander_name_normalized AS commander_key,
                       count(*)::int AS usage_count
                FROM commander_card_usage
                WHERE commander_name_normalized = ANY(%s)
                GROUP BY 1
                """,
                (keys,),
            )
            for commander_key, count in cur.fetchall():
                signals.setdefault(commander_key, empty_source_signals())["card_usage_count"] = int(count or 0)
    return signals


def build_matrix(deck_rows: list[dict[str, Any]], source_signals: dict[str, dict[str, int]]) -> dict[str, Any]:
    by_commander: dict[str, list[dict[str, Any]]] = defaultdict(list)
    skipped_no_commander = 0
    for row in deck_rows:
        if not row["commander_key"]:
            skipped_no_commander += 1
            continue
        by_commander[row["commander_key"]].append(row)

    commanders: list[dict[str, Any]] = []
    totals = Counter()
    for commander_key, rows in sorted(by_commander.items()):
        commander_name = rows[0]["commander"]
        ready_rows = [row for row in rows if row["status"] == "structure_ready" and row["scope"] in READY_SCOPES]
        blocked_rows = [row for row in rows if row["status"] != "structure_ready" and row["scope"] in PRODUCT_SCOPES]
        scope_counts = Counter(row["scope"] for row in rows)
        ready_scope_counts = Counter(row["scope"] for row in ready_rows)
        issue_counts = Counter(issue for row in blocked_rows for issue in row["issues"])
        signals = source_signals.get(commander_key, empty_source_signals())
        lanes = source_lane_count(signals)
        product_ready_count = sum(1 for row in ready_rows if row["scope"] in PRODUCT_SCOPES)
        lab_ready_count = sum(1 for row in ready_rows if row["scope"] in LAB_SCOPES)
        status = readiness_status(
            ready_count=len(ready_rows),
            product_ready_count=product_ready_count,
            source_lanes=lanes,
            blocked_count=len(blocked_rows),
        )
        totals[status] += 1
        commanders.append(
            {
                "commander": commander_name,
                "commander_key": commander_key,
                "status": status,
                "ready_deck_count": len(ready_rows),
                "product_ready_deck_count": product_ready_count,
                "lab_ready_deck_count": lab_ready_count,
                "blocked_product_deck_count": len(blocked_rows),
                "scope_counts": dict(sorted(scope_counts.items())),
                "ready_scope_counts": dict(sorted(ready_scope_counts.items())),
                "blocked_issue_counts": dict(sorted(issue_counts.items())),
                "source_lane_count": lanes,
                "source_signals": signals,
                "ready_decks": [
                    {
                        "scope": row["scope"],
                        "source": row["source"],
                        "deck_id": row["deck_id"],
                        "deck_name": row["deck_name"],
                    }
                    for row in ready_rows[:20]
                ],
                "blocked_product_decks": [
                    {
                        "scope": row["scope"],
                        "deck_id": row["deck_id"],
                        "deck_name": row["deck_name"],
                        "issues": row["issues"],
                        "quantity": row["quantity"],
                        "commander_count": row["commander_count"],
                    }
                    for row in blocked_rows[:20]
                ],
                "next_gate": next_gate(status),
            }
        )

    commanders.sort(
        key=lambda row: (
            row["status"] != "ready_for_strategy_matrix",
            -row["product_ready_deck_count"],
            -row["ready_deck_count"],
            row["commander_key"],
        )
    )
    return {
        "generated_at": utc_now(),
        "status": "pass",
        "contract": rel(COMMANDER_CONTRACT),
        "method": {
            "read_only": True,
            "source_audit": "global_commander_deck_contract_audit.py",
            "postgres_is_product_truth": True,
            "hermes_is_lab_cache": True,
            "eligible_scopes": sorted(READY_SCOPES),
            "battle_or_optimization_performed": False,
        },
        "totals": {
            "commander_count": len(commanders),
            "deck_rows_considered": len(deck_rows),
            "skipped_no_commander": skipped_no_commander,
            "status_counts": dict(sorted(totals.items())),
            "ready_deck_count": sum(row["ready_deck_count"] for row in commanders),
            "product_ready_deck_count": sum(row["product_ready_deck_count"] for row in commanders),
            "blocked_product_deck_count": sum(row["blocked_product_deck_count"] for row in commanders),
        },
        "commanders": commanders,
    }


def next_gate(status: str) -> str:
    if status == "ready_for_strategy_matrix":
        return "run_commander_specific_strategy_matrix_before_battle_gate"
    if status == "structure_ready_source_missing":
        return "add_reference_profile_or_learned_source_lane_before_strategy_matrix"
    if status == "blocked_before_global_promotion":
        return "repair_or_exclude_product_deck_before_strategy_matrix"
    return "no_global_action_until_structure_ready_deck_exists"


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Strategy Matrix",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Contract: `{payload['contract']}`",
        f"- Deck rows considered: `{payload['totals']['deck_rows_considered']}`",
        f"- Commanders considered: `{payload['totals']['commander_count']}`",
        f"- Ready decks: `{payload['totals']['ready_deck_count']}`",
        f"- Product ready decks: `{payload['totals']['product_ready_deck_count']}`",
        f"- Blocked product decks: `{payload['totals']['blocked_product_deck_count']}`",
        "",
        "## Status Counts",
        "",
        "| Status | Commanders |",
        "| --- | ---: |",
    ]
    for status, count in payload["totals"]["status_counts"].items():
        lines.append(f"| `{status}` | {count} |")

    lines.extend(
        [
            "",
            "## Commander Matrix",
            "",
            "| Commander | Status | Ready | Product Ready | Lab Ready | Source Lanes | Blocked Product | Next Gate |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |",
        ]
    )
    for row in payload["commanders"]:
        lines.append(
            "| `{commander}` | `{status}` | {ready} | {product_ready} | {lab_ready} | {lanes} | {blocked} | `{next_gate}` |".format(
                commander=row["commander"].replace("|", "/"),
                status=row["status"],
                ready=row["ready_deck_count"],
                product_ready=row["product_ready_deck_count"],
                lab_ready=row["lab_ready_deck_count"],
                lanes=row["source_lane_count"],
                blocked=row["blocked_product_deck_count"],
                next_gate=row["next_gate"],
            )
        )

    lines.extend(
        [
            "",
            "## Blocked Product Decks",
            "",
            "| Commander | Deck | Quantity | Commanders | Issues |",
            "| --- | --- | ---: | ---: | --- |",
        ]
    )
    blocked_any = False
    for row in payload["commanders"]:
        for deck in row["blocked_product_decks"]:
            blocked_any = True
            lines.append(
                "| `{commander}` | `{deck}` (`{deck_id}`) | {quantity} | {commander_count} | `{issues}` |".format(
                    commander=row["commander"].replace("|", "/"),
                    deck=str(deck["deck_name"]).replace("|", "/"),
                    deck_id=deck["deck_id"],
                    quantity=deck["quantity"],
                    commander_count=deck["commander_count"],
                    issues=", ".join(deck["issues"]),
                )
            )
    if not blocked_any:
        lines.append("| none | none | 0 | 0 | none |")

    lines.extend(
        [
            "",
            "## Method Notes",
            "",
            "- PostgreSQL product decks and registered variants remain product truth.",
            "- Hermes rows are included only as lab/cache candidates.",
            "- This matrix does not run battles, generate cards, or promote any deck.",
            "- A commander can move to battle only after a commander-specific strategy matrix and equal-gate evidence.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--skip-postgres", action="store_true")
    parser.add_argument("--skip-hermes", action="store_true")
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_strategy_matrix_20260701",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    deck_rows = collect_deck_matrix_rows(
        sqlite_db=args.sqlite_db,
        skip_postgres=args.skip_postgres,
        skip_hermes=args.skip_hermes,
    )
    commander_keys = {row["commander_key"] for row in deck_rows if row["commander_key"]}
    source_signals = fetch_source_signals(commander_keys)
    payload = build_matrix(deck_rows, source_signals)
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
