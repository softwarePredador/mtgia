#!/usr/bin/env python3
"""Build review-only cut candidates for global Commander land repairs.

This script sits after the named land candidate pool. It does not pick a final
swap or mutate a deck. It answers the next narrower question: if a deck needs
more lands, which current nonland cards are reviewable cut candidates because
their roles are already above range and they do not carry a missing core role?
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_core_role_audit as core_roles
import global_commander_named_land_candidate_pool as land_pool
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_NAMED_LAND_POOL_REPORT = (
    REPORT_DIR / "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only.json"
)
DEFAULT_CORE_ROLE_REPORT = REPORT_DIR / "global_commander_core_role_audit_20260705_global_goal_hermes_only.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only"

BLOCKED_MISSING_ROLE_REASON = "carries_missing_core_role"
REVIEW_STATUS = "review_only_cut_candidate"


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def normalize_name(value: object) -> str:
    return land_pool.mana_profile.normalize_name(value)


def core_deck_by_id(core_payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {str(row.get("deck_id")): row for row in core_payload.get("decks", [])}


def staple_rank_by_name(conn: sqlite3.Connection) -> dict[str, int]:
    if not land_pool.mana_profile.table_exists(conn, "format_staples"):
        return {}
    rows = conn.execute(
        """
        SELECT card_name, MIN(COALESCE(edhrec_rank, 999999)) AS best_rank
        FROM format_staples
        WHERE lower(format) = 'commander'
        GROUP BY card_name
        """
    ).fetchall()
    return {normalize_name(row[0]): as_int(row[1]) for row in rows}


def deck_rows(conn: sqlite3.Connection, deck_id: str) -> list[dict[str, Any]]:
    rows = land_pool.mana_profile.fetch_deck_cards(conn, deck_id)
    oracle_by_name = land_pool.mana_profile.fetch_oracle_rows(
        conn,
        {str(row.get("card_name") or "") for row in rows},
    )
    return [land_pool.mana_profile.enriched_row(row, oracle_by_name) for row in rows]


def excess_roles(core_row: dict[str, Any]) -> dict[str, dict[str, Any]]:
    plan = core_row.get("core_repair_plan") or {}
    return {
        str(row.get("role")): row
        for row in plan.get("excess_role_slots", [])
        if row.get("role")
    }


def missing_roles(core_row: dict[str, Any]) -> set[str]:
    plan = core_row.get("core_repair_plan") or {}
    return {
        str(row.get("role"))
        for row in plan.get("missing_role_slots", [])
        if row.get("role")
    }


def role_weight(role: str, excess: dict[str, dict[str, Any]]) -> int:
    row = excess.get(role) or {}
    base = as_int(row.get("excess"))
    severity_bonus = 6 if row.get("severity") == "critical" else 2
    return base + severity_bonus


def cut_candidate_score(
    *,
    row: dict[str, Any],
    roles: set[str],
    source: str,
    matching_excess: set[str],
    excess: dict[str, dict[str, Any]],
    staple_rank: int | None,
) -> tuple[int, list[str]]:
    reasons: list[str] = []
    score = sum(role_weight(role, excess) for role in matching_excess)
    if matching_excess:
        reasons.append("matches_excess_roles:" + ",".join(sorted(matching_excess)))
    if roles and roles <= matching_excess:
        score += 14
        reasons.append("only_carries_excess_roles")
    else:
        score -= 6 * len(roles - matching_excess)
        if roles - matching_excess:
            reasons.append("also_carries_non_excess_roles:" + ",".join(sorted(roles - matching_excess)))
    cmc = float(row.get("cmc") or 0)
    if cmc >= 5:
        score += 5
        reasons.append("high_cmc_spell_slot")
    quantity = as_int(row.get("quantity") or 1)
    oracle_text = str(row.get("oracle_text") or "").lower()
    if quantity > 1:
        score -= min(30, quantity * 3)
        reasons.append(f"multi_copy_package_quantity_{quantity}")
    if "a deck can have any number" in oracle_text or "can have any number of cards named" in oracle_text:
        score -= 40
        reasons.append("printed_deck_construction_exception_requires_source_lane")
    if any(pattern in oracle_text for pattern in ("top card", "top two cards", "top three cards", "scry", "surveil")):
        score -= 12
        reasons.append("potential_topdeck_engine_anchor_requires_commander_source_lane")
    if source == "text_inferred":
        score -= 4
        reasons.append("role_text_inferred_review")
    if staple_rank is not None and staple_rank <= 100:
        score -= 20
        reasons.append(f"top_commander_staple_rank_{staple_rank}")
    elif staple_rank is not None and staple_rank <= 500:
        score -= 8
        reasons.append(f"commander_staple_rank_{staple_rank}")
    return score, reasons


def build_cut_candidates_for_pool(
    *,
    conn: sqlite3.Connection,
    pool: dict[str, Any],
    core_row: dict[str, Any],
    staple_ranks: dict[str, int],
    limit: int,
) -> dict[str, Any]:
    deck_id = str(pool.get("deck_id"))
    excess = excess_roles(core_row)
    missing = missing_roles(core_row)
    cut_candidates: list[dict[str, Any]] = []
    blocked_examples: list[dict[str, Any]] = []
    for row in deck_rows(conn, deck_id):
        if as_int(row.get("is_commander")):
            continue
        roles, source = core_roles.card_roles(row)
        if "land" in roles:
            continue
        missing_overlap = roles & missing
        matching_excess = roles & set(excess)
        if missing_overlap:
            if len(blocked_examples) < limit and matching_excess:
                blocked_examples.append(
                    {
                        "card_name": row.get("card_name"),
                        "roles": sorted(roles),
                        "blocked_roles": sorted(missing_overlap),
                        "reason": BLOCKED_MISSING_ROLE_REASON,
                    }
                )
            continue
        if not matching_excess:
            continue
        staple_rank = staple_ranks.get(normalize_name(row.get("card_name")))
        score, reasons = cut_candidate_score(
            row=row,
            roles=roles,
            source=source,
            matching_excess=matching_excess,
            excess=excess,
            staple_rank=staple_rank,
        )
        cut_candidates.append(
            {
                "card_name": row.get("card_name"),
                "score": score,
                "status": REVIEW_STATUS,
                "roles": sorted(roles),
                "matching_excess_roles": sorted(matching_excess),
                "classification_source": source,
                "cmc": row.get("cmc"),
                "staple_rank": staple_rank,
                "cut_reasons": reasons,
                "mutation_allowed": False,
            }
        )
    cut_candidates.sort(key=lambda item: (-as_int(item["score"]), str(item["card_name"])))
    top_land_candidates = list(pool.get("top_candidates") or [])[:3]
    top_cut_candidates = cut_candidates[:limit]
    pair_hypotheses = [
        {
            "add": land["card_name"],
            "cut": cut["card_name"],
            "status": "review_only_land_add_cut_pair",
            "pair_score": as_int(land.get("score")) + as_int(cut.get("score")),
            "required_gates": [
                "candidate_copy_only",
                "structure_and_legality_recheck",
                "mana_base_profile_recheck",
                "strategy_matrix_before_battle",
                "battle_gate_with_drawn_cast_used_trace_before_promotion",
            ],
            "mutation_allowed": False,
        }
        for land in top_land_candidates
        for cut in top_cut_candidates[:3]
    ]
    return {
        "deck_id": deck_id,
        "deck_name": pool.get("deck_name"),
        "commander": pool.get("commander"),
        "excess_roles": list(excess.values()),
        "missing_roles": sorted(missing),
        "land_candidate_count": pool.get("candidate_count"),
        "top_land_candidates": top_land_candidates,
        "cut_candidate_count": len(cut_candidates),
        "top_cut_candidates": top_cut_candidates,
        "blocked_cut_examples": blocked_examples,
        "pair_hypotheses": sorted(
            pair_hypotheses,
            key=lambda item: (-as_int(item["pair_score"]), str(item["add"]), str(item["cut"])),
        )[:limit],
        "status": "review_cut_pool_ready" if cut_candidates else "needs_commander_specific_cut_source_lane",
        "mutation_allowed": False,
    }


def build_report(
    *,
    named_land_pool_payload: dict[str, Any],
    core_role_payload: dict[str, Any],
    sqlite_db: Path,
    named_land_pool_report_path: Path = DEFAULT_NAMED_LAND_POOL_REPORT,
    core_role_report_path: Path = DEFAULT_CORE_ROLE_REPORT,
    limit: int = 12,
) -> dict[str, Any]:
    core_by_id = core_deck_by_id(core_role_payload)
    pools = list(named_land_pool_payload.get("candidate_pools", []))
    with sqlite3.connect(sqlite_db) as conn:
        staple_ranks = staple_rank_by_name(conn)
        deck_cut_pools = [
            build_cut_candidates_for_pool(
                conn=conn,
                pool=pool,
                core_row=core_by_id.get(str(pool.get("deck_id")), {}),
                staple_ranks=staple_ranks,
                limit=limit,
            )
            for pool in pools
            if str(pool.get("deck_id")) in core_by_id
        ]
    status_counts = Counter(row["status"] for row in deck_cut_pools)
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_land_cut_candidate_model",
        "source_named_land_pool_report": rel(named_land_pool_report_path),
        "source_core_role_report": rel(core_role_report_path),
        "source_db": rel(sqlite_db),
        "mutation_allowed": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "summary": {
            "deck_cut_pool_count": len(deck_cut_pools),
            "status_counts": dict(sorted(status_counts.items())),
            "total_cut_candidate_count": sum(as_int(row.get("cut_candidate_count")) for row in deck_cut_pools),
            "total_pair_hypothesis_count": sum(len(row.get("pair_hypotheses") or []) for row in deck_cut_pools),
            "top_next_action": "materialize_candidate_copy_for_top_review_pair_only_after_commander_source_lane",
        },
        "deck_cut_pools": deck_cut_pools,
        "policy": {
            "review_only": "Cut candidates and add/cut pairs are hypotheses only.",
            "floor_protection": "Cards carrying any currently missing core role are blocked from cut suggestions.",
            "land_gap_rule": "Land additions must cut nonland spell slots to actually repair land quantity.",
            "promotion_block": "No deck change is promoted without candidate copy, structure/legal recheck, strategy matrix, battle gate, and replay trace.",
        },
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Land Cut Candidate Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        "- mutation_allowed: `false`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- battle_or_optimization_performed: `false`",
        f"- deck_cut_pool_count: `{payload['summary']['deck_cut_pool_count']}`",
        f"- total_cut_candidate_count: `{payload['summary']['total_cut_candidate_count']}`",
        f"- total_pair_hypothesis_count: `{payload['summary']['total_pair_hypothesis_count']}`",
        f"- top_next_action: `{payload['summary']['top_next_action']}`",
        "",
        "## Deck Cut Pools",
        "",
    ]
    for pool in payload["deck_cut_pools"]:
        lines.extend(
            [
                f"### Deck {pool['deck_id']} - {pool['commander']}",
                "",
                f"- status: `{pool['status']}`",
                f"- cut_candidate_count: `{pool['cut_candidate_count']}`",
                f"- missing_roles: `{','.join(pool['missing_roles'])}`",
                "",
                "| Score | Cut Candidate | Roles | Reasons |",
                "| --- | --- | --- | --- |",
            ]
        )
        for row in pool["top_cut_candidates"]:
            lines.append(
                "| `{score}` | `{name}` | `{roles}` | {reasons} |".format(
                    score=row["score"],
                    name=row["card_name"],
                    roles=",".join(row["roles"]),
                    reasons=", ".join(row["cut_reasons"]),
                )
            )
        if not pool["top_cut_candidates"]:
            lines.append("|  | none |  |  |")
        lines.extend(["", "| Pair Score | Add | Cut | Status |", "| --- | --- | --- | --- |"])
        for row in pool["pair_hypotheses"][:6]:
            lines.append(f"| `{row['pair_score']}` | `{row['add']}` | `{row['cut']}` | `{row['status']}` |")
        if not pool["pair_hypotheses"]:
            lines.append("|  | none | none |  |")
        lines.append("")
    lines.extend(["## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def write_outputs(payload: dict[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(payload, md_path)
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--named-land-pool-report", type=Path, default=DEFAULT_NAMED_LAND_POOL_REPORT)
    parser.add_argument("--core-role-report", type=Path, default=DEFAULT_CORE_ROLE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--limit", type=int, default=12)
    args = parser.parse_args()

    named_land_pool_payload = load_json(args.named_land_pool_report)
    core_role_payload = load_json(args.core_role_report)
    payload = build_report(
        named_land_pool_payload=named_land_pool_payload,
        core_role_payload=core_role_payload,
        sqlite_db=args.db,
        named_land_pool_report_path=args.named_land_pool_report,
        core_role_report_path=args.core_role_report,
        limit=args.limit,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": "pass",
                "deck_cut_pool_count": payload["summary"]["deck_cut_pool_count"],
                "total_cut_candidate_count": payload["summary"]["total_cut_candidate_count"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
