#!/usr/bin/env python3
"""Review expanded external nonpayoff source candidates before seeded mining.

This read-only gate follows
``global_commander_external_nonpayoff_source_candidate_pool_expander``. It
rechecks expanded source candidates against the current evaluation DB and turns
only locally valid, outside-deck, non-recycled, commander-legal role matches
into miner seeds. It does not create cut permission, copy a deck, mutate any
DB, run battles, reclassify value-safe cuts, or promote a package.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_external_nonpayoff_source_candidate_pool_expander as expander
from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_EXPANDER_REPORT = expander.DEFAULT_OUT_PREFIX.with_suffix(".json")
DEFAULT_SELECTED_DB = expander.DEFAULT_SELECTED_DB
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_expanded_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1_new_sources"
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


def resolve_selected_db(expander_payload: Mapping[str, Any], selected_db: Path | None = None) -> Path:
    if selected_db is not None:
        return selected_db
    inputs = expander_payload.get("input_artifacts") or {}
    path_text = str(inputs.get("selected_db") or "").strip()
    if path_text:
        candidate = Path(path_text)
        candidate = candidate if candidate.is_absolute() else REPO_ROOT / candidate
        if candidate.exists():
            return candidate
    return expander.resolve_selected_db(DEFAULT_SELECTED_DB)


def legality_status(indexes: Mapping[str, Any], keys: set[str]) -> str:
    for key in keys:
        status = indexes.get("legalities", {}).get(key)
        if status:
            return str(status)
    return "unknown"


def seed_cautions(scope: str) -> list[str]:
    cautions = {
        "equipment_haste_protection_seed": [
            "equipment_seed_requires_package_target_mapping_before_add_approval",
            "does_not_make_existing_attack_window_card_cuttable",
        ],
        "protection_spell_or_haste_seed": [
            "protection_seed_requires_target_role_cut_source_evidence_later",
            "does_not_make_current_protection_card_cuttable",
        ],
        "repeatable_creature_protection_seed": [
            "creature_protection_seed_requires_removal_pressure_context",
            "does_not_make_current_protection_card_cuttable",
        ],
        "enchantment_resilience_or_haste_seed": [
            "enchantment_seed_requires_package_target_mapping_before_add_approval",
            "does_not_make_existing_attack_window_card_cuttable",
        ],
        "mana_rock_seed_curve_pressure_review": [
            "mana_rock_seed_requires_curve_and_source_pressure_review",
            "does_not_make_existing_ramp_cuttable",
        ],
        "color_fixing_rock_seed_curve_pressure_review": [
            "color_fixing_seed_requires_mana_profile_pressure_review",
            "does_not_make_existing_ramp_cuttable",
        ],
        "zero_mana_or_conditional_acceleration_seed_bracket_context_required": [
            "fast_mana_seed_requires_bracket_and_game_changer_context",
            "cannot_override_current_deck_usage_or_same_lane_cut_proof",
        ],
        "high_power_generic_tutor_seed_bracket_context_required": [
            "high_power_tutor_seed_requires_bracket_and_game_changer_context",
            "cannot_override_current_deck_usage_or_same_lane_cut_proof",
        ],
        "narrow_creature_tutor_seed_package_target_required": [
            "narrow_tutor_seed_requires_specific_package_targets",
            "does_not_replace_generic_tutor_or_open_cut_permission",
        ],
        "conditional_tutor_seed_context_required": [
            "conditional_tutor_seed_requires_threshold_context",
            "cannot_override_same_lane_cut_proof",
        ],
    }
    return cautions.get(scope, ["seed_requires_contextual_review_before_any_deck_action"])


def review_status(
    row: Mapping[str, Any],
    *,
    in_deck: bool,
    recycled: bool,
    oracle_row: Mapping[str, Any] | None,
    commander_legal: bool,
    commander_legality_status: str,
    matched_terms: list[str],
) -> tuple[str, str, bool]:
    source_status = str(row.get("status") or "")
    if commander_legality_status == "banned" or source_status == "expanded_source_candidate_blocks_commander_banned":
        return (
            "expanded_source_candidate_local_review_blocks_commander_banned",
            "discard_banned_candidate",
            False,
        )
    if in_deck or source_status == "expanded_source_candidate_already_in_current_deck_blocked":
        return (
            "expanded_source_candidate_local_review_blocks_current_deck",
            "target_deck_trace_or_negative_review_before_cut_consideration",
            False,
        )
    if recycled or source_status == "expanded_source_candidate_recycled_from_prior_seed_blocked":
        return (
            "expanded_source_candidate_local_review_blocks_recycled_prior_seed",
            "broaden_external_source_candidate_pool_without_recycling",
            False,
        )
    if source_status != "expanded_external_source_candidate_ready_for_local_review":
        return (
            "expanded_source_candidate_local_review_blocks_prior_expander_status",
            "resolve_prior_expander_block_before_seeded_miner",
            False,
        )
    if not oracle_row:
        return (
            "expanded_source_candidate_local_review_needs_identity_resolution",
            "resolve_local_identity_before_seeded_miner",
            False,
        )
    if not commander_legal:
        return (
            "expanded_source_candidate_local_review_blocks_color_identity",
            "discard_color_identity_mismatch",
            False,
        )
    if expander.finder.type_line_contains(oracle_row, "Land"):
        return (
            "expanded_source_candidate_local_review_blocks_land_lane",
            "route_land_candidate_to_mana_base_lane",
            False,
        )
    if not matched_terms:
        return (
            "expanded_source_candidate_local_review_blocks_role_mismatch",
            "collect_stronger_role_evidence_before_seeded_miner",
            False,
        )
    return (
        "expanded_source_candidate_local_review_ready_for_seeded_miner",
        "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
        True,
    )


def review_candidate(row: Mapping[str, Any], *, indexes: Mapping[str, Any]) -> dict[str, Any]:
    role = str(row.get("target_cut_role") or "")
    source_name = str(row.get("card_name") or row.get("source_card_name") or "")
    normalized = expander.finder.normalize_name(source_name)
    base = expander.finder.split_face_normalized(source_name)
    oracle_row = indexes.get("oracle", {}).get(normalized) or indexes.get("oracle", {}).get(base)
    canonical_name = str((oracle_row or {}).get("name") or source_name)
    keys = expander.candidate_keys(source_name, oracle_row)
    in_deck = bool(keys & indexes.get("deck_names", set())) or bool(keys & indexes.get("deck_base_names", set()))
    in_deck = in_deck or bool(row.get("current_deck_present"))
    recycled = bool(row.get("recycled_from_prior_external_seed"))
    commander_legal = expander.finder.color_identity_legal(oracle_row)
    commander_legality_status = legality_status(indexes, keys)
    if commander_legality_status == "unknown" and row.get("commander_legality_status"):
        commander_legality_status = str(row.get("commander_legality_status"))
    matched_terms = expander.role_terms(role, oracle_row)
    status, next_evidence, seed_allowed = review_status(
        row,
        in_deck=in_deck,
        recycled=recycled,
        oracle_row=oracle_row,
        commander_legal=commander_legal,
        commander_legality_status=commander_legality_status,
        matched_terms=matched_terms,
    )
    scope = expander.seed_scope(role, canonical_name, oracle_row) if seed_allowed else "blocked_not_a_seed"
    return {
        "target_cut_role": role,
        "card_name": canonical_name,
        "source_card_name": row.get("source_card_name") or source_name,
        "source_status": row.get("status"),
        "review_status": status,
        "next_evidence": next_evidence,
        "current_deck_present": in_deck,
        "recycled_from_prior_external_seed": recycled,
        "local_identity_found": bool(oracle_row),
        "commander_identity_legal": commander_legal,
        "commander_legality_status": commander_legality_status,
        "type_line": (oracle_row or {}).get("type_line") or row.get("type_line"),
        "cmc": (oracle_row or {}).get("cmc") if oracle_row else row.get("cmc"),
        "local_role_evidence_terms": matched_terms,
        "seed_scope": scope,
        "seed_cautions": seed_cautions(scope),
        "source_ids": row.get("source_ids") or [],
        "candidate_signal": row.get("candidate_signal"),
        "miner_source_seed_allowed": seed_allowed,
        "rerun_miner_allowed_for_card": seed_allowed,
        "card_level_cut_permission_now": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "value_safe_reclassification_allowed": False,
        "promotion_allowed": False,
    }


def count_by(rows: Iterable[Mapping[str, Any]], field: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(field) or "unknown")] += 1
    return dict(counts)


def candidate_rows(expander_payload: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    rows = expander_payload.get("expanded_source_candidate_rows")
    if isinstance(rows, list):
        return [row for row in rows if isinstance(row, Mapping)]
    ready_rows = expander_payload.get("ready_expanded_source_candidate_rows") or []
    return [row for row in ready_rows if isinstance(row, Mapping)]


def choose_status_and_next_gate(seed_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if seed_rows:
        return (
            "expanded_external_source_candidates_reviewed_seed_ready_no_deck_action",
            "rerun_seeded_cut_source_miner_with_reviewed_expanded_external_nonpayoff_sources",
        )
    return (
        "expanded_external_source_candidate_review_blocks_no_seed_ready",
        "broaden_external_nonpayoff_source_research_live",
    )


def build_report(*, expander_report: Path, selected_db: Path | None = None) -> dict[str, Any]:
    expander_payload = load_json(expander_report)
    expander_summary = expander_payload.get("summary") or {}
    deck_id = str(expander_summary.get("deck_id") or "")
    resolved_db = resolve_selected_db(expander_payload, selected_db)
    indexes = expander.finder.db_indexes(resolved_db, deck_id)
    review_rows = [review_candidate(row, indexes=indexes) for row in candidate_rows(expander_payload)]
    seed_rows = [row for row in review_rows if row["miner_source_seed_allowed"]]
    status, next_gate = choose_status_and_next_gate(seed_rows)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_expanded_source_candidate_reviewer",
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
            "expander_report": rel(expander_report),
            "selected_db": rel(resolved_db),
        },
        "source_snapshots": expander_payload.get("source_snapshots") or [],
        "summary": {
            "deck_id": deck_id,
            "commander": str(expander_summary.get("commander") or ""),
            "expander_ready_candidate_count": int(expander_summary.get("expanded_ready_for_review_count") or 0),
            "reviewed_candidate_count": len(review_rows),
            "miner_source_seed_allowed_count": len(seed_rows),
            "blocked_current_deck_count": sum(
                1 for row in review_rows if row["review_status"] == "expanded_source_candidate_local_review_blocks_current_deck"
            ),
            "blocked_commander_banned_count": sum(
                1 for row in review_rows if row["review_status"] == "expanded_source_candidate_local_review_blocks_commander_banned"
            ),
            "blocked_recycled_prior_seed_count": sum(
                1 for row in review_rows if row["review_status"] == "expanded_source_candidate_local_review_blocks_recycled_prior_seed"
            ),
            "blocked_role_mismatch_count": sum(
                1 for row in review_rows if row["review_status"] == "expanded_source_candidate_local_review_blocks_role_mismatch"
            ),
            "card_level_cut_permission_count": 0,
            "candidate_copy_allowed_count": 0,
            "battle_gate_allowed_count": 0,
            "value_safe_reclassification_allowed_count": 0,
            "miner_seed_count_by_role": count_by(seed_rows, "target_cut_role"),
            "seed_scope_counts": count_by(seed_rows, "seed_scope"),
            "review_status_counts": count_by(review_rows, "review_status"),
            "next_gate": next_gate,
        },
        "miner_source_seed_rows": seed_rows,
        "review_rows": review_rows,
        "candidate_copy_blockers": [
            "reviewed_expanded_external_candidates_are_miner_seeds_not_cut_permission",
            "current_deck_cards_remain_blocked_until_trace_or_negative_review",
            "banned_cards_are_discarded_before_strategy_review",
            "candidate_copy_closed_until_seeded_miner_finds_traceable_current_deck_cut_source",
            "value_safe_reclassification_closed_until_same_lane_or_equal_gate_proof_exists",
        ],
        "policy": {
            "review_boundary": "Only locally legal outside-deck expanded source candidates can seed the miner.",
            "seed_boundary": "Reviewed expanded external nonpayoff candidates may seed miner research only; they are not add approvals.",
            "scope_boundary": "Fast mana, high-power tutors, narrow tutors, protection, and mana rocks retain separate seed scopes and cautions.",
            "legality_boundary": "Banned candidates stay blocked even if they appeared in historical high-power context.",
            "mutation_boundary": "This reviewer does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Expanded Source Candidate Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- expander_ready_candidate_count: `{summary['expander_ready_candidate_count']}`",
        f"- reviewed_candidate_count: `{summary['reviewed_candidate_count']}`",
        f"- miner_source_seed_allowed_count: `{summary['miner_source_seed_allowed_count']}`",
        f"- blocked_current_deck_count: `{summary['blocked_current_deck_count']}`",
        f"- blocked_commander_banned_count: `{summary['blocked_commander_banned_count']}`",
        f"- blocked_recycled_prior_seed_count: `{summary['blocked_recycled_prior_seed_count']}`",
        f"- blocked_role_mismatch_count: `{summary['blocked_role_mismatch_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_count: `{summary['candidate_copy_allowed_count']}`",
        f"- battle_gate_allowed_count: `{summary['battle_gate_allowed_count']}`",
        f"- value_safe_reclassification_allowed_count: `{summary['value_safe_reclassification_allowed_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Miner Source Seeds",
        "",
        "| Role | Card | Scope | Evidence Terms | Cautions |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in payload["miner_source_seed_rows"]:
        terms = ", ".join(row.get("local_role_evidence_terms") or [])
        cautions = ", ".join(row.get("seed_cautions") or [])
        lines.append(
            f"| `{row['target_cut_role']}` | `{row['card_name']}` | `{row['seed_scope']}` | `{terms}` | `{cautions}` |"
        )
    lines.extend(["", "## Review Rows", ""])
    lines.append("| Role | Card | In Deck | Legal | Miner Seed | Status |")
    lines.append("| --- | --- | ---: | ---: | ---: | --- |")
    for row in payload["review_rows"]:
        lines.append(
            "| `{role}` | `{card}` | {deck} | `{legal}` | {seed} | `{status}` |".format(
                role=row.get("target_cut_role"),
                card=row.get("card_name"),
                deck=str(row.get("current_deck_present")).lower(),
                legal=row.get("commander_legality_status"),
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
    parser.add_argument("--expander-report", type=Path, default=DEFAULT_EXPANDER_REPORT)
    parser.add_argument("--selected-db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(expander_report=args.expander_report, selected_db=args.selected_db)
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
