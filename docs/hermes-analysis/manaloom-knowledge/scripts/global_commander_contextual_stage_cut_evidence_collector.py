#!/usr/bin/env python3
"""Collect evidence for contextual stage-only Commander cuts.

This read-only gate consumes a stage-only cut evidence plan and the current
candidate SQLite DB. It inspects only contextual staple rows and records whether
there is enough usage, same-lane, or replay evidence to consider a later
value-safe reclassification. It does not reclassify cuts, materialize decks, run
battles, mutate SQLite/PostgreSQL, or promote any package.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_STAGE_ONLY_PLAN_REPORT = (
    REPORT_DIR / "global_commander_stage_only_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_contextual_stage_cut_evidence_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
)
CONTEXTUAL_LANE = "contextual_staple_same_lane_usage_review"
PROOF_KEYS = (
    "usage_evidence",
    "same_lane_replacement_proof",
    "negative_replay_trace",
    "neutral_replay_trace",
)


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


def resolve_repo_path(value: object, fallback: Path) -> Path:
    text = str(value or "").strip()
    if not text:
        return fallback
    path = Path(text)
    return path if path.is_absolute() else REPO_ROOT / path


def contextual_plan_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in payload.get("evidence_plan_rows") or []:
        if not isinstance(row, Mapping) or not row.get("card_name"):
            continue
        lanes = {str(lane) for lane in row.get("evidence_lanes") or []}
        if CONTEXTUAL_LANE in lanes:
            rows.append(dict(row))
    return rows


def resolve_source_db(
    *,
    stage_payload: Mapping[str, Any],
    stage_only_plan_report: Path,
    sqlite_db: Path | None,
) -> tuple[Path, dict[str, Any]]:
    if sqlite_db is not None:
        return sqlite_db, {
            "selected_db": rel(sqlite_db),
            "source": "cli_override",
            "fallback_used": False,
            "selected_db_exists": sqlite_db.exists(),
        }
    inputs = stage_payload.get("input_artifacts") or {}
    cut_report = resolve_repo_path(inputs.get("cut_source_lane_report"), stage_only_plan_report)
    cut_payload = load_json(cut_report) if cut_report.exists() else {}
    cut_inputs = cut_payload.get("input_artifacts") or {}
    db_resolution = cut_payload.get("db_resolution") or {}
    candidate_db = resolve_repo_path(
        db_resolution.get("selected_db") or cut_inputs.get("selected_db"),
        DEFAULT_SQLITE_DB,
    )
    return candidate_db, {
        "selected_db": rel(candidate_db),
        "source": "cut_source_lane_selected_db",
        "fallback_used": not bool(db_resolution.get("selected_db") or cut_inputs.get("selected_db")),
        "selected_db_exists": candidate_db.exists(),
        "cut_source_lane_report": rel(cut_report),
    }


def table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
        (table_name,),
    ).fetchone()
    return bool(row)


def deck_rows_by_name(conn: sqlite3.Connection, deck_id: str, names: list[str]) -> dict[str, dict[str, Any]]:
    if not table_exists(conn, "deck_cards"):
        return {}
    wanted = {normalize_name(name) for name in names}
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT card_name, COALESCE(quantity, 1) AS quantity,
               functional_tag, functional_tags_json, type_line, oracle_text,
               cmc, COALESCE(is_commander, 0) AS is_commander
        FROM deck_cards
        WHERE CAST(deck_id AS TEXT)=?
        ORDER BY card_name
        """,
        (str(deck_id),),
    ).fetchall()
    result: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(str(row["card_name"] or ""))
        if key in wanted:
            result[key] = dict(row)
    return result


