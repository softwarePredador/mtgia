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
FUNCTIONAL_EFFECT_TAGS = {
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "ramp_engine": "ramp",
    "land_ramp": "ramp",
    "treasure_maker": "ramp",
    "silence_opponents": "protection",
    "silence_spell": "protection",
    "indestructible": "protection",
    "phase_out": "protection",
    "phase_creatures": "protection",
    "protect_creature": "protection",
    "redirect_removal": "protection",
    "counter": "protection",
    "hate_artifact": "protection",
    "life_artifact": "protection",
    "attack_limit": "protection",
    "attack_tax": "protection",
    "draw_cards": "draw",
    "draw_engine": "draw",
    "topdeck_manipulation": "draw",
    "loot": "draw",
    "tutor": "tutor",
    "finisher": "wincon",
    "approach": "wincon",
    "token_maker": "wincon",
    "overload_recursion": "wincon",
    "steal_all_creatures": "wincon",
    "pump_all": "wincon",
    "extra_turn": "wincon",
    "board_wipe": "board_wipe",
    "damage_wipe": "board_wipe",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "remove_artifact_or_3dmg": "removal",
    "damage_player_and_creatures": "removal",
    "deal_damage": "removal",
    "copy_spell": "engine",
    "recursion": "recursion",
    "land_recursion": "recursion",
    "land_recursion_creature": "recursion",
}
TAG_ALIASES = {
    "wipe": "board_wipe",
    "damage_wipe": "board_wipe",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "remove_artifact_or_3dmg": "removal",
    "damage_player_and_creatures": "removal",
    "draw_cards": "draw",
    "draw_engine": "draw",
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "ramp_engine": "ramp",
    "land_ramp": "ramp",
    "treasure_maker": "ramp",
    "attack_limit": "protection",
    "attack_tax": "protection",
    "finisher": "wincon",
    "approach": "wincon",
    "token_maker": "wincon",
    "copy_spell": "engine",
    "land_recursion": "recursion",
    "land_recursion_creature": "recursion",
}
CARD_EFFECT_REVIEW_FLAGS = {
    # These rules are useful to the battle simulator, but too contextual to
    # become canonical deckbuilding function tags without card-by-card review.
    ("dramatic reversal", "draw_cards"): "card_specific_effect_scope_review",
    ("dramatic reversal", "ramp_ritual"): "combo_ramp_scope_review",
    ("manamorphose", "treasure_maker"): "mana_filter_not_treasure_review",
    ("victory chimes", "draw_engine"): "mana_engine_not_draw_review",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Produce report-only card_function_tags candidates from card_battle_rules."
    )
    parser.add_argument("--min-confidence", type=float, default=MIN_CONFIDENCE)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--allowlist",
        help=(
            "Optional JSON review allowlist. Supports a list or an object with "
            "approved/allowlist entries. Entries can be strings or objects with "
            "card_id, card_name, tag and/or logical_rule_key."
        ),
    )
    parser.add_argument(
        "--allow-manual-review",
        action="store_true",
        help=(
            "Allow allowlist entries to include manual_review candidates. "
            "Default false keeps scope-sensitive candidates blocked."
        ),
    )
    parser.add_argument(
        "--pg-transaction-dry-run",
        action="store_true",
        help=(
            "Exercise the PostgreSQL insert/update/delete path inside a "
            "transaction that is always rolled back. This is the only database "
            "mutation mode in this runner; it proves counts without applying "
            "canonical card_function_tags changes."
        ),
    )
    parser.add_argument(
        "--apply-reviewed-allowlist",
        action="store_true",
        help=(
            "Apply allowlisted low-risk candidates to PostgreSQL. This is "
            "blocked unless the allowlist JSON has apply_approved=true and "
            "--confirm-apply-card-battle-rules-v1 is also passed."
        ),
    )
    parser.add_argument(
        "--confirm-apply-card-battle-rules-v1",
        action="store_true",
        help=(
            "Second operator confirmation required for --apply-reviewed-allowlist."
        ),
    )
    parser.add_argument("--output")
    return parser.parse_args()


