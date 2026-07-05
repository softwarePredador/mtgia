#!/usr/bin/env python3
"""Build review-only nonland core repair candidates for Commander decks.

This model is intentionally narrower than a deck optimizer. It handles missing
nonland core roles after the core repair hypothesis audit. For roles with a
trusted local candidate lane, such as removal staples, it builds add/cut
hypotheses. For roles that require commander-specific win-plan proof, such as
wincon, it keeps the deck blocked on source-lane evidence.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_core_role_audit as core_roles
import global_commander_land_cut_candidate_model as land_cuts
import global_commander_named_land_candidate_pool as land_pool
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REPAIR_HYPOTHESIS_REPORT = (
    REPORT_DIR / "global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.json"
)
DEFAULT_CORE_ROLE_REPORT = REPORT_DIR / "global_commander_core_role_audit_20260705_global_goal_hermes_only.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_nonland_core_candidate_model_20260705_global_goal_hermes_only"

SUPPORTED_CANDIDATE_ROLES = {"removal", "draw", "ramp", "board_wipe", "protection", "recursion"}
SOURCE_LANE_ONLY_ROLES = {"wincon"}
ROLE_TO_FORMAT_STAPLE_ARCHETYPES = {
    "ramp": ["ramp"],
    "draw": ["draw"],
    "removal": ["removal"],
    "board_wipe": ["removal"],
    "protection": [],
    "recursion": [],
}
KAALIA_PAYOFF_TYPES = {"angel", "demon", "dragon"}


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


def as_int(value: object) -> int:
    return land_cuts.as_int(value)


def normalize_name(value: object) -> str:
    return land_pool.mana_profile.normalize_name(value)


def core_deck_by_id(core_payload: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {str(row.get("deck_id")): row for row in core_payload.get("decks", [])}


def commander_colors_for_deck(conn: sqlite3.Connection, deck_id: str, commander_hint: str) -> list[str]:
    rows = land_pool.mana_profile.fetch_deck_cards(conn, deck_id)
    oracle_by_name = land_pool.mana_profile.fetch_oracle_rows(
        conn,
        {str(row.get("card_name") or "") for row in rows} | {commander_hint},
    )
    _name, colors, _source = land_pool.mana_profile.commander_identity(
        conn=conn,
        deck_rows=rows,
        oracle_by_name=oracle_by_name,
        commander_hint=commander_hint,
    )
    return colors


def oracle_row_for_card(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    rows = land_pool.mana_profile.fetch_oracle_rows(conn, {card_name})
    return rows.get(normalize_name(card_name), {})


def commander_legality(conn: sqlite3.Connection, card_name: str) -> str:
    legalities = land_pool.commander_legality_by_name(conn)
    for key in land_pool.candidate_keys(card_name):
        if key in legalities:
            return legalities[key]
    return ""


def candidate_color_identity(candidate: dict[str, Any], oracle: dict[str, Any]) -> list[str]:
    colors = land_pool.mana_profile.parse_color_identity(oracle.get("color_identity_json"))
    if colors:
        return colors
    return land_pool.mana_profile.parse_color_identity(candidate.get("color_identity"))


def candidate_score(
    *,
    role: str,
    candidate: dict[str, Any],
    oracle: dict[str, Any],
    legality_status: str,
) -> tuple[int, list[str]]:
    reasons: list[str] = []
    rank = as_int(candidate.get("edhrec_rank")) or 999999
    score = max(0, 80 - min(60, rank // 25))
    reasons.append(f"format_staple_rank_{rank}")
    if legality_status == "legal":
        score += 15
        reasons.append("commander_legal")
    elif not legality_status:
        score -= 20
        reasons.append("missing_commander_legality")
    else:
        score -= 100
        reasons.append(f"commander_legality_{legality_status}")
    type_line = str(oracle.get("type_line") or "")
    oracle_text = str(oracle.get("oracle_text") or "").lower()
    cmc = float(oracle.get("cmc") or 0)
    if "land" in type_line.lower():
        score -= 35
        reasons.append("land_candidate_blocked_for_nonland_core_gap")
    if role == "removal":
        if cmc <= 2:
            score += 12
            reasons.append("cheap_interaction")
        if any(pattern in oracle_text for pattern in ("exile target", "destroy target", "counter target")):
            score += 14
            reasons.append("direct_targeted_answer")
        if any(
            pattern in oracle_text
            for pattern in (
                "damage to target",
                "damage divided as you choose among any number of target",
                "target creature gets -",
                "target creature an opponent controls gets -",
            )
        ):
            score += 10
            reasons.append("damage_or_debuff_answer")
        if any(
            pattern in oracle_text
            for pattern in (
                "destroy all",
                "exile all",
                "each player sacrifices",
                "each opponent sacrifices",
                "all creatures get -",
            )
        ):
            score += 8
            reasons.append("sweeper_or_sacrifice_answer")
        if "enchantment" in oracle_text or "artifact" in oracle_text or "permanent" in oracle_text:
            score += 6
            reasons.append("flexible_answer_text")
        if (
            "blink" in oracle_text
            or "exile target creature you control" in oracle_text
            or "exile another target creature you control" in oracle_text
        ):
            score -= 80
            reasons.append("blink_or_self_target_not_primary_removal")
    return score, reasons


def role_text_allowed(role: str, reasons: list[str]) -> bool:
    if role != "removal":
        return True
    if "blink_or_self_target_not_primary_removal" in reasons:
        return False
    answer_reasons = {
        "direct_targeted_answer",
        "damage_or_debuff_answer",
        "sweeper_or_sacrifice_answer",
    }
    return bool(answer_reasons & set(reasons))


def format_staple_candidates_for_role(
    conn: sqlite3.Connection,
    *,
    role: str,
    existing_names: set[str],
    limit: int,
) -> list[dict[str, Any]]:
    archetypes = ROLE_TO_FORMAT_STAPLE_ARCHETYPES.get(role, [])
    if not archetypes or not land_pool.mana_profile.table_exists(conn, "format_staples"):
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
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in rows:
        card_name = str(row[0] or "")
        keys = land_pool.candidate_keys(card_name)
        if not card_name or keys & existing_names or keys & seen:
            continue
        seen.update(keys)
        out.append(
            {
                "card_name": card_name,
                "source": "format_staples_expanded_role_pool",
                "archetype": row[1] or "",
                "category": row[2] or "",
                "color_identity": row[3] or "",
                "edhrec_rank": row[4],
            }
        )
        if len(out) >= limit:
            break
    return out


def merged_candidate_sources(
    conn: sqlite3.Connection,
    *,
    hypothesis: dict[str, Any],
    existing_names: set[str],
    limit: int,
) -> list[dict[str, Any]]:
    role = str(hypothesis.get("role") or "")
    raw = list(hypothesis.get("review_candidates", []))
    raw.extend(
        format_staple_candidates_for_role(
            conn,
            role=role,
            existing_names=existing_names,
            limit=limit * 6,
        )
    )
    out: list[dict[str, Any]] = []
    seen: set[str] = set()
    for candidate in raw:
        card_name = str(candidate.get("card_name") or "")
        keys = land_pool.candidate_keys(card_name)
        if not card_name or keys & existing_names or keys & seen:
            continue
        seen.update(keys)
        out.append(candidate)
    return out


def build_candidates_for_hypothesis(
    *,
    conn: sqlite3.Connection,
    hypothesis: dict[str, Any],
    commander_colors: list[str],
    existing_names: set[str],
    limit: int,
) -> list[dict[str, Any]]:
    role = str(hypothesis.get("role") or "")
    candidates: list[dict[str, Any]] = []
    for candidate in merged_candidate_sources(
        conn,
        hypothesis=hypothesis,
        existing_names=existing_names,
        limit=limit,
    ):
        card_name = str(candidate.get("card_name") or "")
        oracle = oracle_row_for_card(conn, card_name)
        colors = candidate_color_identity(candidate, oracle)
        if not land_pool.color_identity_allowed(colors, commander_colors):
            continue
        legality = commander_legality(conn, card_name)
        if legality and legality != "legal":
            continue
        score, reasons = candidate_score(
            role=role,
            candidate=candidate,
            oracle=oracle,
            legality_status=legality,
        )
        if "land_candidate_blocked_for_nonland_core_gap" in reasons:
            continue
        if not role_text_allowed(role, reasons):
            continue
        candidates.append(
            {
                "card_name": card_name,
                "score": score,
                "status": "review_only_nonland_core_candidate"
                if legality == "legal"
                else "review_only_requires_commander_legality_check",
                "role": role,
                "source": candidate.get("source"),
                "archetype": candidate.get("archetype") or "",
                "category": candidate.get("category") or "",
                "edhrec_rank": candidate.get("edhrec_rank"),
                "commander_legality": legality or "missing",
                "color_identity": colors,
                "type_line": oracle.get("type_line") or "",
                "cmc": oracle.get("cmc"),
                "fit_reasons": reasons,
                "mutation_allowed": False,
            }
        )
    candidates.sort(key=lambda row: (-as_int(row["score"]), str(row["card_name"])))
    return candidates[:limit]


def commander_specific_cut_blockers(commander: str, row: dict[str, Any]) -> list[str]:
    blockers: list[str] = []
    commander_key = normalize_name(commander)
    card_name = normalize_name(row.get("card_name"))
    type_line = str(row.get("type_line") or "").lower()
    if commander_key == "kaalia of the vast":
        if "creature" in type_line and any(payoff_type in type_line for payoff_type in KAALIA_PAYOFF_TYPES):
            blockers.append("kaalia_angel_demon_dragon_payoff_requires_source_lane")
        if card_name == "master of cruelties":
            blockers.append("kaalia_master_of_cruelties_combo_anchor_requires_source_lane")
    return blockers


def cross_lane_cut_blockers(target_role: str, roles: set[str]) -> list[str]:
    blockers: list[str] = []
    if target_role != "ramp" and "ramp" in roles:
        blockers.append("cross_lane_ramp_cut_requires_same_lane_source_or_gate")
    return blockers


def cut_candidates_for_hypothesis(
    *,
    conn: sqlite3.Connection,
    hypothesis: dict[str, Any],
    core_row: dict[str, Any],
    limit: int,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    deck_id = str(hypothesis.get("deck_id"))
    commander = str(hypothesis.get("commander") or "")
    missing = land_cuts.missing_roles(core_row)
    excess = land_cuts.excess_roles(core_row)
    staple_ranks = land_cuts.staple_rank_by_name(conn)
    out: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    for row in land_cuts.deck_rows(conn, deck_id):
        if as_int(row.get("is_commander")) or "land" in str(row.get("type_line") or "").lower():
            continue
        roles, source = core_roles.card_roles(row)
        if roles & missing:
            continue
        cut_blockers = [
            *commander_specific_cut_blockers(commander, row),
            *cross_lane_cut_blockers(str(hypothesis.get("role") or ""), roles),
        ]
        if cut_blockers:
            blocked.append(
                {
                    "card_name": row.get("card_name"),
                    "status": "blocked_cut_requires_source_lane",
                    "roles": sorted(roles),
                    "classification_source": source,
                    "cmc": row.get("cmc"),
                    "block_reasons": cut_blockers,
                    "mutation_allowed": False,
                }
            )
            continue
        matching_excess = roles & set(excess)
        if not matching_excess:
            continue
        staple_rank = staple_ranks.get(normalize_name(row.get("card_name")))
        score, reasons = land_cuts.cut_candidate_score(
            row=row,
            roles=roles,
            source=source,
            matching_excess=matching_excess,
            excess=excess,
            staple_rank=staple_rank,
        )
        out.append(
            {
                "card_name": row.get("card_name"),
                "score": score,
                "status": "review_only_nonland_cut_candidate",
                "roles": sorted(roles),
                "matching_excess_roles": sorted(matching_excess),
                "classification_source": source,
                "cmc": row.get("cmc"),
                "staple_rank": staple_rank,
                "cut_reasons": reasons,
                "mutation_allowed": False,
            }
        )
    out.sort(key=lambda row: (-as_int(row["score"]), str(row["card_name"])))
    blocked.sort(key=lambda row: str(row["card_name"]))
    return out[:limit], blocked[:limit]


def related_learned_sources(conn: sqlite3.Connection, commander: str, limit: int) -> list[dict[str, Any]]:
    if not land_pool.mana_profile.table_exists(conn, "learned_decks"):
        return []
    key_words = [part for part in normalize_name(commander).split() if len(part) > 3]
    if not key_words:
        return []
    clauses = " OR ".join("lower(commander) LIKE ?" for _ in key_words)
    params = [f"%{word}%" for word in key_words]
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        f"""
        SELECT id, source, commander, deck_name, archetype, card_count,
               wincon_primary, wincon_backup
        FROM learned_decks
        WHERE {clauses}
        ORDER BY CASE WHEN lower(commander) = lower(?) THEN 0 ELSE 1 END, id
        LIMIT ?
        """,
        params + [commander, limit],
    ).fetchall()
    return [dict(row) for row in rows]


def build_pool_for_hypothesis(
    *,
    conn: sqlite3.Connection,
    hypothesis: dict[str, Any],
    core_row: dict[str, Any],
    limit: int,
) -> dict[str, Any]:
    deck_id = str(hypothesis.get("deck_id"))
    role = str(hypothesis.get("role") or "")
    commander = str(hypothesis.get("commander") or "")
    commander_colors = commander_colors_for_deck(conn, deck_id, commander)
    existing_names = land_pool.current_deck_names(conn, deck_id)
    candidates: list[dict[str, Any]] = []
    cuts: list[dict[str, Any]] = []
    blocked_cuts: list[dict[str, Any]] = []
    related_sources: list[dict[str, Any]] = []
    if role in SUPPORTED_CANDIDATE_ROLES:
        candidates = build_candidates_for_hypothesis(
            conn=conn,
            hypothesis=hypothesis,
            commander_colors=commander_colors,
            existing_names=existing_names,
            limit=limit,
        )
        cuts, blocked_cuts = cut_candidates_for_hypothesis(
            conn=conn,
            hypothesis=hypothesis,
            core_row=core_row,
            limit=limit,
        )
    elif role in SOURCE_LANE_ONLY_ROLES:
        related_sources = related_learned_sources(conn, commander, limit)
    pairs = [
        {
            "add": candidate["card_name"],
            "cut": cut["card_name"],
            "role": role,
            "status": "review_only_nonland_add_cut_pair",
            "pair_score": as_int(candidate.get("score")) + as_int(cut.get("score")),
            "required_gates": [
                "candidate_copy_only",
                "structure_and_legality_recheck",
                "role_floor_recheck",
                "commander_strategy_matrix_before_battle",
                "battle_gate_with_drawn_cast_used_trace_before_promotion",
            ],
            "mutation_allowed": False,
        }
        for candidate in candidates[:3]
        for cut in cuts[:3]
    ]
    pairs.sort(key=lambda row: (-as_int(row["pair_score"]), str(row["add"]), str(row["cut"])))
    if candidates and cuts:
        status = "review_nonland_add_cut_pool_ready"
    elif role in SOURCE_LANE_ONLY_ROLES:
        status = "needs_commander_specific_source_lane"
    else:
        status = "needs_candidate_or_cut_source_lane"
    return {
        "deck_id": deck_id,
        "deck_name": hypothesis.get("deck_name"),
        "commander": commander,
        "scope": hypothesis.get("scope"),
        "role": role,
        "missing": hypothesis.get("missing"),
        "current_count": hypothesis.get("current_count"),
        "target_min": hypothesis.get("target_min"),
        "commander_color_identity": commander_colors,
        "candidate_count": len(candidates),
        "cut_candidate_count": len(cuts),
        "blocked_cut_candidate_count": len(blocked_cuts),
        "top_candidates": candidates,
        "top_cut_candidates": cuts,
        "blocked_cut_candidates": blocked_cuts,
        "pair_hypotheses": pairs[:limit],
        "related_source_lanes": related_sources,
        "status": status,
        "mutation_allowed": False,
    }


def build_report(
    *,
    repair_payload: dict[str, Any],
    core_role_payload: dict[str, Any],
    sqlite_db: Path,
    repair_report_path: Path = DEFAULT_REPAIR_HYPOTHESIS_REPORT,
    core_role_report_path: Path = DEFAULT_CORE_ROLE_REPORT,
    limit: int = 12,
) -> dict[str, Any]:
    core_by_id = core_deck_by_id(core_role_payload)
    nonland_hypotheses = [
        row for row in repair_payload.get("hypotheses", []) if str(row.get("role") or "") != "land"
    ]
    with sqlite3.connect(sqlite_db) as conn:
        pools = [
            build_pool_for_hypothesis(
                conn=conn,
                hypothesis=row,
                core_row=core_by_id.get(str(row.get("deck_id")), {}),
                limit=limit,
            )
            for row in nonland_hypotheses
        ]
    status_counts = Counter(row["status"] for row in pools)
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_nonland_core_candidate_model",
        "source_repair_hypothesis_report": rel(repair_report_path),
        "source_core_role_report": rel(core_role_report_path),
        "source_db": rel(sqlite_db),
        "mutation_allowed": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "summary": {
            "pool_count": len(pools),
            "status_counts": dict(sorted(status_counts.items())),
            "total_candidate_count": sum(as_int(row.get("candidate_count")) for row in pools),
            "total_cut_candidate_count": sum(as_int(row.get("cut_candidate_count")) for row in pools),
            "total_blocked_cut_candidate_count": sum(as_int(row.get("blocked_cut_candidate_count")) for row in pools),
            "total_pair_hypothesis_count": sum(len(row.get("pair_hypotheses") or []) for row in pools),
            "top_next_action": "review_nonland_add_cut_pairs_or_build_commander_source_lane",
        },
        "nonland_pools": pools,
        "policy": {
            "review_only": "Nonland candidates and cuts are hypotheses only.",
            "source_lane_boundary": "Wincon candidates require commander-specific win-plan evidence before named additions.",
            "floor_protection": "Cards carrying any missing core role are blocked from cut suggestions.",
            "commander_payoff_protection": "Commander-specific payoffs such as Kaalia Angel/Demon/Dragon creatures are blocked from generic excess-role cuts until source-lane review.",
            "promotion_block": "No deck change is promoted without candidate copy, structure/legal recheck, strategy matrix, battle gate, and replay trace.",
        },
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Nonland Core Candidate Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        "- mutation_allowed: `false`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- battle_or_optimization_performed: `false`",
        f"- pool_count: `{payload['summary']['pool_count']}`",
        f"- status_counts: `{json.dumps(payload['summary']['status_counts'], sort_keys=True)}`",
        f"- total_pair_hypothesis_count: `{payload['summary']['total_pair_hypothesis_count']}`",
        "",
        "## Pools",
        "",
    ]
    for pool in payload["nonland_pools"]:
        lines.extend(
            [
                f"### Deck {pool['deck_id']} - {pool['commander']} - {pool['role']}",
                "",
                f"- status: `{pool['status']}`",
                f"- missing: `{pool['missing']}`",
                f"- candidates: `{pool['candidate_count']}`",
                f"- cut_candidates: `{pool['cut_candidate_count']}`",
                f"- blocked_cut_candidates: `{pool.get('blocked_cut_candidate_count', 0)}`",
                "",
                "| Score | Candidate | Status | Reasons |",
                "| --- | --- | --- | --- |",
            ]
        )
        for row in pool["top_candidates"]:
            lines.append(
                f"| `{row['score']}` | `{row['card_name']}` | `{row['status']}` | {', '.join(row['fit_reasons'])} |"
            )
        if not pool["top_candidates"]:
            lines.append("|  | none |  |  |")
        lines.extend(["", "| Score | Cut Candidate | Roles | Reasons |", "| --- | --- | --- | --- |"])
        for row in pool["top_cut_candidates"]:
            lines.append(
                f"| `{row['score']}` | `{row['card_name']}` | `{','.join(row['roles'])}` | {', '.join(row['cut_reasons'])} |"
            )
        if not pool["top_cut_candidates"]:
            lines.append("|  | none |  |  |")
        if pool.get("blocked_cut_candidates"):
            lines.extend(["", "| Blocked Cut | Status | Reasons |", "| --- | --- | --- |"])
            for row in pool["blocked_cut_candidates"]:
                lines.append(
                    f"| `{row['card_name']}` | `{row['status']}` | {', '.join(row.get('block_reasons') or [])} |"
                )
        if pool["related_source_lanes"]:
            lines.extend(["", "Related source lanes:"])
            for row in pool["related_source_lanes"]:
                lines.append(
                    f"- `{row['commander']}` from `{row['source']}` archetype `{row['archetype']}`"
                )
        lines.append("")
    lines.extend(["## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def write_outputs(payload: dict[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(payload, md_path)
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_SQLITE_DB)
    parser.add_argument("--repair-hypothesis-report", type=Path, default=DEFAULT_REPAIR_HYPOTHESIS_REPORT)
    parser.add_argument("--core-role-report", type=Path, default=DEFAULT_CORE_ROLE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--limit", type=int, default=12)
    args = parser.parse_args()
    payload = build_report(
        repair_payload=load_json(args.repair_hypothesis_report),
        core_role_payload=load_json(args.core_role_report),
        sqlite_db=args.db,
        repair_report_path=args.repair_hypothesis_report,
        core_role_report_path=args.core_role_report,
        limit=args.limit,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": "pass",
                "pool_count": payload["summary"]["pool_count"],
                "total_pair_hypothesis_count": payload["summary"]["total_pair_hypothesis_count"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