def format_staples_by_name(conn: sqlite3.Connection, names: list[str]) -> dict[str, dict[str, Any]]:
    if not table_exists(conn, "format_staples"):
        return {}
    wanted = {normalize_name(name) for name in names}
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT card_name, format, archetype, category, edhrec_rank, is_banned
        FROM format_staples
        WHERE COALESCE(is_banned, 0)=0
        ORDER BY COALESCE(edhrec_rank, 999999), card_name
        """
    ).fetchall()
    result: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(str(row["card_name"] or ""))
        if key not in wanted:
            continue
        rank = int(row["edhrec_rank"] or 999999)
        current = result.get(key)
        if current is None or rank < int(current.get("edhrec_rank") or 999999):
            result[key] = {
                "card_name": row["card_name"],
                "format": row["format"],
                "archetype": row["archetype"],
                "category": row["category"],
                "edhrec_rank": rank,
            }
    return result


def collect_db_context(
    *,
    db_path: Path,
    deck_id: str,
    names: list[str],
) -> tuple[dict[str, dict[str, Any]], dict[str, dict[str, Any]], dict[str, Any]]:
    if not db_path.exists():
        return {}, {}, {
            "selected_db": rel(db_path),
            "available": False,
            "reason": "selected_db_missing",
        }
    with sqlite3.connect(db_path) as conn:
        cards = deck_rows_by_name(conn, deck_id, names)
        staples = format_staples_by_name(conn, names)
    return cards, staples, {
        "selected_db": rel(db_path),
        "available": True,
        "deck_row_count": len(cards),
        "format_staple_row_count": len(staples),
    }


def supporting_proofs(row: Mapping[str, Any]) -> list[str]:
    proofs = []
    for key in PROOF_KEYS:
        value = row.get(key)
        if value:
            proofs.append(key)
    return proofs


def oracle_excerpt(row: Mapping[str, Any] | None) -> str:
    if not row:
        return ""
    text = " ".join(str(row.get("oracle_text") or "").split())
    return text[:260]


def classify_contextual_row(
    *,
    plan_row: Mapping[str, Any],
    deck_row: Mapping[str, Any] | None,
    staple: Mapping[str, Any] | None,
) -> dict[str, Any]:
    proofs = supporting_proofs(plan_row)
    missing: list[str] = []
    if deck_row is None:
        missing.append("current_deck_row")
    if not proofs:
        missing.append("usage_or_same_lane_or_replay_proof")
    if staple:
        missing.append("format_staple_replacement_risk_review")
    status = (
        "contextual_stage_cut_has_supporting_proof_needs_manual_value_safe_review"
        if deck_row is not None and proofs
        else "contextual_stage_cut_needs_usage_or_trace_evidence"
    )
    return {
        "card_name": plan_row.get("card_name"),
        "status": status,
        "reclassification_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "matching_over_target_roles": plan_row.get("matching_over_target_roles") or [],
        "profile_roles": plan_row.get("profile_roles") or [],
        "stage_reasons": plan_row.get("stage_reasons") or [],
        "evidence_lanes": plan_row.get("evidence_lanes") or [],
        "score": plan_row.get("score") or 0,
        "current_deck_context": {
            "present": deck_row is not None,
            "quantity": deck_row.get("quantity") if deck_row else None,
            "cmc": deck_row.get("cmc") if deck_row else None,
            "type_line": deck_row.get("type_line") if deck_row else "",
            "functional_tag": deck_row.get("functional_tag") if deck_row else None,
            "functional_tags_json": deck_row.get("functional_tags_json") if deck_row else "[]",
            "oracle_excerpt": oracle_excerpt(deck_row),
        },
        "format_staple_context": dict(staple or {}),
        "supporting_proofs_present": proofs,
        "missing_evidence": missing,
        "next_required_evidence": [
            "drawn_cast_used_or_negative_usage_trace",
            "same_lane_replacement_proof_preserves_profile_floor",
            "candidate_strategy_matrix_recheck_before_battle",
        ],
    }


def build_report(
    *,
    stage_only_plan_report: Path,
    sqlite_db: Path | None = None,
) -> dict[str, Any]:
    stage_payload = load_json(stage_only_plan_report)
    summary = stage_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    contextual_rows = contextual_plan_rows(stage_payload)
    db_path, db_resolution = resolve_source_db(
        stage_payload=stage_payload,
        stage_only_plan_report=stage_only_plan_report,
        sqlite_db=sqlite_db,
    )
    names = [str(row.get("card_name") or "") for row in contextual_rows]
    deck_context, staple_context, db_context = collect_db_context(db_path=db_path, deck_id=deck_id, names=names)
    evidence_rows = []
    for row in contextual_rows:
        key = normalize_name(str(row.get("card_name") or ""))
        evidence_rows.append(
            classify_contextual_row(
                plan_row=row,
                deck_row=deck_context.get(key),
                staple=staple_context.get(key),
            )
        )
    ready_count = sum(
        1
        for row in evidence_rows
        if row["status"] == "contextual_stage_cut_has_supporting_proof_needs_manual_value_safe_review"
    )
    if not contextual_rows:
        status = "contextual_stage_cut_evidence_blocks_no_contextual_rows"
        next_gate = "find_new_stage_only_cut_evidence_lane"
    elif ready_count:
        status = "contextual_stage_cut_evidence_collected_manual_review_required"
        next_gate = "manual_value_safe_reclassification_review_before_candidate_copy"
    else:
        status = "contextual_stage_cut_evidence_collected_no_value_safe_reclassification"
        next_gate = "collect_usage_or_trace_evidence_for_contextual_stage_cuts"
    blockers = []
    if contextual_rows and not ready_count:
        blockers.append("contextual_stage_cuts_missing_usage_same_lane_or_replay_proof")
    if not contextual_rows:
        blockers.append("no_contextual_stage_only_cut_rows_to_collect")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_contextual_stage_cut_evidence_collector",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "stage_only_plan_report": rel(stage_only_plan_report),
            "selected_db": rel(db_path),
        },
        "db_resolution": db_resolution,
        "db_context": db_context,
        "summary": {
            "deck_id": deck_id,
            "commander": str(summary.get("commander") or ""),
            "stage_only_plan_status": stage_payload.get("status"),
            "required_cut_count": summary.get("required_cut_count"),
            "contextual_row_count": len(contextual_rows),
            "reclassification_ready_count": ready_count,
            "missing_usage_or_trace_count": len(evidence_rows) - ready_count,
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "contextual_evidence_rows": evidence_rows,
        "policy": {
            "collector_boundary": "This collector records evidence state; it does not reclassify any cut.",
            "contextual_staple_boundary": "A contextual staple needs usage, same-lane replacement, or replay evidence before value-safe review.",
            "battle_boundary": "Battle remains closed until candidate-copy, strategy-matrix, and replay gates pass.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Contextual Stage Cut Evidence Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- stage_only_plan_status: `{summary['stage_only_plan_status']}`",
        f"- contextual_row_count: `{summary['contextual_row_count']}`",
        f"- reclassification_ready_count: `{summary['reclassification_ready_count']}`",
        f"- missing_usage_or_trace_count: `{summary['missing_usage_or_trace_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Contextual Evidence Rows",
        "",
        "| Cut | Roles | Staple Rank | Status | Missing Evidence |",
        "| --- | --- | ---: | --- | --- |",
    ]
    for row in payload["contextual_evidence_rows"]:
        staple = row.get("format_staple_context") or {}
        rank = staple.get("edhrec_rank") or ""
        lines.append(
            "| `{card}` | `{roles}` | {rank} | `{status}` | `{missing}` |".format(
                card=row.get("card_name"),
                roles=", ".join(row.get("matching_over_target_roles") or []),
                rank=rank,
                status=row.get("status"),
                missing=", ".join(row.get("missing_evidence") or []),
            )
        )
    if not payload["contextual_evidence_rows"]:
        lines.append("| none | `-` |  | `-` | `-` |")
    lines.extend(["", "## Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
    lines.extend(["", "## Current Card Context", ""])
    for row in payload["contextual_evidence_rows"]:
        context = row.get("current_deck_context") or {}
        lines.append(
            "- `{card}`: `{type_line}`, cmc `{cmc}`, oracle `{oracle}`".format(
                card=row.get("card_name"),
                type_line=context.get("type_line") or "",
                cmc=context.get("cmc"),
                oracle=context.get("oracle_excerpt") or "",
            )
        )
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
    parser.add_argument("--stage-only-plan-report", type=Path, default=DEFAULT_STAGE_ONLY_PLAN_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(stage_only_plan_report=args.stage_only_plan_report, sqlite_db=args.db)
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
