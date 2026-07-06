#!/usr/bin/env python3
"""Discover named external nonpayoff same-lane source candidates."""

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
DEFAULT_POLICY_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_cut_policy_mapper_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_CORPUS_REPORT = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_cut_corpus_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PACKAGE_SOURCE_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_package_source_synthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_SELECTED_DB = (
    REPORT_DIR
    / "global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1_candidate"
    / "knowledge_candidate.db"
)
FALLBACK_SELECTED_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer_20260705_kaalia_value_safe_stage1_repair_scope1"
)


SOURCE_CANDIDATES: tuple[dict[str, object], ...] = (
    {"role": "haste_protection_silence", "card": "Lightning Greaves", "signal": "direct_external_haste_protection_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05", "edhrec_kaalia_upgraded_demons_2026_07_05"]},
    {"role": "haste_protection_silence", "card": "Swiftfoot Boots", "signal": "direct_external_haste_protection_staple", "source_ids": ["edhrec_kaalia_upgraded_demons_2026_07_05", "flipside_kaalia_deck_tech_2026"]},
    {"role": "haste_protection_silence", "card": "Boros Charm", "signal": "direct_external_protection_spell", "source_ids": ["edhrec_kaalia_upgraded_demons_2026_07_05"]},
    {"role": "haste_protection_silence", "card": "Dragon Tempest", "signal": "direct_external_haste_source", "source_ids": ["edhrec_kaalia_current_2026_07_05", "draftsim_kaalia_deck_guide_2025"]},
    {"role": "haste_protection_silence", "card": "Bitter Reunion", "signal": "direct_external_haste_source", "source_ids": ["edhrec_kaalia_hidden_gems_2026_07_05"]},
    {"role": "haste_protection_silence", "card": "Dihada, Binder of Wills", "signal": "external_attack_window_planeswalker_support", "source_ids": ["flipside_kaalia_deck_tech_2026"]},
    {"role": "mana_acceleration", "card": "Arcane Signet", "signal": "direct_external_mana_rock_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05", "wizards_commander_brackets_2026_02_09"]},
    {"role": "mana_acceleration", "card": "Sword of the Animist", "signal": "external_repeatable_land_ramp_source", "source_ids": ["edhrec_kaalia_current_2026_07_05"]},
    {"role": "mana_acceleration", "card": "Dihada, Binder of Wills", "signal": "external_treasure_or_selection_support", "source_ids": ["flipside_kaalia_deck_tech_2026"]},
    {"role": "mana_acceleration", "card": "Simian Spirit Guide", "signal": "external_fast_mana_context", "source_ids": ["wizards_commander_brackets_2026_02_09"]},
    {"role": "mana_acceleration", "card": "Fellwar Stone", "signal": "direct_external_mana_rock_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05"]},
    {"role": "tutors_access", "card": "Demonic Tutor", "signal": "direct_external_tutor_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05", "edhrec_kaalia_combos_2026_07_05"]},
    {"role": "tutors_access", "card": "Enlightened Tutor", "signal": "direct_external_tutor_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05", "edhrec_kaalia_combos_2026_07_05"]},
    {"role": "tutors_access", "card": "Vampiric Tutor", "signal": "direct_external_tutor_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05", "edhrec_kaalia_combos_2026_07_05"]},
    {"role": "tutors_access", "card": "Diabolic Intent", "signal": "direct_external_tutor_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05", "edhrec_kaalia_combos_2026_07_05"]},
    {"role": "tutors_access", "card": "Gamble", "signal": "external_tutor_or_access_staple", "source_ids": ["edhrec_kaalia_current_2026_07_05"]},
)


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


def discovery_roles(policy_payload: Mapping[str, Any]) -> set[str]:
    roles: set[str] = set()
    for row in policy_payload.get("role_policy_rows") or []:
        if not isinstance(row, Mapping):
            continue
        if row.get("cut_policy") == "require_external_nonpayoff_source_discovery_before_miner":
            role = str(row.get("target_cut_role") or "")
            if role:
                roles.add(role)
    return roles


