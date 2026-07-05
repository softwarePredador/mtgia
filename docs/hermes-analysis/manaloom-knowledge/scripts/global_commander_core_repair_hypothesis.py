#!/usr/bin/env python3
"""Build read-only Commander core repair hypotheses from global role gaps.

This is a bridge between role-floor auditing and actual deck optimization. It
does not mutate decks, materialize candidates, or promote cards. It turns each
missing core role into a reviewable hypothesis with required gates.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
DEFAULT_CORE_ROLE_REPORT = (
    REPORT_DIR / "global_commander_core_role_audit_20260705_global_goal_hermes_only.json"
)

ROLE_TO_FORMAT_STAPLE_ARCHETYPES = {
    "ramp": ["ramp"],
    "draw": ["draw"],
    "removal": ["removal"],
    "board_wipe": ["removal"],
    "protection": [],
    "recursion": [],
    "wincon": [],
    "land": [],
}

ROLE_REPAIR_CLASSES = {
    "land": [
        "basic_or_color_source_floor",
        "untapped_fixing_land",
        "utility_land_only_after_color_floor",
    ],
    "ramp": ["two_mana_rock_or_dork", "commander_curve_ramp", "fixing_ramp"],
    "draw": ["repeatable_card_flow", "burst_draw", "selection_or_impulse_draw"],
    "removal": ["cheap_targeted_interaction", "flexible_permanent_answer"],
    "board_wipe": ["table_reset", "asymmetric_or_scalable_wipe"],
    "protection": ["commander_protection", "stack_or_combat_protection"],
    "recursion": ["graveyard_recovery", "engine_rebuy"],
    "wincon": ["commander_plan_finisher", "deterministic_combo_or_closer"],
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def normalize_name(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return row is not None


def deck_card_names(conn: sqlite3.Connection) -> dict[str, set[str]]:
    if not table_exists(conn, "deck_cards"):
        return {}
    rows = conn.execute("SELECT deck_id, card_name FROM deck_cards").fetchall()
    by_deck: dict[str, set[str]] = defaultdict(set)
    for row in rows:
        by_deck[str(row[0])].add(normalize_name(row[1]))
    return by_deck


def format_staple_candidates(
    conn: sqlite3.Connection,
    *,
    role: str,
    existing_cards: set[str],
    limit: int,
) -> list[dict[str, Any]]:
    archetypes = ROLE_TO_FORMAT_STAPLE_ARCHETYPES.get(role, [])
    if not archetypes or not table_exists(conn, "format_staples"):
        return []
    placeholders = ", ".join("?" for _ in archetypes)
    rows = conn.execute(
        f"""
        SELECT card_name, archetype, category, color_identity, edhrec_rank
        FROM format_staples
        WHERE lower(format) = 'commander'
          AND lower(archetype) IN ({placeholders})
          AND COALESCE(is_banned, 0) = 0
        ORDER BY COALESCE(edhrec_rank, 999999), card_name
        """,
        [item.lower() for item in archetypes],
    ).fetchall()
    result: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in rows:
        key = normalize_name(row[0])
        if not key or key in existing_cards or key in seen:
            continue
        seen.add(key)
        result.append(
            {
                "card_name": row[0],
                "source": "format_staples",
                "archetype": row[1] or "",
                "category": row[2] or "",
                "color_identity": row[3] or "",
                "edhrec_rank": row[4],
                "status": "review_only_requires_commander_color_identity_and_fit",
            }
        )
        if len(result) >= limit:
            break
    return result


def sorted_excess_slots(plan: dict[str, Any], missing_role: str) -> list[dict[str, Any]]:
    slots = [
        row
        for row in plan.get("excess_role_slots", [])
        if row.get("role") != missing_role
    ]
    return sorted(slots, key=lambda row: (-int(row.get("excess") or 0), str(row.get("role") or "")))


def required_gates_for_role(role: str) -> list[str]:
    gates = [
        "commander_color_identity_check",
        "card_legality_and_singleton_check",
        "same_lane_or_excess_role_cut_model",
        "strategy_matrix_before_battle",
        "battle_gate_with_drawn_cast_used_trace_before_promotion",
    ]
    if role == "land":
        gates.insert(0, "mana_source_and_untapped_land_profile")
    if role == "wincon":
        gates.insert(0, "commander_win_plan_or_spellbook_source_lane")
    return gates


def hypothesis_status(role: str, candidates: list[dict[str, Any]]) -> str:
    if role == "land":
        return "needs_mana_base_profile_before_named_cards"
    if role == "wincon":
        return "needs_commander_win_plan_source_lane"
    if candidates:
        return "review_candidate_pool_ready_color_identity_required"
    return "needs_source_lane_or_card_pool"


def build_hypothesis(
    *,
    deck_row: dict[str, Any],
    gap: dict[str, Any],
    candidates: list[dict[str, Any]],
) -> dict[str, Any]:
    role = str(gap["role"])
    plan = deck_row.get("core_repair_plan") or {}
    excess_slots = sorted_excess_slots(plan, role)
    return {
        "deck_id": str(deck_row.get("deck_id")),
        "deck_name": deck_row.get("deck_name"),
        "commander": deck_row.get("commander"),
        "scope": deck_row.get("scope"),
        "role": role,
        "missing": int(gap.get("missing") or 0),
        "current_count": int(gap.get("count") or 0),
        "target_min": int(gap.get("target_min") or 0),
        "severity": gap.get("severity"),
        "status": hypothesis_status(role, candidates),
        "repair_classes": ROLE_REPAIR_CLASSES.get(role, ["commander_specific_role_repair"]),
        "review_candidates": candidates,
        "cut_pressure": excess_slots[:5],
        "cut_policy": (
            "review excess roles first; never cut below another core floor; "
            "commander anchors and protected staples require explicit source proof"
        ),
        "required_gates": required_gates_for_role(role),
        "mutation_allowed": False,
    }


def build_report(
    *,
    core_payload: dict[str, Any],
    sqlite_db: Path,
    staple_limit: int,
) -> dict[str, Any]:
    with sqlite3.connect(sqlite_db) as conn:
        existing_by_deck = deck_card_names(conn)
        hypotheses: list[dict[str, Any]] = []
        for deck_row in core_payload.get("decks", []):
            plan = deck_row.get("core_repair_plan") or {}
            for gap in plan.get("missing_role_slots", []):
                if gap.get("severity") != "critical":
                    continue
                role = str(gap.get("role") or "")
                candidates = format_staple_candidates(
                    conn,
                    role=role,
                    existing_cards=existing_by_deck.get(str(deck_row.get("deck_id")), set()),
                    limit=staple_limit,
                )
                hypotheses.append(
                    build_hypothesis(
                        deck_row=deck_row,
                        gap=gap,
                        candidates=candidates,
                    )
                )

    by_role = Counter(row["role"] for row in hypotheses)
    by_status = Counter(row["status"] for row in hypotheses)
    commanders = Counter(row["commander"] for row in hypotheses if row.get("commander"))
    hypotheses.sort(
        key=lambda row: (
            -int(row["missing"]),
            str(row["commander"] or ""),
            str(row["deck_id"]),
            str(row["role"]),
        )
    )
    return {
        "generated_at": utc_now(),
        "status": "pass",
        "artifact_type": "global_commander_core_repair_hypothesis",
        "contract": rel(COMMANDER_CONTRACT),
        "source_core_role_report": core_payload.get("artifact_type", "global_commander_core_role_audit"),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "method": {
            "sqlite_db": str(sqlite_db),
            "format_staples_are_review_only": True,
            "requires_color_identity_before_named_card_use": True,
            "lorehold_607_role": "benchmark_regression_only_not_global_template",
        },
        "summary": {
            "deck_count": len({row["deck_id"] for row in hypotheses}),
            "commander_count": len(commanders),
            "hypothesis_count": len(hypotheses),
            "role_counts": dict(sorted(by_role.items())),
            "status_counts": dict(sorted(by_status.items())),
            "top_next_action": (
                "build_commander_specific_source_lane_for_wincon_or_apply_safe_core_floor_repair_review"
                if hypotheses
                else "no_critical_core_floor_repair_hypotheses"
            ),
        },
        "hypotheses": hypotheses,
    }


def format_candidates(candidates: list[dict[str, Any]]) -> str:
    if not candidates:
        return "-"
    return ", ".join(
        f"{row['card_name']}({row['color_identity'] or 'colorless'})"
        for row in candidates[:5]
    )


def format_cut_pressure(slots: list[dict[str, Any]]) -> str:
    if not slots:
        return "-"
    return ", ".join(f"{row['role']}={row['excess']}" for row in slots[:5])


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Core Repair Hypotheses",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Hypotheses: `{payload['summary']['hypothesis_count']}`",
        f"- Mutation allowed: `{str(payload['mutation_allowed']).lower()}`",
        f"- Battle or optimization performed: `{payload['battle_or_optimization_performed']}`",
        "",
        "## Status Counts",
        "",
        "| Status | Count |",
        "| --- | ---: |",
    ]
    for status, count in payload["summary"]["status_counts"].items():
        lines.append(f"| `{status}` | {count} |")
    lines.extend(
        [
            "",
            "## Hypothesis Queue",
            "",
            "| Deck | Commander | Role | Missing | Status | Repair Classes | Review Candidates | Cut Pressure |",
            "| --- | --- | --- | ---: | --- | --- | --- | --- |",
        ]
    )
    for row in payload["hypotheses"]:
        lines.append(
            "| `{deck}` | `{commander}` | `{role}` | {missing} | `{status}` | {classes} | {candidates} | {cuts} |".format(
                deck=f"{row['deck_name']} ({row['deck_id']})".replace("|", "/"),
                commander=str(row.get("commander") or "").replace("|", "/"),
                role=row["role"],
                missing=row["missing"],
                status=row["status"],
                classes=", ".join(f"`{item}`" for item in row["repair_classes"]),
                candidates=format_candidates(row["review_candidates"]),
                cuts=format_cut_pressure(row["cut_pressure"]),
            )
        )
    lines.extend(
        [
            "",
            "## Method Notes",
            "",
            "- This report is read-only and never materializes deck changes.",
            "- Format staples are review candidates only; color identity, legality, commander fit, same-lane cut, strategy matrix, and battle gates remain required.",
            "- Land gaps require a mana-base profile before named cards.",
            "- Wincon gaps require commander win-plan/source-lane proof before named cards.",
            "- Deck 607 remains a regression benchmark, not the global objective.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--core-role-report", type=Path, default=DEFAULT_CORE_ROLE_REPORT)
    parser.add_argument("--sqlite-db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--staple-limit", type=int, default=5)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_core_repair_hypothesis_20260705_current",
    )
    args = parser.parse_args()
    payload = build_report(
        core_payload=load_json(args.core_role_report),
        sqlite_db=args.sqlite_db,
        staple_limit=max(0, args.staple_limit),
    )
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
