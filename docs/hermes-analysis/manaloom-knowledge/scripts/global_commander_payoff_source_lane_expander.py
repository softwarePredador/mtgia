#!/usr/bin/env python3
"""Expand Commander payoff source lanes before broad repair materialization.

This read-only gate consumes the profile repair candidate model and scans local
Oracle/Hermes rows for legal, commander-color-compatible payoff cards. It
does not mutate decks, run battles, or authorize promotion.
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
import global_commander_named_land_candidate_pool as land_pool
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REPAIR_CANDIDATE_MODEL_REPORT = (
    REPORT_DIR / "global_commander_profile_repair_candidate_model_20260705_kaalia_removal_floor_step5.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_payoff_source_lane_expander_20260705_kaalia_removal_floor_step5"
)
DEFAULT_ADD_ROLE = "angels_demons_dragons_payoffs"
SPELL_PAYOFF_ROLE = "spell_payoffs_copy_engines"
SUPPORTED_PAYOFF_AXES = (DEFAULT_ADD_ROLE, SPELL_PAYOFF_ROLE)


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


def resolve_working_db(*, payload: Mapping[str, Any], sqlite_db: Path | None) -> tuple[Path, dict[str, Any]]:
    if sqlite_db is not None:
        return sqlite_db, {
            "requested_db": rel(sqlite_db),
            "selected_db": rel(sqlite_db),
            "source": "cli_override",
            "candidate_db_exists": sqlite_db.exists(),
            "fallback_used": False,
        }
    input_artifacts = payload.get("input_artifacts") or {}
    candidate_db = resolve_repo_path(input_artifacts.get("candidate_db"), DEFAULT_SQLITE_DB)
    if candidate_db.exists():
        return candidate_db, {
            "requested_db": rel(candidate_db),
            "selected_db": rel(candidate_db),
            "source": "repair_candidate_model_candidate_db",
            "candidate_db_exists": True,
            "fallback_used": False,
        }
    strategy_report = resolve_repo_path(input_artifacts.get("strategy_matrix_report"), Path())
    strategy_payload = load_json(strategy_report) if strategy_report.exists() else {}
    strategy_inputs = strategy_payload.get("input_artifacts") or {}
    base_db = resolve_repo_path(strategy_inputs.get("base_db"), DEFAULT_SQLITE_DB)
    return base_db, {
        "requested_db": rel(candidate_db),
        "selected_db": rel(base_db),
        "source": "strategy_matrix_base_db_fallback",
        "candidate_db_exists": False,
        "fallback_used": True,
        "fallback_reason": "candidate_db_missing_local_ignored_artifact",
        "strategy_matrix_report": rel(strategy_report) if strategy_report else "",
    }


def deck_name_keys(conn: sqlite3.Connection, deck_id: str) -> set[str]:
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT card_name FROM deck_cards WHERE CAST(deck_id AS TEXT)=?",
        (str(deck_id),),
    ).fetchall()
    keys: set[str] = set()
    for row in rows:
        keys.update(land_pool.candidate_keys(str(row["card_name"] or "")))
    return keys


def expected_package_names(payload: Mapping[str, Any], add_role: str) -> set[str]:
    out: set[str] = set()
    for pool in payload.get("repair_axis_pools") or []:
        if not isinstance(pool, Mapping) or pool.get("repair_axis") != add_role:
            continue
        for row in pool.get("top_add_candidates") or []:
            if isinstance(row, Mapping):
                out.update(land_pool.candidate_keys(str(row.get("card_name") or "")))
    return out


def payoff_axis(payload: Mapping[str, Any]) -> dict[str, Any]:
    pools = [
        pool
        for pool in payload.get("repair_axis_pools") or []
        if isinstance(pool, Mapping) and pool.get("repair_axis") in SUPPORTED_PAYOFF_AXES
    ]
    for pool in pools:
        if pool.get("status") == "needs_add_candidate_source_lane":
            return dict(pool)
    for pool in pools:
        if not pool.get("top_add_candidates"):
            return dict(pool)
    for pool in payload.get("repair_axis_pools") or []:
        if isinstance(pool, Mapping) and pool.get("repair_axis") == DEFAULT_ADD_ROLE:
            return dict(pool)
    return {}


def commander_legality(legalities: Mapping[str, str], card_name: str) -> str:
    for key in land_pool.candidate_keys(card_name):
        if key in legalities:
            return str(legalities[key])
    return ""


def all_oracle_payoff_rows(conn: sqlite3.Connection, *, add_role: str) -> list[dict[str, Any]]:
    conn.row_factory = sqlite3.Row
    if add_role == SPELL_PAYOFF_ROLE:
        rows = conn.execute(
            """
            SELECT name, normalized_name, mana_cost, colors_json, color_identity_json,
                   type_line, oracle_text, cmc, scryfall_id, card_id
            FROM card_oracle_cache
            WHERE lower(type_line) NOT LIKE '%land%'
              AND (
                lower(oracle_text) LIKE '%copy target instant%'
                OR lower(oracle_text) LIKE '%copy target sorcery%'
                OR lower(oracle_text) LIKE '%copy that spell%'
                OR lower(oracle_text) LIKE '%whenever you cast or copy an instant or sorcery%'
                OR lower(oracle_text) LIKE '%whenever you cast a noncreature spell%'
                OR lower(oracle_text) LIKE '%magecraft%'
                OR lower(oracle_text) LIKE '%spells you cast cost%'
                OR lower(oracle_text) LIKE '%costs less to cast%'
                OR lower(oracle_text) LIKE '%create a treasure token%'
                OR lower(oracle_text) LIKE '%create a 1/1%'
              )
            ORDER BY name
            """
        ).fetchall()
        return [dict(row) for row in rows]
    rows = conn.execute(
        """
        SELECT name, normalized_name, mana_cost, colors_json, color_identity_json,
               type_line, oracle_text, cmc, scryfall_id, card_id
        FROM card_oracle_cache
        WHERE lower(type_line) LIKE '%creature%'
          AND (
            lower(type_line) LIKE '%angel%'
            OR lower(type_line) LIKE '%demon%'
            OR lower(type_line) LIKE '%dragon%'
          )
        ORDER BY name
        """
    ).fetchall()
    return [dict(row) for row in rows]


def profile_roles(row: Mapping[str, Any]) -> set[str]:
    return strategy_matrix.profile_roles_for_card(
        {
            "card_name": row.get("name") or row.get("card_name"),
            "quantity": 1,
            "functional_tag": "",
            "functional_tags_json": "[]",
            "type_line": row.get("type_line") or "",
            "oracle_text": row.get("oracle_text") or "",
            "cmc": row.get("cmc") or 0,
            "is_commander": 0,
        }
    )


def card_text(row: Mapping[str, Any]) -> str:
    return f"{row.get('type_line') or ''}\n{row.get('oracle_text') or ''}".lower()


def impact_score(
    *,
    row: Mapping[str, Any],
    expected_package: bool,
    legality: str,
    add_role: str,
) -> tuple[int, list[str]]:
    body = card_text(row)
    cmc = float(row.get("cmc") or 0)
    score = 40
    reasons: list[str] = []
    if legality == "legal":
        score += 15
        reasons.append("commander_legal")
    elif not legality:
        score -= 10
        reasons.append("missing_commander_legality")
    else:
        score -= 100
        reasons.append(f"commander_legality_{legality}")
    if expected_package:
        score += 25
        reasons.append("profile_expected_package")
    if add_role == SPELL_PAYOFF_ROLE:
        if 2 <= cmc <= 5:
            score += 12
            reasons.append("castable_spell_engine_curve")
        elif 6 <= cmc <= 7:
            score += 4
            reasons.append("high_curve_spell_engine_review")
        elif cmc > 7:
            score -= 4
            reasons.append("too_expensive_spell_engine_review")
        if "whenever you cast or copy an instant or sorcery" in body or "magecraft" in body:
            score += 16
            reasons.append("magecraft_spell_payoff")
        if "whenever you cast a noncreature spell" in body or "whenever you cast an instant or sorcery" in body:
            score += 14
            reasons.append("spell_cast_payoff")
        if "copy target instant" in body or "copy target sorcery" in body or "copy that spell" in body:
            score += 14
            reasons.append("spell_copy_payoff")
        if "spells you cast cost" in body or "costs less to cast" in body:
            score += 12
            reasons.append("spell_cost_reduction")
        if "create a treasure token" in body or "treasure token" in body:
            score += 10
            reasons.append("treasure_spell_conversion")
        if "create a 1/1" in body:
            score += 8
            reasons.append("token_spell_payoff")
        if "draw" in body or "exile the top" in body:
            score += 8
            reasons.append("card_flow_payload")
        return score, reasons
    if 5 <= cmc <= 8:
        score += 12
        reasons.append("kaalia_cheat_curve")
    elif cmc > 8:
        score += 6
        reasons.append("expensive_cheat_target")
    elif cmc <= 4:
        score -= 5
        reasons.append("low_payoff_body_review")
    if "flying" in body:
        score += 8
        reasons.append("evasive_body")
    if "haste" in body:
        score += 7
        reasons.append("haste")
    if "trample" in body or "double strike" in body or "first strike" in body:
        score += 5
        reasons.append("combat_keywords")
    if "whenever this creature deals combat damage" in body or ("whenever " in body and "deals combat damage" in body):
        score += 15
        reasons.append("combat_damage_trigger")
    if "whenever this creature attacks" in body or ("whenever " in body and " attacks" in body):
        score += 12
        reasons.append("attack_trigger")
    if "when this creature enters" in body or ("when " in body and " enters" in body):
        score += 10
        reasons.append("etb_value")
    if "search your library" in body:
        score += 14
        reasons.append("tutor_payload")
    if "treasure" in body or "add " in body:
        score += 9
        reasons.append("mana_or_treasure_payload")
    if "destroy" in body or "exile target" in body or "damage to any target" in body:
        score += 9
        reasons.append("removal_payload")
    if "draw" in body or "exile the top" in body or "play them" in body:
        score += 8
        reasons.append("card_flow_payload")
    if "indestructible" in body or "protection" in body or "can't be activated" in body:
        score += 8
        reasons.append("protection_or_lock_payload")
    if "additional combat phase" in body or "untap all attacking creatures" in body:
        score += 16
        reasons.append("extra_combat_payload")
    if "life total becomes 1" in body or "lose twice" in body or "deals that much damage" in body:
        score += 12
        reasons.append("life_total_or_damage_multiplier")
    return score, reasons


def build_candidate_rows(
    *,
    conn: sqlite3.Connection,
    payload: Mapping[str, Any],
    deck_id: str,
    commander_colors: list[str],
    limit: int,
    add_role: str,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    existing = deck_name_keys(conn, deck_id)
    expected = expected_package_names(payload, add_role)
    legalities = land_pool.commander_legality_by_name(conn)
    candidates: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    seen: set[str] = set()
    local_source = "local_oracle_spell_payoff_scan" if add_role == SPELL_PAYOFF_ROLE else "local_oracle_add_type_scan"
    for row in all_oracle_payoff_rows(conn, add_role=add_role):
        card_name = str(row.get("name") or "")
        keys = land_pool.candidate_keys(card_name)
        if not keys or keys & seen:
            continue
        seen.update(keys)
        colors = land_pool.mana_profile.parse_color_identity(row.get("color_identity_json"))
        roles = profile_roles(row)
        legality = commander_legality(legalities, card_name)
        block_reasons: list[str] = []
        if keys & existing:
            block_reasons.append("already_in_candidate_deck")
        if not set(colors).issubset(set(commander_colors)):
            block_reasons.append("not_commander_color_identity_compatible")
        if legality and legality != "legal":
            block_reasons.append(f"commander_legality_{legality}")
        if add_role not in roles:
            block_reasons.append(f"not_profile_{add_role}")
        score, reasons = impact_score(
            row=row,
            expected_package=bool(keys & expected),
            legality=legality,
            add_role=add_role,
        )
        base = {
            "card_name": card_name,
            "score": score,
            "source": "profile_expected_package" if keys & expected else local_source,
            "commander_legality": legality or "missing",
            "color_identity": colors,
            "profile_roles": sorted(roles),
            "type_line": row.get("type_line") or "",
            "cmc": row.get("cmc"),
            "fit_reasons": reasons,
            "mutation_allowed": False,
        }
        if block_reasons:
            blocked.append(
                {
                    **base,
                    "status": "blocked_commander_payoff_source_candidate",
                    "block_reasons": block_reasons,
                }
            )
            continue
        candidates.append(
            {
                **base,
                "status": "review_only_commander_payoff_source_candidate",
                "required_gates": [
                    "source_lane_package_synthesis",
                    "profile_repair_candidate_model_recheck",
                    "candidate_copy_only",
                    "strategy_matrix_before_battle",
                    "battle_gate_with_drawn_cast_used_trace_before_promotion",
                ],
            }
        )
    candidates.sort(key=lambda item: (-int(item["score"]), item["card_name"]))
    blocked.sort(key=lambda item: (item.get("block_reasons", []), -int(item["score"]), item["card_name"]))
    return candidates[:limit], blocked[:limit]


def build_report(
    *,
    repair_candidate_model_report: Path,
    sqlite_db: Path | None = None,
    limit: int = 30,
) -> dict[str, Any]:
    payload = load_json(repair_candidate_model_report)
    summary = payload.get("summary") or {}
    db_path, db_resolution = resolve_working_db(payload=payload, sqlite_db=sqlite_db)
    deck_id = str(summary.get("deck_id") or "")
    commander = str(summary.get("commander") or "")
    colors = [str(color) for color in summary.get("commander_color_identity") or []]
    axis = payoff_axis(payload)
    add_role = str(axis.get("repair_axis") or DEFAULT_ADD_ROLE)
    shortfall = int(axis.get("shortfall_to_min") or 0)
    with sqlite3.connect(db_path) as conn:
        candidates, blocked = build_candidate_rows(
            conn=conn,
            payload=payload,
            deck_id=deck_id,
            commander_colors=colors,
            limit=limit,
            add_role=add_role,
        )
    ready_count = len(candidates)
    covers = ready_count >= shortfall if shortfall else bool(candidates)
    status = (
        "commander_payoff_source_lane_expanded"
        if covers
        else "commander_payoff_source_lane_needs_external_or_oracle_backfill"
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_payoff_source_lane_expander",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "input_artifacts": {
            "repair_candidate_model_report": rel(repair_candidate_model_report),
            "candidate_db": rel(db_path),
        },
        "db_resolution": db_resolution,
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "commander_color_identity": colors,
            "repair_axis": add_role,
            "shortfall_to_min": shortfall,
            "ready_candidate_count": ready_count,
            "blocked_candidate_count_sample": len(blocked),
            "ready_candidates_cover_shortfall": covers,
            "next_gate": (
                "synthesize_commander_payoff_package_before_candidate_copy"
                if covers
                else "external_reference_or_oracle_backfill_for_payoffs"
            ),
        },
        "top_payoff_candidates": candidates,
        "blocked_payoff_candidate_sample": blocked,
        "policy": {
            "source_lane_boundary": "Expanded payoff candidates are source evidence, not deck changes.",
            "package_boundary": "Large payoff repairs require package synthesis before candidate-copy materialization.",
            "battle_boundary": "No battle gate opens until a candidate copy passes strategy matrix and replay exposure gates.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Payoff Source Lane Expander",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- colors: `{''.join(summary['commander_color_identity'])}`",
        f"- repair_axis: `{summary['repair_axis']}`",
        f"- shortfall_to_min: `{summary['shortfall_to_min']}`",
        f"- ready_candidate_count: `{summary['ready_candidate_count']}`",
        f"- ready_candidates_cover_shortfall: `{str(summary['ready_candidates_cover_shortfall']).lower()}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Top Payoff Candidates",
        "",
        "| Score | Candidate | Source | Roles | Reasons |",
        "| ---: | --- | --- | --- | --- |",
    ]
    for row in payload["top_payoff_candidates"]:
        lines.append(
            "| {score} | `{name}` | `{source}` | `{roles}` | {reasons} |".format(
                score=row["score"],
                name=row["card_name"],
                source=row["source"],
                roles=", ".join(row.get("profile_roles") or []) or "-",
                reasons=", ".join(row.get("fit_reasons") or []),
            )
        )
    lines.extend(["", "## Blocked Candidate Sample", ""])
    if payload["blocked_payoff_candidate_sample"]:
        for row in payload["blocked_payoff_candidate_sample"][:12]:
            lines.append(f"- `{row['card_name']}`: `{', '.join(row.get('block_reasons') or [])}`")
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
    parser.add_argument("--repair-candidate-model-report", type=Path, default=DEFAULT_REPAIR_CANDIDATE_MODEL_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--limit", type=int, default=30)
    args = parser.parse_args()
    payload = build_report(
        repair_candidate_model_report=args.repair_candidate_model_report,
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
