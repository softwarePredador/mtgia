#!/usr/bin/env python3
"""Build read-only candidate pools for Commander profile-blocker repairs.

This model consumes a blocked package strategy matrix plus its repair plan and
names source-lane candidates for each blocker. It is not a deck optimizer and
does not materialize a deck. When a blocker is too large for a narrow add/cut
repair, it keeps candidate-copy gates closed and routes the work back to the
commander source lane.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_candidate_package_strategy_matrix as strategy_matrix
import global_commander_core_role_audit as core_roles
import global_commander_mana_base_profile as mana_profile
import global_commander_named_land_candidate_pool as land_pool
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REPAIR_PLAN_REPORT = (
    REPORT_DIR / "global_commander_profile_blocker_repair_plan_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_STRATEGY_MATRIX_REPORT = (
    REPORT_DIR / "global_commander_candidate_package_strategy_matrix_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5"
)

ROLE_TO_EXPECTED_PACKAGE = {
    "angels_demons_dragons_payoffs": "angels_demons_dragons_payoffs",
    "spot_interaction": "interaction_and_resets",
    "commander_attack_window": "commander_attack_enablers",
    "haste_protection_silence": "commander_attack_enablers",
    "reanimation_plan_b": "reanimation_plan_b",
}
PROTECTED_ANCHOR_AXIS = "protected_profile_anchor"
AXIS_SOURCE_ALIASES = {
    "core_removal_floor": "spot_interaction",
}
GLOBAL_FEEDBACK_STAGE_ONLY_CUTS = {
    normalize_name("Birgi, God of Storytelling // Harnfel, Horn of Bounty"),
}
STRUCTURAL_STAPLE_PROTECTED_CUTS = {
    normalize_name(card)
    for card in (
        "Demonic Tutor",
        "Vampiric Tutor",
        "Enlightened Tutor",
        "Smothering Tithe",
        "Mana Vault",
        "Arcane Signet",
        "Sol Ring",
    )
}
BLOCKED_HARD_ROLES = {
    "lands",
    "angels_demons_dragons_payoffs",
    "spot_interaction",
    "haste_protection_silence",
    "reanimation_plan_b",
}


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


def deck_rows(conn: sqlite3.Connection, deck_id: str) -> list[dict[str, Any]]:
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
    return [dict(row) for row in rows]


def oracle_row(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not mana_profile.table_exists(conn, "card_oracle_cache"):
        return {}
    conn.row_factory = sqlite3.Row
    row = conn.execute(
        """
        SELECT name, normalized_name, mana_cost, colors_json, color_identity_json,
               type_line, oracle_text, cmc, scryfall_id, card_id
        FROM card_oracle_cache
        WHERE lower(name)=lower(?) OR normalized_name=?
        ORDER BY name
        LIMIT 1
        """,
        (card_name, normalize_name(card_name)),
    ).fetchone()
    return dict(row) if row else {}


def card_row_for_roles(card_name: str, oracle: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "card_name": oracle.get("name") or card_name,
        "quantity": 1,
        "functional_tag": "",
        "functional_tags_json": "[]",
        "type_line": oracle.get("type_line") or "",
        "oracle_text": oracle.get("oracle_text") or "",
        "cmc": oracle.get("cmc") or 0,
        "is_commander": 0,
    }


def commander_colors(conn: sqlite3.Connection, deck_id: str, commander: str) -> list[str]:
    rows = mana_profile.fetch_deck_cards(conn, deck_id)
    oracle_by_name = mana_profile.fetch_oracle_rows(
        conn,
        {str(row.get("card_name") or "") for row in rows} | {commander},
    )
    _commander_name, colors, _source = mana_profile.commander_identity(
        conn=conn,
        deck_rows=rows,
        oracle_by_name=oracle_by_name,
        commander_hint=commander,
    )
    return colors


def expected_missing_cards(strategy_payload: Mapping[str, Any], package_name: str) -> list[str]:
    packages = strategy_payload.get("candidate_expected_package_presence") or {}
    payload = packages.get(package_name) if isinstance(packages, dict) else None
    if not isinstance(payload, Mapping):
        return []
    return [str(card) for card in payload.get("missing_cards") or []]


def existing_name_keys(rows: list[dict[str, Any]]) -> set[str]:
    keys: set[str] = set()
    for row in rows:
        keys.update(land_pool.candidate_keys(str(row.get("card_name") or "")))
    return keys


def commander_legality(legalities: Mapping[str, str], card_name: str) -> str:
    for key in land_pool.candidate_keys(card_name):
        if key in legalities:
            return str(legalities[key])
    return ""


def color_identity(oracle: Mapping[str, Any]) -> list[str]:
    return mana_profile.parse_color_identity(oracle.get("color_identity_json"))


def text(oracle: Mapping[str, Any]) -> str:
    return f"{oracle.get('type_line') or ''}\n{oracle.get('oracle_text') or ''}".lower()


def candidate_score(axis: str, card_name: str, oracle: Mapping[str, Any], roles: set[str], source: str) -> tuple[int, list[str]]:
    body = text(oracle)
    cmc = float(oracle.get("cmc") or 0)
    reasons: list[str] = [source]
    score = 50
    if source == "commander_reference_profile_expected_package":
        score += 30
        reasons.append("profile_expected_package")
    if source == "restore_protected_anchor_to_candidate_package":
        score += 40
        reasons.append("restores_protected_profile_anchor")
    if source == "restore_previous_attack_window_cut":
        score += 35
        reasons.append("restores_removed_attack_window")
    if axis == "spot_interaction":
        if "spot_interaction" in roles:
            score += 35
            reasons.append("role_confirms_spot_interaction")
        if cmc <= 2:
            score += 12
            reasons.append("cheap_interaction")
        if "exile target" in body:
            score += 10
            reasons.append("exile_target_answer")
        if "permanent" in body or "artifact" in body or "enchantment" in body:
            score += 5
            reasons.append("flexible_answer_text")
    elif axis == "angels_demons_dragons_payoffs":
        if "angels_demons_dragons_payoffs" in roles:
            score += 35
            reasons.append("role_confirms_kaalia_payoff")
        if any(pattern in body for pattern in ("additional combat phase", "extra combat", "deals combat damage")):
            score += 12
            reasons.append("combat_damage_or_extra_combat_payoff")
        if any(pattern in body for pattern in ("search your library", "treasure", "indestructible")):
            score += 8
            reasons.append("secondary_payoff_text")
    elif axis == "commander_attack_window":
        if "haste_protection_silence" in roles:
            score += 35
            reasons.append("role_confirms_attack_window_support")
        if "land" in str(oracle.get("type_line") or "").lower():
            score += 8
            reasons.append("also_land_slot_candidate")
        if "haste" in body:
            score += 12
            reasons.append("haste_text")
        if "opponents can't cast" in body or "can't cast spells" in body:
            score += 10
            reasons.append("silence_or_protection_text")
        if "indestructible" in body or "protection" in body:
            score += 8
            reasons.append("protects_attack_window")
    elif axis == "reanimation_plan_b":
        if "reanimation_plan_b" in roles:
            score += 35
            reasons.append("role_confirms_reanimation_plan_b")
        if cmc <= 3:
            score += 10
            reasons.append("cheap_reanimation")
        if "from your graveyard" in body or "from a graveyard" in body:
            score += 8
            reasons.append("graveyard_to_battlefield_text")
        if "return target creature card" in body:
            score += 6
            reasons.append("targeted_creature_reanimation")
    elif axis == "lands":
        if "land" in str(oracle.get("type_line") or "").lower():
            score += 30
            reasons.append("land_slot_candidate")
        if "haste" in body or "commander" in body:
            score += 10
            reasons.append("land_has_commander_synergy")
    elif axis == PROTECTED_ANCHOR_AXIS:
        score += 25
        reasons.append("protected_anchor_restore_axis")
    return score, reasons


def build_card_candidates(
    *,
    conn: sqlite3.Connection,
    axis: str,
    card_names: list[str],
    source: str,
    existing_names: set[str],
    legalities: Mapping[str, str],
    commander_color_identity: list[str],
    limit: int,
) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    seen: set[str] = set()
    for card_name in card_names:
        keys = land_pool.candidate_keys(card_name)
        if not card_name or keys & existing_names or keys & seen:
            continue
        seen.update(keys)
        oracle = oracle_row(conn, card_name)
        colors = color_identity(oracle)
        color_allowed = land_pool.color_identity_allowed(colors, commander_color_identity)
        legality = commander_legality(legalities, card_name)
        role_row = card_row_for_roles(card_name, oracle)
        roles = strategy_matrix.profile_roles_for_card(role_row)
        if not color_allowed or (legality and legality != "legal"):
            status = "blocked_candidate_identity_or_legality"
        elif axis == "angels_demons_dragons_payoffs" and "angels_demons_dragons_payoffs" not in roles:
            status = "blocked_not_commander_payoff_role"
        elif axis == "spot_interaction" and "spot_interaction" not in roles:
            status = "blocked_not_spot_interaction_role"
        elif axis == "commander_attack_window" and not (
            "haste_protection_silence" in roles or strategy_matrix.is_attack_window_card(role_row)
        ):
            status = "blocked_not_attack_window_role"
        elif axis == "reanimation_plan_b" and "reanimation_plan_b" not in roles:
            status = "blocked_not_reanimation_plan_b_role"
        else:
            status = "review_only_profile_repair_add_candidate"
        score, reasons = candidate_score(axis, card_name, oracle, roles, source)
        candidates.append(
            {
                "card_name": oracle.get("name") or card_name,
                "score": score,
                "status": status,
                "axis": axis,
                "source": source,
                "commander_legality": legality or "missing",
                "color_identity": colors,
                "color_identity_allowed": color_allowed,
                "profile_roles": sorted(roles),
                "type_line": oracle.get("type_line") or "",
                "cmc": oracle.get("cmc"),
                "fit_reasons": reasons,
                "mutation_allowed": False,
            }
        )
    candidates.sort(key=lambda row: (row["status"] != "review_only_profile_repair_add_candidate", -int(row["score"]), row["card_name"]))
    return candidates[:limit]


def fake_land_profile(
    *,
    deck_id: str,
    commander: str,
    action: Mapping[str, Any],
    conn: sqlite3.Connection,
) -> dict[str, Any]:
    hypothesis = {
        "deck_id": deck_id,
        "deck_name": None,
        "commander": commander,
        "scope": "profile_blocker_repair",
        "missing": action.get("shortfall_to_min") or 1,
        "current_count": action.get("candidate_count") or 0,
        "target_min": action.get("target_min") or 0,
    }
    return mana_profile.build_profile_for_hypothesis(conn=conn, hypothesis=hypothesis)


def land_candidates_for_action(
    *,
    conn: sqlite3.Connection,
    deck_id: str,
    commander: str,
    action: Mapping[str, Any],
    legalities: Mapping[str, str],
    limit: int,
) -> list[dict[str, Any]]:
    profile = fake_land_profile(deck_id=deck_id, commander=commander, action=action, conn=conn)
    pool = land_pool.build_candidate_pool_for_profile(
        profile=profile,
        all_lands=land_pool.candidate_land_rows(conn),
        existing_names=land_pool.current_deck_names(conn, deck_id),
        legalities=dict(legalities),
        limit=limit,
    )
    candidates = []
    for row in pool.get("top_candidates", []):
        candidate = dict(row)
        candidate["axis"] = "lands"
        candidate["source"] = "global_commander_named_land_candidate_pool"
        candidate["profile_roles"] = ["lands"]
        candidate["mutation_allowed"] = False
        candidates.append(candidate)
    return candidates


def attack_restore_candidates(strategy_payload: Mapping[str, Any]) -> list[str]:
    cards = []
    for row in strategy_payload.get("package_delta") or []:
        if not isinstance(row, Mapping) or row.get("action") != "cut":
            continue
        if "attack_window_or_extra_combat_cut" in [str(flag) for flag in row.get("risk_flags") or []]:
            cards.append(str(row.get("card") or ""))
    return [card for card in cards if card]


def over_target_roles(repair_payload: Mapping[str, Any]) -> set[str]:
    return {
        str(row.get("role"))
        for row in repair_payload.get("over_target_review_roles") or []
        if isinstance(row, Mapping) and row.get("role")
    }


def cut_review_candidates(
    *,
    rows: list[dict[str, Any]],
    over_roles: set[str],
    limit: int,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    candidates: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    for row in rows:
        card_name = str(row.get("card_name") or "")
        if int(row.get("is_commander") or 0):
            continue
        type_line = str(row.get("type_line") or "")
        if "land" in type_line.lower():
            continue
        roles = strategy_matrix.profile_roles_for_card(row)
        core, source = core_roles.card_roles(row)
        risk_flags = strategy_matrix.cut_risk(row)
        blockers: list[str] = []
        if normalize_name(card_name) in GLOBAL_FEEDBACK_STAGE_ONLY_CUTS:
            blockers.append("global_battle_feedback_requires_new_same_lane_or_gate")
        if normalize_name(card_name) in STRUCTURAL_STAPLE_PROTECTED_CUTS:
            blockers.append("structural_foundation_staple_requires_same_lane_or_battle_proof")
        if roles & BLOCKED_HARD_ROLES:
            blockers.extend(f"carries_blocked_role_{role}" for role in sorted(roles & BLOCKED_HARD_ROLES))
        if "attack_window_or_extra_combat_cut" in risk_flags:
            blockers.append("attack_window_cut_not_allowed")
        if strategy_matrix.is_add_payoff(row):
            blockers.append("add_payoff_cut_not_allowed")
        matching = sorted((roles & over_roles) or (core & over_roles))
        if blockers:
            blocked.append(
                {
                    "card_name": card_name,
                    "status": "blocked_profile_repair_cut_candidate",
                    "profile_roles": sorted(roles),
                    "core_roles": sorted(core),
                    "risk_flags": risk_flags,
                    "block_reasons": blockers,
                    "mutation_allowed": False,
                }
            )
            continue
        if not matching:
            continue
        cmc = float(row.get("cmc") or 0)
        score = 30 + (10 * len(matching)) + int(min(cmc, 6))
        reasons = [f"over_target_{role}" for role in matching]
        if "tutors_access" in matching:
            score += 8
            reasons.append("tutor_role_above_target_review")
        if "card_draw_selection" in matching:
            score += 4
            reasons.append("card_flow_above_target_review")
        candidates.append(
            {
                "card_name": card_name,
                "score": score,
                "status": "review_only_profile_repair_cut_candidate",
                "profile_roles": sorted(roles),
                "core_roles": sorted(core),
                "matching_over_target_roles": matching,
                "classification_source": source,
                "cmc": row.get("cmc"),
                "cut_reasons": reasons,
                "mutation_allowed": False,
            }
        )
    candidates.sort(key=lambda row: (-int(row["score"]), row["card_name"]))
    blocked.sort(key=lambda row: row["card_name"])
    return candidates[:limit], blocked[:limit]


def build_axis_pool(
    *,
    conn: sqlite3.Connection,
    action: Mapping[str, Any],
    strategy_payload: Mapping[str, Any],
    deck_id: str,
    commander: str,
    existing_names: set[str],
    legalities: Mapping[str, str],
    commander_color_identity: list[str],
    cut_candidates: list[dict[str, Any]],
    limit: int,
) -> dict[str, Any]:
    axis = str(action.get("repair_axis") or "")
    source_axis = AXIS_SOURCE_ALIASES.get(axis, axis)
    blocker = str(action.get("blocker") or "")
    if source_axis == "lands":
        adds = land_candidates_for_action(
            conn=conn,
            deck_id=deck_id,
            commander=commander,
            action=action,
            legalities=legalities,
            limit=limit,
        )
    elif source_axis == "commander_attack_window":
        restore = build_card_candidates(
            conn=conn,
            axis=source_axis,
            card_names=attack_restore_candidates(strategy_payload),
            source="restore_previous_attack_window_cut",
            existing_names=existing_names,
            legalities=legalities,
            commander_color_identity=commander_color_identity,
            limit=limit,
        )
        expected = build_card_candidates(
            conn=conn,
            axis=source_axis,
            card_names=expected_missing_cards(strategy_payload, ROLE_TO_EXPECTED_PACKAGE[source_axis]),
            source="commander_reference_profile_expected_package",
            existing_names=existing_names,
            legalities=legalities,
            commander_color_identity=commander_color_identity,
            limit=limit,
        )
        adds = sorted(restore + expected, key=lambda row: (row["status"] != "review_only_profile_repair_add_candidate", -int(row["score"]), row["card_name"]))[:limit]
    elif source_axis == PROTECTED_ANCHOR_AXIS:
        adds = build_card_candidates(
            conn=conn,
            axis=source_axis,
            card_names=[str(action.get("protected_card") or "")],
            source="restore_protected_anchor_to_candidate_package",
            existing_names=existing_names,
            legalities=legalities,
            commander_color_identity=commander_color_identity,
            limit=limit,
        )
    else:
        package_name = ROLE_TO_EXPECTED_PACKAGE.get(source_axis)
        adds = build_card_candidates(
            conn=conn,
            axis=source_axis,
            card_names=expected_missing_cards(strategy_payload, package_name or ""),
            source="commander_reference_profile_expected_package",
            existing_names=existing_names,
            legalities=legalities,
            commander_color_identity=commander_color_identity,
            limit=limit,
        )
    ready_adds = [row for row in adds if row.get("status") in {"review_only_profile_repair_add_candidate", "review_only_named_land_candidate"}]
    shortfall = int(action.get("shortfall_to_min") or 0)
    if axis == "angels_demons_dragons_payoffs" and shortfall > len(ready_adds):
        status = "needs_broader_commander_payoff_source_lane_before_materialization"
    elif axis == PROTECTED_ANCHOR_AXIS and ready_adds:
        status = "protected_anchor_restore_requires_package_resynthesis"
    elif not ready_adds:
        status = "needs_add_candidate_source_lane"
    elif not cut_candidates:
        status = "needs_same_lane_or_over_target_cut_source_lane"
    else:
        status = "review_only_profile_repair_candidate_pool_ready"
    return {
        "blocker": blocker,
        "repair_axis": axis,
        "candidate_source_axis": source_axis,
        "candidate_count": len(ready_adds),
        "shortfall_to_min": shortfall,
        "status": status,
        "protected_card": action.get("protected_card"),
        "top_add_candidates": adds,
        "top_cut_candidates": cut_candidates[:limit],
        "mutation_allowed": False,
    }


def materialization_blockers(axis_pools: list[dict[str, Any]]) -> list[str]:
    blockers = []
    for pool in axis_pools:
        status = str(pool.get("status") or "")
        if status != "review_only_profile_repair_candidate_pool_ready":
            axis = str(pool.get("repair_axis") or "")
            if axis == PROTECTED_ANCHOR_AXIS and pool.get("protected_card"):
                blockers.append(f"{axis}:{pool.get('protected_card')}:{status}")
            else:
                blockers.append(f"{axis}:{status}")
    return blockers


def next_gate_for_blockers(blockers: list[str]) -> str:
    if not blockers:
        return "materialize_profile_repair_candidate_copy"
    if any(blocker.startswith(f"{PROTECTED_ANCHOR_AXIS}:") for blocker in blockers):
        return "resynthesize_profile_repair_package_with_protected_anchor_restoration"
    if any("angels_demons_dragons_payoffs" in blocker for blocker in blockers):
        return "expand_commander_payoff_source_lane_before_candidate_copy"
    return "expand_commander_repair_source_lane_before_candidate_copy"


def build_report(
    *,
    repair_plan_report: Path,
    strategy_report: Path,
    sqlite_db: Path | None = None,
    limit: int = 10,
) -> dict[str, Any]:
    repair_payload = load_json(repair_plan_report)
    strategy_payload = load_json(strategy_report)
    summary = strategy_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or (repair_payload.get("summary") or {}).get("deck_id") or "")
    commander = str(summary.get("commander") or (repair_payload.get("summary") or {}).get("commander") or "")
    input_artifacts = strategy_payload.get("input_artifacts") or {}
    db_path = sqlite_db or resolve_repo_path(input_artifacts.get("candidate_db"), DEFAULT_SQLITE_DB)
    with sqlite3.connect(db_path) as conn:
        legalities = land_pool.commander_legality_by_name(conn)
        rows = deck_rows(conn, deck_id)
        colors = commander_colors(conn, deck_id, commander)
        existing = existing_name_keys(rows)
        cuts, blocked_cuts = cut_review_candidates(
            rows=rows,
            over_roles=over_target_roles(repair_payload),
            limit=limit,
        )
        axis_pools = [
            build_axis_pool(
                conn=conn,
                action=action,
                strategy_payload=strategy_payload,
                deck_id=deck_id,
                commander=commander,
                existing_names=existing,
                legalities=legalities,
                commander_color_identity=colors,
                cut_candidates=cuts,
                limit=limit,
            )
            for action in repair_payload.get("repair_actions") or []
            if isinstance(action, Mapping)
        ]
    blockers = materialization_blockers(axis_pools)
    candidate_copy_allowed = not blockers and bool(axis_pools)
    next_gate = next_gate_for_blockers(blockers)
    return {
        "generated_at": utc_now(),
        "status": (
            "profile_repair_candidate_model_ready_for_candidate_copy"
            if candidate_copy_allowed
            else "profile_repair_candidate_model_blocks_materialization"
        ),
        "artifact_type": "global_commander_profile_repair_candidate_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": candidate_copy_allowed,
        "input_artifacts": {
            "repair_plan_report": rel(repair_plan_report),
            "strategy_matrix_report": rel(strategy_report),
            "candidate_db": rel(db_path),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "commander_color_identity": colors,
            "repair_axis_count": len(axis_pools),
            "candidate_copy_blocker_count": len(blockers),
            "cut_candidate_count": len(cuts),
            "blocked_cut_candidate_count": len(blocked_cuts),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "repair_axis_pools": axis_pools,
        "global_cut_review_pool": cuts,
        "blocked_cut_review_pool": blocked_cuts,
        "policy": {
            "repair_boundary": "Candidates are review-only source-lane rows, not deck changes.",
            "materialization_boundary": "Candidate copy opens only when every blocker axis has enough legal candidates and reviewable cuts.",
            "payoff_boundary": "Large commander payoff shortfalls require a broader commander source lane, not a narrow interaction-style swap.",
            "protected_anchor_boundary": "Protected commander anchors can be restored as review candidates, but package resynthesis must prove the replacement cuts before materialization.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Profile Repair Candidate Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- colors: `{''.join(summary['commander_color_identity'])}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- candidate_copy_blocker_count: `{summary['candidate_copy_blocker_count']}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Axis Pools",
        "",
    ]
    for pool in payload["repair_axis_pools"]:
        lines.extend(
            [
                f"### `{pool['repair_axis']}`",
                "",
                f"- blocker: `{pool['blocker']}`",
                f"- status: `{pool['status']}`",
                f"- candidate_count: `{pool['candidate_count']}`",
                f"- shortfall_to_min: `{pool['shortfall_to_min']}`",
                "",
                "| Score | Add Candidate | Status | Roles | Reasons |",
                "| ---: | --- | --- | --- | --- |",
            ]
        )
        for row in pool["top_add_candidates"][:8]:
            lines.append(
                f"| {row.get('score', '-')} | `{row['card_name']}` | `{row['status']}` | `{', '.join(row.get('profile_roles') or []) or '-'}` | {', '.join(row.get('fit_reasons') or row.get('fit_reasons', []) or row.get('fit_reasons') or [])} |"
            )
        lines.extend(["", "| Score | Cut Candidate | Roles | Reasons |", "| ---: | --- | --- | --- |"])
        for row in pool["top_cut_candidates"][:5]:
            lines.append(
                f"| {row.get('score', '-')} | `{row['card_name']}` | `{', '.join(row.get('profile_roles') or []) or '-'}` | {', '.join(row.get('cut_reasons') or [])} |"
            )
        lines.append("")
    lines.extend(["## Candidate-Copy Blockers", ""])
    if payload["candidate_copy_blockers"]:
        for blocker in payload["candidate_copy_blockers"]:
            lines.append(f"- `{blocker}`")
    else:
        lines.append("- none")
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
    parser.add_argument("--repair-plan-report", type=Path, default=DEFAULT_REPAIR_PLAN_REPORT)
    parser.add_argument("--strategy-matrix-report", type=Path, default=DEFAULT_STRATEGY_MATRIX_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--limit", type=int, default=10)
    args = parser.parse_args()
    payload = build_report(
        repair_plan_report=args.repair_plan_report,
        strategy_report=args.strategy_matrix_report,
        sqlite_db=args.db,
        limit=args.limit,
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
