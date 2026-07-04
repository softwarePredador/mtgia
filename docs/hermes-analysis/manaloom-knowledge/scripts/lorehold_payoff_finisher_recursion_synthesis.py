#!/usr/bin/env python3
"""Synthesize Lorehold 607 payoff, finisher, and recursion evidence.

This read-only auditor consolidates the current protected 607 list, local
runtime rules, prior gate reports, public deckbuilding signals, and known stale
baseline assumptions. It answers whether a payoff/finisher/recursion card is
ready to replace a protected 607 slot, or whether it remains a learning
hypothesis that needs a named cut and equal battle gate.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
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

CURRENT_PAYOFF_ANCHORS = [
    "Approach of the Second Sun",
    "Mizzix's Mastery",
    "Surge to Victory",
    "Insurrection",
    "Storm Herd",
    "Rise of the Eldrazi",
    "Creative Technique",
    "Hit the Mother Lode",
    "Call Forth the Tempest",
    "Molecule Man",
    "Furygale Flocking",
    "Prismari Pianist",
    "Reforge the Soul",
]

RECURSION_BASELINE_PROBES = [
    "Mizzix's Mastery",
    "Squee, Goblin Nabob",
]

CANDIDATE_CARDS = [
    "Soulfire Eruption",
    "Twinflame Tyrant",
    "Possibility Storm",
    "Restoration Seminar",
    "Volcanic Vision",
    "Underworld Breach",
    "Past in Flames",
    "Wheel of Fortune",
    "Apex of Power",
    "Dance with Calamity",
    "Storm-Kiln Artist",
    "Brass's Bounty",
    "Mana Vault",
    "The One Ring",
]

EXTERNAL_LEARNING = [
    {
        "source": "EDHREC Lorehold cEDH average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/cedh",
        "learning": (
            "The cEDH average shell contains fast mana, Top/Rack, Underworld Breach, "
            "The One Ring, Mana Vault, Restoration Seminar, Soulfire Eruption, and "
            "big red payoff spells; this is a candidate pool, not replacement proof."
        ),
    },
    {
        "source": "EDHREC cEDH Lorehold article",
        "url": "https://edhrec.com/articles/a-cedh-miracle-with-lorehold-the-historian",
        "learning": (
            "Lorehold payoff quality starts with topdeck control and miracle windows; "
            "finishers are only better when they preserve that setup and convert it."
        ),
    },
    {
        "source": "EDHREC topdeck average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/topdeck",
        "learning": (
            "Casual/topdeck public lists reinforce Apex, Dance, Soulfire, Restoration, "
            "Volcanic Vision, Mizzix's Mastery, Approach, Storm Herd, and Top/Rack as "
            "the relevant comparison lane."
        ),
    },
    {
        "source": "Draftsim Lorehold guide",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "learning": (
            "Surge to Victory and Mizzix's Mastery are graveyard conversion pieces, "
            "while Storm Herd is a high-ceiling finisher dream."
        ),
    },
    {
        "source": "Commander Spellbook Underworld Breach search",
        "url": "https://commanderspellbook.com/search/?q=card%3D%22Underworld+Breach%22",
        "learning": (
            "Underworld Breach has broad combo pedigree, including red and Boros-adjacent "
            "wheel/treasure shells, but ManaLoom still requires Lorehold-specific cuts."
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


def default_soulfire_report() -> Path:
    return newest_report(
        "lorehold_soulfire_eruption_need_audit_20260704_learning.json",
        REPORT_DIR / "lorehold_soulfire_eruption_need_audit_20260704_learning.json",
    )


def default_recursion_report() -> Path:
    return newest_report(
        "lorehold_recursion_cut_model_20260704_cmc_safe_learning_after_baseline_cut_fix.json",
        REPORT_DIR / "lorehold_recursion_cut_model_20260704_cmc_safe_learning_after_baseline_cut_fix.json",
    )


def default_restoration_report() -> Path:
    return newest_report(
        "lorehold_restoration_seminar_need_audit_20260704_broad_trace_scan.json",
        REPORT_DIR / "lorehold_restoration_seminar_need_audit_20260704_broad_trace_scan.json",
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


def default_twinflame_report() -> Path:
    return newest_report(
        "lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json",
        REPORT_DIR / "lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json",
    )


def default_candidate_notes() -> Path:
    return newest_report(
        "lorehold_607_candidate_lane_hypotheses_20260704.md",
        REPORT_DIR / "lorehold_607_candidate_lane_hypotheses_20260704.md",
    )


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def read_json_if_exists(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def read_text_if_exists(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8")


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


def report_summary(report: Mapping[str, Any]) -> dict[str, Any]:
    summary = report.get("summary")
    return dict(summary) if isinstance(summary, Mapping) else {}


def json_dict(value: Any) -> dict[str, Any]:
    if isinstance(value, Mapping):
        return dict(value)
    if value in (None, ""):
        return {}
    try:
        decoded = json.loads(str(value))
    except Exception:
        return {}
    return dict(decoded) if isinstance(decoded, Mapping) else {}


def oracle_lookup(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "card_oracle_cache"):
        return {}
    row = conn.execute(
        """
        SELECT name, mana_cost, type_line, oracle_text, cmc, card_id, color_identity_json
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
    cards: list[dict[str, Any]] = []
    for row in rows:
        card = dict(row)
        oracle = oracle_lookup(conn, str(card.get("card_name") or ""))
        for field in ("mana_cost", "type_line", "oracle_text", "cmc", "card_id", "color_identity_json"):
            if field == "mana_cost" and oracle.get(field):
                card[field] = oracle[field]
            elif card.get(field) in (None, "") and oracle.get(field) not in (None, ""):
                card[field] = oracle[field]
        card["safe_cmc"] = safe_cmc_from_card(card, unknown_nonland_fallback=99.0)
        cards.append(card)
    return cards


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


