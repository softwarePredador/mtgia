#!/usr/bin/env python3
"""Build read-only mana-base profiles for global Commander land gaps.

The core repair hypothesis audit intentionally refuses to name land candidates
before a deck has a mana profile. This script fills that missing diagnostic
layer: commander color identity, land quantity, direct/fetchable color access,
tapped-land pressure, colorless-only pressure, and utility-land pressure.

It does not mutate Hermes SQLite, PostgreSQL, or any decklist.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REPAIR_HYPOTHESIS_REPORT = (
    REPORT_DIR / "global_commander_core_repair_hypothesis_20260705_global_goal_hermes_only.json"
)
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_mana_base_profile_20260705_global_goal_hermes_only"

COLOR_ORDER = ("W", "U", "B", "R", "G")
BASIC_TYPES_BY_COLOR = {
    "W": "plains",
    "U": "island",
    "B": "swamp",
    "R": "mountain",
    "G": "forest",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def normalize_name(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def parse_color_identity(value: object) -> list[str]:
    def ordered(colors: list[str]) -> list[str]:
        color_set = {color for color in colors if color in COLOR_ORDER}
        return [color for color in COLOR_ORDER if color in color_set]

    if value is None:
        return []
    if isinstance(value, list):
        return ordered([str(item).upper() for item in value])
    text = str(value or "").strip()
    if not text:
        return []
    try:
        decoded = json.loads(text)
    except json.JSONDecodeError:
        decoded = None
    if isinstance(decoded, list):
        return ordered([str(item).upper() for item in decoded])
    return ordered([color for color in COLOR_ORDER if color in text.upper()])


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    return row is not None


def fetch_deck_cards(conn: sqlite3.Connection, deck_id: str) -> list[dict[str, Any]]:
    if not table_exists(conn, "deck_cards"):
        return []
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT deck_id, card_name, quantity, functional_tag, is_commander,
               cmc, type_line, oracle_text, card_id
        FROM deck_cards
        WHERE CAST(deck_id AS TEXT) = ?
        ORDER BY COALESCE(is_commander, 0) DESC, card_name
        """,
        (str(deck_id),),
    ).fetchall()
    return [dict(row) for row in rows]


def fetch_oracle_rows(conn: sqlite3.Connection, names: set[str]) -> dict[str, dict[str, Any]]:
    if not names or not table_exists(conn, "card_oracle_cache"):
        return {}
    placeholders = ",".join("?" for _ in names)
    lowered = [name.lower() for name in names]
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        f"""
        SELECT name, normalized_name, mana_cost, colors_json, color_identity_json,
               type_line, oracle_text, cmc, scryfall_id, card_id
        FROM card_oracle_cache
        WHERE lower(name) IN ({placeholders})
           OR lower(normalized_name) IN ({placeholders})
        """,
        lowered + lowered,
    ).fetchall()
    by_name: dict[str, dict[str, Any]] = {}
    for row in rows:
        data = dict(row)
        by_name[normalize_name(data.get("name"))] = data
        by_name[normalize_name(data.get("normalized_name"))] = data
    return by_name


def fetch_commander_table_identity(conn: sqlite3.Connection, commander: str) -> list[str]:
    if not commander or not table_exists(conn, "commanders"):
        return []
    row = conn.execute(
        "SELECT color_identity FROM commanders WHERE lower(name) = lower(?) LIMIT 1",
        (commander,),
    ).fetchone()
    if not row:
        return []
    return parse_color_identity(row[0])


def enriched_row(row: dict[str, Any], oracle_by_name: dict[str, dict[str, Any]]) -> dict[str, Any]:
    oracle = oracle_by_name.get(normalize_name(row.get("card_name")), {})
    result = dict(row)
    for field in ("type_line", "oracle_text", "cmc", "card_id"):
        if not result.get(field) and oracle.get(field):
            result[field] = oracle[field]
    for field in ("mana_cost", "colors_json", "color_identity_json", "scryfall_id"):
        result[field] = oracle.get(field)
    return result


def is_land(row: dict[str, Any]) -> bool:
    return str(row.get("functional_tag") or "").lower() == "land" or "land" in str(
        row.get("type_line") or ""
    ).lower()


def enters_tapped_profile(oracle_text: str) -> str:
    text = oracle_text.lower()
    if "enters tapped unless" in text:
        if "two or more opponents" in text:
            return "commander_expected_untapped"
        return "conditional_tapped"
    if "as this land enters, you may pay" in text:
        return "optional_untapped_life"
    if "enters tapped" in text:
        return "always_tapped"
    return "reliably_untapped"


