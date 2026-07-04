#!/usr/bin/env python3
"""Synthesize Lorehold 607 staple policy and backlog lanes.

This read-only auditor turns the raw Commander staple gap into deckbuilding
policy: which staples already protect the 607 floor, which famous cards were
tested and rejected, which are merely commander-context hypotheses, and which
generic staples need a named same-lane cut before any battle gate.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter, defaultdict
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
BOROS_COLORS = {"R", "W"}

STRUCTURAL_FLOOR_NAMES = {
    "Sol Ring",
    "Arcane Signet",
    "Fellwar Stone",
    "Boros Signet",
    "Talisman of Conviction",
    "Swords to Plowshares",
    "Path to Exile",
    "Generous Gift",
    "Smothering Tithe",
    "Esper Sentinel",
    "Deflecting Swat",
    "Teferi's Protection",
    "Jeska's Will",
}

LOREHOLD_CONTEXT_NAMES = {
    "Sensei's Divining Top",
    "Scroll Rack",
    "Library of Leng",
    "Land Tax",
    "Bender's Waterskin",
    "Victory Chimes",
    "Ruby Medallion",
    "Pearl Medallion",
    "Molecule Man",
    "Creative Technique",
    "Reforge the Soul",
}

PREMIUM_MOX_POLICY_NAMES = {
    "Chrome Mox",
    "Mox Diamond",
    "Mox Opal",
    "Mox Amber",
}

GENERIC_TAPPED_LAND_NAMES = {
    "Evolving Wilds",
    "Terramorphic Expanse",
    "Myriad Landscape",
    "Fabled Passage",
}

SUPPLEMENTAL_STAPLE_CANDIDATES = [
    {
        "card_name": "The One Ring",
        "edhrec_rank": 180,
        "archetypes": ["draw"],
        "categories": ["external_lorehold_cedh"],
        "color_identity": "",
    },
    {
        "card_name": "Possibility Storm",
        "edhrec_rank": 260,
        "archetypes": ["combo"],
        "categories": ["local_profiled_cut"],
        "color_identity": "R",
    },
]

KNOWN_INTERACTION_NAMES = {
    "Abrade",
    "Boros Charm",
    "Chaos Warp",
    "Grand Abolisher",
    "Orim's Chant",
    "Pyroblast",
    "Red Elemental Blast",
    "Reprieve",
    "Silence",
    "Untimely Malfunction",
    "Vandalblast",
    "Wear // Tear",
}

EXTERNAL_LEARNING = [
    {
        "source": "Wizards banned and restricted list",
        "url": "https://magic.wizards.com/en/banned-restricted-list",
        "learning": (
            "Commander legality is format-specific. Mana Crypt, Jeweled Lotus, and the five Moxen "
            "are banned in Commander, while Mana Vault and The One Ring are not listed in the "
            "Commander banned section checked on 2026-07-04."
        ),
    },
    {
        "source": "EDHREC Lorehold cEDH average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/cedh",
        "learning": (
            "The cEDH average deck uses premium artifacts, Mana Vault, The One Ring, Underworld "
            "Breach, and optimized lands; those are role signals, not automatic 607 cuts."
        ),
    },
    {
        "source": "EDHREC ramp guide",
        "url": "https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander",
        "learning": (
            "Ramp is useful when it lets a deck spend more mana ahead of curve. Ramp that competes "
            "with the commander turn or removes utility has to prove the tradeoff."
        ),
    },
    {
        "source": "EDHREC cEDH Lorehold article",
        "url": "https://edhrec.com/articles/a-cedh-miracle-with-lorehold-the-historian",
        "learning": (
            "Lorehold's true contextual staples are miracle/topdeck tools such as Top, Scroll Rack, "
            "and Library of Leng, plus cards that reach and convert the commander window."
        ),
    },
    {
        "source": "EDHREC ramp top ten",
        "url": "https://edhrec.com/articles/the-10-best-ramp-spells-in-commander-that-arent-sol-ring",
        "learning": (
            "Sol Ring and Arcane Signet are format-level floor cards, but the article itself frames "
            "other ramp by Commander-specific edge cases rather than universal auto-inclusion."
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


def newest_report(pattern: str, fallback: Path, *, report_dir: Path = REPORT_DIR) -> Path:
    matches = sorted(
        report_dir.glob(pattern),
        key=lambda path: (path.stat().st_mtime, path.name),
        reverse=True,
    )
    return matches[0] if matches else fallback


def default_mana_foundation_report() -> Path:
    return newest_report(
        "lorehold_mana_foundation_audit_20260704_learning.json",
        REPORT_DIR / "lorehold_mana_foundation_audit_20260704_learning.json",
    )


def default_staple_gap_report() -> Path:
    return newest_report(
        "lorehold_607_unprotected_format_staples_gap_20260704_current.json",
        REPORT_DIR / "lorehold_607_unprotected_format_staples_gap_20260704_current.json",
    )


def default_staple_summary_report() -> Path:
    return newest_report(
        "lorehold_607_unprotected_staple_relearn_summary_20260704.md",
        REPORT_DIR / "lorehold_607_unprotected_staple_relearn_summary_20260704.md",
    )


def default_profiled_cut_report() -> Path:
    return newest_report(
        "lorehold_607_unprotected_profiled_cut_benchmark_generator_20260704_current.json",
        REPORT_DIR / "lorehold_607_unprotected_profiled_cut_benchmark_generator_20260704_current.json",
    )


def default_mana_vault_report() -> Path:
    return newest_report(
        "lorehold_mana_vault_evidence_synthesis_20260704_learning_refresh.json",
        REPORT_DIR / "lorehold_mana_vault_evidence_synthesis_20260704_learning_refresh.json",
    )


def default_selection_report() -> Path:
    return newest_report(
        "lorehold_selection_access_synthesis_20260704_learning*.json",
        REPORT_DIR / "lorehold_selection_access_synthesis_20260704_learning.json",
    )


def default_interaction_report() -> Path:
    return newest_report(
        "lorehold_interaction_resilience_synthesis_20260704_learning*.json",
        REPORT_DIR / "lorehold_interaction_resilience_synthesis_20260704_learning.json",
    )


def default_payoff_report() -> Path:
    return newest_report(
        "lorehold_payoff_finisher_recursion_synthesis_20260704_learning.json",
        REPORT_DIR / "lorehold_payoff_finisher_recursion_synthesis_20260704_learning.json",
    )


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


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


def read_json_if_exists(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def read_text_if_exists(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


def report_summary(report: Mapping[str, Any]) -> dict[str, Any]:
    summary = report.get("summary")
    return dict(summary) if isinstance(summary, Mapping) else {}


def color_identity_allowed(value: str | None) -> bool:
    if not value:
        return True
    colors = {part.strip() for part in str(value).replace(",", " ").split() if part.strip()}
    return colors.issubset(BOROS_COLORS)


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


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT deck_id, card_name, quantity, functional_tag, functional_tags_json,
               is_commander, cmc, type_line, oracle_text, card_id
        FROM deck_cards
        WHERE deck_id = ?
        ORDER BY is_commander DESC, card_name
        """,
        (deck_id,),
    ).fetchall()
    out: list[dict[str, Any]] = []
    for row in rows:
        card = dict(row)
        oracle = oracle_lookup(conn, str(card.get("card_name") or ""))
        for field in ("mana_cost", "type_line", "oracle_text", "cmc", "color_identity_json", "card_id"):
            if field == "mana_cost" and oracle.get(field):
                card[field] = oracle[field]
            elif card.get(field) in (None, "") and oracle.get(field) not in (None, ""):
                card[field] = oracle[field]
        card["safe_cmc"] = safe_cmc_from_card(card, unknown_nonland_fallback=99.0)
        out.append(card)
    return out