def variant_usage(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "lorehold_variant_deck_cards"):
        return {"variant_count": 0, "deck_hashes": []}
    rows = conn.execute(
        """
        SELECT DISTINCT deck_hash
        FROM lorehold_variant_deck_cards
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        ORDER BY deck_hash
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    deck_hashes = [str(row["deck_hash"]) for row in rows]
    return {"variant_count": len(deck_hashes), "deck_hashes": deck_hashes[:12]}


def battle_rule_summary(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return {"rule_count": 0, "active_rule_count": 0, "role_categories": []}
    rows = conn.execute(
        """
        SELECT execution_status, review_status, confidence, deck_role_json, effect_json
        FROM battle_card_rules
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    active_execution = {"auto", "active", "verified"}
    active_review = {"active", "verified", "reviewed"}
    active = 0
    categories: set[str] = set()
    functions: set[str] = set()
    for row in rows:
        if str(row["execution_status"] or "") in active_execution and str(
            row["review_status"] or ""
        ) in active_review:
            active += 1
        deck_role = json_dict(row["deck_role_json"])
        effect = json_dict(row["effect_json"])
        for payload in (deck_role, effect):
            category = payload.get("category")
            if category:
                categories.add(str(category))
            for item in payload.get("functions") or []:
                functions.add(str(item))
    return {
        "rule_count": len(rows),
        "active_rule_count": active,
        "role_categories": sorted(categories),
        "functions": sorted(functions),
    }


def current_anchor_profiles(
    conn: sqlite3.Connection,
    cards_by_name: Mapping[str, Mapping[str, Any]],
) -> list[dict[str, Any]]:
    profiles: list[dict[str, Any]] = []
    for card_name in CURRENT_PAYOFF_ANCHORS:
        card = cards_by_name.get(normalize_name(card_name))
        profiles.append(
            {
                "card_name": card_name,
                "in_protected_607": bool(card),
                "role": (card or {}).get("functional_tag"),
                "tags": (card or {}).get("functional_tags_json"),
                "safe_cmc": (card or {}).get("safe_cmc"),
                "battle_rule_summary": battle_rule_summary(conn, card_name),
                "variant_usage": variant_usage(conn, card_name),
            }
        )
    return profiles


def candidate_notes_decision(card_name: str, notes_text: str) -> str | None:
    lowered = notes_text.lower()
    wanted = card_name.lower()
    if wanted not in lowered:
        return None
    if card_name == "The One Ring" and "not a generic auto-include" in lowered:
        return "blocked_existing_package_rejected"
    if card_name == "Mana Vault" and "not currently better than the protected" in lowered:
        return "blocked_prior_mana_vault_pair_rejected"
    if card_name == "Restoration Seminar" and "not gate-ready" in lowered:
        return "blocked_no_current_target_graveyard_trace"
    if card_name == "Soulfire Eruption" and "negative for broad inclusion" in lowered:
        return "blocked_existing_soulfire_shell_underperformed"
    return None


def twinflame_decision(report: Mapping[str, Any]) -> tuple[str | None, list[str], dict[str, Any]]:
    packages = report.get("packages")
    if not isinstance(packages, list) or not packages:
        return None, [], {}
    for package in packages:
        if not isinstance(package, Mapping):
            continue
        adds = {normalize_name(str(card)) for card in package.get("adds") or []}
        if normalize_name("Twinflame Tyrant") not in adds:
            continue
        gate = package.get("gate_summary")
        gate = gate if isinstance(gate, Mapping) else {}
        baseline = gate.get("baseline") if isinstance(gate.get("baseline"), Mapping) else {}
        candidate = gate.get("candidate") if isinstance(gate.get("candidate"), Mapping) else {}
        baseline_wr = as_float(baseline.get("win_rate"))
        candidate_wr = as_float(candidate.get("win_rate"))
        cut_safety = package.get("cut_safety") if isinstance(package.get("cut_safety"), Mapping) else {}
        reasons = []
        if candidate_wr < baseline_wr:
            reasons.append("prior_twinflame_gate_lost_to_baseline")
        if cut_safety.get("status") == "override_locked_cut_safety":
            reasons.append("prior_gate_used_locked_cut_override")
        status = "blocked_prior_twinflame_gate_lost_locked_cut" if reasons else "candidate_requires_equal_gate"
        evidence = {
            "baseline_win_rate": baseline_wr,
            "candidate_win_rate": candidate_wr,
            "cuts": package.get("cuts") or [],
            "cut_safety_status": cut_safety.get("status"),
        }
        return status, reasons, evidence
    return None, [], {}


def possibility_decision(profiled_summary: Mapping[str, Any]) -> tuple[str | None, list[str], dict[str, Any]]:
    selected = profiled_summary.get("selected_packages")
    if not isinstance(selected, list):
        selected = []
    preflight_ready = as_int(profiled_summary.get("preflight_ready_pair_count"))
    if preflight_ready <= 0 and not selected:
        return None, [], {}
    package = None
    for row in selected:
        if not isinstance(row, Mapping):
            continue
        if normalize_name(str(row.get("card_added") or row.get("add") or "")) == normalize_name(
            "Possibility Storm"
        ):
            package = row
            break
    reasons = ["preflight_ready_is_not_promotion"]
    evidence: dict[str, Any] = {
        "preflight_ready_pair_count": preflight_ready,
        "recommended_next_action": profiled_summary.get("recommended_next_action"),
    }
    if package:
        evidence["selected_package"] = dict(package)
    return "preflight_hypothesis_not_promotion", reasons, evidence


def candidate_profile(
    conn: sqlite3.Connection,
    cards_by_name: Mapping[str, Mapping[str, Any]],
    reports: Mapping[str, Mapping[str, Any]],
    candidate_notes_text: str,
    card_name: str,
) -> dict[str, Any]:
    key = normalize_name(card_name)
    card = cards_by_name.get(key)
    oracle = oracle_lookup(conn, card_name)
    soulfire_summary = report_summary(reports.get("soulfire") or {})
    recursion_summary = report_summary(reports.get("recursion") or {})
    restoration_summary = report_summary(reports.get("restoration") or {})
    profiled_summary = report_summary(reports.get("profiled_cut") or {})
    mana_vault_summary = report_summary(reports.get("mana_vault") or {})
    notes_decision = candidate_notes_decision(card_name, candidate_notes_text)
    decision = "candidate_hypothesis_requires_named_cut_and_equal_gate"
    reasons: list[str] = []
    evidence: dict[str, Any] = {}

    if card:
        decision = "already_in_protected_607"
        reasons.append("card_is_current_607_anchor_or_support")
    elif notes_decision:
        decision = notes_decision
        reasons.append("candidate_lane_notes_block_promotion")

    if card_name == "Soulfire Eruption" and not card:
        negative = as_int(soulfire_summary.get("existing_soulfire_negative_vs_607_count"))
        if negative > 0 or (reports.get("soulfire") or {}).get("status"):
            decision = str((reports.get("soulfire") or {}).get("status") or decision)
            reasons.append("existing_soulfire_shells_have_negative_607_evidence")
            evidence["existing_negative_vs_607_count"] = negative
            evidence["trace_use_event_count"] = soulfire_summary.get("trace_use_event_count")

    if card_name == "Twinflame Tyrant" and not card:
        twin_decision, twin_reasons, twin_evidence = twinflame_decision(reports.get("twinflame") or {})
        if twin_decision:
            decision = twin_decision
            reasons.extend(twin_reasons)
            evidence.update(twin_evidence)

    if card_name == "Possibility Storm" and not card:
        poss_decision, poss_reasons, poss_evidence = possibility_decision(profiled_summary)
        if poss_decision:
            decision = poss_decision
            reasons.extend(poss_reasons)
            evidence.update(poss_evidence)

    if card_name in {"Restoration Seminar", "Volcanic Vision"} and not card:
        preflight = as_int(recursion_summary.get("preflight_benchmark_ready_count"))
        if preflight == 0:
            decision = "recursion_candidate_blocked_no_safe_cut"
            reasons.append("recursion_model_has_zero_preflight_ready_pairs")
            evidence["recursion_recommended_next_action"] = recursion_summary.get("recommended_next_action")
        if card_name == "Restoration Seminar" and restoration_summary:
            evidence["restoration_target_graveyard_event_count"] = restoration_summary.get(
                "target_graveyard_event_count"
            )
            if as_int(restoration_summary.get("target_graveyard_event_count")) == 0:
                decision = "blocked_no_current_target_graveyard_trace"
                reasons.append("restoration_audit_found_zero_current_target_graveyard_events")

    if card_name == "Mana Vault" and not card:
        if mana_vault_summary.get("promotion_allowed") is False or mana_vault_summary.get("decision"):
            decision = "blocked_prior_mana_vault_pair_rejected"
            reasons.append("mana_vault_prior_pair_rejected_with_exposure")
            evidence["latest_gate_delta_pp"] = mana_vault_summary.get("latest_gate_delta_pp")
            evidence["promotion_allowed"] = mana_vault_summary.get("promotion_allowed")

    if card_name == "The One Ring" and not card and decision == "candidate_hypothesis_requires_named_cut_and_equal_gate":
        if "The One Ring" in candidate_notes_text and "not a generic auto-include" in candidate_notes_text:
            decision = "blocked_existing_package_rejected"
            reasons.append("one_ring_prior_package_lost_current_607_value_slot")

    if not reasons and decision == "candidate_hypothesis_requires_named_cut_and_equal_gate":
        reasons.append("public_or_staple_signal_without_current_same_lane_gate")

    return {
        "card_name": card_name,
        "in_protected_607": bool(card),
        "safe_cmc": (card or {}).get("safe_cmc", safe_cmc_from_card(oracle, unknown_nonland_fallback=99.0)),
        "oracle_type_line": oracle.get("type_line"),
        "commander_legality": commander_legality(conn, card_name),
        "format_staple": format_staple(conn, card_name),
        "battle_rule_summary": battle_rule_summary(conn, card_name),
        "variant_usage": variant_usage(conn, card_name),
        "decision": decision,
        "decision_reasons": sorted(set(reasons)),
        "evidence": evidence,
    }


def build_divergences(
    cards_by_name: Mapping[str, Mapping[str, Any]],
    reports: Mapping[str, Mapping[str, Any]],
) -> list[dict[str, Any]]:
    divergences: list[dict[str, Any]] = []
    if normalize_name("Squee, Goblin Nabob") not in cards_by_name:
        recursion_report = reports.get("recursion") or {}
        guardrails = recursion_report.get("guardrails") if isinstance(recursion_report.get("guardrails"), list) else []
        if any("Squee" in json.dumps(row) for row in guardrails):
            divergences.append(
                {
                    "key": "nonbaseline_squee_recursion_assumption",
                    "detail": (
                        "Squee appears in historical recursion exposure and variants, but is not in the "
                        "loaded protected 607. It cannot be used as a 607 cut or protected anchor unless a "
                        "new package explicitly reintroduces it."
                    ),
                    "cards": ["Squee, Goblin Nabob"],
                }
            )
    return divergences


def synthesize_status(candidate_rows: Iterable[Mapping[str, Any]]) -> str:
    promotion_ready = {
        "direct_swap_ready",
        "promotion_ready",
        "natural_gate_won",
    }
    if any(str(row.get("decision")) in promotion_ready for row in candidate_rows):
        return "payoff_finisher_recursion_candidate_requires_gate_review"
    return "payoff_finisher_recursion_no_direct_swap_ready_current_607"


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    soulfire_report_path: Path,
    recursion_report_path: Path,
    restoration_report_path: Path,
    profiled_cut_report_path: Path,
    mana_vault_report_path: Path,
    twinflame_report_path: Path,
    candidate_notes_path: Path,
) -> dict[str, Any]:
    cards = load_deck_cards(conn, deck_id)
    cards_by_name = {normalize_name(str(card.get("card_name") or "")): card for card in cards}
    reports = {
        "soulfire": read_json_if_exists(soulfire_report_path),
        "recursion": read_json_if_exists(recursion_report_path),
        "restoration": read_json_if_exists(restoration_report_path),
        "profiled_cut": read_json_if_exists(profiled_cut_report_path),
        "mana_vault": read_json_if_exists(mana_vault_report_path),
        "twinflame": read_json_if_exists(twinflame_report_path),
    }
    candidate_notes_text = read_text_if_exists(candidate_notes_path)
    anchor_rows = current_anchor_profiles(conn, cards_by_name)
    candidate_rows = [
        candidate_profile(conn, cards_by_name, reports, candidate_notes_text, name)
        for name in CANDIDATE_CARDS
    ]
    divergences = build_divergences(cards_by_name, reports)
    status = synthesize_status(candidate_rows)
    soulfire_summary = report_summary(reports["soulfire"])
    recursion_summary = report_summary(reports["recursion"])
    restoration_summary = report_summary(reports["restoration"])
    profiled_summary = report_summary(reports["profiled_cut"])
    mana_vault_summary = report_summary(reports["mana_vault"])
    blocked_candidates = [
        row["card_name"]
        for row in candidate_rows
        if not bool(row.get("in_protected_607"))
        and str(row.get("decision")) not in {"already_in_protected_607"}
    ]
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_payoff_finisher_recursion_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": status,
        "source_reports": {
            "soulfire": rel(soulfire_report_path),
            "recursion": rel(recursion_report_path),
            "restoration": rel(restoration_report_path),
            "profiled_cut": rel(profiled_cut_report_path),
            "mana_vault": rel(mana_vault_report_path),
            "twinflame": rel(twinflame_report_path),
            "candidate_notes": rel(candidate_notes_path),
        },
        "summary": {
            "total_cards": sum(as_int(card.get("quantity"), 1) for card in cards),
            "current_payoff_anchor_count": sum(1 for row in anchor_rows if row["in_protected_607"]),
            "current_squee_in_607": normalize_name("Squee, Goblin Nabob") in cards_by_name,
            "soulfire_status": reports["soulfire"].get("status"),
            "soulfire_negative_vs_607_count": as_int(
                soulfire_summary.get("existing_soulfire_negative_vs_607_count")
            ),
            "recursion_preflight_ready_count": as_int(
                recursion_summary.get("preflight_benchmark_ready_count")
            ),
            "restoration_target_graveyard_event_count": as_int(
                restoration_summary.get("target_graveyard_event_count")
            ),
            "profiled_preflight_ready_pair_count": as_int(
                profiled_summary.get("preflight_ready_pair_count")
            ),
            "mana_vault_promotion_allowed": mana_vault_summary.get("promotion_allowed"),
            "blocked_or_learning_candidate_count": len(blocked_candidates),
            "divergence_count": len(divergences),
        },
        "external_learning": EXTERNAL_LEARNING,
        "current_payoff_anchors": anchor_rows,
        "candidate_cards": candidate_rows,
        "divergences": divergences,
        "decision": {
            "keep_607_payoff_finisher_recursion_package": status
            == "payoff_finisher_recursion_no_direct_swap_ready_current_607",
            "reason": (
                "The protected 607 already carries multiple independent conversion lanes "
                "(Approach, Mizzix, Surge, Insurrection, Storm Herd, Rise, Creative Technique, "
                "Molecule Man, Hit the Mother Lode, and Call Forth the Tempest). Public staples "
                "and variant cards remain learning inputs until a named same-lane cut survives "
                "current trace and equal battle gates."
            ),
            "next_action": (
                "continue learning with forced-access probes and named same-lane packages; "
                "do not mutate protected 607 from popularity or historical nonbaseline assumptions"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Payoff Finisher Recursion Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- current payoff anchors present: `{summary['current_payoff_anchor_count']}`",
        f"- current Squee in 607: `{str(summary['current_squee_in_607']).lower()}`",
        f"- Soulfire status: `{summary['soulfire_status']}`",
        f"- Soulfire negative rows vs 607: `{summary['soulfire_negative_vs_607_count']}`",
        f"- recursion preflight-ready pairs: `{summary['recursion_preflight_ready_count']}`",
        f"- Restoration target graveyard events: `{summary['restoration_target_graveyard_event_count']}`",
        f"- profiled preflight-ready pairs: `{summary['profiled_preflight_ready_pair_count']}`",
        f"- Mana Vault promotion allowed: `{summary['mana_vault_promotion_allowed']}`",
        f"- divergences: `{summary['divergence_count']}`",
        "",
        "## Current Anchors",
        "",
        "| Card | In 607 | Role | Safe CMC | Active Rules | Variants |",
        "| --- | --- | --- | ---: | ---: | ---: |",
    ]
    for row in payload["current_payoff_anchors"]:
        rules = row.get("battle_rule_summary") or {}
        variants = row.get("variant_usage") or {}
        lines.append(
            "| {card} | `{in_deck}` | `{role}` | {cmc} | {rules} | {variants} |".format(
                card=row["card_name"],
                in_deck=str(row["in_protected_607"]).lower(),
                role=row.get("role") or "-",
                cmc=row.get("safe_cmc") if row.get("safe_cmc") is not None else "-",
                rules=rules.get("active_rule_count", 0),
                variants=variants.get("variant_count", 0),
            )
        )
    lines.extend(
        [
            "",
            "## Candidate Cards",
            "",
            "| Card | In 607 | Legal | Safe CMC | Active Rules | Variants | Decision |",
            "| --- | --- | --- | ---: | ---: | ---: | --- |",
        ]
    )
    for row in payload["candidate_cards"]:
        rules = row.get("battle_rule_summary") or {}
        variants = row.get("variant_usage") or {}
        lines.append(
            "| {card} | `{in_deck}` | `{legal}` | {cmc} | {rules} | {variants} | `{decision}` |".format(
                card=row["card_name"],
                in_deck=str(row["in_protected_607"]).lower(),
                legal=row.get("commander_legality") or "unknown",
                cmc=row.get("safe_cmc") if row.get("safe_cmc") is not None else "-",
                rules=rules.get("active_rule_count", 0),
                variants=variants.get("variant_count", 0),
                decision=row.get("decision"),
            )
        )
    if payload.get("divergences"):
        lines.extend(["", "## Divergences", ""])
        for row in payload["divergences"]:
            lines.append(f"- `{row['key']}`: {row['detail']} Cards: {', '.join(row.get('cards') or [])}.")
    lines.extend(["", "## Learning Sources", ""])
    for source in payload["external_learning"]:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(
        "- keep_607_payoff_finisher_recursion_package: "
        f"`{str(decision['keep_607_payoff_finisher_recursion_package']).lower()}`"
    )
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
    parser.add_argument("--soulfire-report", type=Path, default=None)
    parser.add_argument("--recursion-report", type=Path, default=None)
    parser.add_argument("--restoration-report", type=Path, default=None)
    parser.add_argument("--profiled-cut-report", type=Path, default=None)
    parser.add_argument("--mana-vault-report", type=Path, default=None)
    parser.add_argument("--twinflame-report", type=Path, default=None)
    parser.add_argument("--candidate-notes", type=Path, default=None)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_payoff_finisher_recursion_synthesis",
    )
    args = parser.parse_args()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            soulfire_report_path=args.soulfire_report or default_soulfire_report(),
            recursion_report_path=args.recursion_report or default_recursion_report(),
            restoration_report_path=args.restoration_report or default_restoration_report(),
            profiled_cut_report_path=args.profiled_cut_report or default_profiled_cut_report(),
            mana_vault_report_path=args.mana_vault_report or default_mana_vault_report(),
            twinflame_report_path=args.twinflame_report or default_twinflame_report(),
            candidate_notes_path=args.candidate_notes or default_candidate_notes(),
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