def direct_colors(type_line: str, oracle_text: str, commander_colors: list[str]) -> tuple[set[str], set[str]]:
    type_text = type_line.lower()
    text = oracle_text.lower()
    direct: set[str] = set()
    conditional_any: set[str] = set()
    for color, land_type in BASIC_TYPES_BY_COLOR.items():
        if land_type in type_text or f"{{{color.lower()}}}" in text or f"add {{{color.lower()}}}" in text:
            direct.add(color)
    any_color_is_conditional = any(
        phrase in text
        for phrase in (
            "spend this mana only",
            "could produce",
            "among legendary",
            "{1}, {t}: add one mana of any color",
            "pay {e}: add one mana of any color",
            "sacrifice this land: add one mana of any color",
            "chosen color",
            "choose a color",
        )
    )
    if "add one mana of any color in your commander's color identity" in text:
        if any_color_is_conditional:
            conditional_any.update(commander_colors)
        else:
            direct.update(commander_colors)
    elif "add one mana of any color" in text:
        if any_color_is_conditional:
            conditional_any.update(commander_colors)
        else:
            direct.update(commander_colors)
    return direct, conditional_any


def fetchable_colors(oracle_text: str, commander_colors: list[str]) -> set[str]:
    text = oracle_text.lower()
    if "search your library" not in text:
        return set()
    colors: set[str] = set()
    for color, land_type in BASIC_TYPES_BY_COLOR.items():
        if land_type in text:
            colors.add(color)
    if "basic land" in text:
        colors.update(commander_colors)
    return colors


def utility_roles(card_name: str, oracle_text: str, type_line: str) -> list[str]:
    text = oracle_text.lower()
    type_text = type_line.lower()
    roles: set[str] = set()
    if "draw a card" in text:
        roles.add("card_flow")
    if "scry" in text or "surveil" in text:
        roles.add("topdeck_selection")
    if "cycling" in text:
        roles.add("cycling")
    if "commander" in text:
        roles.add("commander_support")
    if "hexproof" in text or "indestructible" in text or "protection" in text:
        roles.add("protection")
    if "can't be countered" in text:
        roles.add("anti_countermagic")
    if "search your library for an artifact" in text:
        roles.add("artifact_tutor")
    if "graveyard" in text:
        roles.add("graveyard_utility")
    if "treasure" in text:
        roles.add("treasure_support")
    if "return a land you control" in text:
        roles.add("bounce_land_tempo_risk")
    if "desert" in type_text:
        roles.add("desert_typal")
    if card_name.lower() in {"ancient tomb", "temple of the false god"}:
        roles.add("fast_colorless_mana")
    return sorted(roles)


def land_feature(row: dict[str, Any], commander_colors: list[str]) -> dict[str, Any]:
    type_line = str(row.get("type_line") or "")
    oracle_text = str(row.get("oracle_text") or "")
    direct, conditional_any = direct_colors(type_line, oracle_text, commander_colors)
    fetches = fetchable_colors(oracle_text, commander_colors)
    quantity = max(1, as_int(row.get("quantity") or 1))
    has_colorless = "{c}" in oracle_text.lower() or "add {c}" in oracle_text.lower()
    return {
        "card_name": row.get("card_name"),
        "quantity": quantity,
        "type_line": type_line,
        "has_oracle_text": bool(oracle_text.strip()),
        "direct_colors": sorted(direct, key=COLOR_ORDER.index),
        "conditional_any_colors": sorted(conditional_any, key=COLOR_ORDER.index),
        "fetchable_colors": sorted(fetches, key=COLOR_ORDER.index),
        "enters_tapped_profile": enters_tapped_profile(oracle_text),
        "colorless_only": has_colorless and not direct and not conditional_any and not fetches,
        "basic": type_line.lower().startswith("basic land"),
        "fetch_or_search_land": bool(fetches),
        "utility_roles": utility_roles(str(row.get("card_name") or ""), oracle_text, type_line),
    }


def source_floor(commander_color_count: int, target_land_floor: int) -> int:
    if commander_color_count <= 0:
        return 0
    ratio_by_colors = {1: 0.78, 2: 0.60, 3: 0.44, 4: 0.36, 5: 0.32}
    ratio = ratio_by_colors.get(commander_color_count, 0.32)
    return max(8, math.ceil(target_land_floor * ratio))


