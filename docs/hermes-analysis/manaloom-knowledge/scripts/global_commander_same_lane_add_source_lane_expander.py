#!/usr/bin/env python3
"""Expand same-lane Commander add source lanes after package resynthesis.

This read-only gate consumes the same-lane package resynthesizer and scans the
current evaluation SQLite DB for legal, commander-color-compatible cards that
can explicitly replace each exhausted cut lane. It does not select cuts,
materialize decks, mutate SQLite/PostgreSQL, run battle, or promote a package.
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
import global_commander_mana_base_profile as mana_profile
import global_commander_named_land_candidate_pool as land_pool
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SAME_LANE_RESYNTHESIS_REPORT = (
    REPORT_DIR / "global_commander_same_lane_package_resynthesizer_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_PROFILE_REPAIR_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_same_lane_add_source_lane_expander_20260705_kaalia_value_safe_stage1_repair_scope1"
)

AXIS_TO_PROFILE_ROLE = {
    "commander_attack_window": "haste_protection_silence",
    "mana_acceleration_replacement": "mana_acceleration",
    "tutors_access_replacement": "tutors_access",
}
AXIS_TO_EXPECTED_PACKAGE = {
    "commander_attack_window": "commander_attack_enablers",
    "mana_acceleration_replacement": "mana_ramp_foundation",
    "tutors_access_replacement": "card_flow_and_access",
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


def resolve_working_db(
    *,
    profile_repair_payload: Mapping[str, Any],
    sqlite_db: Path | None,
) -> tuple[Path, dict[str, Any]]:
    if sqlite_db is not None:
        return sqlite_db, {
            "selected_db": rel(sqlite_db),
            "source": "cli_override",
            "selected_db_exists": sqlite_db.exists(),
        }
    inputs = profile_repair_payload.get("input_artifacts") or {}
    candidate_db = resolve_repo_path(inputs.get("candidate_db"), DEFAULT_SQLITE_DB)
    if candidate_db.exists():
        return candidate_db, {
            "selected_db": rel(candidate_db),
            "source": "profile_repair_candidate_db",
            "selected_db_exists": True,
        }
    return DEFAULT_SQLITE_DB, {
        "requested_db": rel(candidate_db),
        "selected_db": rel(DEFAULT_SQLITE_DB),
        "source": "default_sqlite_fallback",
        "selected_db_exists": DEFAULT_SQLITE_DB.exists(),
    }


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def all_oracle_rows(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    if not mana_profile.table_exists(conn, "card_oracle_cache"):
        return []
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT name, normalized_name, mana_cost, colors_json, color_identity_json,
               type_line, oracle_text, cmc, scryfall_id, card_id
        FROM card_oracle_cache
        ORDER BY name
        """
    ).fetchall()
    return [dict(row) for row in rows]


def deck_name_keys(conn: sqlite3.Connection, deck_id: str) -> set[str]:
    if not mana_profile.table_exists(conn, "deck_cards"):
        return set()
    rows = conn.execute(
        "SELECT card_name FROM deck_cards WHERE CAST(deck_id AS TEXT)=?",
        (str(deck_id),),
    ).fetchall()
    out: set[str] = set()
    for row in rows:
        out.update(land_pool.candidate_keys(str(row[0] or "")))
    return out


