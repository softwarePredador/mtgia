#!/usr/bin/env python3
"""Synthesize Lorehold 607 interaction, protection, and removal evidence.

This read-only auditor answers the next deckbuilding question after mana and
card-flow: does protected deck 607 need a direct interaction/protection/removal
swap, or does the evidence only justify a future same-lane package hypothesis?
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

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
DEFAULT_EDHREC_CARD_DATA = SCRIPT_DIR / "_edhrec_card_data.json"
DEFAULT_TIBALT_DECISION = REPORT_DIR / "lorehold_tibalt_replacement_decision_20260630.md"

CURRENT_FLOOR_CARDS = [
    "Swords to Plowshares",
    "Path to Exile",
    "Generous Gift",
    "Stroke of Midnight",
    "Winds of Abandon",
    "Deflecting Swat",
    "Dawn's Truce",
    "Flawless Maneuver",
    "Teferi's Protection",
    "Mother of Runes",
    "Giver of Runes",
    "Lightning Greaves",
    "Swiftfoot Boots",
    "Farewell",
    "Promise of Loyalty",
    "Tibalt's Trickery",
]

INTERACTION_CANDIDATES = [
    "Silence",
    "Orim's Chant",
    "Pyroblast",
    "Red Elemental Blast",
    "Reprieve",
    "Boros Charm",
    "Grand Abolisher",
    "Perch Protection",
    "Akroma's Will",
    "Chaos Warp",
    "Wear // Tear",
    "Abrade",
]

PRIOR_TIBALT_REPLACEMENT_CARDS = {
    normalize_name("Boros Charm"),
    normalize_name("Silence"),
    normalize_name("Grand Abolisher"),
}

STACK_OR_SILENCE_CARDS = {
    normalize_name(card)
    for card in [
        "Silence",
        "Orim's Chant",
        "Pyroblast",
        "Red Elemental Blast",
        "Reprieve",
        "Boros Charm",
        "Grand Abolisher",
        "Tibalt's Trickery",
        "Deflecting Swat",
        "Redirect Lightning",
    ]
}

NARROW_COLOR_HATE = {
    normalize_name("Pyroblast"),
    normalize_name("Red Elemental Blast"),
}

REMOVAL_CANDIDATES = {
    normalize_name(card)
    for card in [
        "Chaos Warp",
        "Wear // Tear",
        "Abrade",
    ]
}

PROTECTION_PRESSURE_CANDIDATES = {
    normalize_name(card)
    for card in [
        "Perch Protection",
        "Akroma's Will",
    ]
}

PRESSURE_ABSORBER_CARDS = {
    normalize_name(card)
    for card in [
        "Promise of Loyalty",
        "Avatar's Wrath",
        "Perch Protection",
        "Akroma's Will",
    ]
}

EXTERNAL_LEARNING = [
    {
        "source": "EDHREC Lorehold cEDH average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/cedh",
        "learning": (
            "The current cEDH average shell includes cheap stack interaction and spell "
            "windows such as Deflecting Swat, Orim's Chant, Pyroblast, Red Elemental "
            "Blast, Silence, Swords to Plowshares, and Path to Exile."
        ),
    },
    {
        "source": "EDHREC Lorehold cEDH article",
        "url": "https://edhrec.com/articles/a-cedh-miracle-with-lorehold-the-historian",
        "learning": (
            "Lorehold's plan depends on reaching the commander and converting miracle "
            "windows into decisive spells, so protection is valuable only when it keeps "
            "that plan executing."
        ),
    },
    {
        "source": "TopDeck.gg cEDH rules interaction article",
        "url": "https://topdeck.gg/articles/cedh-important-rules-interactions",
        "learning": (
            "REB and Pyroblast are both stack-relevant but differ under redirect effects; "
            "that makes them meta/targeting hypotheses, not generic removal upgrades."
        ),
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def read_json_if_exists(path: Path) -> Any:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def json_list(value: object) -> list[Any]:
    if isinstance(value, list):
        return value
    if value in (None, ""):
        return []
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def as_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    if sqlite_connection_has_table(conn, "card_oracle_cache"):
        from_sql = """
        FROM deck_cards dc
        LEFT JOIN card_oracle_cache coc
          ON coc.normalized_name = lower(dc.card_name)
        """
        mana_cost_sql = "coc.mana_cost AS mana_cost"
    else:
        from_sql = "FROM deck_cards dc"
        mana_cost_sql = "'' AS mana_cost"
    rows = conn.execute(
        f"""
        SELECT dc.card_name, dc.quantity, dc.functional_tag, dc.functional_tags_json,
               dc.is_commander, dc.cmc, dc.type_line, dc.oracle_text, {mana_cost_sql}
        {from_sql}
        WHERE dc.deck_id = ?
        ORDER BY dc.is_commander DESC, dc.card_name
        """,
        (deck_id,),
    ).fetchall()
    cards: list[dict[str, Any]] = []
    for row in rows:
        card = dict(row)
        card["quantity"] = as_int(card.get("quantity"), 1)
        card["functional_tags"] = json_list(card.get("functional_tags_json"))
        card["safe_cmc"] = safe_cmc_from_card(card, unknown_nonland_fallback=99.0)
        cards.append(card)
    return cards


def variant_usage(
    conn: sqlite3.Connection,
    card_names: Iterable[str],
    variant_deck_ids: Iterable[int],
) -> dict[str, dict[str, Any]]:
    wanted = {normalize_name(name): str(name) for name in card_names if str(name).strip()}
    out = {
        key: {"card_name": name, "deck_count": 0, "deck_ids": [], "functional_tags": []}
        for key, name in wanted.items()
    }
    if not out:
        return out
    deck_ids = list(variant_deck_ids)
    if not deck_ids:
        return out
    placeholders = ",".join("?" for _ in wanted)
    deck_placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT card_name, deck_id, functional_tag
        FROM deck_cards
        WHERE lower(card_name) IN ({placeholders})
          AND deck_id IN ({deck_placeholders})
        ORDER BY card_name, deck_id
        """,
        [name.lower() for name in wanted.values()] + deck_ids,
    ).fetchall()
    for row in rows:
        key = normalize_name(row["card_name"])
        if key not in out:
            continue
        out[key]["deck_ids"].append(as_int(row["deck_id"]))
        if row["functional_tag"]:
            out[key]["functional_tags"].append(str(row["functional_tag"]))
    for row in out.values():
        row["deck_ids"] = sorted(set(row["deck_ids"]))
        row["deck_count"] = len(row["deck_ids"])
        row["functional_tags"] = sorted(set(row["functional_tags"]))
    return out


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