def selected_add_names(package_payload: Mapping[str, Any]) -> set[str]:
    selected: set[str] = set()
    for row in package_payload.get("selected_add_package") or []:
        if isinstance(row, Mapping):
            selected.add(normalize_name(row.get("card_name")))
    return {name for name in selected if name}


def db_indexes(selected_db: Path, deck_id: str) -> tuple[set[str], dict[str, dict[str, Any]]]:
    deck_names: set[str] = set()
    oracle: dict[str, dict[str, Any]] = {}
    if not selected_db.exists():
        return deck_names, oracle
    con = sqlite3.connect(selected_db)
    con.row_factory = sqlite3.Row
    try:
        for row in con.execute("select card_name from deck_cards where cast(deck_id as text) = ?", (str(deck_id),)):
            deck_names.add(normalize_name(row["card_name"]))
        for row in con.execute("select normalized_name, name, type_line, cmc, scryfall_id from card_oracle_cache"):
            oracle[normalize_name(row["normalized_name"])] = {
                "name": row["name"],
                "type_line": row["type_line"],
                "cmc": row["cmc"],
                "scryfall_id": row["scryfall_id"],
            }
    finally:
        con.close()
    return deck_names, oracle


def resolve_selected_db(selected_db: Path) -> Path:
    if selected_db.exists():
        return selected_db
    if FALLBACK_SELECTED_DB.exists():
        return FALLBACK_SELECTED_DB
    return selected_db