def aggregate_format_staples(conn: sqlite3.Connection, *, rank_limit: int = 750) -> list[dict[str, Any]]:
    if not sqlite_connection_has_table(conn, "format_staples"):
        return []
    rows = conn.execute(
        """
        SELECT card_name, archetype, category, color_identity, edhrec_rank, is_banned
        FROM format_staples
        WHERE lower(format) = 'commander'
          AND coalesce(edhrec_rank, 999999) <= ?
          AND coalesce(is_banned, 0) = 0
        ORDER BY edhrec_rank, card_name
        """,
        (rank_limit,),
    ).fetchall()
    grouped: dict[str, dict[str, Any]] = {}
    for row in rows:
        if not color_identity_allowed(row["color_identity"]):
            continue
        key = normalize_name(str(row["card_name"]))
        item = grouped.setdefault(
            key,
            {
                "card_name": row["card_name"],
                "edhrec_rank": as_int(row["edhrec_rank"], 999999),
                "archetypes": set(),
                "categories": set(),
                "color_identity": row["color_identity"] or "",
            },
        )
        item["edhrec_rank"] = min(item["edhrec_rank"], as_int(row["edhrec_rank"], 999999))
        if row["archetype"]:
            item["archetypes"].add(str(row["archetype"]))
        if row["category"]:
            item["categories"].add(str(row["category"]))
    out = []
    for item in grouped.values():
        out.append(
            {
                **item,
                "archetypes": sorted(item["archetypes"]),
                "categories": sorted(item["categories"]),
            }
        )
    for supplemental in SUPPLEMENTAL_STAPLE_CANDIDATES:
        if normalize_name(str(supplemental["card_name"])) not in grouped:
            out.append(dict(supplemental))
    out.sort(key=lambda row: (row["edhrec_rank"], row["card_name"]))
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
        return {"rule_count": 0, "active_rule_count": 0}
    rows = conn.execute(
        """
        SELECT execution_status, review_status
        FROM battle_card_rules
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    active = 0
    for row in rows:
        if str(row["execution_status"] or "") in {"auto", "active", "verified"} and str(
            row["review_status"] or ""
        ) in {"active", "verified", "reviewed"}:
            active += 1
    return {"rule_count": len(rows), "active_rule_count": active}


def variant_usage(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "lorehold_variant_deck_cards"):
        return {"variant_count": 0}
    rows = conn.execute(
        """
        SELECT DISTINCT deck_hash
        FROM lorehold_variant_deck_cards
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    return {"variant_count": len(rows)}


def classify_lane(card_name: str, archetypes: Iterable[str], type_line: str, oracle_text: str) -> str:
    archetype_set = {str(item).lower() for item in archetypes}
    text = f"{type_line}\n{oracle_text}".lower()
    name_key = normalize_name(card_name)
    if card_name == "The One Ring":
        return "card_draw_selection"
    if card_name in KNOWN_INTERACTION_NAMES:
        if card_name in {"Silence", "Orim's Chant", "Grand Abolisher", "Boros Charm"}:
            return "protection_resilience"
        return "interaction_removal"
    if "land" in type_line.lower() or name_key in {normalize_name(name) for name in GENERIC_TAPPED_LAND_NAMES}:
        return "mana_base"
    if "ramp" in archetype_set or "add " in text or "treasure token" in text:
        return "ramp"
    if (
        "removal" in archetype_set
        or "destroy target" in text
        or "exile target" in text
        or "owner of target permanent shuffles" in text
        or "shuffles it into their library" in text
    ):
        return "interaction_removal"
    if (
        "protection" in archetype_set
        or "protection" in text
        or "indestructible" in text
        or "can't cast spells" in text
    ):
        return "protection_resilience"
    if "draw" in archetype_set or "draw" in text:
        return "card_draw_selection"
    if "tutor" in archetype_set or "search your library" in text:
        return "tutors_access"
    if "graveyard" in text or "escape" in text or "flashback" in text:
        return "recursion_recovery"
    if "combo" in archetype_set or "copy" in text or "win the game" in text:
        return "combo_synergy_and_finishers"
    return "generic_or_low_context_signal"


def source_decision_lookup(report: Mapping[str, Any], key: str) -> dict[str, dict[str, Any]]:
    rows = report.get(key)
    if not isinstance(rows, list):
        return {}
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        if isinstance(row, Mapping) and row.get("card_name"):
            out[normalize_name(str(row["card_name"]))] = dict(row)
    return out


def profiled_candidate_lookup(report: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = report.get("top_pair_evaluations")
    if not isinstance(rows, list):
        return {}
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        if not isinstance(row, Mapping) or not row.get("candidate"):
            continue
        key = normalize_name(str(row["candidate"]))
        current = out.get(key)
        if current is None or as_int(row.get("score")) > as_int(current.get("score")):
            out[key] = dict(row)
    return out


def direct_report_decision(
    card_name: str,
    reports: Mapping[str, Any],
    profiled_lookup: Mapping[str, Mapping[str, Any]],
    staple_summary_text: str,
) -> tuple[str | None, list[str], dict[str, Any]]:
    key = normalize_name(card_name)
    reasons: list[str] = []
    evidence: dict[str, Any] = {}

    mana_vault_summary = report_summary(reports.get("mana_vault") or {})
    if card_name == "Mana Vault" and mana_vault_summary.get("promotion_allowed") is False:
        return (
            "blocked_prior_gate_rejected",
            ["mana_vault_current_pair_lost_with_card_exposure"],
            {
                "latest_gate_delta_pp": mana_vault_summary.get("latest_gate_delta_pp"),
                "promotion_allowed": mana_vault_summary.get("promotion_allowed"),
            },
        )

    for report_name, row_key in [
        ("selection", "candidate_access_cards"),
        ("interaction", "candidate_profiles"),
        ("payoff", "candidate_cards"),
    ]:
        lookup = source_decision_lookup(reports.get(report_name) or {}, row_key)
        row = lookup.get(key)
        if row and row.get("decision"):
            return (
                str(row["decision"]),
                [f"{report_name}_synthesis_decision"],
                {"source_decision": row.get("decision"), "source_reasons": row.get("decision_reasons") or []},
            )

    profiled = profiled_lookup.get(key)
    if profiled:
        blockers = list(profiled.get("blockers") or [])
        evidence = {
            "profiled_status": profiled.get("status"),
            "candidate_cut": profiled.get("cut"),
            "score": profiled.get("score"),
            "blockers": blockers,
        }
        if "candidate_policy_blocked_no_premium_mox" in blockers:
            return "policy_blocked_no_premium_mox", ["premium_mox_policy_blocker"], evidence
        if "prior_exact_reject" in blockers:
            return "blocked_prior_exact_reject", ["profiled_cut_prior_exact_reject"], evidence
        if profiled.get("status") == "preflight_ready":
            return "preflight_only_not_promotion", ["preflight_requires_battle_and_card_use"], evidence
        reasons.extend(blockers)

    if card_name == "Possibility Storm" and "Possibility Storm" in staple_summary_text:
        if "Natural gate lost" in staple_summary_text or "do_not_promote" in staple_summary_text:
            return (
                "blocked_staple_relearn_gate_lost",
                ["natural_gate_lost_or_no_recorded_use"],
                {"summary_report": "lorehold_607_unprotected_staple_relearn_summary_20260704.md"},
            )

    return None, reasons, evidence


def classify_current_staple(card: Mapping[str, Any], staple: Mapping[str, Any] | None) -> dict[str, Any]:
    name = str(card.get("card_name") or "")
    rank = as_int((staple or {}).get("edhrec_rank"), 999999)
    in_global = staple is not None
    if name in STRUCTURAL_FLOOR_NAMES or (in_global and rank <= 150):
        policy = "structural_foundation"
        reason = "format staple already serving a 607 floor role"
    elif name in LOREHOLD_CONTEXT_NAMES:
        policy = "commander_contextual_staple"
        reason = "Lorehold-specific miracle/topdeck or cadence engine"
    else:
        policy = "current_role_card_not_global_staple"
        reason = "current 607 card outside global staple floor"
    return {
        "card_name": name,
        "policy_class": policy,
        "reason": reason,
        "edhrec_rank": rank if in_global else None,
        "role": card.get("functional_tag"),
        "safe_cmc": card.get("safe_cmc"),
    }


def classify_candidate(
    *,
    conn: sqlite3.Connection,
    card_name: str,
    staple: Mapping[str, Any],
    cards_by_name: Mapping[str, Mapping[str, Any]],
    reports: Mapping[str, Any],
    profiled_lookup: Mapping[str, Mapping[str, Any]],
    staple_summary_text: str,
) -> dict[str, Any]:
    oracle = oracle_lookup(conn, card_name)
    lane = classify_lane(
        card_name,
        staple.get("archetypes") or [],
        str(oracle.get("type_line") or ""),
        str(oracle.get("oracle_text") or ""),
    )
    in_607 = normalize_name(card_name) in cards_by_name
    direct_decision, direct_reasons, evidence = direct_report_decision(
        card_name, reports, profiled_lookup, staple_summary_text
    )
    if in_607:
        decision = "already_in_protected_607"
        policy_class = classify_current_staple(cards_by_name[normalize_name(card_name)], staple)["policy_class"]
        reasons = ["current_607_card"]
    elif direct_decision:
        decision = direct_decision
        policy_class = "tested_or_policy_blocked_staple"
        reasons = direct_reasons
    elif card_name in PREMIUM_MOX_POLICY_NAMES:
        decision = "policy_blocked_no_premium_mox"
        policy_class = "generic_or_policy_blocked_staple"
        reasons = ["premium_mox_requires_explicit_policy_and_same_lane_gate"]
    elif card_name in GENERIC_TAPPED_LAND_NAMES:
        decision = "generic_land_staple_requires_mana_base_cut"
        policy_class = "generic_or_low_context_signal"
        reasons = ["current_607_mana_base_already_passes_color_and_land_foundation"]
    elif lane in {"ramp", "mana_base", "interaction_removal", "card_draw_selection"}:
        decision = "candidate_requires_same_lane_cut_and_gate"
        policy_class = "commander_synergy_candidate"
        reasons = ["staple_signal_without_current_cut_proof"]
    else:
        decision = "triage_backlog_not_promotion_proof"
        policy_class = "generic_or_low_context_signal"
        reasons = ["raw_staple_gap_requires_package_definition"]
    return {
        "card_name": card_name,
        "in_protected_607": in_607,
        "lane": lane,
        "policy_class": policy_class,
        "decision": decision,
        "decision_reasons": sorted(set(reasons)),
        "edhrec_rank": staple.get("edhrec_rank"),
        "archetypes": staple.get("archetypes") or [],
        "safe_cmc": safe_cmc_from_card(oracle, unknown_nonland_fallback=99.0),
        "commander_legality": commander_legality(conn, card_name),
        "battle_rule_summary": battle_rule_summary(conn, card_name),
        "variant_usage": variant_usage(conn, card_name),
        "evidence": evidence,
    }


def synthesize_status(candidate_rows: Iterable[Mapping[str, Any]]) -> str:
    promotable = {"direct_swap_ready", "promotion_ready", "natural_gate_won"}
    if any(str(row.get("decision")) in promotable for row in candidate_rows):
        return "staple_policy_candidate_requires_gate_review"
    return "staple_policy_no_direct_auto_include_current_607"


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    mana_foundation_report_path: Path,
    staple_gap_report_path: Path,
    staple_summary_report_path: Path,
    profiled_cut_report_path: Path,
    mana_vault_report_path: Path,
    selection_report_path: Path,
    interaction_report_path: Path,
    payoff_report_path: Path,
    rank_limit: int = 750,
    candidate_limit: int = 80,
) -> dict[str, Any]:
    cards = load_deck_cards(conn, deck_id)
    cards_by_name = {normalize_name(str(card.get("card_name") or "")): card for card in cards}
    staples = aggregate_format_staples(conn, rank_limit=rank_limit)
    staples_by_name = {normalize_name(str(row["card_name"])): row for row in staples}
    reports = {
        "mana_foundation": read_json_if_exists(mana_foundation_report_path),
        "staple_gap": read_json_if_exists(staple_gap_report_path),
        "profiled_cut": read_json_if_exists(profiled_cut_report_path),
        "mana_vault": read_json_if_exists(mana_vault_report_path),
        "selection": read_json_if_exists(selection_report_path),
        "interaction": read_json_if_exists(interaction_report_path),
        "payoff": read_json_if_exists(payoff_report_path),
    }
    staple_summary_text = read_text_if_exists(staple_summary_report_path)
    profiled_lookup = profiled_candidate_lookup(reports["profiled_cut"])
    current_rows = [
        classify_current_staple(card, staples_by_name.get(normalize_name(str(card.get("card_name") or ""))))
        for card in cards
        if staples_by_name.get(normalize_name(str(card.get("card_name") or "")))
        or str(card.get("card_name") or "") in LOREHOLD_CONTEXT_NAMES
    ]
    current_rows.sort(
        key=lambda row: (
            0 if row["policy_class"] == "structural_foundation" else 1,
            row["edhrec_rank"] if row["edhrec_rank"] is not None else 999999,
            row["card_name"],
        )
    )
    candidate_rows = []
    for staple in staples:
        card_name = str(staple["card_name"])
        if normalize_name(card_name) in cards_by_name:
            continue
        candidate_rows.append(
            classify_candidate(
                conn=conn,
                card_name=card_name,
                staple=staple,
                cards_by_name=cards_by_name,
                reports=reports,
                profiled_lookup=profiled_lookup,
                staple_summary_text=staple_summary_text,
            )
        )
        if len(candidate_rows) >= candidate_limit:
            break
    lane_counts = Counter(str(row["lane"]) for row in candidate_rows)
    decision_counts = Counter(str(row["decision"]) for row in candidate_rows)
    policy_counts = Counter(str(row["policy_class"]) for row in candidate_rows)
    mana_summary = report_summary(reports["mana_foundation"])
    gap_summary = report_summary(reports["staple_gap"])
    profile_summary = report_summary(reports["profiled_cut"])
    status = synthesize_status(candidate_rows)
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_staple_policy_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": status,
        "source_reports": {
            "mana_foundation": rel(mana_foundation_report_path),
            "staple_gap": rel(staple_gap_report_path),
            "staple_summary": rel(staple_summary_report_path),
            "profiled_cut": rel(profiled_cut_report_path),
            "mana_vault": rel(mana_vault_report_path),
            "selection": rel(selection_report_path),
            "interaction": rel(interaction_report_path),
            "payoff": rel(payoff_report_path),
        },
        "summary": {
            "total_cards": sum(as_int(card.get("quantity"), 1) for card in cards),
            "format_staples_considered": len(staples),
            "candidate_staples_reviewed": len(candidate_rows),
            "current_structural_foundation_count": sum(
                1 for row in current_rows if row["policy_class"] == "structural_foundation"
            ),
            "current_contextual_staple_count": sum(
                1 for row in current_rows if row["policy_class"] == "commander_contextual_staple"
            ),
            "candidate_lane_counts": dict(sorted(lane_counts.items())),
            "candidate_decision_counts": dict(sorted(decision_counts.items())),
            "candidate_policy_counts": dict(sorted(policy_counts.items())),
            "mana_foundation_status": reports["mana_foundation"].get("status"),
            "mana_foundation_blocker_count": as_int(mana_summary.get("blocker_count")),
            "mana_foundation_watch_item_count": as_int(mana_summary.get("watch_item_count")),
            "raw_staple_gap_rows_considered": as_int(gap_summary.get("rows_considered")),
            "raw_staple_gap_uncovered": as_int(gap_summary.get("not_in_current_lorehold_package_defs")),
            "profiled_preflight_ready_pair_count": as_int(profile_summary.get("preflight_ready_pair_count")),
        },
        "external_learning": EXTERNAL_LEARNING,
        "current_staple_floor": current_rows,
        "candidate_staple_backlog": candidate_rows,
        "decision": {
            "keep_607_staple_policy": status == "staple_policy_no_direct_auto_include_current_607",
            "reason": (
                "Current 607 already contains the structural Boros floor and Lorehold contextual "
                "miracle tools that matter most. Missing global staples are either already rejected, "
                "policy-blocked, generic low-context signals, or hypotheses that need a named same-lane cut."
            ),
            "next_action": (
                "split the remaining raw staple gap into explicit package definitions only when a lane "
                "has a current failure target; do not include a staple by rank alone"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Staple Policy Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- format staples considered: `{summary['format_staples_considered']}`",
        f"- candidate staples reviewed: `{summary['candidate_staples_reviewed']}`",
        f"- current structural foundation staples: `{summary['current_structural_foundation_count']}`",
        f"- current contextual Lorehold staples: `{summary['current_contextual_staple_count']}`",
        f"- mana foundation status: `{summary['mana_foundation_status']}`",
        f"- raw staple gap uncovered: `{summary['raw_staple_gap_uncovered']}`",
        f"- profiled preflight-ready pairs: `{summary['profiled_preflight_ready_pair_count']}`",
        f"- candidate lane counts: `{json.dumps(summary['candidate_lane_counts'], sort_keys=True)}`",
        f"- candidate decision counts: `{json.dumps(summary['candidate_decision_counts'], sort_keys=True)}`",
        "",
        "## Current 607 Staple Floor",
        "",
        "| Card | Policy | Role | Rank | Reason |",
        "| --- | --- | --- | ---: | --- |",
    ]
    for row in payload["current_staple_floor"][:40]:
        lines.append(
            "| {card} | `{policy}` | `{role}` | {rank} | {reason} |".format(
                card=row["card_name"],
                policy=row["policy_class"],
                role=row.get("role") or "-",
                rank=row["edhrec_rank"] if row["edhrec_rank"] is not None else "-",
                reason=row["reason"],
            )
        )
    lines.extend(
        [
            "",
            "## Candidate Staple Backlog",
            "",
            "| Card | Rank | Lane | Policy | Decision | Reasons |",
            "| --- | ---: | --- | --- | --- | --- |",
        ]
    )
    for row in payload["candidate_staple_backlog"][:50]:
        lines.append(
            "| {card} | {rank} | `{lane}` | `{policy}` | `{decision}` | {reasons} |".format(
                card=row["card_name"],
                rank=row.get("edhrec_rank") or "-",
                lane=row["lane"],
                policy=row["policy_class"],
                decision=row["decision"],
                reasons=", ".join(row.get("decision_reasons") or []) or "-",
            )
        )
    lines.extend(["", "## Learning Sources", ""])
    for source in payload["external_learning"]:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_staple_policy: `{str(decision['keep_607_staple_policy']).lower()}`")
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
    parser.add_argument("--staple-gap-report", type=Path, default=None)
    parser.add_argument("--staple-summary-report", type=Path, default=None)
    parser.add_argument("--profiled-cut-report", type=Path, default=None)
    parser.add_argument("--mana-vault-report", type=Path, default=None)
    parser.add_argument("--selection-report", type=Path, default=None)
    parser.add_argument("--interaction-report", type=Path, default=None)
    parser.add_argument("--payoff-report", type=Path, default=None)
    parser.add_argument("--rank-limit", type=int, default=750)
    parser.add_argument("--candidate-limit", type=int, default=80)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_staple_policy_synthesis",
    )
    args = parser.parse_args()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            mana_foundation_report_path=args.mana_foundation_report or default_mana_foundation_report(),
            staple_gap_report_path=args.staple_gap_report or default_staple_gap_report(),
            staple_summary_report_path=args.staple_summary_report or default_staple_summary_report(),
            profiled_cut_report_path=args.profiled_cut_report or default_profiled_cut_report(),
            mana_vault_report_path=args.mana_vault_report or default_mana_vault_report(),
            selection_report_path=args.selection_report or default_selection_report(),
            interaction_report_path=args.interaction_report or default_interaction_report(),
            payoff_report_path=args.payoff_report or default_payoff_report(),
            rank_limit=args.rank_limit,
            candidate_limit=args.candidate_limit,
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