def battle_rule_summary(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return {
            "rule_count": 0,
            "active_rule_count": 0,
            "effects": [],
            "battle_model_scopes": [],
        }
    rows = conn.execute(
        """
        SELECT execution_status, review_status, effect_json
        FROM battle_card_rules
        WHERE lower(card_name) = lower(?)
           OR normalized_name = ?
        ORDER BY execution_status, review_status
        """,
        (card_name, normalize_name(card_name)),
    ).fetchall()
    active_statuses = {"auto", "active", "verified", "reviewed"}
    active_reviews = {"active", "verified", "reviewed", "needs_review"}
    active = 0
    effects: set[str] = set()
    scopes: set[str] = set()
    for row in rows:
        is_active = (
            str(row["execution_status"] or "") in active_statuses
            and str(row["review_status"] or "") in active_reviews
        )
        if is_active:
            active += 1
        try:
            effect = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect = {}
        if isinstance(effect, Mapping):
            if effect.get("effect"):
                effects.add(str(effect["effect"]))
            if effect.get("battle_model_scope"):
                scopes.add(str(effect["battle_model_scope"]))
    return {
        "rule_count": len(rows),
        "active_rule_count": active,
        "effects": sorted(effects),
        "battle_model_scopes": sorted(scopes),
    }


def load_edhrec_stats(path: Path, card_names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_name(name): name for name in card_names}
    out: dict[str, dict[str, Any]] = {}
    payload = read_json_if_exists(path)
    rows = payload if isinstance(payload, list) else []
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        key = normalize_name(str(row.get("name") or ""))
        if key not in wanted:
            continue
        potential = as_float(row.get("potential_decks"))
        inclusion = as_float(row.get("inclusion"))
        pct = as_float(row.get("pct"), 100.0 * inclusion / potential if potential else 0.0)
        out[wanted[key]] = {
            "inclusion": as_int(row.get("inclusion")),
            "potential_decks": as_int(row.get("potential_decks")),
            "pct": round(pct, 2),
            "synergy": row.get("synergy"),
            "source": rel(path),
        }
    return out


def infer_lane(card: Mapping[str, Any], rule: Mapping[str, Any] | None = None) -> str:
    name_key = normalize_name(str(card.get("card_name") or ""))
    tags = {str(card.get("functional_tag") or "").lower()}
    tags.update(str(tag).lower() for tag in card.get("functional_tags") or [])
    effects = set((rule or {}).get("effects") or [])
    scopes = " ".join((rule or {}).get("battle_model_scopes") or []).lower()
    if name_key in STACK_OR_SILENCE_CARDS or effects & {
        "silence_spell",
        "silence_opponents",
        "counter",
        "modal_spell",
        "redirect_removal",
        "return_target_spell_to_hand",
    }:
        return "stack_or_spell_protection"
    if "board_wipe" in tags or "wipe" in tags or "board_wipe" in effects:
        return "board_wipe"
    if (
        name_key in PROTECTION_PRESSURE_CANDIDATES
        or name_key in PRESSURE_ABSORBER_CARDS
        or "phase" in scopes
        or "indestructible" in scopes
        or "vow_counter" in " ".join(effects)
    ):
        return "pressure_protection"
    if "counter_protection" in scopes or "cant_be_countered" in scopes or "ward" in scopes:
        return "protection_resilience"
    if "protection" in tags or effects & {
        "phase_out",
        "indestructible",
        "gift_hexproof_indestructible",
        "equipment_haste_shroud",
        "equipment_static_attachment",
    }:
        return "protection_resilience"
    if "removal" in tags or any(
        str(effect).startswith("remove") or "destroy" in str(effect) for effect in effects
    ):
        return "spot_removal"
    if name_key in REMOVAL_CANDIDATES:
        return "spot_removal"
    return "other"


def is_current_interaction_card(card: Mapping[str, Any], lane: str) -> bool:
    name_key = normalize_name(str(card.get("card_name") or ""))
    tags = {str(card.get("functional_tag") or "").lower()}
    tags.update(str(tag).lower() for tag in card.get("functional_tags") or [])
    return (
        lane != "other"
        or name_key in {normalize_name(card_name) for card_name in CURRENT_FLOOR_CARDS}
        or bool(tags & {"removal", "protection", "board_wipe", "wipe"})
    )


def load_tibalt_replacement_decision(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {
            "path": str(path),
            "status": "missing",
            "decision": "",
            "rejected_cards": [],
        }
    text = path.read_text(encoding="utf-8")
    decision_match = re.search(r"decision:\s*`([^`]+)`", text)
    decision = decision_match.group(1) if decision_match else ""
    rejected_cards: list[str] = []
    if decision == "reject_tested_replacements_keep_deck_607":
        rejected_cards = ["Boros Charm", "Silence", "Grand Abolisher"]
    return {
        "path": rel(path),
        "status": "loaded",
        "decision": decision,
        "rejected_cards": rejected_cards,
        "mentions_real_confirmed_gate": "Confirmed Gates" in text,
    }


def current_floor_profile(
    conn: sqlite3.Connection,
    cards_by_name: Mapping[str, Mapping[str, Any]],
    variant_lookup: Mapping[str, Mapping[str, Any]],
    edhrec_stats: Mapping[str, Mapping[str, Any]],
    card_name: str,
) -> dict[str, Any]:
    key = normalize_name(card_name)
    card = dict(cards_by_name.get(key) or {"card_name": card_name, "functional_tags": []})
    rule = battle_rule_summary(conn, card_name)
    return {
        "card_name": card_name,
        "in_607": key in cards_by_name,
        "lane": infer_lane(card, rule),
        "cmc": card.get("safe_cmc"),
        "functional_tag": card.get("functional_tag"),
        "commander_legality": commander_legality(conn, card_name),
        "edhrec_lorehold": dict(edhrec_stats.get(card_name) or {}),
        "variant_usage": dict(variant_lookup.get(key) or {}),
        "battle_rule_summary": rule,
    }


def current_interaction_profiles(
    conn: sqlite3.Connection,
    cards_by_name: Mapping[str, Mapping[str, Any]],
    variant_lookup: Mapping[str, Mapping[str, Any]],
    edhrec_stats: Mapping[str, Mapping[str, Any]],
) -> list[dict[str, Any]]:
    profiles: list[dict[str, Any]] = []
    for card in cards_by_name.values():
        card_name = str(card.get("card_name") or "")
        if not card_name:
            continue
        rule = battle_rule_summary(conn, card_name)
        lane = infer_lane(card, rule)
        if not is_current_interaction_card(card, lane):
            continue
        profiles.append(
            {
                "card_name": card_name,
                "in_607": True,
                "lane": lane,
                "cmc": card.get("safe_cmc"),
                "functional_tag": card.get("functional_tag"),
                "commander_legality": commander_legality(conn, card_name),
                "edhrec_lorehold": dict(edhrec_stats.get(card_name) or {}),
                "variant_usage": dict(variant_lookup.get(normalize_name(card_name)) or {}),
                "battle_rule_summary": rule,
            }
        )
    profiles.sort(key=lambda row: (str(row["lane"]), float(row.get("cmc") or 99.0), row["card_name"]))
    return profiles


def candidate_decision(
    *,
    card_name: str,
    in_607: bool,
    lane: str,
    rule: Mapping[str, Any],
    variant: Mapping[str, Any],
    tibalt_decision: Mapping[str, Any],
    current_counts: Mapping[str, int],
) -> tuple[str, list[str]]:
    key = normalize_name(card_name)
    reasons: list[str] = []
    if in_607:
        return "already_in_607_floor_or_anchor", ["current_baseline_card"]
    if (
        key in PRIOR_TIBALT_REPLACEMENT_CARDS
        and card_name in set(tibalt_decision.get("rejected_cards") or [])
    ):
        return "prior_tibalt_replacement_rejected", [
            "same_function_tibalt_replacement_lost_confirmed_gate",
            "do_not_repeat_exact_slot_without_new_evidence",
        ]
    if as_int(rule.get("active_rule_count")) <= 0:
        return "blocked_runtime_rule_missing", ["candidate_missing_active_battle_rule"]
    if key in NARROW_COLOR_HATE:
        reasons.append("narrow_color_hate_requires_meta_or_blue_stack_gate")
        return "meta_stack_candidate_needs_targeted_gate_or_safe_cut", reasons
    if key == normalize_name("Orim's Chant"):
        reasons.append("no_current_local_variant_usage")
        reasons.append("same_lane_stack_cut_not_proven")
        return "stack_candidate_needs_new_same_lane_package", reasons
    if key == normalize_name("Reprieve"):
        reasons.append("variant_supported_but_no_current_confirmed_win")
        reasons.append("same_lane_stack_cut_not_proven")
        return "stack_candidate_needs_new_same_lane_package", reasons
    if key in PROTECTION_PRESSURE_CANDIDATES:
        reasons.append("pressure_protection_candidate")
        reasons.append("same_lane_cut_must_preserve_current_protection_floor")
        return "pressure_protection_candidate_needs_gate", reasons
    if key in REMOVAL_CANDIDATES:
        if as_int(current_counts.get("spot_removal")) >= 5:
            return "blocked_current_removal_floor_sufficient", [
                "607_already_has_broad_active_spot_removal_floor",
                "same_lane_cut_not_proven",
            ]
    if lane == "stack_or_spell_protection" and as_int(variant.get("deck_count")) > 0:
        return "stack_candidate_needs_new_same_lane_package", [
            "variant_supported",
            "same_lane_stack_cut_not_proven",
        ]
    return "candidate_hypothesis_no_direct_swap_ready", ["no_seed_safe_cut_or_gate"]


def candidate_profile(
    conn: sqlite3.Connection,
    cards_by_name: Mapping[str, Mapping[str, Any]],
    variant_lookup: Mapping[str, Mapping[str, Any]],
    edhrec_stats: Mapping[str, Mapping[str, Any]],
    tibalt_decision: Mapping[str, Any],
    current_counts: Mapping[str, int],
    card_name: str,
) -> dict[str, Any]:
    key = normalize_name(card_name)
    current_card = dict(cards_by_name.get(key) or {"card_name": card_name, "functional_tags": []})
    rule = battle_rule_summary(conn, card_name)
    lane = infer_lane(current_card, rule)
    variant = dict(variant_lookup.get(key) or {})
    decision, reasons = candidate_decision(
        card_name=card_name,
        in_607=key in cards_by_name,
        lane=lane,
        rule=rule,
        variant=variant,
        tibalt_decision=tibalt_decision,
        current_counts=current_counts,
    )
    return {
        "card_name": card_name,
        "in_607": key in cards_by_name,
        "lane": lane,
        "commander_legality": commander_legality(conn, card_name),
        "edhrec_lorehold": dict(edhrec_stats.get(card_name) or {}),
        "variant_usage": variant,
        "battle_rule_summary": rule,
        "decision": decision,
        "decision_reasons": reasons,
    }


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    edhrec_card_data: Path,
    tibalt_decision_path: Path,
    variant_deck_ids: Iterable[int] = range(608, 617),
) -> dict[str, Any]:
    deck_cards = load_deck_cards(conn, deck_id)
    cards_by_name = {normalize_name(str(card.get("card_name") or "")): card for card in deck_cards}
    all_names = sorted(
        set(
            CURRENT_FLOOR_CARDS
            + INTERACTION_CANDIDATES
            + [str(card.get("card_name") or "") for card in deck_cards if card.get("card_name")]
        )
    )
    edhrec_stats = load_edhrec_stats(edhrec_card_data, all_names)
    variant_lookup = variant_usage(conn, all_names, variant_deck_ids)
    current_profiles = current_interaction_profiles(conn, cards_by_name, variant_lookup, edhrec_stats)
    current_counts = Counter(
        row["lane"]
        for row in current_profiles
        if row["in_607"]
    )
    tibalt_decision = load_tibalt_replacement_decision(tibalt_decision_path)
    candidates = [
        candidate_profile(
            conn,
            cards_by_name,
            variant_lookup,
            edhrec_stats,
            tibalt_decision,
            current_counts,
            name,
        )
        for name in INTERACTION_CANDIDATES
    ]
    direct_swap_ready = [
        row
        for row in candidates
        if row["decision"] in {"direct_swap_ready", "gate_ready"}
    ]
    divergences = []
    stack_candidates = [
        row
        for row in candidates
        if row["lane"] == "stack_or_spell_protection" and not row["in_607"]
    ]
    if stack_candidates:
        divergences.append(
            {
                "key": "external_stack_window_pressure_without_safe_cut",
                "detail": (
                    "External cEDH and local variants point to extra stack/silence windows, "
                    "but current evidence does not prove a replacement over protected 607."
                ),
                "cards": [row["card_name"] for row in stack_candidates],
            }
        )
    rejected = [
        row["card_name"]
        for row in candidates
        if row["decision"] == "prior_tibalt_replacement_rejected"
    ]
    if rejected:
        divergences.append(
            {
                "key": "obvious_tibalt_slot_already_rejected",
                "detail": (
                    "The most obvious same-lane Tibalt's Trickery replacement slot already "
                    "lost confirmed real-opponent gates."
                ),
                "cards": rejected,
            }
        )
    status = (
        "interaction_resilience_no_direct_swap_ready_current_607"
        if not direct_swap_ready
        else "interaction_resilience_candidate_requires_gate_review"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_interaction_resilience_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": status,
        "source_reports": {
            "edhrec_card_data": rel(edhrec_card_data),
            "tibalt_replacement_decision": rel(tibalt_decision_path),
        },
        "summary": {
            "total_cards": sum(as_int(card.get("quantity"), 1) for card in deck_cards),
            "current_floor_card_count": sum(1 for row in current_profiles if row["in_607"]),
            "current_lane_counts": dict(sorted(current_counts.items())),
            "candidate_count": len(candidates),
            "direct_swap_ready_count": len(direct_swap_ready),
            "prior_tibalt_rejected_count": len(rejected),
            "stack_candidate_without_safe_cut_count": len(stack_candidates),
            "tibalt_replacement_decision": tibalt_decision.get("decision"),
            "divergence_count": len(divergences),
        },
        "external_learning": EXTERNAL_LEARNING,
        "tibalt_replacement_decision": tibalt_decision,
        "current_floor_profiles": current_profiles,
        "candidate_profiles": candidates,
        "divergences": divergences,
        "decision": {
            "keep_607_interaction_resilience_package": status
            == "interaction_resilience_no_direct_swap_ready_current_607",
            "reason": (
                "Deck 607 already contains a broad active removal/protection floor. "
                "The extra stack/silence cards are real hypotheses, but the obvious "
                "Tibalt replacement slot already lost confirmed gates and no other "
                "same-lane seed-safe cut is proven."
            ),
            "next_action": (
                "build a new same-lane protection-window package only if it avoids "
                "repeating rejected Tibalt replacements and preserves 607's current "
                "removal, wipe, miracle, and protection floor"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Interaction Resilience Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- current floor cards in 607: `{summary['current_floor_card_count']}`",
        f"- current lane counts: `{json.dumps(summary['current_lane_counts'], sort_keys=True)}`",
        f"- candidates reviewed: `{summary['candidate_count']}`",
        f"- direct swap-ready candidates: `{summary['direct_swap_ready_count']}`",
        f"- prior Tibalt replacements rejected: `{summary['prior_tibalt_rejected_count']}`",
        f"- stack candidates without safe cut: `{summary['stack_candidate_without_safe_cut_count']}`",
        f"- Tibalt decision: `{summary.get('tibalt_replacement_decision') or '-'}`",
        "",
        "## Current 607 Floor",
        "",
        "| Card | In 607 | Lane | EDHREC Lorehold | Active Rules | Variants |",
        "| --- | --- | --- | ---: | ---: | --- |",
    ]
    for row in payload["current_floor_profiles"]:
        stats = row.get("edhrec_lorehold") or {}
        rules = row.get("battle_rule_summary") or {}
        variant = row.get("variant_usage") or {}
        pct = stats.get("pct")
        lines.append(
            "| {card} | `{in_607}` | `{lane}` | {pct} | {rules} | {variants} |".format(
                card=row["card_name"],
                in_607=str(row["in_607"]).lower(),
                lane=row["lane"],
                pct=f"{pct}%" if pct is not None else "-",
                rules=rules.get("active_rule_count", 0),
                variants=", ".join(str(value) for value in variant.get("deck_ids") or []) or "-",
            )
        )
    lines.extend(
        [
            "",
            "## Candidate Review",
            "",
            "| Card | In 607 | Lane | EDHREC Lorehold | Variants | Decision | Reasons |",
            "| --- | --- | --- | ---: | --- | --- | --- |",
        ]
    )
    for row in payload["candidate_profiles"]:
        stats = row.get("edhrec_lorehold") or {}
        variant = row.get("variant_usage") or {}
        pct = stats.get("pct")
        lines.append(
            "| {card} | `{in_607}` | `{lane}` | {pct} | {variants} | `{decision}` | {reasons} |".format(
                card=row["card_name"],
                in_607=str(row["in_607"]).lower(),
                lane=row["lane"],
                pct=f"{pct}%" if pct is not None else "-",
                variants=", ".join(str(value) for value in variant.get("deck_ids") or []) or "-",
                decision=row["decision"],
                reasons=", ".join(row.get("decision_reasons") or []) or "-",
            )
        )
    if payload.get("divergences"):
        lines.extend(["", "## Divergences", ""])
        for row in payload["divergences"]:
            lines.append(
                f"- `{row['key']}`: {row['detail']} Cards: {', '.join(row.get('cards') or []) or '-'}."
            )
    lines.extend(["", "## Learning Sources", ""])
    for row in payload["external_learning"]:
        lines.append(f"- {row['source']}: {row['url']}")
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- keep_607_interaction_resilience_package: `{str(payload['decision']['keep_607_interaction_resilience_package']).lower()}`",
            f"- reason: {payload['decision']['reason']}",
            f"- next_action: `{payload['decision']['next_action']}`",
            "",
        ]
    )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--edhrec-card-data", type=Path, default=DEFAULT_EDHREC_CARD_DATA)
    parser.add_argument("--tibalt-decision", type=Path, default=DEFAULT_TIBALT_DECISION)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_interaction_resilience_synthesis_current",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            edhrec_card_data=args.edhrec_card_data,
            tibalt_decision_path=args.tibalt_decision,
        )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
