#!/usr/bin/env python3
"""Review fresh external nonpayoff source candidates before seeded mining.

This read-only gate follows
``global_commander_external_nonpayoff_new_source_or_replacement_finder``.
It turns already fresh outside-deck source candidates into reviewed miner seeds
only. It does not create card-level cut permission, copy a candidate deck,
mutate any DB, run battles, reclassify value-safe cuts, or promote a package.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_external_nonpayoff_new_source_or_replacement_finder as finder
from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_NEW_SOURCE_FINDER_REPORT = finder.DEFAULT_OUT_PREFIX.with_suffix(".json")
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_new_source_candidate_reviewer_20260706_kaalia_value_safe_stage1_repair_scope1"
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


def resolve_selected_db(finder_payload: Mapping[str, Any], selected_db: Path | None = None) -> Path:
    if selected_db is not None:
        return selected_db
    inputs = finder_payload.get("input_artifacts") or {}
    candidate = resolve_repo_path(inputs.get("selected_db"), finder.DEFAULT_SELECTED_DB)
    if candidate.exists():
        return candidate
    if finder.FALLBACK_SELECTED_DB.exists():
        return finder.FALLBACK_SELECTED_DB
    return candidate


def candidate_keys(card_name: object, oracle_row: Mapping[str, Any] | None) -> set[str]:
    keys = {
        finder.normalize_name(card_name),
        finder.split_face_normalized(card_name),
    }
    if oracle_row:
        keys.add(finder.normalize_name(oracle_row.get("name")))
        keys.add(finder.split_face_normalized(oracle_row.get("name")))
        keys.add(finder.normalize_name(oracle_row.get("normalized_name")))
        keys.add(finder.split_face_normalized(oracle_row.get("normalized_name")))
    return {key for key in keys if key}


def legality_status(indexes: Mapping[str, Any], keys: set[str]) -> str:
    for key in keys:
        status = indexes.get("legalities", {}).get(key)
        if status:
            return str(status)
    return "unknown"


def seed_scope(role: str, card_name: str, oracle_row: Mapping[str, Any] | None) -> str:
    type_line = str((oracle_row or {}).get("type_line") or "").lower()
    oracle_text = str((oracle_row or {}).get("oracle_text") or "").lower()
    normalized = finder.normalize_name(card_name)
    if role == "tutors_access":
        if "equipment" in oracle_text or "equipment" in type_line:
            return "package_access_limited_seed"
        if normalized == "grim tutor":
            return "generic_tutor_seed_bracket_context_required"
        return "generic_tutor_seed_context_required"
    if role == "mana_acceleration":
        return "mana_rock_seed_curve_pressure_review"
    if role == "haste_protection_silence":
        if "equipment" in type_line:
            return "equipment_haste_protection_seed"
        if "change the target" in oracle_text:
            return "removal_redirection_seed"
        return "protection_spell_or_haste_seed"
    return "role_seed_context_required"


def seed_cautions(scope: str) -> list[str]:
    cautions = {
        "package_access_limited_seed": [
            "equipment_or_aura_access_must_map_to_real_package_target",
            "does_not_replace_generic_tutor_or_open_cut_permission",
        ],
        "generic_tutor_seed_bracket_context_required": [
            "high_power_generic_tutor_requires_commander_bracket_context",
            "cannot_override_current_deck_usage_or_same_lane_cut_proof",
        ],
        "generic_tutor_seed_context_required": [
            "generic_access_requires_commander_fit_and_target_trace_later",
            "cannot_override_same_lane_cut_proof",
        ],
        "mana_rock_seed_curve_pressure_review": [
            "mana_rock_seed_requires_curve_and_source_pressure_review",
            "does_not_make_existing_ramp_cuttable",
        ],
        "equipment_haste_protection_seed": [
            "equipment_seed_requires_package_target_mapping_before_add_approval",
            "does_not_make_existing_attack_window_card_cuttable",
        ],
        "removal_redirection_seed": [
            "redirection_seed_is_contextual_protection_not_generic_removal",
            "requires_target_role_trace_before_cut_proof",
        ],
        "protection_spell_or_haste_seed": [
            "protection_seed_requires_target_role_cut_source_evidence_later",
            "does_not_make_current_protection_card_cuttable",
        ],
    }
    return cautions.get(scope, ["seed_requires_contextual_review_before_any_deck_action"])


def review_status(
    row: Mapping[str, Any],
    *,
    in_deck: bool,
    held_add: bool,
    recycled: bool,
    oracle_row: Mapping[str, Any] | None,
    commander_legal: bool,
    commander_legality_status: str,
    matched_terms: list[str],
) -> tuple[str, str, bool]:
    source_status = str(row.get("status") or "")
    if source_status != "new_external_source_candidate_ready_for_local_miner_review":
        return (
            "new_external_source_local_review_blocks_prior_finder_status",
            "resolve_prior_finder_block_before_seeded_miner",
            False,
        )
    if in_deck:
        return (
            "new_external_source_local_review_blocks_current_deck",
            "target_deck_trace_or_negative_review_before_cut_consideration",
            False,
        )
    if held_add:
        return (
            "new_external_source_local_review_blocks_held_package_add",
            "same_lane_value_safe_pair_before_candidate_copy",
            False,
        )
    if recycled:
        return (
            "new_external_source_local_review_blocks_recycled_prior_seed",
            "broaden_external_source_candidate_pool_without_recycling",
            False,
        )
    if commander_legality_status == "banned":
        return (
            "new_external_source_local_review_blocks_commander_banned",
            "discard_banned_candidate",
            False,
        )
    if not oracle_row:
        return (
            "new_external_source_local_review_needs_identity_resolution",
            "resolve_local_identity_before_seeded_miner",
            False,
        )
    if not commander_legal:
        return (
            "new_external_source_local_review_blocks_color_identity",
            "discard_color_identity_mismatch",
            False,
        )
    if finder.type_line_contains(oracle_row, "Land"):
        return (
            "new_external_source_local_review_blocks_land_lane",
            "route_land_candidate_to_mana_base_lane",
            False,
        )
    if not matched_terms:
        return (
            "new_external_source_local_review_blocks_role_mismatch",
            "collect_stronger_role_evidence_before_seeded_miner",
            False,
        )
    return (
        "new_external_source_local_review_ready_for_seeded_miner",
        "rerun_seeded_cut_source_miner_with_new_reviewed_external_nonpayoff_sources",
        True,
    )


def review_candidate(row: Mapping[str, Any], *, indexes: Mapping[str, Any]) -> dict[str, Any]:
    role = str(row.get("target_cut_role") or "")
    card_name = str(row.get("card_name") or row.get("source_card_name") or "")
    normalized = finder.normalize_name(card_name)
    base = finder.split_face_normalized(card_name)
    oracle_row = indexes.get("oracle", {}).get(normalized) or indexes.get("oracle", {}).get(base)
    canonical_name = str((oracle_row or {}).get("name") or card_name)
    keys = candidate_keys(card_name, oracle_row)
    in_deck = bool(keys & indexes.get("deck_names", set())) or bool(keys & indexes.get("deck_base_names", set()))
    in_deck = in_deck or bool(row.get("current_deck_present"))
    held_add = bool(row.get("held_package_add"))
    recycled = bool(row.get("recycled_from_prior_external_seed"))
    commander_legal = finder.color_identity_legal(oracle_row)
    commander_legality_status = legality_status(indexes, keys)
    matched_terms = finder.role_terms(role, oracle_row)
    status, next_evidence, seed_allowed = review_status(
        row,
        in_deck=in_deck,
        held_add=held_add,
        recycled=recycled,
        oracle_row=oracle_row,
        commander_legal=commander_legal,
        commander_legality_status=commander_legality_status,
        matched_terms=matched_terms,
    )
    scope = seed_scope(role, canonical_name, oracle_row) if seed_allowed else "blocked_not_a_seed"
    return {
        "target_cut_role": role,
        "card_name": canonical_name,
        "source_card_name": row.get("source_card_name") or card_name,
        "source_status": row.get("status"),
        "review_status": status,
        "next_evidence": next_evidence,
        "current_deck_present": in_deck,
        "held_package_add": held_add,
        "recycled_from_prior_external_seed": recycled,
        "local_identity_found": bool(oracle_row),
        "commander_identity_legal": commander_legal,
        "commander_legality_status": commander_legality_status,
        "type_line": (oracle_row or {}).get("type_line") or row.get("type_line"),
        "cmc": (oracle_row or {}).get("cmc") if oracle_row else row.get("cmc"),
        "scryfall_id": (oracle_row or {}).get("scryfall_id") or row.get("scryfall_id"),
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


def candidate_rows_for_review(finder_payload: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    ready_rows = finder_payload.get("ready_new_external_source_rows")
    if isinstance(ready_rows, list) and ready_rows:
        return [row for row in ready_rows if isinstance(row, Mapping)]
    return [
        row
        for row in finder_payload.get("new_external_source_rows") or []
        if isinstance(row, Mapping) and row.get("status") == "new_external_source_candidate_ready_for_local_miner_review"
    ]


def choose_status_and_next_gate(seed_rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    if seed_rows:
        return (
            "new_external_source_candidates_reviewed_seed_ready_no_deck_action",
            "rerun_seeded_cut_source_miner_with_new_reviewed_external_nonpayoff_sources",
        )
    return (
        "new_external_source_candidate_review_blocks_no_seed_ready",
        "broaden_external_nonpayoff_source_research_live",
    )


def build_report(*, finder_report: Path, selected_db: Path | None = None) -> dict[str, Any]:
    finder_payload = load_json(finder_report)
    finder_summary = finder_payload.get("summary") or {}
    deck_id = str(finder_summary.get("deck_id") or "")
    resolved_db = resolve_selected_db(finder_payload, selected_db)
    indexes = finder.db_indexes(resolved_db, deck_id)
    review_rows = [review_candidate(row, indexes=indexes) for row in candidate_rows_for_review(finder_payload)]
    seed_rows = [row for row in review_rows if row["miner_source_seed_allowed"]]
    status, next_gate = choose_status_and_next_gate(seed_rows)
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_external_nonpayoff_new_source_candidate_reviewer",
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
            "finder_report": rel(finder_report),
            "selected_db": rel(resolved_db),
        },
        "source_snapshots": finder_payload.get("source_snapshots") or [],
        "summary": {
            "deck_id": deck_id,
            "commander": str(finder_summary.get("commander") or ""),
            "finder_ready_candidate_count": int(finder_summary.get("new_external_ready_for_review_count") or 0),
            "reviewed_candidate_count": len(review_rows),
            "miner_source_seed_allowed_count": len(seed_rows),
            "card_level_cut_permission_count": sum(1 for row in review_rows if row["card_level_cut_permission_now"]),
            "candidate_copy_allowed_count": sum(1 for row in review_rows if row["candidate_copy_allowed"]),
            "battle_gate_allowed_count": sum(1 for row in review_rows if row["battle_gate_allowed"]),
            "value_safe_reclassification_allowed_count": sum(
                1 for row in review_rows if row["value_safe_reclassification_allowed"]
            ),
            "miner_seed_count_by_role": count_by(seed_rows, "target_cut_role"),
            "seed_scope_counts": count_by(seed_rows, "seed_scope"),
            "review_status_counts": count_by(review_rows, "review_status"),
            "next_gate": next_gate,
        },
        "miner_source_seed_rows": seed_rows,
        "review_rows": review_rows,
        "candidate_copy_blockers": [
            "reviewed_new_external_candidates_are_miner_seeds_not_cut_permission",
            "no_current_deck_card_received_explicit_same_lane_replacement_proof",
            "candidate_copy_closed_until_seeded_miner_finds_traceable_current_deck_cut_source",
            "battle_gate_closed_until_candidate_copy_and_card_level_usage_evidence_exist",
            "value_safe_reclassification_closed_until_same_lane_or_equal_gate_proof_exists",
        ],
        "policy": {
            "review_boundary": "Only prior finder-ready outside-deck candidates are reviewed here.",
            "seed_boundary": "Reviewed fresh external nonpayoff candidates may seed miner research only; they are not add approvals.",
            "scope_boundary": "Equipment tutors, generic tutors, mana rocks, and protection spells keep separate seed scopes and cautions.",
            "deck_boundary": "A candidate that resolves into the current deck, held package, recycled seed, land lane, banned card, or color-identity mismatch is blocked.",
            "mutation_boundary": "This reviewer does not copy decks, mutate DBs, run battles, reclassify cuts, or promote packages.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff New Source Candidate Reviewer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- finder_ready_candidate_count: `{summary['finder_ready_candidate_count']}`",
        f"- reviewed_candidate_count: `{summary['reviewed_candidate_count']}`",
        f"- miner_source_seed_allowed_count: `{summary['miner_source_seed_allowed_count']}`",
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
            "| `{role}` | `{card}` | {deck} | {legal} | {seed} | `{status}` |".format(
                role=row.get("target_cut_role"),
                card=row.get("card_name"),
                deck=str(row.get("current_deck_present")).lower(),
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
    parser.add_argument("--finder-report", type=Path, default=DEFAULT_NEW_SOURCE_FINDER_REPORT)
    parser.add_argument("--selected-db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(finder_report=args.finder_report, selected_db=args.selected_db)
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
