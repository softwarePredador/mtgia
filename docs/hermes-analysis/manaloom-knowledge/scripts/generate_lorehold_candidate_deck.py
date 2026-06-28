#!/usr/bin/env python3
"""Generate an isolated Lorehold candidate deck from the current matrix.

The generator is intentionally conservative. It builds a full 100-card draft
from battle-ready matrix rows, writes JSON/Markdown evidence, and materializes a
candidate SQLite copy for battle smoke tests. The canonical knowledge.db is not
mutated.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import (
    DEFAULT_DB,
    PROTECTED_CARDS,
    REPORT_DIR,
    connect,
    deck_hash,
    deck_rows,
    get_deck_summary,
    normalize_name,
    ruleset_hash,
    semantics_hash,
)
from lorehold_strategy_profile import (
    STRATEGY_VERSION,
    force_keep_active_anchor,
    strategy_counts,
    strategy_score as card_strategy_score,
    strategy_score_breakdown,
    strategy_shortfalls,
    strategy_tags_for_card,
)


COMMANDER = "Lorehold, the Historian"
ALLOWED_COLOR_IDENTITY = {"R", "W"}
MAIN_DECK_SIZE = 99
LAND_TARGET = 33
NONLAND_TARGET = MAIN_DECK_SIZE - LAND_TARGET

ROLE_MINIMUMS = {
    "nonland_ramp": 11,
    "draw": 14,
    "engine": 14,
    "protection": 10,
    "removal": 8,
    "tutor": 7,
    "wincon": 7,
    "recursion": 4,
    "board_wipe": 2,
    "stax": 3,
}

LANE_BONUS = {
    "core_keep": 12.0,
    "priority_benchmark_candidate": 7.0,
    "watchlist_candidate": 1.5,
    "low_priority": -8.0,
    "active_low_confidence_review": -18.0,
}

PENDING_PROMOTION_LANES = {
    "mapper_metadata_or_test_scenario_required",
    "split_family_scope_review_required",
    "runtime_family_implementation_required",
    "blocked_missing_xmage_source",
}

NONLAND_ROLE_ORDER = (
    "nonland_ramp",
    "draw",
    "engine",
    "protection",
    "removal",
    "tutor",
    "wincon",
    "recursion",
    "board_wipe",
    "stax",
)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def json_list(value: object) -> list[str]:
    if not value:
        return []
    if isinstance(value, list):
        return [str(item) for item in value if item is not None]
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    if isinstance(decoded, list):
        return [str(item) for item in decoded if item is not None]
    return []


def load_matrix(path: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    decoded = json.loads(path.read_text(encoding="utf-8"))
    rows = decoded.get("rows")
    if not isinstance(rows, list):
        raise ValueError(f"matrix has no rows list: {path}")
    return rows, dict(decoded.get("summary") or {})


def oracle_by_name(conn: sqlite3.Connection, names: set[str]) -> dict[str, sqlite3.Row]:
    result: dict[str, sqlite3.Row] = {}
    for name in names:
        row = conn.execute(
            "SELECT * FROM card_oracle_cache WHERE normalized_name=?",
            (normalize_name(name),),
        ).fetchone()
        if row:
            result[normalize_name(name)] = row
    return result


def active_rules_for_card(conn: sqlite3.Connection, card_name: str) -> list[dict[str, Any]]:
    table = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='battle_card_rules'"
    ).fetchone()
    if not table:
        return []
    rows = conn.execute(
        """
        SELECT logical_rule_key, effect_json, deck_role_json, source,
               confidence, review_status, execution_status, rule_version
        FROM battle_card_rules
        WHERE normalized_name=?
          AND review_status IN ('verified', 'active', 'needs_review')
          AND execution_status != 'disabled'
        ORDER BY logical_rule_key
        """,
        (normalize_name(card_name),),
    ).fetchall()
    return [dict(row) for row in rows]


def matrix_rows_by_name(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for row in rows:
        name = str(row.get("card_name") or "")
        if not name:
            continue
        key = normalize_name(name)
        current = result.get(key)
        if current is None or float(row.get("score") or 0) > float(current.get("score") or 0):
            result[key] = row
    return result


def roles_for(row: dict[str, Any]) -> set[str]:
    return {
        normalize_name(role).replace(" ", "_")
        for role in (row.get("roles") or [])
        if str(role or "").strip()
    }


def is_land(row: dict[str, Any], oracle: sqlite3.Row | None) -> bool:
    type_line = str((oracle["type_line"] if oracle else row.get("type_line")) or "")
    return "Land" in type_line or "land" in roles_for(row)


def color_identity(oracle: sqlite3.Row | None) -> set[str]:
    if not oracle:
        return set()
    return {value.upper() for value in json_list(oracle["color_identity_json"])}


def eligibility_reasons(row: dict[str, Any], oracle: sqlite3.Row | None) -> list[str]:
    reasons: list[str] = []
    if row.get("rule_status") != "battle_ready":
        reasons.append("not_battle_ready")
    if row.get("recommendation_lane") == "policy_blocked":
        reasons.append("policy_blocked")
    if row.get("promotion_lane") in PENDING_PROMOTION_LANES:
        reasons.append(f"pending_promotion_lane:{row.get('promotion_lane')}")
    if row.get("proposal_status") in PENDING_PROMOTION_LANES:
        reasons.append(f"pending_proposal_status:{row.get('proposal_status')}")
    if not oracle:
        reasons.append("missing_oracle_cache")
    identity = color_identity(oracle)
    if oracle and not identity.issubset(ALLOWED_COLOR_IDENTITY):
        reasons.append("color_identity_outside_lorehold:" + "".join(sorted(identity)))
    return reasons


def role_metric_counts(selected: list[dict[str, Any]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for item in selected:
        card_roles = set(item["roles"])
        if "ramp" in card_roles and not item["is_land"]:
            counts["nonland_ramp"] += 1
        for role in NONLAND_ROLE_ORDER:
            if role == "nonland_ramp":
                continue
            if role in card_roles:
                counts[role] += 1
    return counts


def effective_score(
    row: dict[str, Any],
    oracle: sqlite3.Row | None,
    *,
    active_names: set[str],
    current_counts: Counter[str] | None = None,
    current_strategy_counts: Counter[str] | None = None,
    is_land_card: bool = False,
) -> float:
    score = float(row.get("score") or 0)
    lane = str(row.get("recommendation_lane") or "")
    score += LANE_BONUS.get(lane, 0.0)
    if normalize_name(str(row.get("card_name") or "")) in active_names:
        score += 7.0
    score += min(8.0, len(row.get("deck_ids") or []) * 0.6)
    card_roles = roles_for(row)
    if "unknown" in card_roles:
        score -= 10.0
    cmc = float((oracle["cmc"] if oracle else row.get("cmc")) or 0)
    card_view = {
        "card_name": row.get("card_name"),
        "roles": sorted(card_roles),
        "type_line": (oracle["type_line"] if oracle else row.get("type_line")) or "",
        "oracle_text": (oracle["oracle_text"] if oracle else row.get("oracle_text")) or "",
        "cmc": cmc,
        "is_land": is_land_card,
        "in_active_deck": normalize_name(str(row.get("card_name") or "")) in active_names,
    }
    score += card_strategy_score(
        card_view,
        current_counts=current_strategy_counts,
        in_active_deck=card_view["in_active_deck"],
    )
    if not is_land_card:
        if cmc <= 2:
            score += 2.0
        if cmc > 5:
            score -= min(18.0, (cmc - 5.0) * 4.0)
    if current_counts is not None and not is_land_card:
        virtual_item = {
            "roles": card_roles,
            "is_land": is_land_card,
        }
        fills = role_metric_counts([virtual_item])
        for role, minimum in ROLE_MINIMUMS.items():
            if current_counts[role] < minimum and fills[role]:
                score += 18.0 + (minimum - current_counts[role]) * 1.5
    return score


def to_candidate_item(
    row: dict[str, Any],
    oracle: sqlite3.Row,
    *,
    active_names: set[str],
) -> dict[str, Any]:
    land = is_land(row, oracle)
    card_view = {
        "card_name": str(row["card_name"]),
        "roles": sorted(roles_for(row)),
        "is_land": land,
        "cmc": float(oracle["cmc"] or 0),
        "type_line": oracle["type_line"] or row.get("type_line") or "",
        "oracle_text": oracle["oracle_text"] or "",
        "in_active_deck": bool(row.get("in_active_deck"))
        or normalize_name(str(row["card_name"])) in active_names,
    }
    return {
        "card_name": str(row["card_name"]),
        "normalized_name": normalize_name(str(row["card_name"])),
        "roles": sorted(roles_for(row)),
        "is_land": land,
        "score": float(row.get("score") or 0),
        "effective_score": effective_score(
            row,
            oracle,
            active_names=active_names,
            is_land_card=land,
        ),
        "recommendation_lane": row.get("recommendation_lane"),
        "promotion_lane": row.get("promotion_lane"),
        "deck_ids": row.get("deck_ids") or [],
        "cmc": float(oracle["cmc"] or 0),
        "type_line": oracle["type_line"] or row.get("type_line") or "",
        "oracle_text": oracle["oracle_text"] or "",
        "color_identity": sorted(color_identity(oracle)),
        "in_active_deck": bool(row.get("in_active_deck"))
        or normalize_name(str(row["card_name"])) in active_names,
        "strategy_tags": sorted(strategy_tags_for_card(card_view)),
        "strategy_score_breakdown": strategy_score_breakdown(card_view),
    }


def force_keep_active_core(item: dict[str, Any]) -> bool:
    return (
        bool(item.get("in_active_deck"))
        and not bool(item.get("is_land"))
        and item.get("recommendation_lane") == "core_keep"
    )


def select_deck(
    matrix_rows: list[dict[str, Any]],
    oracle: dict[str, sqlite3.Row],
    active_rows: list[sqlite3.Row],
    *,
    max_novel: int,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    active_names = {normalize_name(row["card_name"]) for row in active_rows}
    rows_by_name = matrix_rows_by_name(matrix_rows)
    eligible: list[dict[str, Any]] = []
    blocked: Counter[str] = Counter()
    for key, row in rows_by_name.items():
        if normalize_name(str(row.get("card_name") or "")) == normalize_name(COMMANDER):
            continue
        reasons = eligibility_reasons(row, oracle.get(key))
        if reasons:
            for reason in reasons:
                blocked[reason] += 1
            continue
        eligible.append(to_candidate_item(row, oracle[key], active_names=active_names))

    lands = sorted(
        [item for item in eligible if item["is_land"]],
        key=lambda item: (item["effective_score"], item["score"], item["card_name"]),
        reverse=True,
    )
    nonlands = [item for item in eligible if not item["is_land"]]
    selected: list[dict[str, Any]] = []
    selected_names: set[str] = set()

    for item in lands:
        if len([card for card in selected if card["is_land"]]) >= LAND_TARGET:
            break
        if item["normalized_name"] in selected_names:
            continue
        selected.append(item)
        selected_names.add(item["normalized_name"])

    protected_keep = {
        normalize_name(card)
        for card in PROTECTED_CARDS
        if card != COMMANDER
    }
    novel_count = 0
    by_name = {item["normalized_name"]: item for item in nonlands}
    active_forced_keep = {
        item["normalized_name"]
        for item in nonlands
        if force_keep_active_anchor(item) or force_keep_active_core(item)
    }
    forced_keep_order = sorted(active_forced_keep) + sorted(protected_keep - active_forced_keep)
    for name in forced_keep_order:
        if len([card for card in selected if not card["is_land"]]) >= NONLAND_TARGET:
            break
        item = by_name.get(name)
        if not item or item["normalized_name"] in selected_names:
            continue
        if item["normalized_name"] not in active_names and novel_count >= max_novel:
            continue
        selected.append(item)
        selected_names.add(item["normalized_name"])
        if item["normalized_name"] not in active_names:
            novel_count += 1

    while len([card for card in selected if not card["is_land"]]) < NONLAND_TARGET:
        current_counts = role_metric_counts([card for card in selected if not card["is_land"]])
        current_strategy_counts = strategy_counts(
            [card for card in selected if not card["is_land"]]
        )
        scored = []
        for item in nonlands:
            if item["normalized_name"] in selected_names:
                continue
            if item["normalized_name"] not in active_names and novel_count >= max_novel:
                continue
            row = rows_by_name[item["normalized_name"]]
            score = effective_score(
                row,
                oracle[item["normalized_name"]],
                active_names=active_names,
                current_counts=current_counts,
                current_strategy_counts=current_strategy_counts,
                is_land_card=False,
            )
            scored.append((score, item["score"], item["card_name"], item))
        if not scored:
            raise RuntimeError("not enough eligible nonland cards to finish candidate deck")
        scored.sort(reverse=True)
        item = dict(scored[0][3])
        item["effective_score"] = scored[0][0]
        selected.append(item)
        selected_names.add(item["normalized_name"])
        if item["normalized_name"] not in active_names:
            novel_count += 1

    commander_row = rows_by_name.get(normalize_name(COMMANDER))
    commander_oracle = oracle.get(normalize_name(COMMANDER))
    commander_item = {
        "card_name": COMMANDER,
        "normalized_name": normalize_name(COMMANDER),
        "roles": sorted(roles_for(commander_row or {"roles": ["engine", "draw"]})),
        "is_land": False,
        "is_commander": True,
        "score": float((commander_row or {}).get("score") or 0),
        "effective_score": float((commander_row or {}).get("score") or 0),
        "recommendation_lane": (commander_row or {}).get("recommendation_lane"),
        "promotion_lane": (commander_row or {}).get("promotion_lane"),
        "deck_ids": (commander_row or {}).get("deck_ids") or [],
        "cmc": float((commander_oracle["cmc"] if commander_oracle else 5) or 0),
        "type_line": (commander_oracle["type_line"] if commander_oracle else "")
        or "Legendary Creature",
        "oracle_text": (commander_oracle["oracle_text"] if commander_oracle else "") or "",
        "color_identity": sorted(color_identity(commander_oracle)),
        "in_active_deck": True,
        "strategy_tags": sorted(
            strategy_tags_for_card(
                {
                    "card_name": COMMANDER,
                    "roles": sorted(roles_for(commander_row or {"roles": ["engine", "draw"]})),
                    "type_line": (commander_oracle["type_line"] if commander_oracle else "")
                    or "Legendary Creature",
                    "oracle_text": (commander_oracle["oracle_text"] if commander_oracle else "") or "",
                    "cmc": float((commander_oracle["cmc"] if commander_oracle else 5) or 0),
                    "in_active_deck": True,
                }
            )
        ),
        "strategy_score_breakdown": {},
    }
    final = [commander_item]
    for item in sorted(selected, key=lambda card: (not card["is_land"], card["card_name"])):
        item = dict(item)
        item["is_commander"] = False
        final.append(item)

    active_set = active_names
    final_set = {card["normalized_name"] for card in final}
    selection_summary = {
        "eligible_cards": len(eligible),
        "eligible_lands": len(lands),
        "eligible_nonlands": len(nonlands),
        "blocked_reasons": dict(blocked.most_common()),
        "novel_cards": sorted(
            card["card_name"] for card in final if card["normalized_name"] not in active_set
        ),
        "cut_from_active": sorted(
            row["card_name"] for row in active_rows if normalize_name(row["card_name"]) not in final_set
        ),
    }
    return final, selection_summary


def validate_deck(final: list[dict[str, Any]]) -> dict[str, Any]:
    names = [card["normalized_name"] for card in final]
    duplicate_names = sorted(name for name, count in Counter(names).items() if count > 1)
    lands = [card for card in final if card["is_land"]]
    nonlands = [card for card in final if not card["is_land"] and not card["is_commander"]]
    roles = Counter()
    for card in final:
        for role in card["roles"]:
            roles[role] += 1
    metric_counts = role_metric_counts([card for card in final if not card["is_commander"]])
    strategy_metric_counts = strategy_counts([card for card in final if not card["is_commander"]])
    strategy_package_shortfalls = strategy_shortfalls(
        [card for card in final if not card["is_commander"]]
    )
    role_shortfalls = {
        role: {"actual": metric_counts[role], "minimum": minimum}
        for role, minimum in ROLE_MINIMUMS.items()
        if metric_counts[role] < minimum
    }
    color_issues = [
        {
            "card_name": card["card_name"],
            "color_identity": card["color_identity"],
        }
        for card in final
        if not set(card["color_identity"]).issubset(ALLOWED_COLOR_IDENTITY)
    ]
    issues = []
    if len(final) != 100:
        issues.append(f"quantity_not_100:{len(final)}")
    if len(lands) != LAND_TARGET:
        issues.append(f"land_count_not_{LAND_TARGET}:{len(lands)}")
    if len(nonlands) != NONLAND_TARGET:
        issues.append(f"nonland_count_not_{NONLAND_TARGET}:{len(nonlands)}")
    if duplicate_names:
        issues.append("singleton_duplicates")
    if role_shortfalls:
        issues.append("role_shortfalls")
    if color_issues:
        issues.append("color_identity_issues")
    return {
        "status": "passed" if not issues else "blocked",
        "issues": issues,
        "quantity": len(final),
        "main_quantity": len(final) - 1,
        "land_count": len(lands),
        "nonland_count": len(nonlands),
        "distinct_cards": len(set(names)),
        "duplicate_normalized_names": duplicate_names,
        "role_counts": dict(sorted(roles.items())),
        "role_metric_counts": dict(sorted(metric_counts.items())),
        "role_shortfalls": role_shortfalls,
        "strategy_package_counts": dict(sorted(strategy_metric_counts.items())),
        "strategy_package_shortfalls": strategy_package_shortfalls,
        "color_identity_issues": color_issues,
        "battle_ready_cards": len(final),
    }


def candidate_hash(final: list[dict[str, Any]]) -> str:
    payload = [
        {
            "card_name": card["card_name"],
            "quantity": 1,
            "is_commander": bool(card["is_commander"]),
        }
        for card in final
    ]
    encoded = json.dumps(payload, sort_keys=True, ensure_ascii=True)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def insert_candidate_deck(
    source_db: Path,
    output_dir: Path,
    final: list[dict[str, Any]],
    *,
    deck_id: int,
    sync_run_id: str,
) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    candidate_db = output_dir / "knowledge_candidate.db"
    shutil.copy2(source_db, candidate_db)
    with connect(candidate_db) as conn:
        columns = [row[1] for row in conn.execute("PRAGMA table_info(deck_cards)")]
        active_by_name = {
            normalize_name(row["card_name"]): dict(row)
            for row in conn.execute("SELECT * FROM deck_cards WHERE deck_id=?", (deck_id,))
        }
        conn.execute("DELETE FROM deck_cards WHERE deck_id=?", (deck_id,))
        for card in final:
            values: dict[str, Any] = {column: None for column in columns}
            active_row = active_by_name.get(card["normalized_name"])
            if active_row:
                values.update(active_row)
            values["deck_id"] = deck_id
            values["card_name"] = card["card_name"]
            values["quantity"] = 1
            values["functional_tag"] = (
                "commander"
                if card["is_commander"]
                else next((role for role in card["roles"] if role != "unknown"), "candidate")
            )
            values["tag_confidence"] = active_row.get("tag_confidence") if active_row else None
            values["is_commander"] = 1 if card["is_commander"] else 0
            values["is_partner"] = 0
            values["cmc"] = card["cmc"]
            values["type_line"] = card["type_line"]
            values["oracle_text"] = card["oracle_text"]
            if "card_id" in values:
                values["card_id"] = active_row.get("card_id") if active_row else None
            if "functional_tags_json" in values:
                tags = ["commander"] + card["roles"] if card["is_commander"] else card["roles"]
                values["functional_tags_json"] = json.dumps(tags, ensure_ascii=True)
            if "semantic_tags_v2_json" in values and not values["semantic_tags_v2_json"]:
                values["semantic_tags_v2_json"] = "[]"
            if "battle_rules_json" in values:
                values["battle_rules_json"] = json.dumps(
                    active_rules_for_card(conn, card["card_name"]),
                    ensure_ascii=True,
                    sort_keys=True,
                )
            if "sync_run_id" in values:
                values["sync_run_id"] = sync_run_id
            for hash_col in ("deck_hash", "semantics_hash", "ruleset_hash"):
                if hash_col in values:
                    values[hash_col] = None
            insert_columns = [column for column in columns if column != "id"]
            placeholders = ",".join("?" for _ in insert_columns)
            conn.execute(
                f"INSERT INTO deck_cards ({','.join(insert_columns)}) VALUES ({placeholders})",
                [values[column] for column in insert_columns],
            )
        conn.commit()
        hashes = {
            "deck_hash": deck_hash(conn, deck_id),
            "semantics_hash": semantics_hash(conn, deck_id),
            "ruleset_hash": ruleset_hash(conn, deck_id),
        }
        for column, value in hashes.items():
            if column in columns:
                conn.execute(
                    f"UPDATE deck_cards SET {column}=? WHERE deck_id=?",
                    (value, deck_id),
                )
        conn.commit()
    return candidate_db


def render_markdown(report: dict[str, Any]) -> str:
    validation = report["validation"]
    selection = report["selection_summary"]
    lines = [
        "# Lorehold Generated Candidate Deck PG217",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- status: `{report['status']}`",
        f"- deck_id: `{report['deck_id']}`",
        f"- source_matrix: `{report['source_matrix']}`",
        f"- source_db: `{report['source_db']}`",
        f"- candidate_db: `{report['candidate_db']}`",
        f"- postgres_writes: `{report['postgres_writes']}`",
        f"- source_db_mutated: `{report['source_db_mutated']}`",
        f"- candidate_hash: `{report['candidate_hash']}`",
        "",
        "## Validation",
        "",
        f"- validation_status: `{validation['status']}`",
        f"- quantity: `{validation['quantity']}`",
        f"- main_quantity: `{validation['main_quantity']}`",
        f"- land_count: `{validation['land_count']}`",
        f"- nonland_count: `{validation['nonland_count']}`",
        f"- distinct_cards: `{validation['distinct_cards']}`",
        f"- role_shortfalls: `{json.dumps(validation['role_shortfalls'], sort_keys=True)}`",
        f"- color_identity_issues: `{json.dumps(validation['color_identity_issues'], sort_keys=True)}`",
        f"- novel_cards_vs_active: `{len(selection['novel_cards'])}`",
        f"- cuts_vs_active: `{len(selection['cut_from_active'])}`",
        "",
        "## Novel Cards",
        "",
    ]
    lines.extend(f"- {name}" for name in selection["novel_cards"])
    lines.extend(["", "## Cuts From Active Deck", ""])
    lines.extend(f"- {name}" for name in selection["cut_from_active"])
    lines.extend(["", "## Role Metric Counts", ""])
    for role, minimum in ROLE_MINIMUMS.items():
        lines.append(
            f"- {role}: `{validation['role_metric_counts'].get(role, 0)}` "
            f"(minimum `{minimum}`)"
        )
    lines.extend(["", "## Strategy Package Counts", ""])
    for package, count in validation["strategy_package_counts"].items():
        shortfall = validation["strategy_package_shortfalls"].get(package)
        suffix = f" (minimum `{shortfall['minimum']}`)" if shortfall else ""
        lines.append(f"- {package}: `{count}`{suffix}")
    lines.extend(["", "## Deck List", ""])
    for card in report["final_deck"]:
        lines.append(f"1 {card['card_name']}")
    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- Generated from battle-ready matrix rows only.",
            "- Cards with pending mapper/split/runtime promotion lanes were excluded.",
            "- Color identity was checked against the local card_oracle_cache.",
            "- The candidate SQLite DB is an isolated copy for battle smoke only.",
            "- This report does not approve applying the deck to PostgreSQL or deck 6.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrix", required=True)
    parser.add_argument("--db", default=str(DEFAULT_DB))
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--stem", default="")
    parser.add_argument("--max-novel", type=int, default=16)
    args = parser.parse_args()

    matrix_path = Path(args.matrix)
    source_db = Path(args.db)
    stem = args.stem or "lorehold_generated_candidate_pg217_v1"
    output_dir = REPORT_DIR / stem
    output_dir.mkdir(parents=True, exist_ok=True)
    generated_at = utc_now()
    sync_run_id = stem + "_" + generated_at.replace(":", "").replace("+", "_")

    matrix_rows, matrix_summary = load_matrix(matrix_path)
    with connect(source_db) as conn:
        active = deck_rows(conn, args.deck_id)
        current_deck_summary = get_deck_summary(conn, args.deck_id)
        names = {str(row.get("card_name") or "") for row in matrix_rows}
        names.add(COMMANDER)
        oracle = oracle_by_name(conn, names)
        final, selection_summary = select_deck(
            matrix_rows,
            oracle,
            active,
            max_novel=args.max_novel,
        )

    validation = validate_deck(final)
    status = "generated_isolated_candidate" if validation["status"] == "passed" else "blocked"
    candidate_db = insert_candidate_deck(
        source_db,
        output_dir,
        final,
        deck_id=args.deck_id,
        sync_run_id=sync_run_id,
    )
    with connect(candidate_db) as conn:
        candidate_deck_summary = get_deck_summary(conn, args.deck_id)

    report = {
        "generated_at": generated_at,
        "status": status,
        "deck_id": args.deck_id,
        "source_matrix": str(matrix_path),
        "source_db": str(source_db),
        "candidate_db": str(candidate_db),
        "postgres_writes": False,
        "source_db_mutated": False,
        "max_novel": args.max_novel,
        "strategy_version": STRATEGY_VERSION,
        "candidate_hash": candidate_hash(final),
        "current_deck_summary": current_deck_summary,
        "candidate_deck_summary": candidate_deck_summary,
        "matrix_summary": matrix_summary,
        "selection_summary": selection_summary,
        "validation": validation,
        "final_deck": final,
    }
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    print(json.dumps({"json": str(json_path), "markdown": str(md_path), "candidate_db": str(candidate_db), "status": status}, indent=2))
    return 0 if validation["status"] == "passed" else 2


if __name__ == "__main__":
    raise SystemExit(main())
