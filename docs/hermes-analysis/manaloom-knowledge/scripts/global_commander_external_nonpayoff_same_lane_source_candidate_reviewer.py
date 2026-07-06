#!/usr/bin/env python3
"""Review external nonpayoff same-lane source candidates before miner rerun."""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SOURCE_CANDIDATE_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer_20260705_kaalia_value_safe_stage1_repair_scope1"
)
FALLBACK_SELECTED_DB = SCRIPT_DIR / "knowledge.db"
COMMANDER_IDENTITY = {"B", "R", "W"}

ROLE_EVIDENCE_TERMS = {
    "haste_protection_silence": (
        "haste",
        "hexproof",
        "indestructible",
        "protection",
        "vigilance",
        "lifelink",
        "double strike",
    ),
    "mana_acceleration": (
        "add {",
        "add one mana",
        "treasure",
        "search your library for a basic land",
        "put it onto the battlefield",
    ),
    "tutors_access": (
        "search your library",
        "reveal the top",
        "put any number",
        "put that card into your hand",
    ),
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(value: object) -> str:
    return " ".join(str(value or "").strip().lower().split())


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


def resolve_selected_db(source_payload: Mapping[str, Any]) -> Path:
    inputs = source_payload.get("input_artifacts") or {}
    candidate_db = resolve_repo_path(inputs.get("selected_db"), FALLBACK_SELECTED_DB)
    if candidate_db.exists():
        return candidate_db
    return FALLBACK_SELECTED_DB


def load_oracle_rows(selected_db: Path) -> dict[str, dict[str, Any]]:
    if not selected_db.exists():
        return {}
    con = sqlite3.connect(selected_db)
    con.row_factory = sqlite3.Row
    try:
        rows = con.execute(
            """
            select normalized_name, name, type_line, oracle_text, cmc,
                   color_identity_json, keywords_json, scryfall_id
            from card_oracle_cache
            """
        ).fetchall()
    finally:
        con.close()
    result: dict[str, dict[str, Any]] = {}
    for row in rows:
        result[normalize_name(row["normalized_name"])] = dict(row)
    return result


def as_list(value: object) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    if isinstance(value, str) and value.strip():
        try:
            parsed = json.loads(value)
        except Exception:
            return [value]
        if isinstance(parsed, list):
            return [str(item) for item in parsed]
    return []


def color_identity_legal(oracle_row: Mapping[str, Any] | None) -> bool:
    if not oracle_row:
        return False
    identity = set(as_list(oracle_row.get("color_identity_json")))
    return identity.issubset(COMMANDER_IDENTITY)


def role_evidence_terms(role: str, oracle_row: Mapping[str, Any] | None) -> list[str]:
    if not oracle_row:
        return []
    text = " ".join(
        [
            str(oracle_row.get("oracle_text") or ""),
            str(oracle_row.get("type_line") or ""),
            " ".join(as_list(oracle_row.get("keywords_json"))),
        ]
    ).lower()
    return [term for term in ROLE_EVIDENCE_TERMS.get(role, ()) if term in text]


def review_status(row: Mapping[str, Any], *, legal: bool, matched_terms: list[str]) -> tuple[str, str, bool]:
    source_status = str(row.get("status") or "")
    if source_status == "external_source_candidate_needs_local_identity_resolution":
        return (
            "external_source_candidate_local_review_needs_identity_resolution",
            "resolve_local_identity_before_miner_seed",
            False,
        )
    if source_status == "external_source_candidate_already_in_current_deck_needs_trace_policy":
        return (
            "external_source_candidate_local_review_current_deck_trace_required",
            "target_deck_trace_or_negative_review_before_cut_consideration",
            False,
        )
    if source_status == "external_source_candidate_already_selected_as_add_needs_pair_policy":
        return (
            "external_source_candidate_local_review_held_package_pair_required",
            "same_lane_value_safe_pair_before_candidate_copy",
            False,
        )
    if not legal:
        return (
            "external_source_candidate_local_review_blocks_commander_legality",
            "resolve_commander_legality_before_miner_seed",
            False,
        )
    if not matched_terms:
        return (
            "external_source_candidate_local_review_blocks_role_mismatch",
            "collect_stronger_role_evidence_before_miner_seed",
            False,
        )
    return (
        "external_source_candidate_local_review_ready_for_miner_seed",
        "rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates",
        True,
    )


def review_candidate(row: Mapping[str, Any], oracle_rows: Mapping[str, Mapping[str, Any]]) -> dict[str, Any]:
    role = str(row.get("target_cut_role") or "")
    card_name = str(row.get("card_name") or "")
    oracle_row = oracle_rows.get(normalize_name(card_name))
    legal = color_identity_legal(oracle_row)
    matched_terms = role_evidence_terms(role, oracle_row)
    status, next_evidence, miner_allowed = review_status(row, legal=legal, matched_terms=matched_terms)
    return {
        "target_cut_role": role,
        "card_name": card_name,
        "source_status": row.get("status"),
        "review_status": status,
        "next_evidence": next_evidence,
        "local_identity_found": bool(oracle_row),
        "commander_identity_legal": legal,
        "local_role_evidence_terms": matched_terms,
        "type_line": oracle_row.get("type_line") if oracle_row else row.get("type_line"),
        "cmc": oracle_row.get("cmc") if oracle_row else row.get("cmc"),
        "scryfall_id": oracle_row.get("scryfall_id") if oracle_row else row.get("scryfall_id"),
        "miner_source_seed_allowed": miner_allowed,
        "rerun_miner_allowed_for_card": miner_allowed,
        "card_level_cut_permission_now": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "value_safe_reclassification_allowed": False,
    }


def count_by(rows: list[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def build_report(*, source_candidate_report: Path) -> dict[str, Any]:
    source_payload = load_json(source_candidate_report)
    source_summary = source_payload.get("summary") or {}
    selected_db = resolve_selected_db(source_payload)
    oracle_rows = load_oracle_rows(selected_db)
    review_rows = [
        review_candidate(row, oracle_rows)
        for row in source_payload.get("source_candidate_rows") or []
        if isinstance(row, Mapping)
    ]
    seed_rows = [row for row in review_rows if row["miner_source_seed_allowed"]]
    blockers = [
        "reviewed_external_candidates_are_miner_seeds_not_cut_permission",
        "current_deck_candidates_still_need_trace_or_negative_review",
        "held_package_candidates_still_need_value_safe_pairs",
        "candidate_copy_closed_until_new_cut_pairs_exist",
    ]
    return {
        "generated_at": utc_now(),
        "status": "external_nonpayoff_same_lane_source_candidates_reviewed_miner_seed_ready_no_deck_action",
        "artifact_type": "global_commander_external_nonpayoff_same_lane_source_candidate_reviewer",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "battle_replay_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "card_level_cut_permission_now": False,
        "input_artifacts": {
            "source_candidate_report": rel(source_candidate_report),
            "selected_db": rel(selected_db),
        },
        "summary": {
            "deck_id": str(source_summary.get("deck_id") or ""),
            "commander": str(source_summary.get("commander") or ""),
            "reviewed_candidate_count": len(review_rows),
            "miner_source_seed_allowed_count": len(seed_rows),
            "card_level_cut_permission_count": sum(1 for row in review_rows if row["card_level_cut_permission_now"]),
            "candidate_copy_allowed_count": sum(1 for row in review_rows if row["candidate_copy_allowed"]),
            "current_deck_trace_required_count": sum(
                1 for row in review_rows if row["review_status"] == "external_source_candidate_local_review_current_deck_trace_required"
            ),
            "held_package_pair_required_count": sum(
                1 for row in review_rows if row["review_status"] == "external_source_candidate_local_review_held_package_pair_required"
            ),
            "identity_resolution_required_count": sum(
                1 for row in review_rows if row["review_status"] == "external_source_candidate_local_review_needs_identity_resolution"
            ),
            "role_mismatch_blocked_count": sum(
                1 for row in review_rows if row["review_status"] == "external_source_candidate_local_review_blocks_role_mismatch"
            ),
            "review_status_counts": count_by(review_rows, "review_status"),
            "miner_seed_count_by_role": count_by(seed_rows, "target_cut_role"),
            "next_gate": "rerun_same_lane_cut_source_miner_with_reviewed_external_nonpayoff_candidates",
        },
        "miner_source_seed_rows": seed_rows,
        "review_rows": review_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "miner_seed_boundary": "Reviewed external candidates may seed miner research only; they are not cut permission.",
            "target_deck_boundary": "Cards already in the current deck still require target trace or explicit negative review before cut consideration.",
            "held_package_boundary": "Cards already selected as adds remain held until value-safe same-lane cut pairs exist.",
            "battle_boundary": "No battle gate opens before candidate copy and relevant card-level usage evidence.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Same-Lane Source Candidate Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- reviewed_candidate_count: `{summary['reviewed_candidate_count']}`",
        f"- miner_source_seed_allowed_count: `{summary['miner_source_seed_allowed_count']}`",
        f"- current_deck_trace_required_count: `{summary['current_deck_trace_required_count']}`",
        f"- held_package_pair_required_count: `{summary['held_package_pair_required_count']}`",
        f"- identity_resolution_required_count: `{summary['identity_resolution_required_count']}`",
        f"- role_mismatch_blocked_count: `{summary['role_mismatch_blocked_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Miner Source Seeds",
        "",
        "| Role | Card | Evidence Terms | Status |",
        "| --- | --- | --- | --- |",
    ]
    for row in payload["miner_source_seed_rows"]:
        terms = ", ".join(row.get("local_role_evidence_terms") or [])
        lines.append(
            f"| `{row['target_cut_role']}` | `{row['card_name']}` | `{terms}` | `{row['review_status']}` |"
        )
    lines.extend(["", "## Review Rows", ""])
    lines.append("| Role | Card | Legal | Miner Seed | Review Status |")
    lines.append("| --- | --- | ---: | ---: | --- |")
    for row in payload["review_rows"]:
        lines.append(
            "| `{role}` | `{card}` | {legal} | {seed} | `{status}` |".format(
                role=row.get("target_cut_role"),
                card=row.get("card_name"),
                legal=str(row.get("commander_identity_legal")).lower(),
                seed=str(row.get("miner_source_seed_allowed")).lower(),
                status=row.get("review_status"),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
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
    parser.add_argument("--source-candidate-report", type=Path, default=DEFAULT_SOURCE_CANDIDATE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(source_candidate_report=args.source_candidate_report)
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
