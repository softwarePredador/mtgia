#!/usr/bin/env python3
"""Synthesize Lorehold 607 mana sequencing policy.

This read-only auditor is deliberately narrower than a full battle gate. It
asks whether land/ramp candidates improve the current 607 mana sequence without
breaking Boros fixing, commander turn timing, protected miracle turn-cycle
mana, or already-tested cut evidence.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from lorehold_mana_foundation_audit import (
    BOROS_COLORS,
    as_float,
    as_int,
    card_text,
    etb_mode,
    is_land,
    land_roles,
    load_deck_cards,
    mana_colors,
    ramp_kind,
    role_counts,
    summarize_lands,
    summarize_ramp,
)
from master_optimizer_common import (
    normalize_name,
    resolve_default_knowledge_db,
    safe_cmc_from_card,
    sqlite_connection_has_table,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_DECK_ID = 607

PREMIUM_MOX_NAMES = {"Chrome Mox", "Mox Diamond", "Mox Opal", "Mox Amber"}
BANNED_FAST_MANA_NAMES = {"Mana Crypt", "Jeweled Lotus", "Black Lotus"}
TURN_CYCLE_MANA_NAMES = {"Bender's Waterskin", "Victory Chimes"}
PROTECTED_CURRENT_MANA_NAMES = {
    "Ancient Tomb",
    "Arcane Signet",
    "Bender's Waterskin",
    "Boros Signet",
    "Fellwar Stone",
    "Jeska's Will",
    "Land Tax",
    "Monument to Endurance",
    "Pearl Medallion",
    "Ruby Medallion",
    "Smothering Tithe",
    "Sol Ring",
    "Talisman of Conviction",
    "The Mind Stone",
    "Unexpected Windfall",
    "Victory Chimes",
    "Urza's Saga",
}

EXTERNAL_LEARNING = [
    {
        "source": "EDHREC Lorehold cEDH average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/cedh",
        "learning": (
            "The cEDH average list runs very low land count plus dense fast mana. "
            "That is a velocity signal, not proof that protected 607 should cut a "
            "colored source or miracle engine."
        ),
    },
    {
        "source": "EDHREC Miracles Every Turn with Lorehold",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "learning": (
            "Lorehold's critical window is the first draw on each turn; Top, Scroll "
            "Rack, Library of Leng, and opponent-turn mana matter more than generic "
            "value cards when they preserve miracle cadence."
        ),
    },
    {
        "source": "Card Kingdom Lorehold synergy article",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "learning": (
            "Victory Chimes and Bender's Waterskin are specifically turn-cycle "
            "miracle mana, not interchangeable three-mana rocks."
        ),
    },
    {
        "source": "CoolStuffInc Commander ramp discussion",
        "url": "https://www.coolstuffinc.com/a/markwischkaemper-06222023-how-much-ramp-is-right-for-your-commander-deck",
        "learning": (
            "Generic land/ramp math is a baseline. ManaLoom should adjust by deck "
            "plan, curve, commander cost, and how the ramp actually sequences."
        ),
    },
]

MANA_SEQUENCE_CANDIDATES = [
    "Ancient Tomb",
    "City of Traitors",
    "Gemstone Caverns",
    "Mana Confluence",
    "City of Brass",
    "Plateau",
    "Sacred Foundry",
    "Spectator Seating",
    "Sunbaked Canyon",
    "Urza's Saga",
    "Ancient Den",
    "Great Furnace",
    "Elegant Parlor",
    "Arid Mesa",
    "Marsh Flats",
    "Bloodstained Mire",
    "Flooded Strand",
    "Scalding Tarn",
    "Windswept Heath",
    "Wooded Foothills",
    "Command Tower",
    "Sol Ring",
    "Arcane Signet",
    "Fellwar Stone",
    "Boros Signet",
    "Talisman of Conviction",
    "Mana Vault",
    "Grim Monolith",
    "Chrome Mox",
    "Mox Diamond",
    "Mox Opal",
    "Mox Amber",
    "Lotus Petal",
    "Mana Crypt",
    "Jeweled Lotus",
    "Bender's Waterskin",
    "Victory Chimes",
    "Pearl Medallion",
    "Ruby Medallion",
    "Jeska's Will",
    "Rite of Flame",
    "Pyretic Ritual",
    "Seething Song",
    "Strike It Rich",
    "Storm-Kiln Artist",
    "Treasonous Ogre",
    "Smothering Tithe",
    "Monument to Endurance",
    "Big Score",
    "Unexpected Windfall",
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def newest_report(pattern: str, fallback: Path, *, report_dir: Path = REPORT_DIR) -> Path:
    matches = sorted(
        report_dir.glob(pattern),
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )
    return matches[0] if matches else fallback


def default_mana_foundation_report() -> Path:
    return newest_report(
        "lorehold_mana_foundation_audit_*.json",
        REPORT_DIR / "lorehold_mana_foundation_audit_20260704_learning.json",
    )


def default_staple_policy_report() -> Path:
    return newest_report(
        "lorehold_staple_policy_synthesis_*.json",
        REPORT_DIR / "lorehold_staple_policy_synthesis_20260704_learning.json",
    )


def default_ramp_package_report() -> Path:
    return newest_report(
        "lorehold_ramp_package_evaluation_*.json",
        REPORT_DIR / "lorehold_ramp_package_evaluation_20260704_learning_refresh_20260704_195019.json",
    )


def default_mana_vault_report() -> Path:
    return newest_report(
        "lorehold_mana_vault_evidence_synthesis_*.json",
        REPORT_DIR / "lorehold_mana_vault_evidence_synthesis_20260704_learning_refresh.json",
    )


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def read_json_if_exists(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def oracle_lookup(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {}
    row = conn.execute(
        """
        SELECT name, mana_cost, type_line, oracle_text, cmc, color_identity_json, card_id
        FROM card_oracle_cache
        WHERE normalized_name = ?
           OR lower(name) = lower(?)
        LIMIT 1
        """,
        (normalize_name(card_name), card_name),
    ).fetchone()
    return dict(row) if row else {}


def commander_legality(conn: sqlite3.Connection, card_name: str) -> str | None:
    if not sqlite_connection_has_table(conn, "card_legalities"):
        return None
    row = conn.execute(
        """
        SELECT status
        FROM card_legalities
        WHERE lower(card_name) = lower(?)
          AND lower(format) = 'commander'
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return str(row["status"]) if row else None