def classify_candidate(
    candidate: Mapping[str, object],
    *,
    deck_names: set[str],
    selected_adds: set[str],
    oracle: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    card_name = str(candidate["card"])
    normalized = normalize_name(card_name)
    in_deck = normalized in deck_names
    selected = normalized in selected_adds
    identity = oracle.get(normalized)
    if in_deck:
        status = "external_source_candidate_already_in_current_deck_needs_trace_policy"
        next_evidence = "target_deck_trace_or_negative_review_before_cut_consideration"
    elif selected:
        status = "external_source_candidate_already_selected_as_add_needs_pair_policy"
        next_evidence = "same_lane_value_safe_pair_before_candidate_copy"
    elif identity:
        status = "external_source_candidate_ready_for_local_source_lane_review"
        next_evidence = "review_external_nonpayoff_same_lane_source_candidate_locally"
    else:
        status = "external_source_candidate_needs_local_identity_resolution"
        next_evidence = "resolve_local_identity_before_source_lane_review"
    return {
        "target_cut_role": candidate["role"],
        "card_name": card_name,
        "candidate_signal": candidate["signal"],
        "source_ids": candidate["source_ids"],
        "source_observation": "Named external source candidate for this nonpayoff same-lane role.",
        "current_deck_present": in_deck,
        "selected_as_package_add": selected,
        "local_identity_found": bool(identity),
        "type_line": identity.get("type_line") if identity else None,
        "cmc": identity.get("cmc") if identity else None,
        "scryfall_id": identity.get("scryfall_id") if identity else None,
        "status": status,
        "next_evidence": next_evidence,
        "policy_required_evidence": [
            "named_external_source_candidate_rows",
            "local_identity_and_legality_check",
            "target_deck_trace_or_negative_review_before_cut_consideration",
            "same_lane_value_safe_pair_before_candidate_copy",
        ],
        "rerun_miner_allowed_for_card": False,
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


def build_report(
    *,
    policy_report: Path,
    corpus_report: Path,
    package_source_report: Path,
    selected_db: Path,
) -> dict[str, Any]:
    policy_payload = load_json(policy_report)
    corpus_payload = load_json(corpus_report)
    package_payload = load_json(package_source_report)
    summary = policy_payload.get("summary") or corpus_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    roles = discovery_roles(policy_payload)
    resolved_selected_db = resolve_selected_db(selected_db)
    deck_names, oracle = db_indexes(resolved_selected_db, deck_id)
    selected_adds = selected_add_names(package_payload)
    rows = [
        classify_candidate(candidate, deck_names=deck_names, selected_adds=selected_adds, oracle=oracle)
        for candidate in SOURCE_CANDIDATES
        if candidate.get("role") in roles
    ]
    blockers = [
        "named_external_candidates_are_not_cut_permission",
        "current_deck_present_candidates_need_trace_policy_before_cut_consideration",
        "outside_deck_candidates_need_local_source_lane_review_before_miner",
        "candidate_copy_closed_until_value_safe_same_lane_pair_exists",
    ]
    return {
        "generated_at": utc_now(),
        "status": "external_nonpayoff_same_lane_source_candidates_discovered_no_cut_permission",
        "artifact_type": "global_commander_external_nonpayoff_same_lane_source_candidate_discoverer",
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
            "policy_report": rel(policy_report),
            "corpus_report": rel(corpus_report),
            "package_source_report": rel(package_source_report),
            "selected_db": rel(resolved_selected_db),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": str(summary.get("commander") or ""),
            "source_candidate_count": len(rows),
            "role_count": len({row["target_cut_role"] for row in rows}),
            "current_deck_present_count": sum(1 for row in rows if row["current_deck_present"]),
            "outside_current_deck_count": sum(1 for row in rows if not row["current_deck_present"]),
            "local_identity_found_count": sum(1 for row in rows if row["local_identity_found"]),
            "selected_as_package_add_count": sum(1 for row in rows if row["selected_as_package_add"]),
            "rerun_miner_allowed_card_count": sum(1 for row in rows if row["rerun_miner_allowed_for_card"]),
            "card_level_cut_permission_count": sum(1 for row in rows if row["card_level_cut_permission_now"]),
            "candidate_count_by_role": count_by(rows, "target_cut_role"),
            "status_counts": count_by(rows, "status"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": "review_external_nonpayoff_same_lane_source_candidates_locally_before_miner",
        },
        "source_candidate_rows": rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "candidate_boundary": "Named external candidates are source-lane evidence, not card-level cut permission.",
            "current_deck_boundary": "Candidates already in the current deck need trace/negative-review policy before any cut consideration.",
            "outside_deck_boundary": "Candidates outside the current deck can inform future add/source lanes, but do not solve current cuts.",
            "battle_boundary": "No battle gate opens before candidate copy and relevant card-level usage evidence.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander External Nonpayoff Same-Lane Source Candidate Discoverer",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- source_candidate_count: `{summary['source_candidate_count']}`",
        f"- role_count: `{summary['role_count']}`",
        f"- current_deck_present_count: `{summary['current_deck_present_count']}`",
        f"- outside_current_deck_count: `{summary['outside_current_deck_count']}`",
        f"- local_identity_found_count: `{summary['local_identity_found_count']}`",
        f"- selected_as_package_add_count: `{summary['selected_as_package_add_count']}`",
        f"- card_level_cut_permission_count: `{summary['card_level_cut_permission_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Source Candidate Rows",
        "",
        "| Role | Card | In Deck | Selected Add | Identity | Status |",
        "| --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["source_candidate_rows"]:
        lines.append(
            "| `{role}` | `{card}` | {in_deck} | {selected} | {identity} | `{status}` |".format(
                role=row.get("target_cut_role"),
                card=row.get("card_name"),
                in_deck=str(row.get("current_deck_present")).lower(),
                selected=str(row.get("selected_as_package_add")).lower(),
                identity=str(row.get("local_identity_found")).lower(),
                status=row.get("status"),
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
    parser.add_argument("--policy-report", type=Path, default=DEFAULT_POLICY_REPORT)
    parser.add_argument("--corpus-report", type=Path, default=DEFAULT_CORPUS_REPORT)
    parser.add_argument("--package-source-report", type=Path, default=DEFAULT_PACKAGE_SOURCE_REPORT)
    parser.add_argument("--selected-db", type=Path, default=DEFAULT_SELECTED_DB)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        policy_report=args.policy_report,
        corpus_report=args.corpus_report,
        package_source_report=args.package_source_report,
        selected_db=args.selected_db,
    )
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