def mana_counts(features: list[dict[str, Any]], commander_colors: list[str]) -> dict[str, Any]:
    counts: Counter[str] = Counter()
    direct_by_color: Counter[str] = Counter()
    access_by_color: Counter[str] = Counter()
    conditional_by_color: Counter[str] = Counter()
    for item in features:
        quantity = as_int(item.get("quantity"))
        counts["land_quantity"] += quantity
        counts["land_rows"] += 1
        if item.get("has_oracle_text"):
            counts["land_rows_with_oracle_text"] += 1
        if item.get("basic"):
            counts["basic_land_quantity"] += quantity
        if item.get("fetch_or_search_land"):
            counts["fetch_or_search_quantity"] += quantity
        if item.get("colorless_only"):
            counts["colorless_only_quantity"] += quantity
        tapped = item.get("enters_tapped_profile")
        counts[f"{tapped}_quantity"] += quantity
        if tapped in {"reliably_untapped", "commander_expected_untapped", "optional_untapped_life"}:
            counts["untapped_or_expected_quantity"] += quantity
        if item.get("utility_roles"):
            counts["utility_land_quantity"] += quantity
        direct = set(item.get("direct_colors") or [])
        conditional = set(item.get("conditional_any_colors") or [])
        fetches = set(item.get("fetchable_colors") or [])
        for color in commander_colors:
            if color in direct:
                direct_by_color[color] += quantity
            if color in conditional:
                conditional_by_color[color] += quantity
            if color in direct or color in conditional or color in fetches:
                access_by_color[color] += quantity
    return {
        "counts": dict(sorted(counts.items())),
        "direct_sources_by_color": {color: direct_by_color[color] for color in commander_colors},
        "conditional_sources_by_color": {color: conditional_by_color[color] for color in commander_colors},
        "direct_or_fetch_access_by_color": {color: access_by_color[color] for color in commander_colors},
    }


def commander_identity(
    *,
    conn: sqlite3.Connection,
    deck_rows: list[dict[str, Any]],
    oracle_by_name: dict[str, dict[str, Any]],
    commander_hint: str,
) -> tuple[str, list[str], str]:
    commander_row = next((row for row in deck_rows if as_int(row.get("is_commander")) == 1), None)
    commander_name = str((commander_row or {}).get("card_name") or commander_hint or "")
    if commander_row:
        enriched = enriched_row(commander_row, oracle_by_name)
        colors = parse_color_identity(enriched.get("color_identity_json"))
        if colors:
            return commander_name, colors, "card_oracle_cache"
    colors = fetch_commander_table_identity(conn, commander_name)
    if colors:
        return commander_name, colors, "commanders_table"
    return commander_name, [], "missing"


def recommended_classes(
    *,
    land_gap: int,
    commander_colors: list[str],
    counts: dict[str, Any],
    floor: int,
) -> list[str]:
    recommendations: list[str] = []
    if land_gap > 0:
        recommendations.append("add_land_quantity_before_spell_slots")
    access = counts.get("direct_or_fetch_access_by_color") or {}
    for color in commander_colors:
        if as_int(access.get(color)) < floor:
            recommendations.append(f"add_{color}_source_or_fetchable_access")
    total_lands = as_int((counts.get("counts") or {}).get("land_quantity"))
    always_tapped = as_int((counts.get("counts") or {}).get("always_tapped_quantity"))
    conditional_tapped = as_int((counts.get("counts") or {}).get("conditional_tapped_quantity"))
    colorless_only = as_int((counts.get("counts") or {}).get("colorless_only_quantity"))
    if total_lands and (always_tapped + conditional_tapped) / total_lands > 0.24:
        recommendations.append("prioritize_untapped_fixing_lands")
    if colorless_only > max(2, len(commander_colors)):
        recommendations.append("limit_colorless_utility_until_color_floor")
    if len(commander_colors) >= 2 and as_int((counts.get("counts") or {}).get("fetch_or_search_quantity")) > 0:
        recommendations.append("review_fetchable_dual_or_basic_mix")
    return recommendations or ["mana_profile_has_no_immediate_source_class_warning"]


def profile_status(*, commander_colors: list[str], features: list[dict[str, Any]], land_gap: int) -> str:
    if not commander_colors:
        return "blocked_missing_commander_color_identity"
    if not features:
        return "blocked_no_land_rows_detected"
    with_oracle = sum(1 for row in features if row.get("has_oracle_text"))
    if with_oracle / len(features) < 0.80:
        return "needs_card_oracle_cache_backfill_before_named_lands"
    if land_gap > 0:
        return "mana_profile_ready_for_named_land_candidate_pool"
    return "mana_profile_ready_no_quantity_gap"