def format_staple(conn: sqlite3.Connection, card_name: str) -> dict[str, Any] | None:
    if not sqlite_connection_has_table(conn, "format_staples"):
        return None
    row = conn.execute(
        """
        SELECT card_name, archetype, category, color_identity, edhrec_rank, is_banned
        FROM format_staples
        WHERE lower(card_name) = lower(?)
          AND lower(format) = 'commander'
        ORDER BY edhrec_rank
        LIMIT 1
        """,
        (card_name,),
    ).fetchone()
    return dict(row) if row else None


def battle_rule_summary(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return {"rule_count": 0, "active_rule_count": 0, "scopes": []}
    rows = conn.execute(
        """
        SELECT execution_status, review_status, effect_json
        FROM battle_card_rules
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    scopes: set[str] = set()
    active = 0
    for row in rows:
        if str(row["execution_status"] or "") in {"auto", "active", "verified"} and str(
            row["review_status"] or ""
        ) in {"active", "verified", "reviewed"}:
            active += 1
        try:
            effect = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect = {}
        if isinstance(effect, Mapping) and effect.get("battle_model_scope"):
            scopes.add(str(effect["battle_model_scope"]))
    return {"rule_count": len(rows), "active_rule_count": active, "scopes": sorted(scopes)}


def source_decisions(report: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for key in ("candidate_staple_backlog", "candidate_staples"):
        rows = report.get(key)
        if not isinstance(rows, list):
            continue
        for row in rows:
            if isinstance(row, Mapping) and row.get("card_name"):
                out[normalize_name(str(row["card_name"]))] = dict(row)
    return out


def report_summary(report: Mapping[str, Any]) -> dict[str, Any]:
    summary = report.get("summary")
    return dict(summary) if isinstance(summary, Mapping) else {}


def card_from_oracle(card_name: str, oracle: Mapping[str, Any]) -> dict[str, Any]:
    return {
        "card_name": oracle.get("name") or card_name,
        "type_line": oracle.get("type_line") or "",
        "oracle_text": oracle.get("oracle_text") or "",
        "cmc": oracle.get("cmc"),
        "safe_cmc": safe_cmc_from_card(oracle, unknown_nonland_fallback=99.0),
        "quantity": 1,
        "functional_tag": "land" if "land" in str(oracle.get("type_line") or "").lower() else "",
    }


def candidate_lane(card_name: str, card: Mapping[str, Any]) -> str:
    text = card_text(card)
    type_line = str(card.get("type_line") or "").lower()
    colors = mana_colors(card)
    cmc = as_float(card.get("safe_cmc"), as_float(card.get("cmc")))
    if card_name in BANNED_FAST_MANA_NAMES:
        return "banned_fast_mana"
    if "land" in type_line:
        if "add {c}{c}" in text or card_name in {"City of Traitors", "Gemstone Caverns"}:
            return "fast_or_utility_land"
        if colors & BOROS_COLORS:
            return "colored_land_fixing"
        return "utility_land"
    if card_name in PREMIUM_MOX_NAMES:
        return "premium_mox_fast_mana"
    if card_name in TURN_CYCLE_MANA_NAMES or "untap this artifact during each other player's untap step" in text:
        return "turn_cycle_miracle_mana"
    if card_name == "Mana Vault" or "doesn't untap during your untap step" in text:
        return "fast_colorless_burst"
    if "cost {1} less" in text or "costs {1} less" in text:
        return "cost_reducer"
    if "treasure token" in text:
        return "treasure_or_discard_ramp"
    if "add {r} for each card" in text or ("sorcery" in type_line and "add" in text):
        return "ritual_or_spell_burst"
    if cmc <= 2 and colors & BOROS_COLORS:
        return "early_colored_rock"
    if "{t}: add {c}{c}" in text or "add {c}{c}" in text:
        return "early_colorless_burst"
    if "add" in text:
        return "contextual_mana_source"
    return "mana_sequence_low_context"


def current_mana_rows(cards: Iterable[Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for card in cards:
        name = str(card.get("card_name") or "")
        if not name:
            continue
        tag = str(card.get("functional_tag") or "").lower()
        if not (is_land(card) or tag == "ramp" or name == "Land Tax"):
            continue
        lane = candidate_lane(name, card)
        if name in TURN_CYCLE_MANA_NAMES:
            policy = "protected_turn_cycle_miracle_mana"
        elif name in PROTECTED_CURRENT_MANA_NAMES:
            policy = "protected_current_mana_foundation"
        elif lane in {"colored_land_fixing", "early_colored_rock"}:
            policy = "current_fixing_floor"
        elif lane in {"fast_or_utility_land", "utility_land"}:
            policy = "current_utility_land_watch"
        else:
            policy = "current_mana_role_card"
        rows.append(
            {
                "card_name": name,
                "quantity": as_int(card.get("quantity"), 1),
                "lane": lane,
                "policy_class": policy,
                "cmc": as_float(card.get("safe_cmc"), as_float(card.get("cmc"))),
                "colors": sorted(mana_colors(card)),
                "etb_mode": etb_mode(card) if is_land(card) else None,
                "roles": land_roles(card) if is_land(card) else [ramp_kind(card)] if tag == "ramp" else [],
            }
        )
    rows.sort(key=lambda row: (row["lane"], row["cmc"], row["card_name"]))
    return rows


def land_sequence_score(card: Mapping[str, Any]) -> dict[str, Any]:
    if not is_land(card):
        return {}
    mode = etb_mode(card)
    roles = land_roles(card)
    colors = mana_colors(card)
    score = 0
    reasons: list[str] = []
    if colors & BOROS_COLORS:
        score += 3
        reasons.append("boros_color_source")
    if mode == "untapped":
        score += 2
        reasons.append("untapped_timing")
    elif mode == "optional_life_untapped":
        score += 1
        reasons.append("can_enter_untapped_for_life")
    elif mode == "always_tapped":
        score -= 2
        reasons.append("always_tapped_tempo_cost")
    if "fast_colorless_acceleration" in roles:
        score += 3
        reasons.append("fast_land_mana")
    if "fetch_or_basic_access" in roles:
        score += 2
        reasons.append("fetch_or_basic_access")
    if "artifact_tutor_land" in roles:
        score += 2
        reasons.append("artifact_tutor_land")
    if "land_card_flow" in roles or "cycling_flood_escape" in roles:
        score += 1
        reasons.append("flood_escape")
    if colors and colors <= {"C"}:
        score -= 1
        reasons.append("colorless_only_pressure")
    return {"score": score, "reasons": reasons}


def direct_decision_from_reports(
    card_name: str,
    staple_decisions: Mapping[str, Mapping[str, Any]],
    mana_vault_report: Mapping[str, Any],
) -> tuple[str | None, list[str], dict[str, Any]]:
    key = normalize_name(card_name)
    if card_name == "Mana Vault":
        summary = report_summary(mana_vault_report)
        if summary.get("promotion_allowed") is False:
            return (
                "blocked_prior_gate_rejected",
                ["mana_vault_current_pair_lost_with_real_card_use"],
                {
                    "promotion_allowed": summary.get("promotion_allowed"),
                    "latest_gate_delta_pp": summary.get("latest_gate_delta_pp"),
                },
            )
    row = staple_decisions.get(key)
    if row and row.get("decision") and row.get("decision") != "already_in_protected_607":
        return (
            str(row["decision"]),
            [f"staple_policy:{row['decision']}"],
            {"staple_policy_lane": row.get("lane"), "staple_policy_reasons": row.get("decision_reasons") or []},
        )
    return None, [], {}


def classify_candidate(
    *,
    conn: sqlite3.Connection,
    card_name: str,
    cards_by_name: Mapping[str, Mapping[str, Any]],
    staple_decisions: Mapping[str, Mapping[str, Any]],
    mana_vault_report: Mapping[str, Any],
) -> dict[str, Any]:
    oracle = oracle_lookup(conn, card_name)
    current = cards_by_name.get(normalize_name(card_name))
    card = dict(current) if current else card_from_oracle(card_name, oracle)
    lane = candidate_lane(card_name, card)
    legality = commander_legality(conn, card_name)
    staple = format_staple(conn, card_name)
    direct_decision, direct_reasons, evidence = direct_decision_from_reports(
        card_name, staple_decisions, mana_vault_report
    )

    if current:
        if card_name in TURN_CYCLE_MANA_NAMES:
            decision = "already_in_607_protected_turn_cycle_miracle_mana"
            reasons = ["opponent_turn_miracle_mana_is_not_generic_ramp"]
        elif card_name in PROTECTED_CURRENT_MANA_NAMES:
            decision = "already_in_607_protected_mana_foundation"
            reasons = ["current_607_role_card"]
        else:
            decision = "already_in_607_mana_package"
            reasons = ["current_607_card"]
        policy = "current_protected_or_watch"
    elif card_name in BANNED_FAST_MANA_NAMES or legality == "banned":
        decision = "blocked_commander_banned_or_not_accessible"
        reasons = ["commander_ban_or_legality_block"]
        policy = "not_accessible"
    elif direct_decision:
        decision = direct_decision
        reasons = direct_reasons
        policy = "tested_or_policy_blocked"
    elif card_name in PREMIUM_MOX_NAMES:
        decision = "policy_blocked_no_premium_mox"
        reasons = ["premium_mox_requires_explicit_policy_and_same_lane_gate"]
        policy = "policy_blocked_fast_mana"
    elif lane == "fast_or_utility_land":
        decision = "candidate_land_requires_named_land_cut_and_equal_gate"
        reasons = ["fast_or_utility_land_cannot_cut_colored_or_protected_land_by_rank"]
        policy = "land_hypothesis"
    elif lane in {"colored_land_fixing", "utility_land"}:
        decision = "candidate_land_upgrade_requires_current_land_cut"
        reasons = ["mana_base_already_passes_current_foundation"]
        policy = "land_hypothesis"
    elif lane in {"ritual_or_spell_burst", "treasure_or_discard_ramp"}:
        decision = "candidate_spell_ramp_requires_spell_slot_gate"
        reasons = ["one_shot_or_contextual_ramp_is_not_opening_fixing"]
        policy = "spell_ramp_hypothesis"
    elif lane in {"fast_colorless_burst", "early_colorless_burst"}:
        decision = "candidate_fast_mana_requires_fixing_and_use_gate"
        reasons = ["colorless_burst_must_not_reduce_boros_fixing_or_miracle_cadence"]
        policy = "fast_mana_hypothesis"
    elif lane in {"early_colored_rock", "cost_reducer", "contextual_mana_source"}:
        decision = "candidate_requires_same_lane_cut_and_sequence_gate"
        reasons = ["must_preserve_commander_turn_and_current_protected_anchors"]
        policy = "same_lane_hypothesis"
    else:
        decision = "triage_backlog_not_mana_sequence_proof"
        reasons = ["low_context_mana_signal"]
        policy = "triage_backlog"

    sequence_score = land_sequence_score(card) if is_land(card) else {}
    return {
        "card_name": card_name,
        "in_protected_607": bool(current),
        "lane": lane,
        "policy_class": policy,
        "decision": decision,
        "decision_reasons": sorted(set(reasons)),
        "commander_legality": legality,
        "edhrec_rank": as_int((staple or {}).get("edhrec_rank"), 0) or None,
        "colors": sorted(mana_colors(card)),
        "safe_cmc": safe_cmc_from_card(card, unknown_nonland_fallback=99.0),
        "land_sequence_score": sequence_score,
        "battle_rule_summary": battle_rule_summary(conn, card_name),
        "evidence": evidence,
    }


def synthesize_status(candidate_rows: Iterable[Mapping[str, Any]], mana_foundation: Mapping[str, Any]) -> str:
    summary = report_summary(mana_foundation)
    if as_int(summary.get("blocker_count")) > 0:
        return "mana_sequence_foundation_blocked"
    promotable = {"direct_swap_ready", "promotion_ready", "natural_gate_won"}
    if any(str(row.get("decision")) in promotable for row in candidate_rows):
        return "mana_sequence_candidate_requires_gate_review"
    return "mana_sequence_no_direct_auto_upgrade_current_607"


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    mana_foundation_report_path: Path,
    staple_policy_report_path: Path,
    ramp_package_report_path: Path,
    mana_vault_report_path: Path,
    candidate_names: Iterable[str] = MANA_SEQUENCE_CANDIDATES,
) -> dict[str, Any]:
    cards = load_deck_cards(conn, deck_id)
    cards_by_name = {normalize_name(str(card.get("card_name") or "")): card for card in cards}
    lands = summarize_lands(cards)
    ramp = summarize_ramp(cards)
    mana_foundation = read_json_if_exists(mana_foundation_report_path)
    staple_policy = read_json_if_exists(staple_policy_report_path)
    ramp_package = read_json_if_exists(ramp_package_report_path)
    mana_vault = read_json_if_exists(mana_vault_report_path)
    staple_decisions = source_decisions(staple_policy)
    candidates = [
        classify_candidate(
            conn=conn,
            card_name=name,
            cards_by_name=cards_by_name,
            staple_decisions=staple_decisions,
            mana_vault_report=mana_vault,
        )
        for name in candidate_names
    ]
    candidates.sort(
        key=lambda row: (
            0 if row["in_protected_607"] else 1,
            row["lane"],
            row["edhrec_rank"] if row["edhrec_rank"] is not None else 999999,
            row["card_name"],
        )
    )
    current_rows = current_mana_rows(cards)
    lane_counts = Counter(str(row["lane"]) for row in candidates)
    decision_counts = Counter(str(row["decision"]) for row in candidates)
    current_policy_counts = Counter(str(row["policy_class"]) for row in current_rows)
    status = synthesize_status(candidates, mana_foundation)
    foundation_summary = report_summary(mana_foundation)
    ramp_package_summary = report_summary(ramp_package)
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_sequence_policy_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": status,
        "source_reports": {
            "mana_foundation": rel(mana_foundation_report_path),
            "staple_policy": rel(staple_policy_report_path),
            "ramp_package": rel(ramp_package_report_path),
            "mana_vault": rel(mana_vault_report_path),
        },
        "summary": {
            "total_cards": sum(as_int(card.get("quantity"), 1) for card in cards),
            "role_counts": role_counts(cards),
            "land_count": lands["land_count"],
            "ramp_count": ramp["ramp_count"],
            "early_foundation_count": ramp["early_foundation_count"],
            "true_early_mana_count": ramp["true_early_mana_count"],
            "red_source_count": lands["red_source_count"],
            "white_source_count": lands["white_source_count"],
            "colorless_only_land_count": len(lands["colorless_only_lands"]),
            "tapped_land_pressure_count": as_int((lands["tapped_mode_counts"] or {}).get("always_tapped"))
            + as_int((lands["tapped_mode_counts"] or {}).get("conditional_tapped")),
            "mana_foundation_status": mana_foundation.get("status"),
            "mana_foundation_blocker_count": as_int(foundation_summary.get("blocker_count")),
            "mana_foundation_watch_item_count": as_int(foundation_summary.get("watch_item_count")),
            "ramp_package_count": len(ramp_package.get("packages") or []),
            "ramp_package_summary_count": len(ramp_package_summary),
            "candidate_count": len(candidates),
            "candidate_lane_counts": dict(sorted(lane_counts.items())),
            "candidate_decision_counts": dict(sorted(decision_counts.items())),
            "current_policy_counts": dict(sorted(current_policy_counts.items())),
        },
        "external_learning": EXTERNAL_LEARNING,
        "mana_sequence_policy": {
            "commander_turn_target": "cast Lorehold on or before turn 5 while preserving RW access",
            "post_commander_target": "keep mana available across opponents' turns for first-draw miracle windows",
            "protected_principles": [
                "do not cut turn-cycle miracle mana as if it were a generic three-mana rock",
                "do not cut colored/fetchable sources for colorless burst without equal-gate proof",
                "do not treat rituals or treasures as opening fixing",
                "do not promote a land by prestige unless a current land cut is named",
            ],
        },
        "current_mana_package": current_rows,
        "candidate_mana_backlog": candidates,
        "decision": {
            "keep_607_mana_sequence_policy": status == "mana_sequence_no_direct_auto_upgrade_current_607",
            "reason": (
                "The protected 607 shell already passes the current land/ramp foundation and "
                "contains both early fixing and Lorehold-specific turn-cycle mana. Missing fast "
                "mana and land staples are either already in the deck, blocked by legality/policy, "
                "previously rejected, or require a named same-lane cut plus equal battle gate."
            ),
            "next_action": (
                "only generate a land/ramp challenger when it names the exact current land or ramp "
                "slot being cut and states which sequencing failure it is trying to fix"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Mana Sequence Policy Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- lands: `{summary['land_count']}`",
        f"- ramp: `{summary['ramp_count']}`",
        f"- early foundation pieces: `{summary['early_foundation_count']}`",
        f"- true early mana pieces: `{summary['true_early_mana_count']}`",
        f"- red sources: `{summary['red_source_count']}`",
        f"- white sources: `{summary['white_source_count']}`",
        f"- colorless-only lands: `{summary['colorless_only_land_count']}`",
        f"- tapped land pressure count: `{summary['tapped_land_pressure_count']}`",
        f"- mana foundation status: `{summary['mana_foundation_status']}`",
        f"- candidate decision counts: `{json.dumps(summary['candidate_decision_counts'], sort_keys=True)}`",
        "",
        "## Mana Sequence Policy",
        "",
        f"- commander_turn_target: `{payload['mana_sequence_policy']['commander_turn_target']}`",
        f"- post_commander_target: `{payload['mana_sequence_policy']['post_commander_target']}`",
    ]
    for item in payload["mana_sequence_policy"]["protected_principles"]:
        lines.append(f"- protected: {item}")
    lines.extend(
        [
            "",
            "## Current Mana Package",
            "",
            "| Card | Lane | Policy | CMC | Colors | Roles |",
            "| --- | --- | --- | ---: | --- | --- |",
        ]
    )
    for row in payload["current_mana_package"]:
        lines.append(
            "| {card} | `{lane}` | `{policy}` | {cmc:g} | {colors} | {roles} |".format(
                card=row["card_name"],
                lane=row["lane"],
                policy=row["policy_class"],
                cmc=as_float(row.get("cmc")),
                colors=", ".join(row.get("colors") or []) or "-",
                roles=", ".join(row.get("roles") or []) or "-",
            )
        )
    lines.extend(
        [
            "",
            "## Candidate Mana Backlog",
            "",
            "| Card | Lane | In 607 | Rank | Decision | Reasons |",
            "| --- | --- | --- | ---: | --- | --- |",
        ]
    )
    for row in payload["candidate_mana_backlog"]:
        lines.append(
            "| {card} | `{lane}` | `{in_607}` | {rank} | `{decision}` | {reasons} |".format(
                card=row["card_name"],
                lane=row["lane"],
                in_607=str(row["in_protected_607"]).lower(),
                rank=row.get("edhrec_rank") or "-",
                decision=row["decision"],
                reasons=", ".join(row.get("decision_reasons") or []) or "-",
            )
        )
    lines.extend(["", "## Learning Sources", ""])
    for source in payload["external_learning"]:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_mana_sequence_policy: `{str(decision['keep_607_mana_sequence_policy']).lower()}`")
    lines.append(f"- reason: {decision['reason']}")
    lines.append(f"- next_action: `{decision['next_action']}`")
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
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--mana-foundation-report", type=Path, default=None)
    parser.add_argument("--staple-policy-report", type=Path, default=None)
    parser.add_argument("--ramp-package-report", type=Path, default=None)
    parser.add_argument("--mana-vault-report", type=Path, default=None)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_mana_sequence_policy_synthesis",
    )
    args = parser.parse_args()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            mana_foundation_report_path=args.mana_foundation_report or default_mana_foundation_report(),
            staple_policy_report_path=args.staple_policy_report or default_staple_policy_report(),
            ramp_package_report_path=args.ramp_package_report or default_ramp_package_report(),
            mana_vault_report_path=args.mana_vault_report or default_mana_vault_report(),
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
