#!/usr/bin/env python3
"""Build review-only named land candidate pools from mana-base profiles.

This script is intentionally not a deck materializer. It names possible land
adds only after the mana-base profile has exposed commander color identity,
source gaps, tapped-land pressure, and colorless-only pressure.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_mana_base_profile as mana_profile
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_MANA_BASE_PROFILE_REPORT = (
    REPORT_DIR / "global_commander_mana_base_profile_20260705_global_goal_hermes_only.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_named_land_candidate_pool_20260705_global_goal_hermes_only"


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


def commander_legality_by_name(conn: sqlite3.Connection) -> dict[str, str]:
    if not mana_profile.table_exists(conn, "card_legalities"):
        return {}
    rows = conn.execute(
        """
        SELECT card_name, status
        FROM card_legalities
        WHERE lower(format) = 'commander'
        """
    ).fetchall()
    return {mana_profile.normalize_name(row[0]): str(row[1] or "").lower() for row in rows}


def current_deck_names(conn: sqlite3.Connection, deck_id: str) -> set[str]:
    names: set[str] = set()
    for row in mana_profile.fetch_deck_cards(conn, deck_id):
        names.update(candidate_keys(str(row.get("card_name") or "")))
    return names


def candidate_keys(card_name: str) -> set[str]:
    keys = {mana_profile.normalize_name(card_name)}
    if " // " in card_name:
        parts = [mana_profile.normalize_name(part) for part in card_name.split(" // ") if part.strip()]
        keys.update(parts)
        if len(set(parts)) == 1:
            keys.add(parts[0])
    return {key for key in keys if key}


def is_land_type_line(type_line: object) -> bool:
    return re.search(r"(?<![a-z])land(?![a-z])", str(type_line or ""), re.IGNORECASE) is not None


def candidate_land_rows(conn: sqlite3.Connection) -> list[dict[str, Any]]:
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
    return [dict(row) for row in rows if is_land_type_line(row["type_line"])]


def color_identity_allowed(candidate_colors: list[str], commander_colors: list[str]) -> bool:
    return set(candidate_colors).issubset(set(commander_colors))


def typed_color_pair(feature: dict[str, Any], commander_colors: list[str]) -> bool:
    direct = set(feature.get("direct_colors") or [])
    return len(commander_colors) >= 2 and set(commander_colors).issubset(direct)


def candidate_score(
    *,
    feature: dict[str, Any],
    profile: dict[str, Any],
    legality_status: str,
) -> tuple[int, list[str]]:
    recommendations = set(profile.get("recommended_land_classes") or [])
    commander_colors = list(profile.get("commander_color_identity") or [])
    direct = set(feature.get("direct_colors") or [])
    fetches = set(feature.get("fetchable_colors") or [])
    conditional = set(feature.get("conditional_any_colors") or [])
    reasons: list[str] = []
    score = 0
    if legality_status == "legal":
        score += 15
        reasons.append("commander_legal")
    elif not legality_status:
        score -= 25
        reasons.append("missing_commander_legality")
    else:
        score -= 100
        reasons.append(f"commander_legality_{legality_status}")

    if "add_land_quantity_before_spell_slots" in recommendations:
        score += 5
        reasons.append("fills_land_quantity_gap")

    for color in commander_colors:
        if f"add_{color}_source_or_fetchable_access" not in recommendations:
            continue
        if color in direct or color in fetches:
            score += 24
            reasons.append(f"adds_{color}_access")
        elif color in conditional:
            score += 8
            reasons.append(f"adds_conditional_{color}_access")

    if "review_fetchable_dual_or_basic_mix" in recommendations and (feature.get("fetch_or_search_land") or typed_color_pair(feature, commander_colors)):
        score += 14
        reasons.append("supports_fetchable_or_dual_mix")

    tapped = feature.get("enters_tapped_profile")
    if tapped in {"reliably_untapped", "commander_expected_untapped", "optional_untapped_life"}:
        score += 12
        reasons.append("untapped_or_commander_expected")
    elif tapped == "conditional_tapped":
        score -= 4
        reasons.append("conditional_tapped")
    elif tapped == "always_tapped":
        score -= 18
        reasons.append("always_tapped")

    if "prioritize_untapped_fixing_lands" in recommendations and tapped not in {
        "reliably_untapped",
        "commander_expected_untapped",
        "optional_untapped_life",
    }:
        score -= 12
        reasons.append("does_not_solve_tapped_pressure")

    if feature.get("colorless_only"):
        score -= 18
        reasons.append("colorless_only")
        if "limit_colorless_utility_until_color_floor" in recommendations:
            score -= 24
            reasons.append("profile_has_colorless_pressure")

    utility = set(feature.get("utility_roles") or [])
    if utility & {"card_flow", "topdeck_selection", "cycling", "commander_support"}:
        score += 5
        reasons.append("useful_land_utility")
    if "bounce_land_tempo_risk" in utility:
        score -= 16
        reasons.append("bounce_land_tempo_risk")

    return score, reasons


def build_candidate_pool_for_profile(
    *,
    profile: dict[str, Any],
    all_lands: list[dict[str, Any]],
    existing_names: set[str],
    legalities: dict[str, str],
    limit: int,
) -> dict[str, Any]:
    commander_colors = list(profile.get("commander_color_identity") or [])
    candidates: list[dict[str, Any]] = []
    for row in all_lands:
        card_name = str(row.get("name") or row.get("card_name") or "")
        keys = candidate_keys(card_name)
        if not keys or keys & existing_names:
            continue
        candidate_colors = mana_profile.parse_color_identity(row.get("color_identity_json"))
        if not color_identity_allowed(candidate_colors, commander_colors):
            continue
        feature = mana_profile.land_feature(
            {
                "card_name": card_name,
                "quantity": 1,
                "type_line": row.get("type_line"),
                "oracle_text": row.get("oracle_text"),
                "functional_tag": "land",
            },
            commander_colors,
        )
        legality_status = next((legalities[item] for item in keys if item in legalities), "")
        if legality_status and legality_status not in {"legal"}:
            continue
        score, reasons = candidate_score(feature=feature, profile=profile, legality_status=legality_status)
        candidates.append(
            {
                "card_name": card_name,
                "score": score,
                "status": "review_only_named_land_candidate"
                if legality_status == "legal"
                else "review_only_requires_commander_legality_check",
                "commander_legality": legality_status or "missing",
                "color_identity": candidate_colors,
                "direct_colors": feature["direct_colors"],
                "conditional_any_colors": feature["conditional_any_colors"],
                "fetchable_colors": feature["fetchable_colors"],
                "enters_tapped_profile": feature["enters_tapped_profile"],
                "colorless_only": feature["colorless_only"],
                "utility_roles": feature["utility_roles"],
                "fit_reasons": reasons,
                "mutation_allowed": False,
            }
        )
    candidates.sort(key=lambda row: (-int(row["score"]), row["card_name"]))
    return {
        "deck_id": profile.get("deck_id"),
        "deck_name": profile.get("deck_name"),
        "commander": profile.get("commander"),
        "commander_color_identity": commander_colors,
        "source_profile_status": profile.get("status"),
        "recommended_land_classes": profile.get("recommended_land_classes") or [],
        "candidate_count": len(candidates),
        "top_candidates": candidates[:limit],
        "mutation_allowed": False,
    }


def build_report(
    *,
    mana_payload: dict[str, Any],
    sqlite_db: Path,
    mana_profile_report_path: Path = DEFAULT_MANA_BASE_PROFILE_REPORT,
    limit: int = 12,
) -> dict[str, Any]:
    profiles = [
        row
        for row in mana_payload.get("profiles", [])
        if row.get("status") == "mana_profile_ready_for_named_land_candidate_pool"
    ]
    with sqlite3.connect(sqlite_db) as conn:
        legalities = commander_legality_by_name(conn)
        all_lands = candidate_land_rows(conn)
        pools = [
            build_candidate_pool_for_profile(
                profile=profile,
                all_lands=all_lands,
                existing_names=current_deck_names(conn, str(profile.get("deck_id"))),
                legalities=legalities,
                limit=limit,
            )
            for profile in profiles
        ]
    status_counts = Counter(
        row["status"] for pool in pools for row in pool.get("top_candidates", [])
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_named_land_candidate_pool",
        "source_mana_base_profile_report": rel(mana_profile_report_path),
        "source_db": rel(sqlite_db),
        "mutation_allowed": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "summary": {
            "pool_count": len(pools),
            "total_candidate_count": sum(int(pool.get("candidate_count") or 0) for pool in pools),
            "top_candidate_status_counts": dict(sorted(status_counts.items())),
            "top_next_action": "run_same_lane_cut_model_for_top_named_land_candidates",
        },
        "candidate_pools": pools,
        "policy": {
            "review_only": "Named lands here are candidate-pool rows, not additions.",
            "promotion_block": (
                "A candidate still needs same-lane cuts, structure/legal recheck, strategy matrix, "
                "battle gate, and drawn/cast/used trace before product promotion."
            ),
        },
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Named Land Candidate Pool",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        "- mutation_allowed: `false`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- battle_or_optimization_performed: `false`",
        f"- pool_count: `{payload['summary']['pool_count']}`",
        f"- total_candidate_count: `{payload['summary']['total_candidate_count']}`",
        f"- top_next_action: `{payload['summary']['top_next_action']}`",
        "",
        "## Pools",
        "",
    ]
    for pool in payload["candidate_pools"]:
        lines.extend(
            [
                f"### Deck {pool['deck_id']} - {pool['commander']}",
                "",
                f"- colors: `{''.join(pool['commander_color_identity'])}`",
                f"- source_profile_status: `{pool['source_profile_status']}`",
                f"- candidate_count: `{pool['candidate_count']}`",
                "",
                "| Score | Candidate | Status | Access | Tapped | Reasons |",
                "| --- | --- | --- | --- | --- | --- |",
            ]
        )
        for row in pool["top_candidates"]:
            access = sorted(set(row["direct_colors"]) | set(row["conditional_any_colors"]) | set(row["fetchable_colors"]))
            lines.append(
                "| `{score}` | `{name}` | `{status}` | `{access}` | `{tapped}` | {reasons} |".format(
                    score=row["score"],
                    name=row["card_name"],
                    status=row["status"],
                    access="".join(access) or "none",
                    tapped=row["enters_tapped_profile"],
                    reasons=", ".join(row["fit_reasons"]),
                )
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
    parser.add_argument("--mana-base-profile-report", type=Path, default=DEFAULT_MANA_BASE_PROFILE_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--limit", type=int, default=12)
    args = parser.parse_args()

    mana_payload = load_json(args.mana_base_profile_report)
    payload = build_report(
        mana_payload=mana_payload,
        sqlite_db=args.db,
        mana_profile_report_path=args.mana_base_profile_report,
        limit=args.limit,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": "pass",
                "pool_count": payload["summary"]["pool_count"],
                "total_candidate_count": payload["summary"]["total_candidate_count"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