def build_profile_for_hypothesis(
    *,
    conn: sqlite3.Connection,
    hypothesis: dict[str, Any],
) -> dict[str, Any]:
    deck_id = str(hypothesis.get("deck_id"))
    deck_rows = fetch_deck_cards(conn, deck_id)
    oracle_by_name = fetch_oracle_rows(conn, {str(row.get("card_name") or "") for row in deck_rows})
    commander_name, commander_colors, identity_source = commander_identity(
        conn=conn,
        deck_rows=deck_rows,
        oracle_by_name=oracle_by_name,
        commander_hint=str(hypothesis.get("commander") or ""),
    )
    enriched_rows = [enriched_row(row, oracle_by_name) for row in deck_rows]
    lands = [land_feature(row, commander_colors) for row in enriched_rows if is_land(row)]
    land_gap = as_int(hypothesis.get("missing"))
    target_floor = as_int(hypothesis.get("target_min")) or as_int(hypothesis.get("current_count")) + land_gap
    floor = source_floor(len(commander_colors), target_floor or 34)
    counts = mana_counts(lands, commander_colors)
    return {
        "deck_id": deck_id,
        "deck_name": hypothesis.get("deck_name"),
        "commander": commander_name,
        "scope": hypothesis.get("scope"),
        "commander_color_identity": commander_colors,
        "commander_identity_source": identity_source,
        "land_gap": land_gap,
        "current_land_count": as_int(hypothesis.get("current_count")),
        "target_land_floor": target_floor,
        "diagnostic_source_floor_per_color": floor,
        "status": profile_status(commander_colors=commander_colors, features=lands, land_gap=land_gap),
        "mana_base_counts": counts["counts"],
        "direct_sources_by_color": counts["direct_sources_by_color"],
        "conditional_sources_by_color": counts["conditional_sources_by_color"],
        "direct_or_fetch_access_by_color": counts["direct_or_fetch_access_by_color"],
        "recommended_land_classes": recommended_classes(
            land_gap=land_gap,
            commander_colors=commander_colors,
            counts=counts,
            floor=floor,
        ),
        "land_features": lands,
        "mutation_allowed": False,
        "required_next_gates": [
            "named_land_candidate_pool_by_commander_color_identity",
            "same_lane_or_excess_role_cut_model",
            "structure_and_legality_recheck_after_candidate_copy",
            "strategy_matrix_before_battle",
            "battle_gate_with_drawn_cast_used_trace_before_promotion",
        ],
    }


def build_report(
    *,
    repair_payload: dict[str, Any],
    sqlite_db: Path,
    repair_report_path: Path = DEFAULT_REPAIR_HYPOTHESIS_REPORT,
) -> dict[str, Any]:
    land_hypotheses = [
        row
        for row in repair_payload.get("hypotheses", [])
        if str(row.get("role") or "") == "land"
    ]
    with sqlite3.connect(sqlite_db) as conn:
        profiles = [build_profile_for_hypothesis(conn=conn, hypothesis=row) for row in land_hypotheses]
    status_counts = Counter(row["status"] for row in profiles)
    recommendation_counts = Counter(
        recommendation for row in profiles for recommendation in row.get("recommended_land_classes", [])
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_mana_base_profile",
        "source_repair_hypothesis_report": rel(repair_report_path),
        "source_db": rel(sqlite_db),
        "mutation_allowed": False,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "summary": {
            "profile_count": len(profiles),
            "status_counts": dict(sorted(status_counts.items())),
            "recommendation_counts": dict(sorted(recommendation_counts.items())),
            "top_next_action": "build_named_land_candidate_pool_from_mana_profiles",
        },
        "profiles": profiles,
        "policy": {
            "diagnostic_source_floor": (
                "Heuristic only: each commander color must have enough direct or fetchable access "
                "before named land candidates can be reviewed. This is not a promotion gate by itself."
            ),
            "named_lands": (
                "This report does not name additions. Candidate lands require commander color identity, "
                "legality, current ownership/availability if applicable, same-lane cuts, and battle trace evidence."
            ),
        },
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    lines = [
        "# Global Commander Mana Base Profile",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        "- mutation_allowed: `false`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- battle_or_optimization_performed: `false`",
        f"- profile_count: `{payload['summary']['profile_count']}`",
        f"- status_counts: `{json.dumps(payload['summary']['status_counts'], sort_keys=True)}`",
        f"- top_next_action: `{payload['summary']['top_next_action']}`",
        "",
        "## Profiles",
        "",
        "| Deck | Commander | Colors | Status | Lands | Floor | Access | Recommendations |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in payload["profiles"]:
        access = ", ".join(
            f"{color}:{count}" for color, count in row["direct_or_fetch_access_by_color"].items()
        )
        lines.append(
            "| `{deck}` | `{commander}` | `{colors}` | `{status}` | {lands}/{target} | {floor} | {access} | {recs} |".format(
                deck=row["deck_id"],
                commander=row["commander"],
                colors="".join(row["commander_color_identity"]) or "unknown",
                status=row["status"],
                lands=row["mana_base_counts"].get("land_quantity", 0),
                target=row["target_land_floor"],
                floor=row["diagnostic_source_floor_per_color"],
                access=access or "unknown",
                recs=", ".join(row["recommended_land_classes"]),
            )
        )
    lines.extend(["", "## Policy", ""])
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
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()

    repair_payload = load_json(args.repair_hypothesis_report)
    payload = build_report(
        repair_payload=repair_payload,
        sqlite_db=args.db,
        repair_report_path=args.repair_hypothesis_report,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": "pass",
                "profile_count": payload["summary"]["profile_count"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