def format_staples_by_name(conn: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    if not mana_profile.table_exists(conn, "format_staples"):
        return {}
    rows = conn.execute(
        """
        SELECT card_name, archetype, category, color_identity, edhrec_rank
        FROM format_staples
        WHERE lower(format)='commander'
          AND COALESCE(is_banned, 0)=0
        ORDER BY COALESCE(edhrec_rank, 999999), card_name
        """
    ).fetchall()
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(row[0])
        if key and key not in out:
            out[key] = {
                "card_name": row[0],
                "archetype": row[1] or "",
                "category": row[2] or "",
                "color_identity": row[3] or "",
                "edhrec_rank": row[4],
            }
    return out


def commander_legality(legalities: Mapping[str, str], card_name: str) -> str:
    for key in land_pool.candidate_keys(card_name):
        if key in legalities:
            return str(legalities[key] or "").lower()
    return ""


def commander_colors(
    *,
    conn: sqlite3.Connection,
    commander: str,
    same_lane_summary: Mapping[str, Any],
    profile_summary: Mapping[str, Any],
) -> list[str]:
    colors = mana_profile.parse_color_identity(same_lane_summary.get("commander_color_identity"))
    if colors:
        return colors
    colors = mana_profile.parse_color_identity(profile_summary.get("commander_color_identity"))
    if colors:
        return colors
    if mana_profile.table_exists(conn, "card_oracle_cache"):
        row = conn.execute(
            """
            SELECT color_identity_json
            FROM card_oracle_cache
            WHERE lower(name)=lower(?) OR normalized_name=?
            LIMIT 1
            """,
            (commander, normalize_name(commander)),
        ).fetchone()
        if row:
            return mana_profile.parse_color_identity(row[0])
    return []


def profile_for_commander(commander: str) -> Mapping[str, Any]:
    return strategy_matrix.PROFILE_BY_COMMANDER.get(normalize_name(commander), {})


def expected_names_for_axis(commander: str, axis: str) -> set[str]:
    profile = profile_for_commander(commander)
    package_name = AXIS_TO_EXPECTED_PACKAGE.get(axis, "")
    packages = profile.get("expected_packages") or {}
    names = packages.get(package_name) if isinstance(packages, Mapping) else []
    return {normalize_name(name) for name in as_list(names)}


def role_row(row: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "card_name": row.get("name") or row.get("card_name") or "",
        "quantity": 1,
        "functional_tag": "",
        "functional_tags_json": "[]",
        "type_line": row.get("type_line") or "",
        "oracle_text": row.get("oracle_text") or "",
        "cmc": row.get("cmc") or 0,
        "is_commander": 0,
    }


def card_text(row: Mapping[str, Any]) -> str:
    return f"{row.get('type_line') or ''}\n{row.get('oracle_text') or ''}".lower()


def has_any(text: str, patterns: tuple[str, ...]) -> bool:
    return any(pattern in text for pattern in patterns)


def axis_matches(axis: str, row: Mapping[str, Any], profile_roles: set[str], expected_hit: bool) -> bool:
    text = card_text(row)
    if axis == "commander_attack_window":
        return expected_hit or strategy_matrix.is_attack_window_card(row) or has_any(
            text,
            (
                "opponents can't cast",
                "can't cast spells",
                "phase out",
                "prevent all damage",
                "change the target",
                "equipped creature has",
                "creatures you control gain",
                "creatures you control have haste",
                "target creature gains haste",
                "target legendary creature gains haste",
                "permanents you control gain indestructible",
                "protection from",
            ),
        )
    role = AXIS_TO_PROFILE_ROLE.get(axis)
    return bool(role and role in profile_roles)


def axis_score(
    *,
    axis: str,
    row: Mapping[str, Any],
    profile_roles: set[str],
    expected_package_hit: bool,
    staple: Mapping[str, Any] | None,
    legality: str,
) -> tuple[int, list[str], list[str]]:
    text = card_text(row)
    cmc = float(row.get("cmc") or 0)
    score = 35
    reasons: list[str] = []
    sources = ["local_oracle_same_lane_scan"]
    if legality == "legal":
        score += 15
        reasons.append("commander_legal")
    if expected_package_hit:
        score += 24
        reasons.append("commander_expected_package")
        sources.append("commander_reference_profile_expected_package")
    if staple:
        rank = as_int(staple.get("edhrec_rank")) or 999999
        score += max(0, 20 - min(18, rank // 100))
        reasons.append(f"format_staple_rank_{rank}")
        sources.append("format_staples")
    if axis == "commander_attack_window":
        if "haste_protection_silence" in profile_roles:
            score += 20
            reasons.append("profile_role_haste_protection_silence")
        if strategy_matrix.is_attack_window_card(row):
            score += 12
            reasons.append("attack_window_text")
        if has_any(text, ("opponents can't cast", "can't cast spells", "phase out", "prevent all damage")):
            score += 14
            reasons.append("protects_commander_attack_step")
        if has_any(text, ("haste", "creatures you control have haste", "equipped creature has haste")):
            score += 10
            reasons.append("haste_enabler")
        if cmc <= 2:
            score += 7
            reasons.append("cheap_attack_window_support")
    elif axis == "mana_acceleration_replacement":
        if "mana_acceleration" in profile_roles:
            score += 20
            reasons.append("profile_role_mana_acceleration")
        if cmc <= 2:
            score += 10
            reasons.append("cheap_ramp")
        if has_any(text, ("{t}: add", "add one mana", "add two mana", "mana of any color")):
            score += 12
            reasons.append("mana_production_text")
        if has_any(text, ("treasure token", "create a treasure")):
            score += 8
            reasons.append("treasure_ramp_text")
        if "land" in str(row.get("type_line") or "").lower():
            score -= 15
            reasons.append("land_ramp_requires_mana_base_lane_review")
    elif axis == "tutors_access_replacement":
        if "tutors_access" in profile_roles:
            score += 20
            reasons.append("profile_role_tutors_access")
        if "search your library for a card" in text:
            score += 20
            reasons.append("unrestricted_tutor")
        elif "search your library" in text:
            score += 10
            reasons.append("restricted_tutor")
        if has_any(text, ("put that card into your hand", "put it into your hand")):
            score += 8
            reasons.append("tutor_to_hand")
        if has_any(text, ("put that card on top", "put that card into your graveyard")):
            score += 5
            reasons.append("tutor_to_setup_zone")
        if cmc <= 2:
            score += 8
            reasons.append("cheap_tutor_access")
    return score, reasons, sorted(set(sources))


def classify_candidate(
    *,
    axis: str,
    cut_role: str,
    target_cut_count: int,
    row: Mapping[str, Any],
    existing_names: set[str],
    legalities: Mapping[str, str],
    commander_color_identity: list[str],
    expected_names: set[str],
    staple_by_name: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    name = str(row.get("name") or "")
    keys = land_pool.candidate_keys(name)
    colors = mana_profile.parse_color_identity(row.get("color_identity_json"))
    legality = commander_legality(legalities, name)
    row_for_roles = role_row(row)
    profile_roles = strategy_matrix.profile_roles_for_card(row_for_roles)
    expected_hit = bool(keys & expected_names)
    staple = next((staple_by_name.get(key) for key in keys if key in staple_by_name), None)
    score, reasons, source_lanes = axis_score(
        axis=axis,
        row=row_for_roles,
        profile_roles=profile_roles,
        expected_package_hit=expected_hit,
        staple=staple,
        legality=legality,
    )
    block_reasons: list[str] = []
    if not name:
        block_reasons.append("missing_name")
    if keys & existing_names:
        block_reasons.append("already_in_current_evaluation_deck")
    if not land_pool.color_identity_allowed(colors, commander_color_identity):
        block_reasons.append("not_commander_color_identity_compatible")
    if legality != "legal":
        block_reasons.append("missing_or_nonlegal_commander_legality")
    if axis in {"mana_acceleration_replacement", "tutors_access_replacement"} and "lands" in profile_roles:
        block_reasons.append("land_candidate_requires_mana_base_lane_not_same_lane_nonland_replacement")
    if axis == "commander_attack_window" and "lands" in profile_roles and not expected_hit:
        block_reasons.append("land_candidate_requires_expected_attack_window_package_proof")
    if not axis_matches(axis, row_for_roles, profile_roles, expected_hit):
        block_reasons.append("does_not_match_required_same_lane_add_axis")
    status = (
        "blocked_same_lane_add_source_candidate"
        if block_reasons
        else "review_only_same_lane_add_source_candidate"
    )
    return {
        "card_name": name,
        "axis": axis,
        "cut_role": cut_role,
        "target_cut_count": target_cut_count,
        "score": score,
        "status": status,
        "block_reasons": block_reasons,
        "source_lanes": source_lanes,
        "commander_legality": legality or "missing",
        "color_identity": colors,
        "profile_roles": sorted(profile_roles),
        "type_line": row.get("type_line") or "",
        "cmc": row.get("cmc"),
        "fit_reasons": reasons,
        "candidate_copy_allowed": False,
        "required_gates": [
            "same_lane_source_lane_review",
            "same_lane_package_resynthesis",
            "value_safe_cut_pair_proof",
            "candidate_copy_only_after_scope_reducer",
            "strategy_matrix_before_battle",
            "battle_gate_with_drawn_cast_used_trace_before_promotion",
        ],
    }


def requirement_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in payload.get("same_lane_axis_requirements") or []:
        if not isinstance(row, Mapping):
            continue
        axis = str(row.get("required_add_axis") or "")
        cut_role = str(row.get("cut_role") or "")
        if axis and cut_role:
            rows.append(
                {
                    "required_add_axis": axis,
                    "cut_role": cut_role,
                    "target_cut_count": as_int(row.get("target_cut_count")),
                }
            )
    return rows


def expand_requirement(
    *,
    requirement: Mapping[str, Any],
    oracle_rows: list[Mapping[str, Any]],
    commander: str,
    commander_color_identity: list[str],
    existing_names: set[str],
    legalities: Mapping[str, str],
    staple_by_name: Mapping[str, Mapping[str, Any]],
    limit: int,
) -> dict[str, Any]:
    axis = str(requirement["required_add_axis"])
    cut_role = str(requirement["cut_role"])
    expected = expected_names_for_axis(commander, axis)
    classified = [
        classify_candidate(
            axis=axis,
            cut_role=cut_role,
            target_cut_count=as_int(requirement.get("target_cut_count")),
            row=row,
            existing_names=existing_names,
            legalities=legalities,
            commander_color_identity=commander_color_identity,
            expected_names=expected,
            staple_by_name=staple_by_name,
        )
        for row in oracle_rows
    ]
    ready = sorted(
        [row for row in classified if row["status"] == "review_only_same_lane_add_source_candidate"],
        key=lambda row: (-as_int(row.get("score")), str(row.get("card_name") or "")),
    )
    blocked = sorted(
        [row for row in classified if row["status"] != "review_only_same_lane_add_source_candidate"],
        key=lambda row: (row.get("block_reasons") or [], -as_int(row.get("score")), str(row.get("card_name") or "")),
    )
    return {
        "required_add_axis": axis,
        "cut_role": cut_role,
        "target_cut_count": as_int(requirement.get("target_cut_count")),
        "status": (
            "same_lane_add_source_lane_ready_for_package_resynthesis"
            if ready
            else "same_lane_add_source_lane_missing_candidates"
        ),
        "ready_candidate_count": len(ready),
        "blocked_candidate_sample_count": min(len(blocked), limit),
        "expected_profile_name_count": len(expected),
        "candidate_copy_allowed": False,
        "top_candidates": ready[:limit],
        "blocked_candidate_sample": blocked[:limit],
    }


def build_report(
    *,
    same_lane_resynthesis_report: Path,
    profile_repair_report: Path,
    sqlite_db: Path | None = None,
    limit: int = 20,
) -> dict[str, Any]:
    same_lane_payload = load_json(same_lane_resynthesis_report)
    profile_payload = load_json(profile_repair_report)
    same_summary = same_lane_payload.get("summary") or {}
    profile_summary = profile_payload.get("summary") or {}
    deck_id = str(same_summary.get("deck_id") or profile_summary.get("deck_id") or "")
    commander = str(same_summary.get("commander") or profile_summary.get("commander") or "")
    db_path, db_resolution = resolve_working_db(
        profile_repair_payload=profile_payload,
        sqlite_db=sqlite_db,
    )
    with sqlite3.connect(db_path) as conn:
        colors = commander_colors(
            conn=conn,
            commander=commander,
            same_lane_summary=same_summary,
            profile_summary=profile_summary,
        )
        existing = deck_name_keys(conn, deck_id)
        legalities = land_pool.commander_legality_by_name(conn)
        staple_by_name = format_staples_by_name(conn)
        oracle_rows = all_oracle_rows(conn)
        source_lanes = [
            expand_requirement(
                requirement=requirement,
                oracle_rows=oracle_rows,
                commander=commander,
                commander_color_identity=colors,
                existing_names=existing,
                legalities=legalities,
                staple_by_name=staple_by_name,
                limit=limit,
            )
            for requirement in requirement_rows(same_lane_payload)
        ]
    ready_axis_count = sum(1 for lane in source_lanes if as_int(lane.get("ready_candidate_count")) > 0)
    missing_axes = [lane["required_add_axis"] for lane in source_lanes if as_int(lane.get("ready_candidate_count")) == 0]
    all_ready = bool(source_lanes) and ready_axis_count == len(source_lanes)
    return {
        "generated_at": utc_now(),
        "status": (
            "same_lane_add_source_lanes_expanded_no_deck_action"
            if all_ready
            else "same_lane_add_source_lanes_need_external_research"
        ),
        "artifact_type": "global_commander_same_lane_add_source_lane_expander",
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
        "input_artifacts": {
            "same_lane_resynthesis_report": rel(same_lane_resynthesis_report),
            "profile_repair_report": rel(profile_repair_report),
            "selected_db": rel(db_path),
        },
        "db_resolution": db_resolution,
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "commander_color_identity": colors,
            "requirement_count": len(source_lanes),
            "ready_axis_count": ready_axis_count,
            "missing_axis_count": len(missing_axes),
            "missing_axes": missing_axes,
            "ready_candidate_count_by_axis": {
                str(lane["required_add_axis"]): as_int(lane.get("ready_candidate_count"))
                for lane in source_lanes
            },
            "next_gate": (
                "resynthesize_same_lane_package_from_source_lanes_before_cut_pairing"
                if all_ready
                else "external_same_lane_source_research_for_missing_axes"
            ),
        },
        "source_lanes": source_lanes,
        "candidate_copy_blockers": [
            "source_lanes_are_review_only_not_deck_actions",
            "value_safe_cut_pairs_still_missing",
            "candidate_copy_closed_until_resynthesized_package_and_scope_reducer_pass",
            *(
                [f"missing_same_lane_add_source_axes:{','.join(missing_axes)}"]
                if missing_axes
                else []
            ),
        ],
        "policy": {
            "source_lane_boundary": "Same-lane add source candidates are evidence rows, not deck changes.",
            "same_lane_boundary": "Candidates must explicitly match the required add axis; incidental payoff text is not enough.",
            "cut_boundary": "This report does not reclassify any cut as value-safe.",
            "battle_boundary": "No battle or promotion opens before package resynthesis, scope reduction, candidate copy, strategy matrix, and replay gates.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Add Source Lane Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- colors: `{''.join(summary['commander_color_identity'])}`",
        f"- requirement_count: `{summary['requirement_count']}`",
        f"- ready_axis_count: `{summary['ready_axis_count']}`",
        f"- missing_axis_count: `{summary['missing_axis_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Source Lanes",
        "",
        "| Axis | Cut Role | Target Cuts | Ready Candidates | Status |",
        "| --- | --- | ---: | ---: | --- |",
    ]
    for lane in payload["source_lanes"]:
        lines.append(
            "| `{axis}` | `{role}` | {target} | {ready} | `{status}` |".format(
                axis=lane.get("required_add_axis"),
                role=lane.get("cut_role"),
                target=lane.get("target_cut_count"),
                ready=lane.get("ready_candidate_count"),
                status=lane.get("status"),
            )
        )
    for lane in payload["source_lanes"]:
        lines.extend(["", f"## Top Candidates - `{lane.get('required_add_axis')}`", ""])
        lines.extend(["| Score | Candidate | Roles | Sources | Reasons |", "| ---: | --- | --- | --- | --- |"])
        for row in lane.get("top_candidates") or []:
            lines.append(
                "| {score} | `{name}` | `{roles}` | `{sources}` | {reasons} |".format(
                    score=row.get("score"),
                    name=row.get("card_name"),
                    roles=", ".join(row.get("profile_roles") or []),
                    sources=", ".join(row.get("source_lanes") or []),
                    reasons=", ".join(row.get("fit_reasons") or []),
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
    parser.add_argument("--same-lane-resynthesis-report", type=Path, default=DEFAULT_SAME_LANE_RESYNTHESIS_REPORT)
    parser.add_argument("--profile-repair-report", type=Path, default=DEFAULT_PROFILE_REPAIR_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--limit", type=int, default=20)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        same_lane_resynthesis_report=args.same_lane_resynthesis_report,
        profile_repair_report=args.profile_repair_report,
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