def json_obj(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def normalize_tag(value: Any) -> str:
    tag = str(value or "").strip().lower()
    return TAG_ALIASES.get(tag, tag)


def normalize_rule_effect(value: Any) -> str:
    return str(value or "").strip().lower()


def normalize_card_key(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().split())


def functional_tag_from_effect(effect_json: dict[str, Any]) -> str:
    effect = normalize_rule_effect(effect_json.get("effect"))
    mapped = normalize_tag(FUNCTIONAL_EFFECT_TAGS.get(effect, ""))
    if mapped in DERIVABLE_TAGS:
        return mapped
    mapped = normalize_tag(battle_rule_registry.EFFECT_TO_DECK_CATEGORY.get(effect, effect))
    if mapped in DERIVABLE_TAGS:
        return mapped
    return ""


def tag_from_rule(effect_json: dict[str, Any], deck_role_json: dict[str, Any]) -> str:
    # Functional tags should prefer the traceable effect when it maps to a
    # specific deckbuilding role. The battle registry can intentionally group
    # effects like recursion as "engine" for simulation, but card_function_tags
    # already has a more precise "recursion" role.
    effect_tag = functional_tag_from_effect(effect_json)
    if effect_tag:
        return effect_tag
    role_tag = normalize_tag(deck_role_json.get("category"))
    if role_tag in DERIVABLE_TAGS:
        return role_tag
    return ""


def review_flags(
    *,
    card_name: Any,
    tag: str,
    effect: str,
    role_tag: str,
    confidence: float,
    tag_basis: str,
) -> list[str]:
    flags: list[str] = []
    if " // " in str(card_name or ""):
        flags.append("multi_face_review")
    if confidence < 1.0:
        flags.append("lower_confidence_review")
    if tag_basis == "effect" and role_tag in DERIVABLE_TAGS and role_tag != tag:
        flags.append("effect_overrode_broad_role")
    if tag == "draw" and effect == "topdeck_manipulation":
        flags.append("topdeck_not_direct_draw_review")
    if tag == "protection" and effect in {
        "counter",
        "hate_artifact",
        "life_artifact",
        "phase_creatures",
        "redirect_removal",
        "silence_opponents",
        "silence_spell",
    }:
        flags.append("protection_scope_review")
    if tag == "ramp" and effect in {"ramp_engine", "ramp_permanent"}:
        flags.append("conditional_ramp_review")
    if tag == "tutor":
        flags.append("tutor_scope_review")
    if tag == "wincon" and effect not in {"approach", "finisher"}:
        flags.append("wincon_scope_review")
    card_effect_flag = CARD_EFFECT_REVIEW_FLAGS.get(
        (normalize_card_key(card_name), effect)
    )
    if card_effect_flag:
        flags.append(card_effect_flag)
    return sorted(set(flags))


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


def candidate_allowlist_keys(candidate: dict[str, Any]) -> set[str]:
    card_id = str(candidate.get("card_id") or "")
    card_name = str(candidate.get("card_name") or "")
    tag = str(candidate.get("tag") or "")
    logical_key = str(candidate.get("logical_rule_key") or "")
    return {
        logical_key,
        f"{card_id}|{tag}",
        f"{card_name}|{tag}",
        f"{card_id}|{tag}|{logical_key}",
        f"{card_name}|{tag}|{logical_key}",
    }


def allowlist_keys_from_entry(entry: Any) -> set[str]:
    if isinstance(entry, str):
        value = entry.strip()
        return {value} if value else set()
    if not isinstance(entry, dict):
        return set()
    card_id = str(entry.get("card_id") or "").strip()
    card_name = str(entry.get("card_name") or "").strip()
    tag = str(entry.get("tag") or "").strip()
    logical_key = str(entry.get("logical_rule_key") or "").strip()
    keys = set()
    if logical_key:
        keys.add(logical_key)
    if card_id and tag:
        keys.add(f"{card_id}|{tag}")
    if card_name and tag:
        keys.add(f"{card_name}|{tag}")
    if card_id and tag and logical_key:
        keys.add(f"{card_id}|{tag}|{logical_key}")
    if card_name and tag and logical_key:
        keys.add(f"{card_name}|{tag}|{logical_key}")
    return keys


def allowlist_entries_from_data(data: Any) -> tuple[list[Any], bool]:
    if isinstance(data, dict):
        entries = data.get("approved", data.get("allowlist", []))
        apply_approved = data.get("apply_approved") is True
    else:
        entries = data
        apply_approved = False
    if not isinstance(entries, list):
        raise ValueError("allowlist JSON must be a list or an object with approved/allowlist list")
    return entries, apply_approved


def load_allowlist_data(path: str | None) -> dict[str, Any]:
    if not path:
        return {
            "keys": set(),
            "entry_count": 0,
            "apply_approved": False,
            "path": None,
        }
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    entries, apply_approved = allowlist_entries_from_data(data)
    keys: set[str] = set()
    for entry in entries:
        keys.update(allowlist_keys_from_entry(entry))
    return {
        "keys": {key for key in keys if key},
        "entry_count": len(entries),
        "apply_approved": apply_approved,
        "path": path,
    }


def load_allowlist(path: str | None) -> set[str]:
    return set(load_allowlist_data(path)["keys"])


def evidence_logical_rule_key(evidence: Any) -> str:
    if isinstance(evidence, dict):
        return str(evidence.get("logical_rule_key") or "").strip()
    if not isinstance(evidence, str):
        return ""
    try:
        parsed = json.loads(evidence)
    except json.JSONDecodeError:
        return ""
    if not isinstance(parsed, dict):
        return ""
    return str(parsed.get("logical_rule_key") or "").strip()


def build_candidate(row: dict[str, Any], *, min_confidence: float) -> dict[str, Any]:
    effect_json = json_obj(row.get("effect_json"))
    deck_role_json = json_obj(row.get("deck_role_json"))
    tag = tag_from_rule(effect_json, deck_role_json)
    effect = normalize_rule_effect(effect_json.get("effect"))
    role_tag = normalize_tag(deck_role_json.get("category"))
    effect_tag = functional_tag_from_effect(effect_json)
    tag_basis = "effect" if effect_tag and effect_tag == tag else "deck_role"
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
    flags = [] if reason else review_flags(
        card_name=row.get("card_name"),
        tag=tag,
        effect=effect,
        role_tag=role_tag,
        confidence=confidence,
        tag_basis=tag_basis,
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
                "functional_tag_basis": tag_basis,
            }
        ),
        "logical_rule_key": key,
        "review_flags": flags,
        "review_bucket": "manual_review" if flags else "low_risk_review",
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


