#!/usr/bin/env python3
"""Rank the next safe global Commander deckbuilding learning actions."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT, rel
from global_commander_strategy_matrix import normalize_commander


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
COMMANDER_CONTRACT = REPO_ROOT / "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md"
DEFAULT_CORE_REPORT = REPORT_DIR / "global_commander_core_role_audit_20260705_global_goal_hermes_only.json"
DEFAULT_STRATEGY_REPORT = REPORT_DIR / "global_commander_strategy_matrix_20260705_global_core_pivot_hermes_only.json"
DEFAULT_LAND_CUT_REPORT = REPORT_DIR / "global_commander_land_cut_candidate_model_20260705_global_goal_hermes_only.json"
BRACKET_POLICY_FILE = REPO_ROOT / "server/lib/edh_bracket_policy.dart"

EXTERNAL_RESEARCH_SNAPSHOT = [
    {
        "source": "Wizards Commander format page",
        "url": "https://magic.wizards.com/en/formats/commander",
        "imported_principle": "current_official_bracket_model_has_five_brackets_and_game_changers",
        "guardrail": "bracket_and_game_changer_signals_set_power_intent_not_deck_quality",
    },
    {
        "source": "Official Commander rules",
        "url": "https://mtgcommander.net/index.php/rules/",
        "imported_principle": "exact_100_card_singleton_shape_with_card_text_exceptions",
        "guardrail": "legality_shape_is_required_before_strategy_or_battle",
    },
    {
        "source": "EDHREC Commander deckbuilding guide",
        "url": "https://edhrec.com/guides/how-to-build-a-commander-deck",
        "imported_principle": "commander_pages_top_cards_high_synergy_and_categories_are_reference_lanes",
        "guardrail": "public_popularity_is_evidence_not_automatic_truth",
    },
    {
        "source": "BinderBrew Commander template",
        "url": "https://binderbrew.com/commander-deck-building-template",
        "imported_principle": "lands_ramp_draw_interaction_wipes_are_flexible_starting_targets",
        "guardrail": "templates_are_starting_ranges_and_must_bend_to_commander_intent",
    },
    {
        "source": "Commander Spellbook",
        "url": "https://commanderspellbook.com/",
        "imported_principle": "combo_database_can_find_deterministic_finishers_and_variants",
        "guardrail": "combo_presence_does_not_prove_full_deck_balance_or_runtime_readiness",
    },
]

STAGE_RANK = {
    "structure_repair": 100,
    "role_data_backfill": 95,
    "core_floor_repair": 90,
    "role_extreme_review_then_source_lane": 75,
    "role_extreme_review": 70,
    "source_lane_build": 60,
    "commander_strategy_matrix_ready": 50,
    "benchmark_regression_review_only": 20,
    "no_action": 0,
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def load_optional_json(path: Path) -> dict[str, Any]:
    return load_json(path) if path.exists() else {}


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def bracket_policy_status_from_text(text: str) -> dict[str, Any]:
    clamps_to_legacy_four = "clamp(1, 4)" in text
    supports_five = "case 5" in text or "clamp(1, 5)" in text
    has_game_changers = "gameChanger" in text and "officialGameChangerNamesForBracketPolicy" in text
    status = "aligned_with_current_official_bracket_model"
    if not supports_five or not has_game_changers:
        status = "needs_refresh_for_current_official_brackets"
    return {
        "path": rel(BRACKET_POLICY_FILE),
        "status": status,
        "current_official_bracket_model": "five_brackets_beta_plus_game_changers",
        "backend_supports_five_brackets": supports_five,
        "backend_has_game_changer_policy": has_game_changers,
        "backend_clamps_to_legacy_four_brackets": clamps_to_legacy_four,
        "next_gate": (
            "audit_and_upgrade_backend_bracket_policy_before_using_bracket_as_final_quality_gate"
            if status != "aligned_with_current_official_bracket_model"
            else "keep_bracket_policy_in_surface_audit"
        ),
    }


def bracket_policy_status(path: Path = BRACKET_POLICY_FILE) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8") if path.exists() else ""
    return bracket_policy_status_from_text(text)


def role_rows_by_status(core_row: dict[str, Any], status: str) -> list[dict[str, Any]]:
    return [row for row in core_row.get("role_bands", []) if row.get("status") == status]


def critical_gap_count(core_row: dict[str, Any]) -> int:
    return sum(
        1
        for row in role_rows_by_status(core_row, "below_floor")
        if row.get("severity") == "critical"
    )


def role_label(row: dict[str, Any]) -> str:
    return f"{row['role']}={row['count']} target {row['min']}-{row['max']}"


def stage_for_deck(core_row: dict[str, Any], commander_row: dict[str, Any] | None) -> str:
    deck_id = str(core_row.get("deck_id") or "")
    core_status = str(core_row.get("core_status") or "")
    shape_status = str(core_row.get("shape_status") or "")
    commander_status = str((commander_row or {}).get("status") or "")
    if shape_status != "structure_ready":
        return "structure_repair"
    if core_status == "role_data_incomplete":
        return "role_data_backfill"
    if core_status == "core_role_gap":
        return "core_floor_repair"
    if deck_id == "607":
        return "benchmark_regression_review_only"
    if core_status == "core_review_ready":
        if commander_status == "structure_ready_source_missing":
            return "role_extreme_review_then_source_lane"
        return "role_extreme_review"
    if commander_status == "structure_ready_source_missing":
        return "source_lane_build"
    if commander_status == "ready_for_strategy_matrix":
        return "commander_strategy_matrix_ready"
    return "no_action"


def next_action_for_stage(stage: str) -> str:
    return {
        "structure_repair": "repair_shape_legality_or_scope_before_deckbuilding_learning",
        "role_data_backfill": "backfill_functional_roles_or_verify_oracle_text_before_strategy_matrix",
        "core_floor_repair": "repair_core_role_floor_before_reference_or_strategy_matrix",
        "role_extreme_review_then_source_lane": "review_role_extremes_then_add_commander_profile_or_source_lane",
        "role_extreme_review": "write_commander_specific_role_targets_before_strategy_matrix",
        "source_lane_build": "add_reference_profile_public_corpus_or_learned_source_lane",
        "commander_strategy_matrix_ready": "run_commander_specific_strategy_matrix_before_battle_gate",
        "benchmark_regression_review_only": "keep_as_regression_benchmark_do_not_use_as_global_template",
    }.get(stage, "no_global_learning_action")


def land_cut_pools_by_deck(land_cut_payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        str(row.get("deck_id")): row
        for row in land_cut_payload.get("deck_cut_pools", [])
        if row.get("deck_id")
    }


def repair_gate_state(core_row: dict[str, Any], land_cut_pool: dict[str, Any] | None) -> str:
    missing = {row.get("role") for row in role_rows_by_status(core_row, "below_floor")}
    if "land" in missing:
        if land_cut_pool and land_cut_pool.get("status") == "review_cut_pool_ready":
            return "land_add_cut_pool_ready_review_only"
        return "needs_land_candidate_and_cut_model"
    if missing:
        return "needs_nonland_core_repair_hypothesis"
    if land_cut_pool and land_cut_pool.get("status") == "review_cut_pool_ready":
        return "land_cut_pool_available_for_review"
    return "not_applicable"


def next_action_for_deck(stage: str, core_row: dict[str, Any], land_cut_pool: dict[str, Any] | None) -> str:
    if (
        stage == "core_floor_repair"
        and repair_gate_state(core_row, land_cut_pool) == "land_add_cut_pool_ready_review_only"
    ):
        return "review_top_land_add_cut_pair_then_candidate_copy_after_commander_source_lane"
    return next_action_for_stage(stage)


def priority_score(core_row: dict[str, Any], stage: str) -> int:
    score = STAGE_RANK.get(stage, 0) + critical_gap_count(core_row) * 8
    if str(core_row.get("commander") or "") != "Lorehold, the Historian":
        score += 5
    else:
        score -= 10
    if str(core_row.get("deck_id")) == "607":
        score -= 20
    return score


def build_deck_priorities(
    core_payload: dict[str, Any],
    strategy_payload: dict[str, Any],
    land_cut_payload: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    commander_rows = {
        row["commander_key"]: row
        for row in strategy_payload.get("commanders", [])
        if row.get("commander_key")
    }
    cut_pools = land_cut_pools_by_deck(land_cut_payload or {})
    priorities = []
    for core_row in core_payload.get("decks", []):
        commander_key = normalize_commander(str(core_row.get("commander") or ""))
        commander_row = commander_rows.get(commander_key)
        stage = stage_for_deck(core_row, commander_row)
        land_cut_pool = cut_pools.get(str(core_row.get("deck_id") or ""))
        below = role_rows_by_status(core_row, "below_floor")
        above = role_rows_by_status(core_row, "above_range_review")
        priorities.append(
            {
                "deck_id": str(core_row.get("deck_id") or ""),
                "deck_name": core_row.get("deck_name"),
                "commander": core_row.get("commander"),
                "scope": core_row.get("scope"),
                "stage": stage,
                "priority_score": priority_score(core_row, stage),
                "core_status": core_row.get("core_status"),
                "commander_source_status": (commander_row or {}).get("status"),
                "source_lane_count": int((commander_row or {}).get("source_lane_count") or 0),
                "critical_gap_count": critical_gap_count(core_row),
                "below_floor_roles": [role_label(row) for row in below],
                "above_range_roles": [role_label(row) for row in above],
                "repair_gate_state": repair_gate_state(core_row, land_cut_pool),
                "land_cut_candidate_count": int((land_cut_pool or {}).get("cut_candidate_count") or 0),
                "land_pair_hypothesis_count": len((land_cut_pool or {}).get("pair_hypotheses") or []),
                "next_action": next_action_for_deck(stage, core_row, land_cut_pool),
            }
        )
    priorities.sort(
        key=lambda row: (
            -row["priority_score"],
            row["commander"] == "Lorehold, the Historian",
            row["deck_id"],
        )
    )
    return priorities


def build_commander_queue(deck_priorities: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_commander: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in deck_priorities:
        by_commander[str(row.get("commander") or "")].append(row)
    queue = []
    for commander, rows in by_commander.items():
        stage_counts = Counter(row["stage"] for row in rows)
        top = max(rows, key=lambda row: row["priority_score"])
        queue.append(
            {
                "commander": commander,
                "deck_count": len(rows),
                "top_stage": top["stage"],
                "top_priority_score": top["priority_score"],
                "stage_counts": dict(sorted(stage_counts.items())),
                "next_action": top["next_action"],
                "top_decks": [
                    {
                        "deck_id": row["deck_id"],
                        "stage": row["stage"],
                        "priority_score": row["priority_score"],
                        "below_floor_roles": row["below_floor_roles"],
                    }
                    for row in sorted(rows, key=lambda item: -item["priority_score"])[:5]
                ],
            }
        )
    queue.sort(
        key=lambda row: (
            -row["top_priority_score"],
            row["commander"] == "Lorehold, the Historian",
            row["commander"],
        )
    )
    return queue


def build_report(
    *,
    core_payload: dict[str, Any],
    strategy_payload: dict[str, Any],
    land_cut_payload: dict[str, Any] | None = None,
    bracket_status: dict[str, Any],
    core_report_path: Path,
    strategy_report_path: Path,
    land_cut_report_path: Path | None = None,
) -> dict[str, Any]:
    land_cut_payload = land_cut_payload or {}
    deck_priorities = build_deck_priorities(core_payload, strategy_payload, land_cut_payload)
    commander_queue = build_commander_queue(deck_priorities)
    stage_counts = Counter(row["stage"] for row in deck_priorities)
    repair_gate_counts = Counter(row["repair_gate_state"] for row in deck_priorities)
    input_artifacts = {
        "core_role_report": artifact_rel(core_report_path),
        "strategy_matrix_report": artifact_rel(strategy_report_path),
    }
    if land_cut_report_path is not None:
        input_artifacts["land_cut_candidate_model"] = artifact_rel(land_cut_report_path)
    return {
        "generated_at": utc_now(),
        "status": "pass",
        "artifact_type": "global_commander_learning_priority_audit",
        "contract": rel(COMMANDER_CONTRACT),
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "input_artifacts": input_artifacts,
        "method": {
            "postgres_is_product_truth": True,
            "hermes_is_lab_cache": True,
            "lorehold_607_role": "benchmark_regression_only_not_global_template",
            "external_research_snapshot_date": "2026-07-05",
            "priority_order": [
                "shape_and_legality",
                "role_data_and_core_floor",
                "land_candidate_pool_and_cut_model",
                "role_extreme_review",
                "commander_profile_and_source_lanes",
                "commander_specific_strategy_matrix",
                "battle_gate_with_drawn_cast_used_trace",
            ],
        },
        "external_research_snapshot": EXTERNAL_RESEARCH_SNAPSHOT,
        "backend_contract_gaps": {"bracket_policy": bracket_status},
        "summary": {
            "deck_count": len(deck_priorities),
            "commander_count": len(commander_queue),
            "stage_counts": dict(sorted(stage_counts.items())),
            "repair_gate_counts": dict(sorted(repair_gate_counts.items())),
            "top_next_action": commander_queue[0]["next_action"] if commander_queue else "none",
            "bracket_policy_status": bracket_status["status"],
        },
        "commander_queue": commander_queue,
        "deck_priorities": deck_priorities,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Learning Priority Audit",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Decks ranked: `{payload['summary']['deck_count']}`",
        f"- Commanders ranked: `{payload['summary']['commander_count']}`",
        f"- Battle or optimization performed: `{payload['battle_or_optimization_performed']}`",
        f"- Bracket policy status: `{payload['summary']['bracket_policy_status']}`",
        "",
        "## Stage Counts",
        "",
        "| Stage | Decks |",
        "| --- | ---: |",
    ]
    for stage, count in payload["summary"]["stage_counts"].items():
        lines.append(f"| `{stage}` | {count} |")

    lines.extend(["", "## Repair Gate Counts", "", "| Gate State | Decks |", "| --- | ---: |"])
    for state, count in payload["summary"]["repair_gate_counts"].items():
        lines.append(f"| `{state}` | {count} |")

    lines.extend(["", "## Commander Queue", "", "| Commander | Top Stage | Decks | Next Action |", "| --- | --- | ---: | --- |"])
    for row in payload["commander_queue"]:
        lines.append(
            f"| `{str(row['commander']).replace('|', '/')}` | `{row['top_stage']}` | {row['deck_count']} | `{row['next_action']}` |"
        )

    lines.extend(
        [
            "",
            "## Top Deck Priorities",
            "",
            "| Score | Deck | Commander | Stage | Repair Gate | Below Floor | Above Range | Next Action |",
            "| ---: | --- | --- | --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["deck_priorities"][:20]:
        deck = f"{row['deck_name']} ({row['deck_id']})".replace("|", "/")
        commander = str(row.get("commander") or "").replace("|", "/")
        below = ", ".join(f"`{item}`" for item in row["below_floor_roles"]) or "-"
        above = ", ".join(f"`{item}`" for item in row["above_range_roles"]) or "-"
        lines.append(
            f"| {row['priority_score']} | `{deck}` | `{commander}` | `{row['stage']}` | `{row['repair_gate_state']}` | {below} | {above} | `{row['next_action']}` |"
        )

    bracket_policy = payload["backend_contract_gaps"]["bracket_policy"]
    lines.extend(
        [
            "",
            "## Backend Contract Gaps",
            "",
            f"- Bracket policy: `{bracket_policy['status']}`.",
            f"- Next gate: `{bracket_policy['next_gate']}`.",
            "",
            "## Method Notes",
            "",
            "- This is a learning queue, not a deck mutation permit.",
            "- External sources calibrate priorities; PostgreSQL/backend remains product truth.",
            "- Deck 607 is ranked only as a regression benchmark and must not become the global objective function.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--core-report", type=Path, default=DEFAULT_CORE_REPORT)
    parser.add_argument("--strategy-report", type=Path, default=DEFAULT_STRATEGY_REPORT)
    parser.add_argument("--land-cut-report", type=Path, default=DEFAULT_LAND_CUT_REPORT)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_learning_priority_audit_20260705_current",
    )
    args = parser.parse_args()
    payload = build_report(
        core_payload=load_json(args.core_report),
        strategy_payload=load_json(args.strategy_report),
        land_cut_payload=load_optional_json(args.land_cut_report),
        bracket_status=bracket_policy_status(),
        core_report_path=args.core_report,
        strategy_report_path=args.strategy_report,
        land_cut_report_path=args.land_cut_report,
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
