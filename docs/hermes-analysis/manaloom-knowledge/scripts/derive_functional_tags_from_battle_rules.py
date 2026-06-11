#!/usr/bin/env python3
"""Report-only derivation of card_function_tags from trusted battle rules.

Hermes proposes; PostgreSQL/backend owns. This script intentionally does not
write to PostgreSQL. It produces a sanitized candidate report that can be
reviewed before a future controlled apply path exists.
"""

from __future__ import annotations

import argparse
import json
from typing import Any

import battle_rule_registry
from db_helper import connect, sanitized_database_target
from sync_pg_target_deck_to_hermes import logical_rule_key, stable_json


DERIVED_SOURCE = "card_battle_rules_v1"
TRUSTED_REVIEW_STATUSES = {"verified", "active"}
TRUSTED_SOURCES = {"manual", "curated"}
MIN_CONFIDENCE = 0.75
DERIVABLE_TAGS = {
    "ramp",
    "draw",
    "removal",
    "board_wipe",
    "protection",
    "tutor",
    "wincon",
    "engine",
    "recursion",
}
TAG_ALIASES = {
    "wipe": "board_wipe",
    "damage_wipe": "board_wipe",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "remove_artifact_or_3dmg": "removal",
    "draw_cards": "draw",
    "draw_engine": "draw",
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "ramp_engine": "ramp",
    "land_ramp": "ramp",
    "treasure_maker": "ramp",
    "finisher": "wincon",
    "approach": "wincon",
    "token_maker": "wincon",
    "copy_spell": "engine",
    "land_recursion": "recursion",
    "land_recursion_creature": "recursion",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Produce report-only card_function_tags candidates from card_battle_rules."
    )
    parser.add_argument("--min-confidence", type=float, default=MIN_CONFIDENCE)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--output")
    return parser.parse_args()


def json_obj(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def normalize_tag(value: Any) -> str:
    tag = str(value or "").strip().lower()
    return TAG_ALIASES.get(tag, tag)


def tag_from_rule(effect_json: dict[str, Any], deck_role_json: dict[str, Any]) -> str:
    role_tag = normalize_tag(deck_role_json.get("category"))
    if role_tag in DERIVABLE_TAGS:
        return role_tag
    effect = normalize_tag(effect_json.get("effect"))
    mapped = normalize_tag(battle_rule_registry.EFFECT_TO_DECK_CATEGORY.get(effect, effect))
    if mapped in DERIVABLE_TAGS:
        return mapped
    return ""


def derivation_rejection_reason(
    *,
    review_status: str,
    source: str,
    confidence: float,
    tag: str,
    card_id: str | None,
    min_confidence: float,
) -> str:
    if not card_id:
        return "missing_card_id"
    if review_status not in TRUSTED_REVIEW_STATUSES:
        return "untrusted_review_status"
    if source not in TRUSTED_SOURCES:
        return "untrusted_source"
    if confidence < min_confidence:
        return "low_confidence"
    if tag not in DERIVABLE_TAGS:
        return "non_derivable_tag"
    return ""


def build_candidate(row: dict[str, Any], *, min_confidence: float) -> dict[str, Any]:
    effect_json = json_obj(row.get("effect_json"))
    deck_role_json = json_obj(row.get("deck_role_json"))
    tag = tag_from_rule(effect_json, deck_role_json)
    review_status = str(row.get("review_status") or "").lower()
    source = str(row.get("source") or "").lower()
    confidence = float(row.get("confidence") or 0.0)
    card_id = str(row.get("card_id") or "").strip() or None
    rule = {
        "effect": effect_json,
        "deck_role": deck_role_json,
        "source": source,
        "review_status": review_status,
        "confidence": confidence,
        "rule_version": int(row.get("rule_version") or 1),
        "oracle_hash": row.get("oracle_hash"),
    }
    key = logical_rule_key(rule)
    reason = derivation_rejection_reason(
        review_status=review_status,
        source=source,
        confidence=confidence,
        tag=tag,
        card_id=card_id,
        min_confidence=min_confidence,
    )
    return {
        "card_id": card_id,
        "card_name": row.get("card_name"),
        "tag": tag,
        "confidence": confidence,
        "source": DERIVED_SOURCE,
        "evidence": stable_json(
            {
                "battle_rule_source": source,
                "battle_rule_review_status": review_status,
                "battle_rule_confidence": confidence,
                "logical_rule_key": key,
                "effect": effect_json.get("effect"),
                "deck_role_category": deck_role_json.get("category"),
            }
        ),
        "logical_rule_key": key,
        "rejection_reason": reason,
    }


def load_battle_rules(limit: int) -> list[dict[str, Any]]:
    limit_sql = "LIMIT %s" if limit > 0 else ""
    params: tuple[Any, ...] = (limit,) if limit > 0 else ()
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""
                SELECT
                  card_id::text,
                  card_name,
                  effect_json,
                  deck_role_json,
                  source,
                  confidence::float,
                  review_status,
                  rule_version,
                  oracle_hash
                FROM card_battle_rules
                WHERE review_status NOT IN ('rejected', 'deprecated')
                ORDER BY card_name, rule_version DESC, confidence DESC
                {limit_sql}
                """,
                params,
            )
            return [
                {
                    "card_id": row[0],
                    "card_name": row[1],
                    "effect_json": row[2],
                    "deck_role_json": row[3],
                    "source": row[4],
                    "confidence": row[5],
                    "review_status": row[6],
                    "rule_version": row[7],
                    "oracle_hash": row[8],
                }
                for row in cur.fetchall()
            ]


def load_existing_function_tags() -> set[tuple[str, str]]:
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT card_id::text, LOWER(tag) FROM card_function_tags")
            return {(str(row[0]), normalize_tag(row[1])) for row in cur.fetchall()}


def build_report(*, min_confidence: float, limit: int) -> dict[str, Any]:
    existing = load_existing_function_tags()
    rules = load_battle_rules(limit)
    new_candidates: list[dict[str, Any]] = []
    already_present: list[dict[str, Any]] = []
    rejected_by_gate: list[dict[str, Any]] = []
    seen_candidate_keys: set[tuple[str, str, str]] = set()

    for row in rules:
        candidate = build_candidate(row, min_confidence=min_confidence)
        if candidate["rejection_reason"]:
            rejected_by_gate.append(candidate)
            continue
        candidate_key = (
            str(candidate["card_id"]),
            str(candidate["tag"]),
            str(candidate["logical_rule_key"]),
        )
        if candidate_key in seen_candidate_keys:
            continue
        seen_candidate_keys.add(candidate_key)
        existing_key = (str(candidate["card_id"]), str(candidate["tag"]))
        if existing_key in existing:
            already_present.append(candidate)
        else:
            new_candidates.append(candidate)

    return {
        "apply": False,
        "database_target": sanitized_database_target(),
        "source": DERIVED_SOURCE,
        "min_confidence": min_confidence,
        "rules_seen": len(rules),
        "new_candidates_count": len(new_candidates),
        "already_present_count": len(already_present),
        "rejected_by_gate_count": len(rejected_by_gate),
        "new_candidates": new_candidates,
        "already_present_sample": already_present[:25],
        "rejected_by_gate_sample": rejected_by_gate[:25],
    }


def main() -> int:
    args = parse_args()
    report = build_report(min_confidence=args.min_confidence, limit=args.limit)
    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