def load_existing_derived_function_tags() -> list[dict[str, Any]]:
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  card_id::text,
                  card_name,
                  LOWER(tag),
                  confidence::float,
                  evidence
                FROM card_function_tags
                WHERE source = %s
                ORDER BY card_name, tag
                """,
                (DERIVED_SOURCE,),
            )
            return [
                {
                    "card_id": row[0],
                    "card_name": row[1],
                    "tag": normalize_tag(row[2]),
                    "confidence": float(row[3] or 0.0),
                    "evidence": row[4],
                    "logical_rule_key": evidence_logical_rule_key(row[4]),
                }
                for row in cur.fetchall()
            ]


def stale_cleanup_candidates(
    existing_derived_tags: list[dict[str, Any]],
    valid_candidates: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    valid_keys = {
        (
            str(candidate.get("card_id") or ""),
            str(candidate.get("tag") or ""),
            str(candidate.get("logical_rule_key") or ""),
        )
        for candidate in valid_candidates
        if candidate.get("card_id")
        and candidate.get("tag")
        and candidate.get("logical_rule_key")
        and not candidate.get("rejection_reason")
    }
    stale: list[dict[str, Any]] = []
    for tag in existing_derived_tags:
        logical_key = str(tag.get("logical_rule_key") or "")
        key = (
            str(tag.get("card_id") or ""),
            str(tag.get("tag") or ""),
            logical_key,
        )
        if not logical_key:
            reason = "missing_logical_rule_key"
        elif key not in valid_keys:
            reason = "logical_rule_no_longer_derivable"
        else:
            continue
        stale.append(
            {
                "card_id": tag.get("card_id"),
                "card_name": tag.get("card_name"),
                "tag": tag.get("tag"),
                "logical_rule_key": logical_key,
                "reason": reason,
            }
        )
    return stale


def apply_allowlist(
    candidates: list[dict[str, Any]],
    *,
    allowlist_keys: set[str],
    allow_manual_review: bool,
) -> dict[str, Any]:
    if not allowlist_keys:
        return {
            "allowlist_loaded_count": 0,
            "allowlisted_candidates_count": 0,
            "allowlist_blocked_manual_review_count": 0,
            "allowlist_unmatched_count": 0,
            "allowlisted_candidates": [],
            "allowlist_blocked_manual_review": [],
            "allowlist_unmatched": [],
        }

    matched_keys: set[str] = set()
    allowlisted: list[dict[str, Any]] = []
    blocked_manual: list[dict[str, Any]] = []

    for candidate in candidates:
        keys = candidate_allowlist_keys(candidate)
        matching = keys & allowlist_keys
        if not matching:
            continue
        matched_keys.update(matching)
        if candidate["review_bucket"] == "manual_review" and not allow_manual_review:
            blocked_manual.append(candidate)
            continue
        allowlisted.append(candidate)

    return {
        "allowlist_loaded_count": len(allowlist_keys),
        "allowlisted_candidates_count": len(allowlisted),
        "allowlist_blocked_manual_review_count": len(blocked_manual),
        "allowlist_unmatched_count": len(allowlist_keys - matched_keys),
        "allowlisted_candidates": allowlisted,
        "allowlist_blocked_manual_review": blocked_manual,
        "allowlist_unmatched": sorted(allowlist_keys - matched_keys),
    }


def build_report(
    *,
    min_confidence: float,
    limit: int,
    allowlist_keys: set[str] | None = None,
    allow_manual_review: bool = False,
) -> dict[str, Any]:
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

    allowlist_report = apply_allowlist(
        new_candidates,
        allowlist_keys=allowlist_keys or set(),
        allow_manual_review=allow_manual_review,
    )
    existing_derived = load_existing_derived_function_tags()
    stale_candidates = stale_cleanup_candidates(
        existing_derived,
        [*already_present, *new_candidates],
    )
    return {
        "apply": False,
        "database_target": sanitized_database_target(),
        "source": DERIVED_SOURCE,
        "min_confidence": min_confidence,
        "rules_seen": len(rules),
        "new_candidates_count": len(new_candidates),
        "already_present_count": len(already_present),
        "rejected_by_gate_count": len(rejected_by_gate),
        "manual_review_count": sum(
            1 for candidate in new_candidates if candidate["review_bucket"] == "manual_review"
        ),
        "low_risk_review_count": sum(
            1 for candidate in new_candidates if candidate["review_bucket"] == "low_risk_review"
        ),
        "new_candidates": new_candidates,
        "already_present_sample": already_present[:25],
        "rejected_by_gate_sample": rejected_by_gate[:25],
        "existing_derived_tags_count": len(existing_derived),
        "stale_cleanup_candidates_count": len(stale_candidates),
        "stale_cleanup_candidates": stale_candidates,
        **allowlist_report,
    }


def validate_apply_preconditions(
    report: dict[str, Any],
    *,
    allowlist_apply_approved: bool,
    confirm_apply: bool,
    allow_manual_review: bool,
) -> list[str]:
    errors: list[str] = []
    if report.get("apply") is not False:
        errors.append("report_apply_flag_must_start_false")
    if not allowlist_apply_approved:
        errors.append("allowlist_apply_approved_required")
    if not confirm_apply:
        errors.append("operator_confirmation_required")
    if allow_manual_review:
        errors.append("manual_review_apply_not_allowed")
    if int(report.get("allowlisted_candidates_count") or 0) <= 0:
        errors.append("no_allowlisted_candidates")
    if int(report.get("allowlist_blocked_manual_review_count") or 0) != 0:
        errors.append("blocked_manual_review_candidates_present")
    if int(report.get("allowlist_unmatched_count") or 0) != 0:
        errors.append("allowlist_unmatched_keys_present")
    return errors


def _mutate_pg_derived_tags(
    *,
    report: dict[str, Any],
    commit: bool,
) -> dict[str, Any]:
    allowlisted = list(report.get("allowlisted_candidates") or [])
    stale = list(report.get("stale_cleanup_candidates") or [])
    conn = connect()
    deleted_count = 0
    upsert_count = 0
    source_count_after_mutation = 0
    try:
        conn.autocommit = False
        with conn.cursor() as cur:
            for candidate in stale:
                cur.execute(
                    """
                    DELETE FROM card_function_tags
                    WHERE source = %s
                      AND card_id::text = %s
                      AND LOWER(tag) = %s
                    """,
                    (
                        DERIVED_SOURCE,
                        str(candidate.get("card_id") or ""),
                        str(candidate.get("tag") or ""),
                    ),
                )
                deleted_count += max(cur.rowcount, 0)

            for candidate in allowlisted:
                cur.execute(
                    """
                    INSERT INTO card_function_tags (
                      card_id, card_name, tag, confidence, source, evidence, updated_at
                    )
                    VALUES (%s::uuid, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
                    ON CONFLICT (card_id, tag, source) DO UPDATE SET
                      card_name = EXCLUDED.card_name,
                      confidence = EXCLUDED.confidence,
                      evidence = EXCLUDED.evidence,
                      updated_at = CURRENT_TIMESTAMP
                    """,
                    (
                        candidate.get("card_id"),
                        candidate.get("card_name"),
                        candidate.get("tag"),
                        candidate.get("confidence"),
                        DERIVED_SOURCE,
                        candidate.get("evidence"),
                    ),
                )
                upsert_count += max(cur.rowcount, 0)

            cur.execute(
                "SELECT COUNT(*)::int FROM card_function_tags WHERE source = %s",
                (DERIVED_SOURCE,),
            )
            row = cur.fetchone()
            source_count_after_mutation = int(row[0]) if row else 0
        if commit:
            conn.commit()
        else:
            conn.rollback()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return {
        "committed": commit,
        "rolled_back": not commit,
        "deleted_stale_count": deleted_count,
        "upserted_allowlisted_count": upsert_count,
        "source_count_after_mutation": source_count_after_mutation,
    }


def run_pg_apply(
    report: dict[str, Any],
    *,
    allowlist_apply_approved: bool,
    confirm_apply: bool,
    allow_manual_review: bool,
) -> dict[str, Any]:
    errors = validate_apply_preconditions(
        report,
        allowlist_apply_approved=allowlist_apply_approved,
        confirm_apply=confirm_apply,
        allow_manual_review=allow_manual_review,
    )
    if errors:
        return {
            "enabled": True,
            "applied": False,
            "blocked": True,
            "reasons": errors,
        }
    mutation = _mutate_pg_derived_tags(report=report, commit=True)
    return {
        "enabled": True,
        "applied": True,
        "blocked": False,
        **mutation,
    }


def main() -> int:
    args = parse_args()
    allowlist_data = load_allowlist_data(args.allowlist)
    allowlist_keys = set(allowlist_data["keys"])
    report = build_report(
        min_confidence=args.min_confidence,
        limit=args.limit,
        allowlist_keys=allowlist_keys,
        allow_manual_review=args.allow_manual_review,
    )
    report["allowlist_entry_count"] = allowlist_data["entry_count"]
    report["allowlist_apply_approved"] = allowlist_data["apply_approved"]
    if args.pg_transaction_dry_run:
        report["pg_transaction_dry_run"] = _mutate_pg_derived_tags(
            report=report,
            commit=False,
        )
        report["pg_transaction_dry_run"]["enabled"] = True
        report["pg_transaction_dry_run"][
            "would_delete_stale_count"
        ] = report["pg_transaction_dry_run"].pop("deleted_stale_count")
        report["pg_transaction_dry_run"][
            "would_upsert_allowlisted_count"
        ] = report["pg_transaction_dry_run"].pop("upserted_allowlisted_count")
        report["pg_transaction_dry_run"][
            "source_count_after_mutation_before_rollback"
        ] = report["pg_transaction_dry_run"].pop("source_count_after_mutation")
    if args.apply_reviewed_allowlist:
        report["pg_apply"] = run_pg_apply(
            report,
            allowlist_apply_approved=bool(allowlist_data["apply_approved"]),
            confirm_apply=args.confirm_apply_card_battle_rules_v1,
            allow_manual_review=args.allow_manual_review,
        )
        report["apply"] = bool(report["pg_apply"].get("applied"))
    output = json.dumps(report, ensure_ascii=True, indent=2, sort_keys=True)
    print(output)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
