#!/usr/bin/env python3
"""Build a source-backed Lorehold strategy-learning audit.

This report is intentionally read-only. It stitches together the current
Lorehold champion candidate DB, the latest structural matrix, focused battle
gates, and the broad synergy-package gate so the next deck changes are driven
by commander intent and repeatable evidence instead of one-card intuition.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_DB = (
    REPORT_DIR
    / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
    / "knowledge_candidate.db"
)
DEFAULT_MATRIX = REPORT_DIR / "lorehold_variant_strategy_matrix_20260626_v3.json"
DEFAULT_SQUEE_GATES = [
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed7_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed13_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed21_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed42_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed99_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed123_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260624_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260626_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260627_v1.json",
]
DEFAULT_GENERAL_SYNERGY_CONFIRM = (
    REPORT_DIR / "lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json"
)
DEFAULT_SQUEE_SEED_DIAGNOSTIC = REPORT_DIR / "lorehold_squee_seed_diagnostic_20260627_v1.json"
DEFAULT_SQUEE_RULE_MATERIALIZATION_AUDIT = (
    REPORT_DIR / "lorehold_squee_rule_materialization_audit_20260627_v1.json"
)
DEFAULT_UNRESOLVED_RULE_ROWS_AUDIT = (
    REPORT_DIR / "lorehold_unresolved_rule_rows_audit_20260627_v1.json"
)
DEFAULT_THOR_RULE_RUNTIME_AUDIT = REPORT_DIR / "lorehold_thor_rule_runtime_audit_20260627_v1.json"
DEFAULT_THOR_RULE_GATE_AUDIT = REPORT_DIR / "lorehold_thor_synced_rule_gate_audit_20260627_v1.json"
DEFAULT_RUNTIME_PACKAGE_PROPOSALS = [
    REPORT_DIR / "lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json",
]
DEFAULT_RUNTIME_PACKAGE_MANIFESTS = [
    REPORT_DIR / "pg245_lorehold_topdeck_damage_runtime_20260628_manifest.json",
]
DEFAULT_RUNTIME_PACKAGE_BLOCKERS = [
    REPORT_DIR / "pg245_lorehold_topdeck_damage_runtime_20260628_precheck_blocked.json",
]
DEFAULT_POST_SQUEE_PACKAGE_GATES = [
    REPORT_DIR / "lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v2_seed42_hash0_isolated_timeout_galvanoth_cut_chimes.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v2_seed7_hash0_isolated_timeout_galvanoth_cut_chimes.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v2_seed20260625_hash0_isolated_timeout_galvanoth_cut_chimes.json",
    REPORT_DIR / "lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json",
    REPORT_DIR / "lorehold_finalizer_benchmark_gate_20260627_v1_seed7_hash0_isolated_timeout_storm_challenge.json",
    REPORT_DIR / "lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json",
    REPORT_DIR / "lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json",
    REPORT_DIR / "lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json",
    REPORT_DIR / "lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json",
    REPORT_DIR / "lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1.json",
    REPORT_DIR / "lorehold_life_floor_conversion_gate_20260627_seed7_v1_life_floor_v1.json",
    REPORT_DIR / "lorehold_life_floor_conversion_gate_20260627_seed20260625_v1_life_floor_v1.json",
    REPORT_DIR / "lorehold_spellchain_conversion_gate_20260627_seed42_v1_spellchain_v1.json",
    REPORT_DIR / "lorehold_spellchain_conversion_gate_20260627_seed7_v1_spellchain_v1.json",
    REPORT_DIR / "lorehold_spellchain_conversion_gate_20260627_seed20260625_v1_spellchain_v1.json",
    REPORT_DIR / "lorehold_topfreecast_conversion_gate_20260627_seed42_v1_topfreecast_v1.json",
    REPORT_DIR / "lorehold_topfreecast_conversion_gate_20260627_seed7_v1_topfreecast_v1.json",
    REPORT_DIR / "lorehold_topfreecast_conversion_gate_20260627_seed20260625_v1_topfreecast_v1.json",
    REPORT_DIR / "lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2.json",
    REPORT_DIR / "lorehold_tutor_access_conversion_gate_20260627_seed42_v1_tutor_access_v1.json",
    REPORT_DIR / "lorehold_tutor_access_conversion_gate_20260627_seed7_v1_tutor_access_v1.json",
    REPORT_DIR / "lorehold_tutor_access_conversion_gate_20260627_seed20260625_v1_tutor_access_v1.json",
    REPORT_DIR / "lorehold_tutor_access_conversion_gate_20260627_seed42_v2_tutor_access_v2.json",
    REPORT_DIR / "lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2.json",
    REPORT_DIR / "lorehold_spell_protection_land_gate_20260627_seed42_v1_spell_protection_land_v1.json",
    REPORT_DIR / "lorehold_pressure_conversion_gate_20260627_seed42_v2_pressure_v2.json",
]
DEFAULT_LIBRARY_LENG_TELEMETRY_GATES = [
    REPORT_DIR / "lorehold_library_leng_telemetry_gate_20260627_seed7_squee_v1.json",
    REPORT_DIR / "lorehold_library_leng_telemetry_gate_20260627_seed42_squee_v1.json",
    REPORT_DIR / "lorehold_library_leng_telemetry_gate_20260627_seed20260625_squee_v1.json",
]
DEFAULT_LOSS_FAILURE_CLASSIFIER = (
    REPORT_DIR / "lorehold_loss_failure_classifier_20260627_conversion_pressure_v8.json"
)
DEFAULT_SAFE_PACKAGE_GATES = [
    REPORT_DIR / "lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json",
]
DEFAULT_DECK_IDS = [6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]

EXTERNAL_METHOD_SOURCES = [
    {
        "name": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "use": "commander-specific package comparison lane",
    },
    {
        "name": "EDHREC Lorehold cEDH average deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/cedh",
        "use": "external cross-check for ritual package, Birgi, Seething Song, and medallion retention",
    },
    {
        "name": "Reddit EDHBrews Lorehold thread",
        "url": "https://www.reddit.com/r/EDHBrews/comments/1s8q5nm/lorehold_the_historian/",
        "use": "player-reported failure mode: fizzling, gas depletion, and difficulty finding a win condition",
    },
    {
        "name": "EDHREC spellslinger Commander guide",
        "url": "https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander",
        "use": "spellslinger criteria: card flow, cheap interaction, protection, recursion, payoffs",
    },
    {
        "name": "EDHREC Commander deckbuilding guide",
        "url": "https://edhrec.com/articles/how-to-build-a-commander-deck",
        "use": "baseline structure guardrails for lands, ramp, draw, removal, and focused packages",
    },
    {
        "name": "Archidekt Lorehold corpus",
        "url": "https://archidekt.com/commanders/Lorehold%2C%20the%20Historian",
        "use": "user-built Lorehold shells and recurring package choices",
    },
    {
        "name": "Card Kingdom Lorehold synergy article",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "use": "external confirmation that Library of Leng and topdeck/discard loops are a commander-specific synergy lane",
    },
    {
        "name": "Draftsim Lorehold EDH deck tech",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "use": "external deck-tech framing for miracle setup, draw timing, and support packages",
    },
]

COMMANDER_INTENT = (
    "Use topdeck setup, hand filtering, and Lorehold's miracle discount to cast "
    "high-impact instant/sorcery spells ahead of curve, then convert that window "
    "into a deterministic finisher while surviving fast combat pressure."
)

PACKAGE_KEYS = [
    "spell_chain_conversion",
    "topdeck_miracle_setup",
    "hand_filter",
    "graveyard_recursion",
    "pressure_absorber",
    "deterministic_finisher",
    "early_plan",
]

CARD_REASON_OVERRIDES = {
    "Blasphemous Act": "cheap mass removal when creature pressure is high",
    "Call Forth the Tempest": "high-impact sweeper/big spell that benefits from miracle discount",
    "Creative Technique": "big-spell value line with copy/demonstrate upside",
    "Deflecting Swat": "free stack protection while Lorehold is online",
    "Dawn's Truce": "protects the decisive turn and can preserve the board",
    "Fated Clash": "instant-speed threat answer with clash/topdeck relevance",
    "Hit the Mother Lode": "big-spell mana/value payoff that can chain into more resources",
    "Library of Leng": "core discard-to-top replacement engine; new gate telemetry proves it fires naturally but still needs conversion/survival support",
    "Molecule Man": "miracle-cost modifier hypothesis; keep runtime evidence explicit",
    "Promise of Loyalty": "political wipe that reduces combat pressure on Lorehold",
    "Redirect Lightning": "damage redirection/removal slot, not a mana engine",
    "Rise of the Eldrazi": "major miracle payoff and closing spell",
    "Sensei's Divining Top": "premium first-draw/topdeck control for miracle turns",
    "Smothering Tithe": "treasure engine that turns table draw into big-spell mana",
    "Squee, Goblin Nabob": "recursion engine: reproducible isolated gate shows all observed returns after known graveyard entries; rummage-discard loop is not proven",
    "Starfall Invocation": "board wipe with gift/draw context; pressure control first",
    "Tempt with Bunnies": "token finisher and big-spell payoff",
    "The Mind Stone": "white Infinity Stone ramp/protection engine; not the classic Mind Stone draw rock",
    "Thor, God of Thunder": "noncreature-spell damage payoff now has local runtime; ETB temporary graveyard play remains annotation",
    "Tragic Arrogance": "selective board wipe; active rule exists and only needed deck-row materialization",
}

CARD_ROLE_OVERRIDES = {
    "Call Forth the Tempest": "board_wipe",
    "Creative Technique": "big_spell_value",
    "Deflecting Swat": "protection",
    "Dawn's Truce": "protection",
    "Fated Clash": "removal",
    "Library of Leng": "topdeck_miracle_engine",
    "Molecule Man": "miracle_engine",
    "Promise of Loyalty": "board_wipe",
    "Redirect Lightning": "removal",
    "Squee, Goblin Nabob": "recursion_engine",
    "Starfall Invocation": "board_wipe",
    "The Mind Stone": "ramp",
    "Thor, God of Thunder": "spell_damage_engine",
    "Tragic Arrogance": "board_wipe",
}

CARD_DECISION_OVERRIDES = {
    "Approach of the Second Sun": (
        "core_finisher",
        "deterministic win line; benchmark other finishers against it rather than cutting blindly",
    ),
    "Bender's Waterskin": (
        "flex_but_cut_risky",
        "Galvanoth improved aggregate when cutting this slot but broke the seed-42 success case",
    ),
    "Galvanoth": (
        "probation_external_candidate",
        "not in champion; only Galvanoth/Bender was aggregate-positive and all checked alternate cuts failed seed 42",
    ),
    "Hexing Squelcher": (
        "flex_cut_tested_negative",
        "multiple packages tried this cut and lost aggregate or the known strong seed",
    ),
    "Library of Leng": (
        "core_engine_or_probation",
        "discard-to-top replacement is now measured in the Squee champion; do not cut without a direct conversion/survival benchmark",
    ),
    "Squee, Goblin Nabob": (
        "probation_engine",
        "10-seed suite keeps Squee narrowly ahead and proves clean graveyard returns, but not a self-sufficient discard loop",
    ),
    "Storm Herd": (
        "finisher_benchmark_lane",
        "expensive token finisher; current Storm Herd slot beat Dance with Calamity and Aetherflux Reservoir in aggregate finalizer gates",
    ),
    "Thor, God of Thunder": (
        "modeled_not_deck_proven",
        "local runtime rule and one natural 7-damage exposure exist, but 21-game synced gate showed +0.00 pp",
    ),
    "Victory Chimes": (
        "flex_cut_tested_negative",
        "Galvanoth over this generic colorless ramp slot lost aggregate and broke seed 42",
    ),
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def json_loads(value: object, default: Any) -> Any:
    if value in (None, ""):
        return default
    if isinstance(value, (list, dict)):
        return value
    try:
        return json.loads(str(value))
    except Exception:
        return default


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def load_deck_rows(conn: sqlite3.Connection, deck_id: int) -> list[sqlite3.Row]:
    return conn.execute(
        """
        SELECT card_name, quantity, functional_tag, functional_tags_json,
               semantic_tags_v2_json, battle_rules_json, cmc, type_line,
               oracle_text, is_commander
        FROM deck_cards
        WHERE deck_id = ?
        ORDER BY is_commander DESC, functional_tag, card_name
        """,
        (deck_id,),
    ).fetchall()


def load_deck_meta(conn: sqlite3.Connection, deck_id: int) -> dict[str, Any]:
    row = conn.execute(
        "SELECT id, deck_name, archetype, total_cards, notes FROM decks WHERE id = ?",
        (deck_id,),
    ).fetchone()
    if not row:
        return {
            "deck_id": deck_id,
            "deck_name": f"Deck {deck_id}",
            "archetype": "missing",
            "notes": "",
        }
    return dict(row)


def tag_values(row: sqlite3.Row) -> set[str]:
    tags: set[str] = set()
    primary = normalize_name(row["functional_tag"]).replace(" ", "_")
    if primary:
        tags.add(primary)
    decoded = json_loads(row["functional_tags_json"], [])
    if isinstance(decoded, list):
        for item in decoded:
            if isinstance(item, dict):
                tag = item.get("tag") or item.get("role") or item.get("category")
            else:
                tag = item
            normalized = normalize_name(tag).replace(" ", "_")
            if normalized:
                tags.add(normalized)
    text = f"{row['type_line'] or ''} {row['oracle_text'] or ''}".lower()
    if "instant" in (row["type_line"] or "").lower() or "sorcery" in (row["type_line"] or "").lower():
        tags.add("instant_sorcery")
    if any(token in text for token in ["miracle", "scry", "surveil", "top card", "top of your library"]):
        tags.add("topdeck_miracle_setup")
    if any(token in text for token in ["discard", "draw", "wheel", "rummage"]):
        tags.add("hand_filter")
    if "copy target instant" in text or "copy target sorcery" in text or ("copy" in text and "spell" in text):
        tags.add("spell_copy")
    if any(token in text for token in ["graveyard", "flashback", "return target", "return this card"]):
        tags.add("graveyard_recursion")
    if any(token in text for token in ["treasure", "add ", "costs ", "cost "]):
        tags.add("mana_engine")
    if any(token in text for token in ["can't attack", "prevent", "protection", "indestructible", "phase out"]):
        tags.add("pressure_absorber")
    return tags


def battle_rule_keys(row: sqlite3.Row) -> list[str]:
    rules = json_loads(row["battle_rules_json"], [])
    keys: list[str] = []
    if isinstance(rules, list):
        for rule in rules:
            if isinstance(rule, dict):
                key = rule.get("logical_rule_key") or rule.get("_rule_logical_key")
                if key:
                    keys.append(str(key))
    return sorted(set(keys))


def deck_summary(conn: sqlite3.Connection, deck_id: int) -> dict[str, Any]:
    meta = load_deck_meta(conn, deck_id)
    rows = load_deck_rows(conn, deck_id)
    counts: Counter[str] = Counter()
    role_counts: Counter[str] = Counter()
    cards: list[dict[str, Any]] = []
    missing_rule_cards: list[str] = []
    total_quantity = 0
    for row in rows:
        qty = int(row["quantity"] or 1)
        total_quantity += qty
        primary = normalize_name(row["functional_tag"]).replace(" ", "_") or "unknown"
        role_counts[primary] += qty
        tags = tag_values(row)
        for tag in tags:
            counts[tag] += qty
        keys = battle_rule_keys(row)
        if not keys:
            missing_rule_cards.append(row["card_name"])
        cards.append(
            {
                "card_name": row["card_name"],
                "quantity": qty,
                "primary_role": primary,
                "cmc": row["cmc"],
                "type_line": row["type_line"],
                "tags": sorted(tags),
                "battle_rule_keys": keys,
            }
        )
    return {
        **meta,
        "quantity_total": total_quantity,
        "row_count": len(rows),
        "role_counts": dict(sorted(role_counts.items())),
        "signal_counts": dict(sorted(counts.items())),
        "missing_battle_rule_cards": missing_rule_cards,
        "battle_rule_ready_rows": len(rows) - len(missing_rule_cards),
        "cards": cards,
    }


def load_matrix_by_key(path: Path) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    payload = read_json(path)
    by_key = {}
    for deck in payload.get("decks") or []:
        key = str(deck.get("deck_key") or "")
        if key:
            by_key[key] = deck
    return payload, by_key


def aggregate_squee_gates(paths: list[Path]) -> dict[str, Any]:
    rows = []
    aggregate: dict[str, Counter[str]] = defaultdict(Counter)
    telemetry: dict[str, Counter[str]] = defaultdict(Counter)
    for path in paths:
        payload = read_json(path)
        if not payload:
            continue
        seed = payload.get("simulation_seed")
        for result in payload.get("results") or []:
            key = result.get("deck_key")
            if not key:
                continue
            row = {
                "source": str(path),
                "seed": seed,
                "python_hash_seed": payload.get("python_hash_seed", "unset"),
                "deck_process_isolation": bool(payload.get("deck_process_isolation")),
                "game_timeout_seconds": payload.get("game_timeout_seconds"),
                "deck_key": key,
                "deck_name": result.get("deck_name"),
                "games": int(result.get("games") or 0),
                "wins": int(result.get("wins") or 0),
                "losses": int(result.get("losses") or 0),
                "stalls": int(result.get("stalls") or 0),
                "win_rate": result.get("win_rate"),
                "avg_win_turn": result.get("avg_win_turn"),
                "strategic_events": dict((result.get("telemetry") or {}).get("strategic_event_counts") or {}),
                "strategic_games": dict((result.get("telemetry") or {}).get("strategic_games") or {}),
            }
            rows.append(row)
            aggregate[key]["games"] += row["games"]
            aggregate[key]["wins"] += row["wins"]
            aggregate[key]["losses"] += row["losses"]
            aggregate[key]["stalls"] += row["stalls"]
            for event, count in row["strategic_events"].items():
                telemetry[key][event] += int(count or 0)
            for event, value in row["strategic_games"].items():
                if isinstance(value, dict):
                    telemetry[key][f"games_with:{event}"] += int(value.get("games") or 0)
    summary = {}
    for key, counts in aggregate.items():
        games = max(1, counts["games"])
        summary[key] = {
            "games": counts["games"],
            "wins": counts["wins"],
            "losses": counts["losses"],
            "stalls": counts["stalls"],
            "win_rate": round(100.0 * counts["wins"] / games, 2),
            "strategic_events": dict(telemetry[key]),
        }
    return {"rows": rows, "summary": summary}


def load_general_synergy_confirm(path: Path) -> list[dict[str, Any]]:
    payload = read_json(path)
    rows = []
    for package in payload.get("packages") or []:
        gate = package.get("gate_summary") or {}
        baseline = gate.get("baseline") or {}
        candidate = gate.get("candidate") or {}
        rows.append(
            {
                "package_key": package.get("package_key"),
                "family": package.get("family"),
                "adds": package.get("adds") or [],
                "cuts": package.get("cuts") or [],
                "baseline_record": f"{baseline.get('wins', 0)}-{baseline.get('losses', 0)}-{baseline.get('stalls', 0)}",
                "candidate_record": f"{candidate.get('wins', 0)}-{candidate.get('losses', 0)}-{candidate.get('stalls', 0)}",
                "delta_pp": gate.get("delta_pp"),
                "decision": "reject_or_rework" if (gate.get("delta_pp") or 0) < 0 else "not_promoted",
            }
        )
    return rows


def post_squee_package_decision(row: dict[str, Any]) -> str:
    if row["candidate_wins"] <= row["baseline_wins"]:
        return "reject_or_rework"
    if row["delta_pp"] <= 0:
        return "reject_or_rework"
    if row["strong_seed_delta_pp"] < 0:
        return "probation_deeper_gate_only"
    return "promote_to_deeper_gate"


def aggregate_post_squee_package_gates(paths: list[Path]) -> dict[str, Any]:
    per_seed: list[dict[str, Any]] = []
    aggregate: dict[str, dict[str, Any]] = {}
    metrics = [
        "lorehold_cost_paid",
        "lorehold_spell_cast",
        "spell_cast_mana_trigger",
        "birgi_spell_cast_mana",
        "ritual_mana_added",
        "lorehold_spell_rummage",
        "lorehold_upkeep_rummage",
        "miracle_cast",
        "tutor_resolved",
        "random_discard_after_tutor",
        "topdeck_manipulation_activated",
        "discard_to_top_replacement",
        "lorehold_rummage_discard_to_top",
        "lorehold_spell_rummage_discard_to_top",
        "hand_to_topdeck_activation",
        "squee_to_graveyard",
        "squee_upkeep_return",
        "squee_return_after_known_graveyard_entry",
    ]
    for path in paths:
        payload = read_json(path)
        if not payload:
            continue
        seed = payload.get("simulation_seed")
        for package in payload.get("packages") or []:
            key = str(package.get("package_key") or "")
            gate = package.get("gate_summary") or {}
            baseline = gate.get("baseline") or {}
            candidate = gate.get("candidate") or {}
            baseline_events = (baseline.get("telemetry") or {}).get("strategic_event_counts") or {}
            baseline_raw_events = (baseline.get("telemetry") or {}).get("event_counts") or {}
            candidate_events = (candidate.get("telemetry") or {}).get("strategic_event_counts") or {}
            candidate_raw_events = (candidate.get("telemetry") or {}).get("event_counts") or {}
            seed_row = {
                "source": str(path),
                "seed": seed,
                "package_key": key,
                "family": package.get("family"),
                "adds": package.get("adds") or [],
                "cuts": package.get("cuts") or [],
                "baseline_wins": int(baseline.get("wins") or 0),
                "baseline_losses": int(baseline.get("losses") or 0),
                "candidate_wins": int(candidate.get("wins") or 0),
                "candidate_losses": int(candidate.get("losses") or 0),
                "delta_pp": float(gate.get("delta_pp") or 0.0),
                "strategic_delta": {
                    metric: int(candidate_events.get(metric) or candidate_raw_events.get(metric) or 0)
                    - int(baseline_events.get(metric) or baseline_raw_events.get(metric) or 0)
                    for metric in metrics
                },
            }
            per_seed.append(seed_row)
            entry = aggregate.setdefault(
                key,
                {
                    "package_key": key,
                    "family": package.get("family"),
                    "adds": package.get("adds") or [],
                    "cuts": package.get("cuts") or [],
                    "baseline_wins": 0,
                    "baseline_losses": 0,
                    "candidate_wins": 0,
                    "candidate_losses": 0,
                    "strong_seed_delta_pp": 0.0,
                    "strategic_delta": {metric: 0 for metric in metrics},
                    "seed_rows": [],
                },
            )
            entry["baseline_wins"] += seed_row["baseline_wins"]
            entry["baseline_losses"] += seed_row["baseline_losses"]
            entry["candidate_wins"] += seed_row["candidate_wins"]
            entry["candidate_losses"] += seed_row["candidate_losses"]
            if seed == 42:
                entry["strong_seed_delta_pp"] = seed_row["delta_pp"]
            for metric, value in seed_row["strategic_delta"].items():
                entry["strategic_delta"][metric] += value
            entry["seed_rows"].append(seed_row)

    rows = []
    for entry in aggregate.values():
        baseline_games = max(1, entry["baseline_wins"] + entry["baseline_losses"])
        candidate_games = max(1, entry["candidate_wins"] + entry["candidate_losses"])
        baseline_wr = round(100.0 * entry["baseline_wins"] / baseline_games, 2)
        candidate_wr = round(100.0 * entry["candidate_wins"] / candidate_games, 2)
        row = {
            **entry,
            "baseline_games": baseline_games,
            "candidate_games": candidate_games,
            "baseline_win_rate": baseline_wr,
            "candidate_win_rate": candidate_wr,
            "delta_pp": round(candidate_wr - baseline_wr, 2),
        }
        row["decision"] = post_squee_package_decision(row)
        rows.append(row)

    rows.sort(key=lambda item: (item["decision"] == "reject_or_rework", -item["delta_pp"], item["package_key"]))
    return {"paths": [str(path) for path in paths], "rows": rows, "per_seed": per_seed}


def safe_queue_decision(row: dict[str, Any]) -> str:
    if row.get("status") != "gated":
        return str(row.get("status") or "not_gated")
    delta = float(row.get("delta_pp") or 0.0)
    candidate_wins = int(row.get("candidate_wins") or 0)
    baseline_wins = int(row.get("baseline_wins") or 0)
    if delta >= 0 and candidate_wins >= baseline_wins:
        return "promote_to_deeper_gate"
    if delta > -50.0 and candidate_wins > 0:
        return "watch_only_needs_stronger_justification"
    return "smoke_negative_do_not_promote"


def aggregate_safe_package_gates(paths: list[Path]) -> dict[str, Any]:
    metrics = [
        "lorehold_cost_paid",
        "lorehold_spell_cast",
        "spell_cast_mana_trigger",
        "birgi_spell_cast_mana",
        "ritual_mana_added",
        "lorehold_spell_rummage",
        "lorehold_upkeep_rummage",
        "miracle_cast",
        "tutor_resolved",
        "random_discard_after_tutor",
        "topdeck_manipulation_activated",
        "discard_to_top_replacement",
        "lorehold_rummage_discard_to_top",
        "lorehold_spell_rummage_discard_to_top",
        "hand_to_topdeck_activation",
        "squee_to_graveyard",
        "squee_upkeep_return",
        "squee_return_after_known_graveyard_entry",
    ]
    rows: list[dict[str, Any]] = []
    status_counts: Counter[str] = Counter()
    decision_counts: Counter[str] = Counter()
    for path in paths:
        payload = read_json(path)
        if not payload:
            continue
        for package in payload.get("packages") or []:
            gate = package.get("gate_summary") or {}
            baseline = gate.get("baseline") or {}
            candidate = gate.get("candidate") or {}
            baseline_events = (baseline.get("telemetry") or {}).get("strategic_event_counts") or {}
            baseline_raw_events = (baseline.get("telemetry") or {}).get("event_counts") or {}
            candidate_events = (candidate.get("telemetry") or {}).get("strategic_event_counts") or {}
            candidate_raw_events = (candidate.get("telemetry") or {}).get("event_counts") or {}
            row = {
                "source": str(path),
                "package_key": package.get("package_key"),
                "family": package.get("family"),
                "adds": package.get("adds") or [],
                "cuts": package.get("cuts") or [],
                "status": package.get("status"),
                "cut_safety_status": (package.get("cut_safety") or {}).get("status"),
                "prior_evidence_status": (package.get("prior_evidence") or {}).get("status"),
                "added_rule_counts": (package.get("candidate_meta") or {}).get("added_rule_counts") or {},
                "miracle_core_cuts": (package.get("candidate_meta") or {}).get("miracle_core_cuts") or [],
                "baseline_wins": int(baseline.get("wins") or 0),
                "baseline_losses": int(baseline.get("losses") or 0),
                "baseline_stalls": int(baseline.get("stalls") or 0),
                "baseline_win_rate": float(baseline.get("win_rate") or 0.0),
                "candidate_wins": int(candidate.get("wins") or 0),
                "candidate_losses": int(candidate.get("losses") or 0),
                "candidate_stalls": int(candidate.get("stalls") or 0),
                "candidate_win_rate": float(candidate.get("win_rate") or 0.0),
                "delta_pp": float(gate.get("delta_pp") or 0.0),
                "strategic_delta": {
                    metric: int(candidate_events.get(metric) or candidate_raw_events.get(metric) or 0)
                    - int(baseline_events.get(metric) or baseline_raw_events.get(metric) or 0)
                    for metric in metrics
                },
            }
            row["decision"] = safe_queue_decision(row)
            rows.append(row)
            status_counts[str(row["status"] or "unknown")] += 1
            decision_counts[row["decision"]] += 1

    rows.sort(key=lambda item: (-float(item.get("delta_pp") or 0.0), item.get("package_key") or ""))
    best = rows[0] if rows else {}
    return {
        "paths": [str(path) for path in paths],
        "summary": {
            "package_count": len(rows),
            "status_counts": dict(sorted(status_counts.items())),
            "decision_counts": dict(sorted(decision_counts.items())),
            "best_package_key": best.get("package_key"),
            "best_delta_pp": best.get("delta_pp"),
            "best_candidate_record": (
                f"{best.get('candidate_wins', 0)}-{best.get('candidate_losses', 0)}-"
                f"{best.get('candidate_stalls', 0)}"
                if best
                else None
            ),
        },
        "rows": rows,
    }


def aggregate_runtime_package_readiness(
    *,
    proposal_paths: list[Path],
    manifest_paths: list[Path],
    blocker_paths: list[Path],
) -> dict[str, Any]:
    """Summarize runtime-backed cards that are package-ready but not yet durable."""
    blocked_by_card: dict[str, list[dict[str, Any]]] = defaultdict(list)
    blockers = []
    for path in blocker_paths:
        payload = read_json(path)
        if not payload:
            continue
        blocker = {
            "source": str(path),
            "status": payload.get("status"),
            "deploy_id": payload.get("deploy_id"),
            "slug": payload.get("slug"),
            "blocked_step": payload.get("blocked_step"),
            "sanitized_error": payload.get("sanitized_error"),
            "selected_cards": payload.get("selected_cards") or payload.get("selected_card_names") or [],
        }
        blockers.append(blocker)
        for card_name in blocker["selected_cards"]:
            blocked_by_card[str(card_name)].append(blocker)

    manifests = []
    manifest_by_card: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for path in manifest_paths:
        payload = read_json(path)
        if not payload:
            continue
        manifest = {
            "source": str(path),
            "status": payload.get("status"),
            "deploy_id": payload.get("deploy_id"),
            "slug": payload.get("slug"),
            "selected_count": payload.get("selected_count"),
            "selected_card_names": payload.get("selected_card_names") or [],
            "family_counts": payload.get("family_counts") or {},
            "apply_gate": payload.get("apply_gate"),
        }
        manifests.append(manifest)
        for card_name in manifest["selected_card_names"]:
            manifest_by_card[str(card_name)].append(manifest)

    cards_by_name: dict[str, dict[str, Any]] = {}
    for path in proposal_paths:
        payload = read_json(path)
        if not payload:
            continue
        for proposal in payload.get("proposals") or []:
            if not proposal.get("safe_for_batch_pg_package"):
                continue
            card_name = str(proposal.get("card_name") or "")
            blocker_entries = blocked_by_card.get(card_name, [])
            manifest_entries = manifest_by_card.get(card_name, [])
            if blocker_entries:
                readiness = "runtime_ready_pg_precheck_blocked"
            elif manifest_entries:
                readiness = "runtime_ready_pg_package_prepared"
            else:
                readiness = "runtime_ready_needs_pg_package"
            cards_by_name[card_name] = {
                "card_name": card_name,
                "family_id": proposal.get("family_id"),
                "effect": proposal.get("effect"),
                "battle_model_scope": proposal.get("battle_model_scope"),
                "proposal_status": proposal.get("proposal_status"),
                "oracle_hash": proposal.get("oracle_hash"),
                "logical_rule_key": proposal.get("logical_rule_key"),
                "deck_role_json": proposal.get("deck_role_json") or {},
                "effect_json": proposal.get("effect_json") or {},
                "readiness": readiness,
                "package_manifests": manifest_entries,
                "blockers": blocker_entries,
            }

    family_counts: Counter[str] = Counter()
    readiness_counts: Counter[str] = Counter()
    for row in cards_by_name.values():
        family_counts[str(row.get("family_id") or "unknown")] += 1
        readiness_counts[str(row.get("readiness") or "unknown")] += 1

    return {
        "proposal_paths": [str(path) for path in proposal_paths],
        "manifest_paths": [str(path) for path in manifest_paths],
        "blocker_paths": [str(path) for path in blocker_paths],
        "summary": {
            "card_count": len(cards_by_name),
            "family_counts": dict(sorted(family_counts.items())),
            "readiness_counts": dict(sorted(readiness_counts.items())),
            "blocked_card_count": sum(
                1 for row in cards_by_name.values() if row.get("readiness") == "runtime_ready_pg_precheck_blocked"
            ),
            "manifest_count": len(manifests),
            "blocker_count": len(blockers),
        },
        "cards": sorted(cards_by_name.values(), key=lambda item: item.get("card_name") or ""),
        "manifests": manifests,
        "blockers": blockers,
    }


def aggregate_library_leng_telemetry_gates(paths: list[Path]) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    aggregate = Counter()
    per_card = Counter()
    for path in paths:
        payload = read_json(path)
        if not payload:
            continue
        seed = payload.get("simulation_seed")
        for result in payload.get("results") or []:
            telemetry = result.get("telemetry") or {}
            events = telemetry.get("strategic_event_counts") or {}
            games = telemetry.get("strategic_games") or {}
            top_cards = telemetry.get("top_cards") or []
            row = {
                "source": str(path),
                "seed": seed,
                "deck_key": result.get("deck_key"),
                "wins": int(result.get("wins") or 0),
                "losses": int(result.get("losses") or 0),
                "stalls": int(result.get("stalls") or 0),
                "win_rate": float(result.get("win_rate") or 0),
                "miracle_cast": int(events.get("miracle_cast") or 0),
                "topdeck_manipulation_activated": int(events.get("topdeck_manipulation_activated") or 0),
                "discard_to_top_replacement": int(events.get("discard_to_top_replacement") or 0),
                "lorehold_rummage_discard_to_top": int(events.get("lorehold_rummage_discard_to_top") or 0),
                "lorehold_spell_rummage_discard_to_top": int(events.get("lorehold_spell_rummage_discard_to_top") or 0),
                "lorehold_upkeep_rummage": int(events.get("lorehold_upkeep_rummage") or 0),
                "lorehold_spell_rummage": int(events.get("lorehold_spell_rummage") or 0),
                "squee_to_graveyard": int(events.get("squee_to_graveyard") or 0),
                "squee_upkeep_return": int(events.get("squee_upkeep_return") or 0),
                "discard_to_top_games": int((games.get("discard_to_top_replacement") or {}).get("games") or 0),
                "topdeck_games": int((games.get("topdeck_manipulation_activated") or {}).get("games") or 0),
                "miracle_games": int((games.get("miracle_cast") or {}).get("games") or 0),
            }
            rows.append(row)
            for key in (
                "wins",
                "losses",
                "stalls",
                "miracle_cast",
                "topdeck_manipulation_activated",
                "discard_to_top_replacement",
                "lorehold_rummage_discard_to_top",
                "lorehold_spell_rummage_discard_to_top",
                "lorehold_upkeep_rummage",
                "lorehold_spell_rummage",
                "squee_to_graveyard",
                "squee_upkeep_return",
                "discard_to_top_games",
                "topdeck_games",
                "miracle_games",
            ):
                aggregate[key] += row[key]
            for item in top_cards:
                key = str(item.get("key") or "")
                if key.startswith(("discard_to_top:", "lorehold_rummage_to_top:", "spell_rummage_to_top:")):
                    per_card[key] += int(item.get("count") or 0)
    games = max(1, aggregate["wins"] + aggregate["losses"] + aggregate["stalls"])
    return {
        "paths": [str(path) for path in paths],
        "rows": rows,
        "summary": {
            **dict(aggregate),
            "games": games,
            "win_rate": round(100.0 * aggregate["wins"] / games, 2),
        },
        "top_discard_to_top_cards": [
            {"key": key, "count": count}
            for key, count in per_card.most_common(12)
        ],
    }


def compare_decks(conn: sqlite3.Connection, a: int, b: int) -> dict[str, Any]:
    def card_set(deck_id: int) -> set[str]:
        return {
            row["card_name"]
            for row in conn.execute(
                "SELECT card_name FROM deck_cards WHERE deck_id = ?",
                (deck_id,),
            ).fetchall()
        }

    a_cards = card_set(a)
    b_cards = card_set(b)
    return {
        "left_deck_id": a,
        "right_deck_id": b,
        "only_left": sorted(a_cards - b_cards),
        "only_right": sorted(b_cards - a_cards),
        "shared_count": len(a_cards & b_cards),
    }


def current_champion_key(squee_summary: dict[str, Any]) -> str:
    summary = squee_summary.get("summary") or {}
    if not summary:
        return "unknown"
    return max(summary.items(), key=lambda item: (item[1].get("win_rate", 0), item[1].get("wins", 0)))[0]


def gate_record(summary: dict[str, Any], key: str) -> dict[str, Any]:
    value = summary.get(key) or {}
    wins = int(value.get("wins") or 0)
    losses = int(value.get("losses") or 0)
    stalls = int(value.get("stalls") or 0)
    games = int(value.get("games") or wins + losses + stalls)
    return {
        "deck_key": key,
        "games": games,
        "wins": wins,
        "losses": losses,
        "stalls": stalls,
        "record": f"{wins}-{losses}-{stalls}",
        "win_rate": float(value.get("win_rate") or (100.0 * wins / max(1, games))),
        "strategic_events": value.get("strategic_events") or {},
    }


def find_seed_row(rows: list[dict[str, Any]], seed: object, deck_key: str | None = None) -> dict[str, Any]:
    seed_text = str(seed)
    for row in rows:
        if str(row.get("seed")) != seed_text:
            continue
        if deck_key and row.get("deck_key") != deck_key:
            continue
        return row
    return {}


def summarize_package_results(rows: list[dict[str, Any]]) -> dict[str, Any]:
    decision_counts: Counter[str] = Counter()
    family_counts: Counter[str] = Counter()
    best_probation: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    for row in rows:
        decision = str(row.get("decision") or "unknown")
        family = str(row.get("family") or "unknown")
        decision_counts[decision] += 1
        family_counts[family] += 1
        compact = {
            "package_key": row.get("package_key"),
            "family": row.get("family"),
            "adds": row.get("adds") or [],
            "cuts": row.get("cuts") or [],
            "delta_pp": float(row.get("delta_pp") or 0.0),
            "strong_seed_delta_pp": float(row.get("strong_seed_delta_pp") or 0.0),
            "decision": decision,
        }
        if decision != "reject_or_rework":
            best_probation.append(compact)
        else:
            rejected.append(compact)
    best_probation.sort(key=lambda item: (-item["delta_pp"], item["package_key"] or ""))
    rejected.sort(key=lambda item: (item["delta_pp"], item["package_key"] or ""))
    return {
        "decision_counts": dict(sorted(decision_counts.items())),
        "family_counts": dict(sorted(family_counts.items())),
        "probation_or_watch": best_probation[:8],
        "hard_reject_sample": rejected[:12],
    }


def build_strategy_dependency_map(
    *,
    squee_gates: dict[str, Any],
    matrix_ranked: list[dict[str, Any]],
    post_squee_package_gates: dict[str, Any],
    safe_package_gates: dict[str, Any],
    library_leng_telemetry_gates: dict[str, Any],
    loss_failure_classifier: dict[str, Any],
    cut_safety_manifest: dict[str, Any],
) -> dict[str, Any]:
    """Convert battle evidence into a reusable contract for the next hypothesis."""
    squee_summary = squee_gates.get("summary") or {}
    champion_key = current_champion_key(squee_gates)
    champion_record = gate_record(squee_summary, champion_key)
    deck_607_record = gate_record(squee_summary, "deck_607")
    deck_6_record = gate_record(squee_summary, "deck_6")
    squee_rows = squee_gates.get("rows") or []
    seed42 = find_seed_row(squee_rows, 42, champion_key)
    seed7 = find_seed_row(squee_rows, 7, champion_key)
    seed20260625 = find_seed_row(squee_rows, 20260625, champion_key)
    library_rows = library_leng_telemetry_gates.get("rows") or []
    library_seed42 = find_seed_row(library_rows, 42)
    library_seed7 = find_seed_row(library_rows, 7)
    library_seed20260625 = find_seed_row(library_rows, 20260625)
    loss_rows = loss_failure_classifier.get("summary_rows") or []
    baseline_loss_rows = [
        row
        for row in loss_rows
        if row.get("package_key") == "baseline_squee_champion"
    ]
    cut_rows = cut_safety_manifest.get("cuts") or []
    locked_cuts = [
        row for row in cut_rows
        if row.get("status") in {"locked_do_not_cut", "protected_until_same_lane_win"}
    ]
    risky_cuts = [
        row for row in cut_rows
        if row.get("status") == "risky_cut_only_same_lane"
    ]
    post_rows = post_squee_package_gates.get("rows") or []
    post_summary = summarize_package_results(post_rows)
    safe_rows = safe_package_gates.get("rows") or []
    safe_watch = [
        {
            "package_key": row.get("package_key"),
            "family": row.get("family"),
            "adds": row.get("adds") or [],
            "cuts": row.get("cuts") or [],
            "delta_pp": float(row.get("delta_pp") or 0.0),
            "decision": row.get("decision"),
        }
        for row in safe_rows
        if row.get("decision") == "watch_only_needs_stronger_justification"
    ]
    safe_rejected = [
        {
            "package_key": row.get("package_key"),
            "family": row.get("family"),
            "adds": row.get("adds") or [],
            "cuts": row.get("cuts") or [],
            "delta_pp": float(row.get("delta_pp") or 0.0),
            "decision": row.get("decision"),
        }
        for row in safe_rows
        if row.get("decision") == "smoke_negative_do_not_promote"
    ]

    variant_contract = []
    for item in matrix_ranked:
        key = item.get("deck_key")
        if key == "deck_607":
            action = "baseline_shell"
            reason = "best structural match to commander intent and the current benchmark shell"
        elif key in {"deck_615", "deck_614"}:
            action = "extract_controlled_packages_only"
            reason = "high structural rank but many slot changes; test one package at a time against 607+Squee"
        elif int(item.get("land_count") or 0) < 33:
            action = "do_not_import_full_list"
            reason = "land count below current guardrail; use only isolated ideas if battle-ready"
        else:
            action = "secondary_reference_only"
            reason = "less aligned than 607/615/614 or lower rule-readiness/role balance"
        variant_contract.append(
            {
                "rank": item.get("rank"),
                "deck_key": key,
                "deck_name": item.get("deck_name"),
                "land_count": item.get("land_count"),
                "strategy_score": item.get("strategy_score"),
                "commander_intent_score": item.get("commander_intent_score"),
                "primary_risks": item.get("primary_risks") or [],
                "action": action,
                "reason": reason,
            }
        )

    pillars = [
        {
            "pillar": "topdeck_miracle_setup",
            "depends_on": ["Library of Leng", "Scroll Rack", "Sensei's Divining Top", "Molecule Man", "Bender's Waterskin"],
            "current_evidence": (
                f"seed42 library gate: discard_to_top={library_seed42.get('discard_to_top_replacement', 0)}, "
                f"topdeck={library_seed42.get('topdeck_manipulation_activated', 0)}, "
                f"miracle={library_seed42.get('miracle_cast', 0)}"
            ),
            "risk": "seed 7 shows the deck can miss the engine entirely",
            "next_requirement": "improve early access or topdeck quality without reducing seed-42 miracle/topdeck counts",
        },
        {
            "pillar": "spell_chain_conversion",
            "depends_on": ["Ruby Medallion", "Pearl Medallion", "Jeska's Will", "Big Score", "Unexpected Windfall"],
            "current_evidence": "Birgi and Seething Song produced mana telemetry, but medallion cuts broke seed 42",
            "risk": "ritual mana that lowers miracle density or removes persistent reducers is not a win",
            "next_requirement": "preserve at least one medallion or prove the cut in a same-lane seed-42 benchmark",
        },
        {
            "pillar": "pressure_absorption",
            "depends_on": ["Dawn's Truce", "Teferi's Protection", "High Noon", "Fated Clash", "Hexing Squelcher"],
            "current_evidence": f"classified baseline losses: {len(baseline_loss_rows)} rows, all focused on combat-pressure/life-zero failure modes",
            "risk": "cheap protection swaps can help weak seeds while destroying the known strong seed",
            "next_requirement": "target survival/second-window conversion while preserving the existing protection shell",
        },
        {
            "pillar": "deterministic_finishers",
            "depends_on": ["Approach of the Second Sun", "Storm Herd", "Mizzix's Mastery", "Surge to Victory"],
            "current_evidence": "Dance with Calamity and Aetherflux Reservoir lost the Storm Herd slot benchmark",
            "risk": "replacing finishers with generic value lowers closing certainty",
            "next_requirement": "benchmark finishers against Approach/Storm Herd lanes, not against unrelated support slots",
        },
        {
            "pillar": "graveyard_recursion",
            "depends_on": ["Squee, Goblin Nabob", "Pinnacle Monk // Mystic Peak", "Mizzix's Mastery"],
            "current_evidence": (
                f"Squee champion {champion_record['record']} vs deck_607 {deck_607_record['record']}; "
                f"squee_return={champion_record['strategic_events'].get('squee_upkeep_return', 0)}"
            ),
            "risk": "Squee returns are proven after graveyard entry, but Lorehold discard-to-Squee is still not proven",
            "next_requirement": "test recursion as a package only when the gate tracks actual discard/graveyard entry route",
        },
    ]

    return {
        "commander_plan": {
            "intent": COMMANDER_INTENT,
            "external_alignment": [
                {
                    "source": "EDHREC Lorehold miracle article",
                    "supports": "first-draw miracle timing and opponent-upkeep rummage are the commander's core engine",
                    "internal_decision": "matches the current topdeck/miracle pillar",
                },
                {
                    "source": "Card Kingdom Lorehold synergy article",
                    "supports": "Library of Leng plus Lorehold discard can put the discarded card on top for the draw",
                    "internal_decision": "runtime telemetry confirms the engine exists, but survival/conversion still gates promotion",
                },
                {
                    "source": "EDHREC cEDH average deck",
                    "supports": "Birgi, Seething Song, Scroll Rack, Sensei's Divining Top, Ruby Medallion, and The One Ring are plausible external ideas",
                    "internal_decision": "use as hypothesis source only; current battle gates rejected the tested cuts",
                },
            ],
        },
        "current_benchmark": {
            "champion": champion_record,
            "deck_607": deck_607_record,
            "deck_6": deck_6_record,
            "seed_42_champion": seed42,
            "seed_7_champion": seed7,
            "seed_20260625_champion": seed20260625,
        },
        "dependency_pillars": pillars,
        "cut_guardrails": {
            "locked_or_protected": [
                {
                    "card_name": row.get("card_name"),
                    "status": row.get("status"),
                    "lane": row.get("current_lane"),
                    "worst_strong_seed_delta_pp": row.get("worst_strong_seed_delta_pp"),
                    "reason": row.get("reason"),
                }
                for row in locked_cuts
            ],
            "risky_same_lane_only": [
                {
                    "card_name": row.get("card_name"),
                    "status": row.get("status"),
                    "lane": row.get("current_lane"),
                    "best_delta_pp": row.get("best_delta_pp"),
                    "worst_strong_seed_delta_pp": row.get("worst_strong_seed_delta_pp"),
                    "reason": row.get("reason"),
                }
                for row in risky_cuts
            ],
            "untested_flex_pool": cut_safety_manifest.get("untested_flex_pool") or [],
        },
        "package_learning": {
            "post_squee": post_summary,
            "safe_queue_watch": safe_watch,
            "safe_queue_rejected": safe_rejected,
        },
        "variant_import_contract": variant_contract[:12],
        "next_hypothesis_contract": {
            "promotion_bar": [
                "tie or beat the Squee champion aggregate record across the same seed/opponent window",
                "do not regress seed 42 unless a larger gate proves the strong-seed pattern moved elsewhere",
                "do not promote from popularity or static structure without battle evidence",
                "a negative smoke result remains no-promotion unless a specific failure classifier target explains why to override it",
            ],
            "must_target": [
                "seed 7: missing early topdeck/Library/Squee engine",
                "seed 20260625: engine appears but fails to convert Approach/topdeck loops into survival or a second win window",
                "combat-pressure/life-zero losses without cutting the known protection shell",
            ],
            "required_telemetry": [
                "miracle_cast and topdeck_manipulation_activated must not fall in the strong seed",
                "discard_to_top_replacement should connect to survival, Approach recast, or a finisher window",
                "spell_cast_mana_trigger or ritual_mana_added is useful only if win rate and seed-42 conversion survive",
                "Squee value must be tied to observed graveyard entry route, not assumed discard synergy",
            ],
            "hard_reject_if": [
                "candidate cuts a locked/protected card without same-lane proof",
                "candidate only adds generic ramp/value and lowers miracle/topdeck/spell volume",
                "candidate wins weak seeds but collapses seed 42 in the first controlled gate",
                "candidate depends on a card with unresolved battle runtime/model evidence",
            ],
        },
    }


def render_markdown(report: dict[str, Any]) -> str:
    library_leng = report.get("library_leng_telemetry_gates") or {}
    library_leng_rows = library_leng.get("rows") or []
    loss_classifier = report.get("loss_failure_classifier") or {}
    loss_summary_rows = loss_classifier.get("summary_rows") or []
    report_date = str(report.get("generated_at") or "")[:10] or "latest"
    lines: list[str] = []
    lines.append(f"# Lorehold Strategy Learning Audit - {report_date}")
    lines.append("")
    lines.append(f"- Generated at: `{report['generated_at']}`")
    lines.append(f"- Source DB: `{report['source_db']}`")
    lines.append(f"- Structural matrix: `{report['matrix_path']}`")
    lines.append("- PostgreSQL writes: `false`")
    lines.append("- Source DB mutated: `false`")
    lines.append("")
    lines.append("## Commander Intent")
    lines.append("")
    lines.append(COMMANDER_INTENT)
    lines.append("")
    lines.append("Operationally, a better deck must increase at least one of these without breaking the others: early mana/setup, topdeck/miracle conversion, hand filtering, pressure absorption, deterministic closing, or rule-confidence for the cards being tested.")
    lines.append("")
    lines.append("## Current Finding")
    lines.append("")
    lines.append(f"- Current evidence champion: `{report['current_champion_key']}`.")
    lines.append("- The strongest current direction is not a generic big-spell upgrade; it is improving the 607 shell by testing the expensive `Insurrection` slot against `Squee, Goblin Nabob` and then validating that result across seeds.")
    lines.append("- Decisive gate evidence now uses `PYTHONHASHSEED=0`, `deck_process_isolation=true`, per-game timeout, and the optimized battle-rule lookup cache; seed-42 baseline/candidate-only reproductions match the comparative gate exactly.")
    lines.append("- The 10-seed suite keeps Squee barely ahead but downgrades confidence: champion `24W/66L/0S` (`26.67%`) vs `deck_607` `21W/69L/0S` (`23.33%`) and source `deck_6` `16W/74L/0S` (`17.78%`).")
    lines.append("- Zone-trace evidence proves `Squee` can be cast, move to graveyard, and return during games, not only in a unit test. Across the 10-seed suite it has `squee_to_graveyard=16`, `squee_upkeep_return=12`, `squee_return_after_known_graveyard_entry=12`, and `squee_return_without_known_graveyard_entry=0`.")
    lines.append("- Proven Squee routes in this suite are battlefield-to-graveyard through combat/wipes plus one opponent mill (`Brain Freeze`), but Squee does not appear in enough games to explain the whole deck result.")
    lines.append("- Important caveat: the trace gate still did not show `Squee` being discarded by Lorehold rummage or spell-rummage. Treat the discard-fuel loop as a hypothesis; the proven loop is graveyard recurrence after observed zone entries.")
    lines.append("- The per-game seed diagnostic shows the real failure mode: Squee is not yet self-sufficient. Seed 42 wins when topdeck/miracle/spell volume is high; seeds 7 and 20260625 go `0W/9L` with no Squee graveyard/return events and very low topdeck/miracle conversion.")
    materialization = report.get("squee_rule_materialization_audit") or {}
    if materialization.get("finding"):
        lines.append(f"- Squee rule materialization is now fixed in the equal-gate loader evidence: {materialization['finding']}")
    else:
        lines.append("- `Squee` still needs a rule-materialization check before trusting candidate snapshots that add it.")
    unresolved_audit = report.get("unresolved_rule_rows_audit") or {}
    unresolved_summary = unresolved_audit.get("summary") or {}
    if unresolved_summary:
        lines.append(
            "- Remaining rule-row audit now separates aggregate sync gaps from real model gaps: "
            f"`{unresolved_summary.get('deck_rule_materialization_gap', 0)}` deck materialization gaps and "
            f"`{unresolved_summary.get('missing_battle_rule_model', 0)}` missing battle-rule/model gap."
        )
    thor_audit = report.get("thor_rule_runtime_audit") or {}
    if thor_audit.get("decision"):
        verification = thor_audit.get("temp_sqlite_sync_verification") or {}
        lines.append(
            "- Thor rule/runtime audit now closes the local model gap: "
            f"`{thor_audit.get('decision')}`, temp materialized Thor rule count "
            f"`{verification.get('thor_deck_rule_count_after_temp_materialization', 0)}`. "
            "It still needs durable PostgreSQL/Hermes sync approval before promotion gates use it as source truth."
        )
    thor_gate_audit = report.get("thor_rule_gate_audit") or {}
    if thor_gate_audit.get("decision"):
        interpretation = thor_gate_audit.get("interpretation") or {}
        lines.append(
            "- Thor synced-rule battle gate now has natural exposure evidence: "
            f"`{interpretation.get('candidate_thor_damage_triggers', 0)}` trigger for "
            f"`{interpretation.get('candidate_thor_damage_amount', 0)}` damage across "
            f"`{interpretation.get('candidate_total_games', 0)}` candidate games, "
            f"with win-rate delta `{float(interpretation.get('winrate_delta_pp') or 0):+.2f}` pp."
        )
    runtime_readiness = report.get("runtime_package_readiness") or {}
    runtime_summary = runtime_readiness.get("summary") or {}
    if runtime_summary.get("card_count"):
        lines.append(
            "- Runtime/package readiness now tracks new modeled hypotheses outside the champion list: "
            f"`{runtime_summary.get('card_count')}` cards, families "
            f"`{json.dumps(runtime_summary.get('family_counts', {}), sort_keys=True)}`, readiness "
            f"`{json.dumps(runtime_summary.get('readiness_counts', {}), sort_keys=True)}`."
        )
    lines.append("- The broad synergy-confirm gate rejected the tested Past in Flames, Overmaster, and combined spellchain packages; do not promote them from the current evidence.")
    safe_queue = report.get("safe_package_gates") or {}
    safe_rows = safe_queue.get("rows") or []
    if safe_rows:
        safe_summary = safe_queue.get("summary") or {}
        lines.append(
            "- The cut-safety-aware safe queue v3 produced "
            f"`{safe_summary.get('package_count', 0)}` executable packages that avoided the protected cuts, "
            f"but the smoke gate still found no promotion. Best smoke result was "
            f"`{safe_summary.get('best_package_key')}` at `{safe_summary.get('best_candidate_record')}` "
            f"with delta `{float(safe_summary.get('best_delta_pp') or 0):+.2f}` pp."
        )
        overmaster_safe = next(
            (row for row in safe_rows if row.get("package_key") == "overmaster_protect_draw_cut_tibalts_trickery"),
            None,
        )
        if overmaster_safe:
            lines.append(
                "- `Overmaster` over `Tibalt's Trickery` is only a watch-list clue, not a deck change: "
                f"candidate `{overmaster_safe['candidate_wins']}-{overmaster_safe['candidate_losses']}` vs "
                f"baseline `{overmaster_safe['baseline_wins']}-{overmaster_safe['baseline_losses']}` "
                f"(`{overmaster_safe['delta_pp']:+.2f}` pp), decision `{overmaster_safe['decision']}`."
            )
    post_squee = report.get("post_squee_package_gates") or {}
    post_squee_rows = post_squee.get("rows") or []
    if post_squee_rows:
        best = post_squee_rows[0]
        lines.append(
            "- Post-Squee package gates now cover Brainstone, Faithless Looting, Galvanoth, Birgi, Seething Song, Penance, Primal Amulet, and Gamble against the Squee champion. "
            f"Best aggregate was `{best['package_key']}` at `{best['candidate_wins']}-{best['candidate_losses']}` "
            f"vs baseline `{best['baseline_wins']}-{best['baseline_losses']}` (`{best['delta_pp']:+.2f}` pp), "
            f"but seed 42 moved `{best['strong_seed_delta_pp']:+.2f}` pp, so it is not an automatic deck promotion."
        )
        birgi = next((row for row in post_squee_rows if row["package_key"] == "birgi_spellchain_cut_squelcher"), None)
        penance = next(
            (row for row in post_squee_rows if row["package_key"] == "penance_topdeck_protection_cut_squelcher"),
            None,
        )
        if birgi:
            delta = birgi.get("strategic_delta") or {}
            lines.append(
                f"- Birgi is now instrumented and produced `{int(delta.get('birgi_spell_cast_mana') or 0):+d}` spell-cast mana triggers, "
                f"but its aggregate result was `{birgi['candidate_wins']}-{birgi['candidate_losses']}` "
                f"vs baseline `{birgi['baseline_wins']}-{birgi['baseline_losses']}` (`{birgi['delta_pp']:+.2f}` pp); "
                "mana telemetry alone is not enough to promote it."
            )
        birgi_ritual = next(
            (row for row in post_squee_rows if row["package_key"] == "birgi_seething_chain_cut_medallions"),
            None,
        )
        if birgi_ritual:
            delta = birgi_ritual.get("strategic_delta") or {}
            lines.append(
                "- Birgi + Seething Song over Pearl/Ruby Medallion is a useful but rejected spell-chain clue: "
                f"`{birgi_ritual['candidate_wins']}-{birgi_ritual['candidate_losses']}` vs "
                f"`{birgi_ritual['baseline_wins']}-{birgi_ritual['baseline_losses']}` (`{birgi_ritual['delta_pp']:+.2f}` pp), "
                f"seed 42 `{birgi_ritual['strong_seed_delta_pp']:+.2f}` pp, "
                f"ritual delta `{int(delta.get('ritual_mana_added') or 0):+d}`, "
                f"Birgi mana delta `{int(delta.get('birgi_spell_cast_mana') or 0):+d}`. "
                "It helps weak seeds, but losing both medallions breaks the known strong conversion pattern."
            )
        if penance:
            delta = penance.get("strategic_delta") or {}
            lines.append(
                f"- Penance is not a proven topdeck engine yet: observed `hand_to_topdeck_activation` delta was `{int(delta.get('hand_to_topdeck_activation') or 0):+d}` "
                f"and the package lost `{penance['delta_pp']:+.2f}` pp aggregate."
            )
        library_pressure_keys = [
            "brainstone_topdeck_miracle_cut_squelcher",
            "ghostly_prison_pressure_cut_squelcher",
            "one_ring_protection_draw_cut_squelcher",
        ]
        library_pressure_rows = {
            row["package_key"]: row for row in post_squee_rows if row["package_key"] in library_pressure_keys
        }
        if len(library_pressure_rows) == len(library_pressure_keys):
            brainstone = library_pressure_rows["brainstone_topdeck_miracle_cut_squelcher"]
            ghostly = library_pressure_rows["ghostly_prison_pressure_cut_squelcher"]
            one_ring = library_pressure_rows["one_ring_protection_draw_cut_squelcher"]
            lines.append(
                "- Library/pressure conversion retest is now closed for the first pass: "
                f"`Brainstone` over Hexing Squelcher finished `{brainstone['candidate_wins']}-{brainstone['candidate_losses']}` "
                f"vs `{brainstone['baseline_wins']}-{brainstone['baseline_losses']}` (`{brainstone['delta_pp']:+.2f}` pp) "
                f"but broke seed 42 by `{brainstone['strong_seed_delta_pp']:+.2f}` pp; "
                f"`Ghostly Prison` was `{ghostly['delta_pp']:+.2f}` pp and "
                f"`The One Ring` was `{one_ring['delta_pp']:+.2f}` pp. None promotes from this evidence."
            )
        angel = next((row for row in post_squee_rows if row["package_key"] == "angel_grace_life_floor_cut_dawn"), None)
        if angel:
            lines.append(
                "- Angel's Grace life-floor retest also rejects the intuitive cheap-protection swap: "
                f"`{angel['candidate_wins']}-{angel['candidate_losses']}` vs "
                f"`{angel['baseline_wins']}-{angel['baseline_losses']}` (`{angel['delta_pp']:+.2f}` pp) "
                f"and seed 42 moved `{angel['strong_seed_delta_pp']:+.2f}` pp."
            )
        primal = next((row for row in post_squee_rows if row["package_key"] == "primal_amulet_spell_engine"), None)
        if primal:
            delta = primal.get("strategic_delta") or {}
            lines.append(
                "- Primal Amulet over Bender's Waterskin closes the revised top-freecast test from 615 as a reject/rework: "
                f"`{primal['candidate_wins']}-{primal['candidate_losses']}` vs "
                f"`{primal['baseline_wins']}-{primal['baseline_losses']}` (`{primal['delta_pp']:+.2f}` pp), "
                f"seed 42 `{primal['strong_seed_delta_pp']:+.2f}` pp, "
                f"spell delta `{int(delta.get('lorehold_spell_cast') or 0):+d}`, "
                f"miracle delta `{int(delta.get('miracle_cast') or 0):+d}`. "
                "It helps low-performing seeds but again breaks the known strong conversion pattern."
            )
        galvanoth_thor = next(
            (row for row in post_squee_rows if row["package_key"] == "galvanoth_topdeck_freecast_cut_thor"),
            None,
        )
        if galvanoth_thor:
            lines.append(
                "- Galvanoth over Thor was the controlled topdeck/freecast retest after Bender, Hexing, and Chimes cuts failed: "
                f"`{galvanoth_thor['candidate_wins']}-{galvanoth_thor['candidate_losses']}` vs "
                f"`{galvanoth_thor['baseline_wins']}-{galvanoth_thor['baseline_losses']}` (`{galvanoth_thor['delta_pp']:+.2f}` pp), "
                f"seed 42 `{galvanoth_thor['strong_seed_delta_pp']:+.2f}` pp. "
                "This was only run as a seed-42 triage because it failed the strong-seed promotion filter; do not spend weak-seed runs on this cut."
            )
        gamble = next((row for row in post_squee_rows if row["package_key"] == "gamble_approach_access_cut_creative"), None)
        if gamble:
            delta = gamble.get("strategic_delta") or {}
            lines.append(
                "- Gamble over Creative Technique is the first narrow tutor-access benchmark against the current loss classifier: "
                f"`{gamble['candidate_wins']}-{gamble['candidate_losses']}` vs "
                f"`{gamble['baseline_wins']}-{gamble['baseline_losses']}` (`{gamble['delta_pp']:+.2f}` pp), "
                f"seed 42 `{gamble['strong_seed_delta_pp']:+.2f}` pp, "
                f"tutor delta `{int(delta.get('tutor_resolved') or 0):+d}`, "
                f"random-discard delta `{int(delta.get('random_discard_after_tutor') or 0):+d}`. "
                "Because it breaks the known strong seed, do not replace Creative Technique yet; treat this as a tutor-access clue that needs a different cut or a seed-42-preserving follow-up."
            )
        gamble_thor = next((row for row in post_squee_rows if row["package_key"] == "gamble_access_cut_thor"), None)
        if gamble_thor:
            delta = gamble_thor.get("strategic_delta") or {}
            lines.append(
                "- Gamble over Thor was the attempted seed-42-preserving tutor retest after the Creative Technique cut failed: "
                f"`{gamble_thor['candidate_wins']}-{gamble_thor['candidate_losses']}` vs "
                f"`{gamble_thor['baseline_wins']}-{gamble_thor['baseline_losses']}` (`{gamble_thor['delta_pp']:+.2f}` pp), "
                f"seed 42 `{gamble_thor['strong_seed_delta_pp']:+.2f}` pp, "
                f"tutor delta `{int(delta.get('tutor_resolved') or 0):+d}`, "
                f"random-discard delta `{int(delta.get('random_discard_after_tutor') or 0):+d}`."
                " This was only run as a seed-42 triage because it failed the strong-seed promotion filter."
            )
        enlightened_thor = next(
            (row for row in post_squee_rows if row["package_key"] == "enlightened_engine_access_cut_thor"),
            None,
        )
        if enlightened_thor:
            delta = enlightened_thor.get("strategic_delta") or {}
            lines.append(
                "- Enlightened Tutor over Thor tests access without Gamble's random discard: "
                f"`{enlightened_thor['candidate_wins']}-{enlightened_thor['candidate_losses']}` vs "
                f"`{enlightened_thor['baseline_wins']}-{enlightened_thor['baseline_losses']}` (`{enlightened_thor['delta_pp']:+.2f}` pp), "
                f"seed 42 `{enlightened_thor['strong_seed_delta_pp']:+.2f}` pp, "
                f"tutor delta `{int(delta.get('tutor_resolved') or 0):+d}`, "
                f"topdeck delta `{int(delta.get('topdeck_manipulation_activated') or 0):+d}`."
                " This was only run as a seed-42 triage because it failed the strong-seed promotion filter."
            )
        boseiju_land = next((row for row in post_squee_rows if row["package_key"] == "boseiju_spell_protection_land"), None)
        if boseiju_land:
            lines.append(
                "- Boseiju, Who Shelters All over Reliquary Tower was the land-slot spell-protection test: "
                f"`{boseiju_land['candidate_wins']}-{boseiju_land['candidate_losses']}` vs "
                f"`{boseiju_land['baseline_wins']}-{boseiju_land['baseline_losses']}` (`{boseiju_land['delta_pp']:+.2f}` pp), "
                f"seed 42 `{boseiju_land['strong_seed_delta_pp']:+.2f}` pp. "
                "It preserves land count and has active rules, but the losses still show life-zero combat pressure rather than counterspell denial."
            )
        boros_charm = next((row for row in post_squee_rows if row["package_key"] == "boros_charm_pressure_cut_fated"), None)
        if boros_charm:
            lines.append(
                "- Boros Charm over Fated Clash tested the cheap pressure-absorber idea from the stronger variants: "
                f"`{boros_charm['candidate_wins']}-{boros_charm['candidate_losses']}` vs "
                f"`{boros_charm['baseline_wins']}-{boros_charm['baseline_losses']}` (`{boros_charm['delta_pp']:+.2f}` pp), "
                f"seed 42 `{boros_charm['strong_seed_delta_pp']:+.2f}` pp. "
                "The card may still be coherent in another slot, but cutting Fated Clash removed too much pressure response."
            )
    if loss_summary_rows:
        baseline_7 = next(
            (
                row
                for row in loss_summary_rows
                if row.get("seed") == 7 and row.get("package_key") == "baseline_squee_champion"
            ),
            None,
        )
        baseline_20260625 = next(
            (
                row
                for row in loss_summary_rows
                if row.get("seed") == 20260625 and row.get("package_key") == "baseline_squee_champion"
            ),
            None,
        )
        if baseline_7 and baseline_20260625:
            lines.append(
                "- Loss classifier is now the driver for the next swap: baseline seed 7 losses are mostly "
                f"`{json.dumps(baseline_7.get('primary_cause_counts', {}), sort_keys=True)}`, while seed 20260625 losses are "
                f"`{json.dumps(baseline_20260625.get('primary_cause_counts', {}), sort_keys=True)}`. "
                "Every classified baseline loss carries the combat-pressure death flag, so the next package must improve early survival without breaking the seed-42 engine pattern."
            )
    if library_leng_rows:
        seed42 = next((row for row in library_leng_rows if row.get("seed") == 42), None)
        seed7 = next((row for row in library_leng_rows if row.get("seed") == 7), None)
        seed20260625 = next((row for row in library_leng_rows if row.get("seed") == 20260625), None)
        if seed42:
            lines.append(
                f"- Library of Leng / discard-to-top telemetry is now visible in gates: seed 42 went "
                f"`{seed42['wins']}-{seed42['losses']}` with `{seed42['discard_to_top_replacement']}` discard-to-top replacements, "
                f"`{seed42['topdeck_manipulation_activated']}` topdeck activations, and `{seed42['miracle_cast']}` miracle casts."
            )
        if seed7 and seed20260625:
            lines.append(
                f"- Failure seeds split into two problems: seed 7 had `{seed7['discard_to_top_replacement']}` discard-to-top replacements, "
                f"while seed 20260625 had `{seed20260625['discard_to_top_replacement']}` replacements but still went "
                f"`{seed20260625['wins']}-{seed20260625['losses']}`; the issue is not only finding Library of Leng, but converting the topdecked card into survival or a second Approach window."
            )
    lines.append("")
    lines.append("## Squee Vs 607 Battle Evidence")
    lines.append("")
    lines.append("| Hash | Isolated | Timeout | Seed | Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return | Explained | Unknown | Rummage | Spell Rummage | Rummage Squee |")
    lines.append("| --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
    for row in report["squee_gates"]["rows"]:
        ev = row["strategic_events"]
        lines.append(
            "| {hash_seed} | {isolated} | {timeout} | {seed} | {deck_key} | {games} | {wins} | {losses} | {stalls} | {wr:.2f}% | {miracle} | {topdeck} | {spell} | {cost} | {squee_gy} | {squee_return} | {explained} | {unknown} | {rummage} | {spell_rummage} | {rummage_squee} |".format(
                hash_seed=row.get("python_hash_seed", "unset"),
                isolated=str(row.get("deck_process_isolation")).lower(),
                timeout=row.get("game_timeout_seconds"),
                seed=row["seed"],
                deck_key=row["deck_key"],
                games=row["games"],
                wins=row["wins"],
                losses=row["losses"],
                stalls=row["stalls"],
                wr=float(row.get("win_rate") or 0),
                miracle=ev.get("miracle_cast", 0),
                topdeck=ev.get("topdeck_manipulation_activated", 0),
                spell=ev.get("lorehold_spell_cast", 0),
                cost=ev.get("lorehold_cost_paid", 0),
                squee_gy=ev.get("squee_to_graveyard", 0),
                squee_return=ev.get("squee_upkeep_return", 0),
                explained=ev.get("squee_return_after_known_graveyard_entry", 0),
                unknown=ev.get("squee_return_without_known_graveyard_entry", 0),
                rummage=ev.get("lorehold_upkeep_rummage", 0),
                spell_rummage=ev.get("lorehold_spell_rummage", 0),
                rummage_squee=ev.get("lorehold_rummage_discards_squee", 0),
            )
        )
    lines.append("")
    lines.append("Aggregate across the checked seeds/gates:")
    lines.append("")
    lines.append("| Deck | Games | W | L | S | WR | Miracle | Topdeck | Spell Cast | Cost Paid | Squee GY | Squee Return | Explained | Unknown | Rummage | Spell Rummage | Rummage Squee |")
    lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
    for key, value in report["squee_gates"]["summary"].items():
        ev = value.get("strategic_events") or {}
        lines.append(
            f"| `{key}` | {value['games']} | {value['wins']} | {value['losses']} | {value['stalls']} | {value['win_rate']:.2f}% | {ev.get('miracle_cast', 0)} | {ev.get('topdeck_manipulation_activated', 0)} | {ev.get('lorehold_spell_cast', 0)} | {ev.get('lorehold_cost_paid', 0)} | {ev.get('squee_to_graveyard', 0)} | {ev.get('squee_upkeep_return', 0)} | {ev.get('squee_return_after_known_graveyard_entry', 0)} | {ev.get('squee_return_without_known_graveyard_entry', 0)} | {ev.get('lorehold_upkeep_rummage', 0)} | {ev.get('lorehold_spell_rummage', 0)} | {ev.get('lorehold_rummage_discards_squee', 0)} |"
        )
    lines.append("")
    lines.append("Interpretation: under fixed hash-seed, process-isolated, timeout-bounded conditions, the Squee candidate remains the best current candidate across the 10-seed suite, but only by a narrow margin. This is enough to keep studying the package, not enough to promote it as the final list. The trace evidence still proves every observed `squee_upkeep_return` occurred after an observed Squee graveyard entry, mostly battlefield-to-graveyard movement plus one mill event. It did not prove `lorehold_rummage_discards_squee` or `lorehold_spell_rummage_discards_squee`, so the exact discard-fuel loop remains a targeted next hypothesis rather than a closed fact.")
    lines.append("")
    diagnostic = report.get("squee_seed_diagnostic") or {}
    if diagnostic:
        lines.append("## Squee Seed Diagnostic")
        lines.append("")
        lines.append(f"- Source: `{report.get('squee_seed_diagnostic_path')}`")
        for finding in diagnostic.get("findings") or []:
            lines.append(f"- {finding}")
        lines.append("")
        lines.append("| Seed | Result | Games | Avg Turns | Miracle | Topdeck | Spell Cast | Squee GY | Squee Return | Games With Topdeck | Games With Squee GY |")
        lines.append("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for gate in diagnostic.get("diagnostic_gates") or []:
            for row in gate.get("candidate_by_result") or []:
                ev = row.get("strategic_events") or {}
                games_with = row.get("games_with") or {}
                lines.append(
                    f"| {gate.get('seed')} | {row.get('result')} | {row.get('games')} | {float(row.get('avg_turns') or 0):.2f} | "
                    f"{ev.get('miracle_cast', 0)} | {ev.get('topdeck_manipulation_activated', 0)} | {ev.get('lorehold_spell_cast', 0)} | "
                    f"{ev.get('squee_to_graveyard', 0)} | {ev.get('squee_upkeep_return', 0)} | "
                    f"{games_with.get('topdeck_manipulation_activated', 0)} | {games_with.get('squee_to_graveyard', 0)} |"
                )
        lines.append("")
    if library_leng_rows:
        lines.append("## Library of Leng / Discard-To-Top Telemetry")
        lines.append("")
        lines.append(
            "These gates rerun the Squee champion with the battle gate instrumented for discard-to-top replacement. "
            "The goal is to separate three questions: whether Library of Leng appears, whether it places a meaningful card on top, and whether the deck converts that into miracle/survival before combat pressure kills it."
        )
        lines.append("")
        lines.append("| Seed | W | L | S | WR | Miracle | Topdeck | Discard-To-Top | Rummage-To-Top | Spell-Rummage-To-Top | Rummage | Spell Rummage | Squee GY | Squee Return | Discard-To-Top Games | Topdeck Games | Miracle Games |")
        lines.append("| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for row in sorted(library_leng_rows, key=lambda item: int(item.get("seed") or 0)):
            lines.append(
                f"| {row.get('seed')} | {row['wins']} | {row['losses']} | {row['stalls']} | {row['win_rate']:.2f}% | "
                f"{row['miracle_cast']} | {row['topdeck_manipulation_activated']} | {row['discard_to_top_replacement']} | "
                f"{row['lorehold_rummage_discard_to_top']} | {row['lorehold_spell_rummage_discard_to_top']} | "
                f"{row['lorehold_upkeep_rummage']} | {row['lorehold_spell_rummage']} | {row['squee_to_graveyard']} | "
                f"{row['squee_upkeep_return']} | {row['discard_to_top_games']} | {row['topdeck_games']} | {row['miracle_games']} |"
            )
        lines.append("")
        summary = library_leng.get("summary") or {}
        top_cards = library_leng.get("top_discard_to_top_cards") or []
        lines.append(
            f"Aggregate read: `{summary.get('wins', 0)}-{summary.get('losses', 0)}-{summary.get('stalls', 0)}` over "
            f"`{summary.get('games', 0)}` games, with `{summary.get('discard_to_top_replacement', 0)}` discard-to-top replacements, "
            f"`{summary.get('topdeck_manipulation_activated', 0)}` topdeck activations, and `{summary.get('miracle_cast', 0)}` miracle casts."
        )
        if top_cards:
            cards = ", ".join(f"`{item['key']}`={item['count']}" for item in top_cards[:8])
            lines.append(f"Top discard-to-top signals: {cards}.")
        lines.append(
            "Interpretation: Library of Leng is not a missing runtime feature anymore; it is a measurable engine. "
            "Seed 42 shows the intended conversion pattern, seed 7 lacks the engine almost entirely, and seed 20260625 proves that repeated Approach-to-top loops can still fail under fast life-total pressure. "
            "The next deck work should pair topdeck consistency with either faster protection/pressure absorption or a cleaner second-Approach/finisher conversion, rather than treating discard-to-top alone as the solution."
        )
        lines.append("")
    if loss_summary_rows:
        lines.append("## Loss Failure Classifier")
        lines.append("")
        lines.append(f"- Source: `{report.get('loss_failure_classifier_path')}`")
        lines.append(
            "- Read: this classifier uses per-game observed events over stale reason text; for example, an `approach_cast_tracked` event outranks a legacy `found=False` reason string."
        )
        lines.append("")
        lines.append("| Seed | Package | Deck | Losses | Avg Loss Turn | Primary Causes | Pressure | Approach | Discard-Top | Topdeck | Miracle | Low Spell |")
        lines.append("| ---: | --- | --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |")
        for row in loss_summary_rows:
            flags = row.get("flag_counts") or {}
            causes = ", ".join(
                f"{key}={value}"
                for key, value in sorted((row.get("primary_cause_counts") or {}).items())
            )
            lines.append(
                "| {seed} | `{package}` | `{deck}` | {losses} | {avg:.2f} | {causes} | {pressure} | {approach} | {discard_top} | {topdeck} | {miracle} | {low_spell} |".format(
                    seed=row.get("seed"),
                    package=row.get("package_key"),
                    deck=row.get("deck_key"),
                    losses=row.get("losses"),
                    avg=float(row.get("avg_loss_turn") or 0),
                    causes=causes,
                    pressure=flags.get("combat_pressure_death", 0),
                    approach=flags.get("approach_seen", 0),
                    discard_top=flags.get("discard_to_top_seen", 0),
                    topdeck=flags.get("topdeck_seen", 0),
                    miracle=flags.get("miracle_seen", 0),
                    low_spell=flags.get("low_spell_volume", 0),
                )
            )
        lines.append("")
        lines.append(
            "Interpretation: the problem is not a single missing prison/tax card. The failure mode alternates between no early engine, low early spell volume, and engine without Approach conversion, but all checked losses still die through combat-pressure/life-zero. `Angel's Grace` proves a one-mana life-floor can help the weak 20260625 seed, yet it destroys the seed-42 success pattern when it replaces Dawn's Truce; the next test needs to preserve the existing protection shell and change a less structurally important slot."
        )
        lines.append("")
    if materialization:
        lines.append("## Squee Rule Materialization Audit")
        lines.append("")
        lines.append(f"- Source: `{report.get('squee_rule_materialization_audit_path')}`")
        lines.append(f"- Decision: `{materialization.get('decision')}`")
        lines.append(f"- {materialization.get('finding')}")
        lines.append("")
        lines.append("| Seed | Deck | W | L | S | WR | Miracle | Topdeck | Squee GY | Squee Return | Rule Count | Rule Keys | Tags |")
        lines.append("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |")
        for row in materialization.get("rows") or []:
            materialized = row.get("materialized_squee") or {}
            lines.append(
                "| {seed} | `{deck}` | {wins} | {losses} | {stalls} | {wr:.2f}% | {miracle} | {topdeck} | {squee_gy} | {squee_return} | {rule_count} | {rule_keys} | {tags} |".format(
                    seed=row.get("seed"),
                    deck=row.get("deck_key"),
                    wins=row.get("wins"),
                    losses=row.get("losses"),
                    stalls=row.get("stalls"),
                    wr=float(row.get("win_rate") or 0),
                    miracle=row.get("miracle_cast"),
                    topdeck=row.get("topdeck_manipulation_activated"),
                    squee_gy=row.get("squee_to_graveyard"),
                    squee_return=row.get("squee_upkeep_return"),
                    rule_count=materialized.get("battle_rule_count") or 0,
                    rule_keys=", ".join(materialized.get("battle_rule_keys") or []),
                    tags=", ".join(materialized.get("functional_tags") or []),
                )
            )
        lines.append("")
    if unresolved_audit:
        lines.append("## Remaining Rule Row Audit")
        lines.append("")
        lines.append(f"- Source: `{report.get('unresolved_rule_rows_audit_path')}`")
        lines.append(
            "- Read: cards marked `deck_rule_materialization_gap` already have active reviewed `battle_card_rules`; "
            "future equal gates now materialize those rows deck-wide. Cards marked `missing_battle_rule_model` need a new rule/runtime family before battle evidence is trusted."
        )
        lines.append("")
        lines.append("| Card | Deck Rule Count | Active Rule Count | Decision | Action | Rule Keys |")
        lines.append("| --- | ---: | ---: | --- | --- | --- |")
        for row in unresolved_audit.get("rows") or []:
            lines.append(
                "| {card} | {deck_rules} | {active_rules} | `{decision}` | `{action}` | {keys} |".format(
                    card=row.get("card"),
                    deck_rules=row.get("deck_rule_count"),
                    active_rules=row.get("battle_rule_count"),
                    decision=row.get("decision"),
                    action=row.get("action"),
                    keys=", ".join(row.get("battle_rule_keys") or []) or "none",
                )
            )
        lines.append("")
    if thor_audit:
        verification = thor_audit.get("temp_sqlite_sync_verification") or {}
        runtime = thor_audit.get("runtime_test_verification") or {}
        reviewed_rule = thor_audit.get("reviewed_rule") or {}
        lines.append("## Thor Rule Runtime Audit")
        lines.append("")
        lines.append(f"- Source: `{report.get('thor_rule_runtime_audit_path')}`")
        lines.append(f"- Decision: `{thor_audit.get('decision')}`")
        lines.append(f"- Runtime test: `{runtime.get('result')}`")
        lines.append(
            f"- Temp SQLite sync/materialization: Thor rule count `{verification.get('thor_sqlite_rule_count_after_temp_sync', 0)}`; "
            f"deck materialized Thor rule count `{verification.get('thor_deck_rule_count_after_temp_materialization', 0)}`; "
            f"rule key `{reviewed_rule.get('logical_rule_key')}`."
        )
        lines.append(
            "- Executed branch: noncreature spell casts deal damage equal to the triggering spell mana value to any target. "
            "ETB graveyard recast is recorded as annotation until a safe temporary-play executor is promoted."
        )
        lines.append("")
    thor_gate_audit = report.get("thor_rule_gate_audit") or {}
    if thor_gate_audit:
        interpretation = thor_gate_audit.get("interpretation") or {}
        lines.append("## Thor Synced Rule Battle Gate")
        lines.append("")
        lines.append(f"- Source: `{report.get('thor_rule_gate_audit_path')}`")
        lines.append(f"- Decision: `{thor_gate_audit.get('decision')}`")
        lines.append(
            f"- Natural exposure: `{interpretation.get('candidate_thor_damage_exposure_games', 0)}`/"
            f"`{interpretation.get('candidate_total_games', 0)}` candidate games; "
            f"damage triggers `{interpretation.get('candidate_thor_damage_triggers', 0)}`; "
            f"damage amount `{interpretation.get('candidate_thor_damage_amount', 0)}`; "
            f"win-rate delta `{float(interpretation.get('winrate_delta_pp') or 0):+.2f}` pp."
        )
        lines.append("")
        lines.append("| Deck | Games | W | L | S | WR | Thor Cost | Thor Cast | Thor Damage Triggers | Thor Damage | Miracle | Topdeck | Spell Cast |")
        lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
        for key, value in sorted((thor_gate_audit.get("summary") or {}).items()):
            events = value.get("strategic_events") or {}
            lines.append(
                f"| `{key}` | {value.get('games', 0)} | {value.get('wins', 0)} | {value.get('losses', 0)} | "
                f"{value.get('stalls', 0)} | {float(value.get('win_rate') or 0):.2f}% | "
                f"{events.get('thor_cost_paid', 0)} | {events.get('thor_spell_cast', 0)} | "
                f"{events.get('thor_noncreature_damage', 0)} | {events.get('thor_noncreature_damage_amount', 0)} | "
                f"{events.get('miracle_cast', 0)} | {events.get('topdeck_manipulation_activated', 0)} | "
                f"{events.get('lorehold_spell_cast', 0)} |"
            )
        lines.append("")
        exposure_rows = thor_gate_audit.get("per_game_exposure") or []
        if exposure_rows:
            lines.append("| Seed | Deck | Opponent | Result | Turns | Thor Cost | Thor Cast | Thor Damage | Damage Amount |")
            lines.append("| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: |")
            for row in exposure_rows:
                lines.append(
                    f"| {row.get('seed')} | `{row.get('deck_key')}` | {row.get('opponent')} | {row.get('result')} | "
                    f"{row.get('turns')} | {row.get('thor_cost_paid', 0)} | {row.get('thor_spell_cast', 0)} | "
                    f"{row.get('thor_noncreature_damage', 0)} | {row.get('thor_noncreature_damage_amount', 0)} |"
                )
            lines.append("")
        lines.append(str(interpretation.get("read") or "No interpretation available."))
        lines.append("")
        lines.append(str(interpretation.get("next_action") or "No next action available."))
        lines.append("")
    runtime_readiness = report.get("runtime_package_readiness") or {}
    runtime_cards = runtime_readiness.get("cards") or []
    if runtime_cards:
        lines.append("## Runtime Package Readiness")
        lines.append("")
        lines.append(
            "These rows are not deck promotions. They are modeled hypotheses whose effect family is now executable/package-ready, "
            "but durable PostgreSQL precheck/apply/sync or an isolated materialized gate is still required before judging deck value."
        )
        lines.append("")
        summary = runtime_readiness.get("summary") or {}
        lines.append(f"- Summary: `{json.dumps(summary, sort_keys=True)}`")
        lines.append("")
        lines.append("| Card | Family | Role | Scope | Readiness | Package | Blocker |")
        lines.append("| --- | --- | --- | --- | --- | --- | --- |")
        for row in runtime_cards:
            manifests = row.get("package_manifests") or []
            blockers = row.get("blockers") or []
            package = ", ".join(
                f"{item.get('deploy_id')}/{item.get('slug')}"
                for item in manifests
                if item.get("deploy_id") or item.get("slug")
            ) or "pending"
            blocker = "; ".join(
                f"{item.get('blocked_step')}: {item.get('sanitized_error')}"
                for item in blockers
                if item.get("blocked_step") or item.get("sanitized_error")
            ) or "none"
            role = row.get("deck_role_json") or {}
            lines.append(
                "| {card} | `{family}` | `{role}` | `{scope}` | `{readiness}` | {package} | {blocker} |".format(
                    card=row.get("card_name"),
                    family=row.get("family_id"),
                    role=role.get("category") or role.get("effect") or "unknown",
                    scope=row.get("battle_model_scope"),
                    readiness=row.get("readiness"),
                    package=package,
                    blocker=blocker,
                )
            )
        lines.append("")
        lines.append(
            "Read: `runtime_ready_pg_precheck_blocked` means the card should stay in the hypothesis pool, not be discarded as unmodeled. "
            "The next valid evidence is either successful PG precheck/apply/postcheck plus Hermes sync, or a clearly isolated candidate DB where the same rule rows are materialized for battle gates."
        )
        lines.append("")
    lines.append("## Variant Learning")
    lines.append("")
    lines.append("| Rank | Deck | Score | Intent | Lands | Rule Ready | Main Risks |")
    lines.append("| ---: | --- | ---: | ---: | ---: | ---: | --- |")
    for item in report["matrix_ranked"]:
        risks = ", ".join(item.get("primary_risks") or []) or "none"
        lines.append(
            f"| {item['rank']} | `{item['deck_key']}` {item['deck_name']} | {item.get('strategy_score', 0):.1f} | {item.get('commander_intent_score', 0):.1f} | {item.get('land_count', '')} | {100 * float(item.get('battle_rule_ready_ratio') or 0):.1f}% | {risks} |"
        )
    lines.append("")
    lines.append("Main read: 607 is the best structural shell because it is closest to the commander intent. 615 and 614 are the next serious hypotheses, but they are not automatically better because they change many slots at once. 612 has high copy density but too few lands. 616 is off-axis for this commander and has rule-readiness risk.")
    lines.append("")
    lines.append("## Broad Synergy Packages Checked")
    lines.append("")
    lines.append("| Package | Adds | Cuts | Baseline | Candidate | Delta pp | Decision |")
    lines.append("| --- | --- | --- | ---: | ---: | ---: | --- |")
    for row in report["general_synergy_confirm"]:
        lines.append(
            "| `{package}` | {adds} | {cuts} | {base} | {cand} | {delta} | {decision} |".format(
                package=row["package_key"],
                adds=", ".join(row["adds"]),
                cuts=", ".join(row["cuts"]),
                base=row["baseline_record"],
                cand=row["candidate_record"],
                delta=row["delta_pp"],
                decision=row["decision"],
            )
        )
    lines.append("")
    if post_squee_rows:
        lines.append("## Post-Squee Package And Finalizer Gates")
        lines.append("")
        lines.append("These gates use the Squee champion as source deck id `6`, fixed `PYTHONHASHSEED=0`, process isolation, and per-game timeout. The promotion bar is stricter than a single positive seed: the package must improve aggregate results without breaking the known strong seed.")
        lines.append("")
        lines.append("| Package | Adds | Cuts | Aggregate Baseline | Aggregate Candidate | Delta pp | Seed 42 pp | Miracle | Topdeck | Discard-Top | Rummage-Top | Spell-Rummage-Top | Hand-Top | Spell | Mana | Birgi Mana | Ritual | Squee GY | Squee Return | Decision |")
        lines.append("| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
        for row in post_squee_rows:
            delta = row.get("strategic_delta") or {}
            lines.append(
                "| `{package}` | {adds} | {cuts} | {base_w}-{base_l} | {cand_w}-{cand_l} | {delta_pp:+.2f} | {strong:+.2f} | {miracle:+d} | {topdeck:+d} | {discard_top:+d} | {rummage_top:+d} | {spell_rummage_top:+d} | {hand_top:+d} | {spell:+d} | {mana:+d} | {birgi_mana:+d} | {ritual:+d} | {squee_gy:+d} | {squee_return:+d} | {decision} |".format(
                    package=row["package_key"],
                    adds=", ".join(row["adds"]),
                    cuts=", ".join(row["cuts"]),
                    base_w=row["baseline_wins"],
                    base_l=row["baseline_losses"],
                    cand_w=row["candidate_wins"],
                    cand_l=row["candidate_losses"],
                    delta_pp=float(row["delta_pp"]),
                    strong=float(row["strong_seed_delta_pp"]),
                    miracle=int(delta.get("miracle_cast") or 0),
                    topdeck=int(delta.get("topdeck_manipulation_activated") or 0),
                    discard_top=int(delta.get("discard_to_top_replacement") or 0),
                    rummage_top=int(delta.get("lorehold_rummage_discard_to_top") or 0),
                    spell_rummage_top=int(delta.get("lorehold_spell_rummage_discard_to_top") or 0),
                    hand_top=int(delta.get("hand_to_topdeck_activation") or 0),
                    spell=int(delta.get("lorehold_spell_cast") or 0),
                    mana=int(delta.get("spell_cast_mana_trigger") or 0),
                    birgi_mana=int(delta.get("birgi_spell_cast_mana") or 0),
                    ritual=int(delta.get("ritual_mana_added") or 0),
                    squee_gy=int(delta.get("squee_to_graveyard") or 0),
                    squee_return=int(delta.get("squee_upkeep_return") or 0),
                    decision=row["decision"],
                )
            )
        lines.append("")
        lines.append("Read: Brainstone can improve weak seeds when it preserves the ramp shell, but the Hexing Squelcher cut is only aggregate-neutral and collapses seed 42, so it is not a deck insert. Ghostly Prison was a coherent pressure hypothesis, but the retest avoiding the old High Noon cut still lost aggregate. The One Ring does not justify the slot here despite the Mind Stone interaction idea; it reduced the aggregate result and the Library discard-to-top metrics. Angel's Grace confirms that a one-mana life-floor can help seed 20260625, but replacing Dawn's Truce destroys seed 42 and loses aggregate, so this exact protection swap is rejected. Faithless Looting does not prove the intended Squee-discard loop here and loses badly overall. The original Galvanoth/Bender's Waterskin swap is the only positive aggregate signal, but it loses the strong seed 42; the follow-ups cutting Hexing Squelcher, Victory Chimes, or Thor are worse on seed 42, so Galvanoth stays a probation hypothesis, not a deck insert. Primal Amulet over Bender's Waterskin repeats the same weak-seed improvement and strong-seed collapse pattern, so Bender is not a free cut. Gamble over Creative Technique shows that cheap universal access can help weak seeds, but the current result still breaks seed 42, so it is probation/rework rather than a deck change. The Thor-cut access retests were worse on seed 42, so Thor is not the clean cut for tutor access despite being modeled-not-deck-proven. Boseiju over Reliquary Tower preserves land count and spell-protection rules but still collapses seed 42, so land-slot anti-counter protection is not the current missing piece. Boros Charm over Fated Clash collapsed seed 42 completely, so Fated Clash is not a free slow-response cut even for a cheaper pressure card. Dance with Calamity and Aetherflux Reservoir both improve some weak seeds over Storm Herd, but both lose aggregate and break seed 42, so Storm Herd remains protected for now. Birgi proves the new spell-cast mana telemetry can fire, but it does not improve results alone. Birgi + Seething Song over both medallions improves the weak seeds while losing badly on seed 42, so medallions are part of the strong-seed conversion pattern and the ritual lane needs a different cut before any promotion. Penance did not fire its hand-to-library activation in this gate, so it is not evidence for a working topdeck-protection engine yet.")
        lines.append("")
    if safe_rows:
        lines.append("## Cut-Safety-Aware Safe Queue V3")
        lines.append("")
        lines.append(
            "This queue was generated after the cut-safety manifest blocked the earlier package list. "
            "Every row below cleared cut-safety and prior-exact-package preflight, then ran as an isolated smoke gate against real opponents. "
            "Because the baseline was 3-0 in this smoke, any negative result is treated as no-promotion evidence, not as permission to mutate the deck."
        )
        lines.append("")
        lines.append("| Package | Adds | Cuts | Baseline | Candidate | Delta pp | Miracle | Topdeck | Spell | Mana Trigger | Birgi Mana | Ritual | Decision |")
        lines.append("| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
        for row in safe_rows:
            delta = row.get("strategic_delta") or {}
            lines.append(
                "| `{package}` | {adds} | {cuts} | {base_w}-{base_l}-{base_s} | {cand_w}-{cand_l}-{cand_s} | {delta_pp:+.2f} | {miracle:+d} | {topdeck:+d} | {spell:+d} | {mana:+d} | {birgi_mana:+d} | {ritual:+d} | {decision} |".format(
                    package=row.get("package_key"),
                    adds=", ".join(row.get("adds") or []),
                    cuts=", ".join(row.get("cuts") or []),
                    base_w=row.get("baseline_wins", 0),
                    base_l=row.get("baseline_losses", 0),
                    base_s=row.get("baseline_stalls", 0),
                    cand_w=row.get("candidate_wins", 0),
                    cand_l=row.get("candidate_losses", 0),
                    cand_s=row.get("candidate_stalls", 0),
                    delta_pp=float(row.get("delta_pp") or 0.0),
                    miracle=int(delta.get("miracle_cast") or 0),
                    topdeck=int(delta.get("topdeck_manipulation_activated") or 0),
                    spell=int(delta.get("lorehold_spell_cast") or 0),
                    mana=int(delta.get("spell_cast_mana_trigger") or 0),
                    birgi_mana=int(delta.get("birgi_spell_cast_mana") or 0),
                    ritual=int(delta.get("ritual_mana_added") or 0),
                    decision=row.get("decision"),
                )
            )
        lines.append("")
        lines.append(
            "Read: this is the strongest current evidence against replacing generic ramp/support slots blindly. "
            "Birgi, Seething Song, Storm-Kiln Artist, and Runaway Steam-Kin all reduced the miracle/topdeck conversion pattern in the smoke. "
            "Boros Charm and Ghostly Prison still did not solve pressure when moved to safer non-protected cuts. "
            "Overmaster is the only watch-list row because it retained two wins, but it still trailed the current shell and needs a different, explicit follow-up before any deeper gate."
        )
        lines.append("")
    lines.append("## Current Champion Card-Role Coverage")
    lines.append("")
    champion = report["deck_summaries"].get("6") or {}
    lines.append(f"- Quantity: `{champion.get('quantity_total')}` across `{champion.get('row_count')}` rows.")
    lines.append(f"- Primary role counts: `{json.dumps(champion.get('role_counts', {}), sort_keys=True)}`")
    decision_manifest = report.get("card_decision_manifest") or {}
    decision_summary = (decision_manifest.get("summary") or {}).get("decision_counts") or {}
    lane_summary = (decision_manifest.get("summary") or {}).get("package_lane_counts") or {}
    if decision_summary:
        lines.append(f"- Slot decision counts: `{json.dumps(decision_summary, sort_keys=True)}`")
    if lane_summary:
        lines.append(f"- Package lane counts: `{json.dumps(lane_summary, sort_keys=True)}`")
    missing_cards = list(champion.get("missing_battle_rule_cards", []))
    materialized_cards = {
        row.get("materialized_squee", {}).get("card_name")
        for row in materialization.get("rows", [])
        if row.get("materialized_squee", {}).get("battle_rule_count")
    }
    materialized_cards.discard(None)
    audit_materialization_cards = {
        row.get("card")
        for row in unresolved_audit.get("rows", [])
        if row.get("decision") == "deck_rule_materialization_gap"
    }
    audit_materialization_cards.discard(None)
    thor_local_runtime_cards = set()
    if (report.get("thor_rule_runtime_audit") or {}).get("decision"):
        thor_local_runtime_cards.add((report.get("thor_rule_runtime_audit") or {}).get("card"))
    thor_local_runtime_cards.discard(None)
    missing_after_squee_materialization = [
        card
        for card in missing_cards
        if card not in materialized_cards
    ]
    missing_after_rule_materialization_audit = [
        card
        for card in missing_after_squee_materialization
        if card not in audit_materialization_cards
    ]
    effective_missing_cards = [
        card
        for card in missing_after_rule_materialization_audit
        if card not in thor_local_runtime_cards
    ]
    lines.append(
        f"- Missing aggregated battle-rule rows in the legacy champion DB: `{len(missing_cards)}` cards: {', '.join(missing_cards) or 'none'}."
    )
    if materialized_cards:
        lines.append(
            f"- Superseded by rule-materialization audit: `{', '.join(sorted(materialized_cards))}` now has materialized rule evidence in the equal-gate candidate."
        )
        lines.append(
            f"- Effective unresolved rule rows after only that audit: `{len(missing_after_squee_materialization)}` cards: {', '.join(missing_after_squee_materialization) or 'none'}."
        )
    if audit_materialization_cards:
        lines.append(
            f"- Reclassified by remaining-row audit as deck materialization gaps: `{', '.join(sorted(audit_materialization_cards))}`."
        )
        lines.append(
            f"- Effective unresolved rule/model rows after deck materialization evidence: `{len(missing_after_rule_materialization_audit)}` cards: {', '.join(missing_after_rule_materialization_audit) or 'none'}."
        )
    if thor_local_runtime_cards:
        lines.append(
            f"- Reclassified by Thor runtime audit as local reviewed rule added pending durable sync: `{', '.join(sorted(thor_local_runtime_cards))}`."
        )
        lines.append(
            f"- Effective unresolved local runtime/model rows after Thor audit: `{len(effective_missing_cards)}` cards: {', '.join(effective_missing_cards) or 'none'}."
        )
    lines.append("- Full per-card role, tags, rule keys, package lane, and slot decision are in the companion JSON under `deck_summaries.6.cards` and `card_decision_manifest.cards`.")
    lines.append("")
    cut_safety = report.get("cut_safety_manifest") or {}
    cut_summary = cut_safety.get("summary") or {}
    cut_rows = cut_safety.get("cuts") or []
    if cut_rows:
        lines.append("## Cut Safety Manifest")
        lines.append("")
        lines.append(
            "- Summary: "
            f"`{json.dumps(cut_summary.get('status_counts', {}), sort_keys=True)}`; "
            f"tested cuts `{cut_summary.get('tested_cut_count', 0)}`, "
            f"blocked/protected cuts `{cut_summary.get('blocked_cut_count', 0)}`, "
            f"untested flex pool `{cut_summary.get('untested_flex_pool_count', 0)}`."
        )
        lines.append("")
        lines.append("| Card | Status | Lane | Role | Worst Seed 42 pp | Best Delta pp | Worst Delta pp | Obs | Read |")
        lines.append("| --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |")
        for row in cut_rows:
            lines.append(
                "| {card} | `{status}` | {lane} | {role} | {seed:+.2f} | {best:+.2f} | {worst:+.2f} | {obs} | {reason} |".format(
                    card=row.get("card_name"),
                    status=row.get("status"),
                    lane=row.get("current_lane"),
                    role=row.get("effective_role"),
                    seed=float(row.get("worst_strong_seed_delta_pp") or 0),
                    best=float(row.get("best_delta_pp") or 0),
                    worst=float(row.get("worst_delta_pp") or 0),
                    obs=row.get("observation_count"),
                    reason=row.get("reason"),
                )
            )
        lines.append("")
        flex_pool = cut_safety.get("untested_flex_pool") or []
        flex_names = ", ".join(f"`{row.get('card_name')}`" for row in flex_pool[:12])
        lines.append(
            f"- Untested flex pool sample: {flex_names or 'none'}"
            + (f" plus `{len(flex_pool) - 12}` more." if len(flex_pool) > 12 else ".")
        )
        lines.append("")
    dependency_map = report.get("strategy_dependency_map") or {}
    if dependency_map:
        lines.append("## Strategy Dependency Map")
        lines.append("")
        benchmark = dependency_map.get("current_benchmark") or {}
        champion_record = benchmark.get("champion") or {}
        deck607_record = benchmark.get("deck_607") or {}
        deck6_record = benchmark.get("deck_6") or {}
        lines.append(
            "- Current benchmark contract: "
            f"`{champion_record.get('deck_key')}` `{champion_record.get('record')}` "
            f"({float(champion_record.get('win_rate') or 0):.2f}%) vs "
            f"`deck_607` `{deck607_record.get('record')}` "
            f"({float(deck607_record.get('win_rate') or 0):.2f}%) and "
            f"`deck_6` `{deck6_record.get('record')}` "
            f"({float(deck6_record.get('win_rate') or 0):.2f}%)."
        )
        lines.append(
            "- Read: a new idea must improve a named pillar and preserve the benchmark pattern. "
            "A card being popular externally or cut-safe locally only creates a hypothesis."
        )
        lines.append("")
        lines.append("| Pillar | Depends On | Current Evidence | Risk | Next Requirement |")
        lines.append("| --- | --- | --- | --- | --- |")
        for pillar in dependency_map.get("dependency_pillars") or []:
            lines.append(
                "| `{pillar}` | {depends} | {evidence} | {risk} | {requirement} |".format(
                    pillar=pillar.get("pillar"),
                    depends=", ".join(pillar.get("depends_on") or []),
                    evidence=pillar.get("current_evidence"),
                    risk=pillar.get("risk"),
                    requirement=pillar.get("next_requirement"),
                )
            )
        lines.append("")
        guardrails = dependency_map.get("cut_guardrails") or {}
        locked = guardrails.get("locked_or_protected") or []
        risky = guardrails.get("risky_same_lane_only") or []
        locked_names = ", ".join(f"`{row.get('card_name')}`" for row in locked[:14])
        risky_names = ", ".join(f"`{row.get('card_name')}`" for row in risky[:14])
        lines.append(
            f"- Locked/protected cuts: {locked_names or 'none'}"
            + (f" plus `{len(locked) - 14}` more." if len(locked) > 14 else ".")
        )
        lines.append(
            f"- Risky same-lane-only cuts: {risky_names or 'none'}"
            + (f" plus `{len(risky) - 14}` more." if len(risky) > 14 else ".")
        )
        package_learning = dependency_map.get("package_learning") or {}
        post_summary = package_learning.get("post_squee") or {}
        lines.append(
            "- Package learning summary: "
            f"post-Squee decisions `{json.dumps(post_summary.get('decision_counts', {}), sort_keys=True)}`, "
            f"safe-queue watch `{len(package_learning.get('safe_queue_watch') or [])}`, "
            f"safe-queue rejected `{len(package_learning.get('safe_queue_rejected') or [])}`."
        )
        probation = list(post_summary.get("probation_or_watch") or []) + list(package_learning.get("safe_queue_watch") or [])
        if probation:
            lines.append("")
            lines.append("| Probation / Watch Item | Adds | Cuts | Delta pp | Seed 42 pp | Decision |")
            lines.append("| --- | --- | --- | ---: | ---: | --- |")
            for row in probation[:10]:
                lines.append(
                    "| `{package}` | {adds} | {cuts} | {delta:+.2f} | {seed:+.2f} | `{decision}` |".format(
                        package=row.get("package_key"),
                        adds=", ".join(row.get("adds") or []),
                        cuts=", ".join(row.get("cuts") or []),
                        delta=float(row.get("delta_pp") or 0.0),
                        seed=float(row.get("strong_seed_delta_pp") or 0.0),
                        decision=row.get("decision"),
                    )
                )
        lines.append("")
        lines.append("| Variant | Action | Reason |")
        lines.append("| --- | --- | --- |")
        for row in dependency_map.get("variant_import_contract") or []:
            if row.get("deck_key") not in {"deck_607", "deck_615", "deck_614", "deck_612", "deck_616"}:
                continue
            lines.append(
                f"| `{row.get('deck_key')}` {row.get('deck_name')} | `{row.get('action')}` | {row.get('reason')} |"
            )
        lines.append("")
        contract = dependency_map.get("next_hypothesis_contract") or {}
        lines.append("Next hypothesis contract:")
        for item in contract.get("promotion_bar") or []:
            lines.append(f"- Promotion bar: {item}")
        for item in contract.get("must_target") or []:
            lines.append(f"- Must target: {item}")
        for item in contract.get("required_telemetry") or []:
            lines.append(f"- Required telemetry: {item}")
        for item in contract.get("hard_reject_if") or []:
            lines.append(f"- Hard reject if: {item}")
        lines.append("")
    lines.append("## What Still Must Be Understood")
    lines.append("")
    for item in report["open_questions"]:
        lines.append(f"- {item}")
    lines.append("")
    lines.append("## Next Gates")
    lines.append("")
    for item in report["next_gates"]:
        lines.append(f"- {item}")
    lines.append("")
    lines.append("## External Method Sources")
    lines.append("")
    for source in EXTERNAL_METHOD_SOURCES:
        lines.append(f"- [{source['name']}]({source['url']}): {source['use']}.")
    lines.append("")
    return "\n".join(lines)


def effective_card_role(card: dict[str, Any]) -> str:
    name = card.get("card_name") or ""
    return CARD_ROLE_OVERRIDES.get(name, card.get("primary_role") or "unknown")


def card_synergy_reason(card: dict[str, Any]) -> str:
    name = card.get("card_name") or ""
    role = effective_card_role(card)
    tags = set(card.get("tags") or [])
    cmc = float(card.get("cmc") or 0)
    type_line = str(card.get("type_line") or "")
    if name in CARD_REASON_OVERRIDES:
        return CARD_REASON_OVERRIDES[name]
    if name == "Lorehold, the Historian":
        return "commander engine: miracle discount plus upkeep rummage defines the deck"
    if name == "Squee, Goblin Nabob":
        return "recursion engine: all observed returns in the trusted gate follow known graveyard entries; discard-rummage loop remains unproven"
    if role == "land":
        return "mana base and color consistency"
    if role in {"removal", "board_wipe"}:
        return "answers pressure so Lorehold reaches the miracle/combo window"
    if role in {"protection", "stax"} or "pressure_absorber" in tags:
        return "buys time or protects the decisive spell turn"
    if role in {"ramp", "mana_engine"} or "mana_engine" in tags:
        return "accelerates commander, setup, and big-spell turns"
    if role == "tutor":
        return "finds setup, protection, or closing pieces"
    if "topdeck_miracle_setup" in tags:
        return "sets up first-draw miracle and topdeck quality"
    if "hand_filter" in tags:
        return "filters hands and turns dead expensive cards into new looks"
    if "spell_copy" in tags:
        return "copies high-impact instant/sorcery spells or combo pieces"
    if role == "wincon" or (("instant_sorcery" in tags) and cmc >= 5):
        return "miracle payoff or closing spell"
    if "graveyard_recursion" in tags:
        return "recovers resources or reuses spell value"
    if "instant_sorcery" in tags:
        return "spell density for Lorehold miracle/cast plan"
    if "Creature" in type_line:
        return "creature utility; verify it advances the spell plan"
    return "manual review needed"


def card_status(
    card: dict[str, Any],
    rule_audit: dict[str, Any] | None = None,
    thor_audit: dict[str, Any] | None = None,
) -> str:
    name = card.get("card_name") or ""
    role = effective_card_role(card)
    keys = card.get("battle_rule_keys") or []
    audit_decision = (rule_audit or {}).get("decision")
    if name == "Lorehold, the Historian":
        return "core_commander"
    if name == (thor_audit or {}).get("card") and (thor_audit or {}).get("decision"):
        return "local_runtime_rule_added_pending_sync"
    if not keys and audit_decision == "deck_rule_materialization_gap":
        return "materialization_gap_ready_rule"
    if not keys and audit_decision == "missing_battle_rule_model":
        return "missing_battle_rule_model"
    if not keys and role != "land":
        return "unresolved_rule_or_aggregate_gap"
    if role in {"unknown"}:
        return "manual_role_review"
    if role in {"land", "ramp", "protection", "removal", "board_wipe", "tutor"}:
        return "core_support"
    if role in {"draw", "engine", "wincon", "topdeck_miracle_engine", "miracle_engine", "recursion_engine"}:
        return "core_or_flex_engine"
    return "flex_or_contextual"


def card_package_lane(card: dict[str, Any]) -> str:
    role = effective_card_role(card)
    tags = set(card.get("tags") or [])
    cmc = float(card.get("cmc") or 0)
    type_line = str(card.get("type_line") or "")
    if card.get("card_name") == "Lorehold, the Historian":
        return "commander_engine"
    if role == "land":
        return "mana_base"
    if role in {"topdeck_miracle_engine", "miracle_engine"}:
        return "topdeck_miracle_setup"
    if "topdeck_miracle_setup" in tags:
        return "topdeck_miracle_setup"
    if "hand_filter" in tags:
        return "hand_filter"
    if "graveyard_recursion" in tags:
        return "graveyard_recursion"
    if role in {"ramp", "mana_engine"} or "mana_engine" in tags:
        return "early_mana"
    if role in {"protection", "stax"} or "pressure_absorber" in tags:
        return "pressure_absorber_or_protection"
    if role in {"removal", "board_wipe"}:
        return "interaction"
    if role == "tutor":
        return "selection"
    if role == "wincon" or (("Instant" in type_line or "Sorcery" in type_line) and cmc >= 5):
        return "finisher_or_big_spell"
    if "instant_sorcery" in tags:
        return "spell_density"
    return "contextual"


def card_decision(
    card: dict[str, Any],
    rule_audit: dict[str, Any] | None = None,
    thor_audit: dict[str, Any] | None = None,
) -> tuple[str, str]:
    name = card.get("card_name") or ""
    if name in CARD_DECISION_OVERRIDES:
        return CARD_DECISION_OVERRIDES[name]
    status = card_status(card, rule_audit, thor_audit)
    role = effective_card_role(card)
    lane = card_package_lane(card)
    if status == "core_commander":
        return ("locked_core", "commander defines the whole miracle/topdeck plan")
    if status in {"missing_battle_rule_model", "unresolved_rule_or_aggregate_gap"}:
        return ("unresolved_before_cut", "rule evidence is incomplete; do not use battle result as card judgment")
    if status in {"local_runtime_rule_added_pending_sync", "materialization_gap_ready_rule"}:
        return ("modeled_pending_durable_sync", "local evidence exists but durable source sync still matters before final promotion")
    if role == "land":
        return ("mana_base_core", "land slots are tuned as a package and should not be one-off cuts")
    if lane in {"topdeck_miracle_setup", "hand_filter", "graveyard_recursion"}:
        return ("core_engine_or_probation", "engine lane supports the current best shell; cut only with direct package evidence")
    if role in {"removal", "board_wipe", "protection", "tutor"}:
        return ("core_support", "support lane keeps Lorehold alive through setup and closing turns")
    if role == "ramp":
        return ("support_flex", "ramp slot can be challenged only by same-speed mana or stronger engine evidence")
    if role == "wincon":
        return ("finisher_benchmark_lane", "evaluate as a closing package, not as an isolated card cut")
    if role in {"draw", "engine"}:
        return ("engine_flex", "keep if it increases miracle/topdeck conversion in gates")
    return ("manual_review", "role is contextual or weakly classified")


def build_card_decision_manifest(
    deck: dict[str, Any],
    unresolved_rule_rows_audit: dict[str, Any],
    thor_rule_runtime_audit: dict[str, Any],
    squee_rule_materialization_audit: dict[str, Any] | None = None,
) -> dict[str, Any]:
    rule_audit_by_card = {
        row.get("card"): row for row in (unresolved_rule_rows_audit or {}).get("rows", [])
    }
    materialized_cards = {
        row.get("materialized_squee", {}).get("card_name")
        for row in (squee_rule_materialization_audit or {}).get("rows", [])
        if row.get("materialized_squee", {}).get("battle_rule_count")
    }
    materialized_cards.discard(None)
    cards = []
    decision_counts: Counter[str] = Counter()
    lane_counts: Counter[str] = Counter()
    for card in deck.get("cards") or []:
        rule_audit = rule_audit_by_card.get(card.get("card_name"))
        decision, decision_reason = card_decision(card, rule_audit, thor_rule_runtime_audit)
        lane = card_package_lane(card)
        status = card_status(card, rule_audit, thor_rule_runtime_audit)
        if card.get("card_name") in materialized_cards and status == "unresolved_rule_or_aggregate_gap":
            status = "materialized_rule_in_equal_gate_candidate"
        decision_counts[decision] += 1
        lane_counts[lane] += 1
        cards.append(
            {
                "card_name": card.get("card_name"),
                "quantity": card.get("quantity"),
                "db_role": card.get("primary_role"),
                "effective_role": effective_card_role(card),
                "package_lane": lane,
                "decision": decision,
                "decision_reason": decision_reason,
                "status": status,
                "rule_materialized_in_equal_gate_candidate": card.get("card_name") in materialized_cards,
                "battle_rule_count": len(card.get("battle_rule_keys") or []),
                "tags": card.get("tags") or [],
            }
        )
    return {
        "summary": {
            "decision_counts": dict(sorted(decision_counts.items())),
            "package_lane_counts": dict(sorted(lane_counts.items())),
        },
        "cards": sorted(cards, key=lambda item: (item["decision"], item["package_lane"], item["card_name"] or "")),
    }


def build_cut_safety_manifest(
    post_squee_package_gates: dict[str, Any],
    card_decision_manifest: dict[str, Any],
) -> dict[str, Any]:
    """Summarize which champion slots are unsafe cuts from battle evidence."""
    card_lookup = {
        row.get("card_name"): row
        for row in (card_decision_manifest or {}).get("cards", [])
        if row.get("card_name")
    }
    by_cut: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in (post_squee_package_gates or {}).get("rows", []):
        for cut in row.get("cuts") or []:
            by_cut[cut].append(
                {
                    "package_key": row.get("package_key"),
                    "family": row.get("family"),
                    "adds": row.get("adds") or [],
                    "baseline": f"{row.get('baseline_wins')}-{row.get('baseline_losses')}",
                    "candidate": f"{row.get('candidate_wins')}-{row.get('candidate_losses')}",
                    "candidate_wins": int(row.get("candidate_wins") or 0),
                    "candidate_losses": int(row.get("candidate_losses") or 0),
                    "delta_pp": float(row.get("delta_pp") or 0.0),
                    "strong_seed_delta_pp": float(row.get("strong_seed_delta_pp") or 0.0),
                    "decision": row.get("decision"),
                }
            )

    cut_rows: list[dict[str, Any]] = []
    status_counts: Counter[str] = Counter()
    for cut, observations in sorted(by_cut.items()):
        card = card_lookup.get(cut) or {}
        worst_strong = min(obs["strong_seed_delta_pp"] for obs in observations)
        best_delta = max(obs["delta_pp"] for obs in observations)
        worst_delta = min(obs["delta_pp"] for obs in observations)
        collapsed_strong_seed = any(
            obs["candidate_wins"] == 0 or obs["strong_seed_delta_pp"] <= -50.0
            for obs in observations
        )
        broke_strong_seed = any(obs["strong_seed_delta_pp"] < 0 for obs in observations)
        if collapsed_strong_seed:
            status = "locked_do_not_cut"
            reason = "one or more packages collapsed the known strong seed when cutting this slot"
        elif broke_strong_seed and best_delta > 0:
            status = "risky_cut_only_same_lane"
            reason = "aggregate upside exists, but it broke the known strong seed"
        elif broke_strong_seed or worst_delta < 0:
            status = "protected_until_same_lane_win"
            reason = "tested cuts failed or regressed; require a same-lane win before cutting again"
        else:
            status = "tested_no_blocker_yet"
            reason = "tested without current blocker evidence, but still requires gate proof before promotion"
        status_counts[status] += 1
        cut_rows.append(
            {
                "card_name": cut,
                "status": status,
                "reason": reason,
                "current_decision": card.get("decision", "not_in_current_champion"),
                "current_lane": card.get("package_lane", "unknown"),
                "effective_role": card.get("effective_role", "unknown"),
                "worst_strong_seed_delta_pp": round(worst_strong, 2),
                "best_delta_pp": round(best_delta, 2),
                "worst_delta_pp": round(worst_delta, 2),
                "observation_count": len(observations),
                "observations": sorted(
                    observations,
                    key=lambda item: (item["strong_seed_delta_pp"], item["delta_pp"], item["package_key"] or ""),
                ),
            }
        )

    blocked = {row["card_name"] for row in cut_rows if row["status"] != "tested_no_blocker_yet"}
    untested_flex_pool = [
        {
            "card_name": row.get("card_name"),
            "decision": row.get("decision"),
            "package_lane": row.get("package_lane"),
            "effective_role": row.get("effective_role"),
            "status": row.get("status"),
        }
        for row in (card_decision_manifest or {}).get("cards", [])
        if row.get("card_name") not in blocked
        and row.get("decision") in {"engine_flex", "manual_review", "support_flex"}
    ]
    return {
        "summary": {
            "status_counts": dict(sorted(status_counts.items())),
            "tested_cut_count": len(cut_rows),
            "blocked_cut_count": len(blocked),
            "untested_flex_pool_count": len(untested_flex_pool),
        },
        "cuts": sorted(cut_rows, key=lambda item: (item["status"], item["card_name"])),
        "untested_flex_pool": sorted(untested_flex_pool, key=lambda item: item["card_name"] or ""),
    }


def render_card_roles_markdown(report: dict[str, Any]) -> str:
    deck = report["deck_summaries"].get("6") or {}
    cards = deck.get("cards") or []
    report_date = str(report.get("generated_at") or "")[:10] or "latest"
    rule_audit_by_card = {
        row.get("card"): row for row in (report.get("unresolved_rule_rows_audit") or {}).get("rows", [])
    }
    thor_audit = report.get("thor_rule_runtime_audit") or {}
    materialized_cards = {
        row.get("materialized_squee", {}).get("card_name")
        for row in (report.get("squee_rule_materialization_audit") or {}).get("rows", [])
        if row.get("materialized_squee", {}).get("battle_rule_count")
    }
    materialized_cards.discard(None)
    lines = [
        f"# Lorehold Current Champion Card Roles - {report_date}",
        "",
        f"- Source DB: `{report['source_db']}`",
        "- Deck scope: current champion candidate loaded as deck id `6` in this candidate DB.",
        "- Comparison vs registered `deck_607`: champion has `Squee, Goblin Nabob`; registered 607 has `Insurrection`.",
        "- PostgreSQL writes: `false`",
        "",
        "| Card | Qty | DB Role | Effective Role | Package Lane | Decision | Status | Battle Rule | Synergy Reason |",
        "| --- | ---: | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for card in sorted(cards, key=lambda item: (item.get("primary_role") or "", item.get("card_name") or "")):
        keys = card.get("battle_rule_keys") or []
        rule_audit = rule_audit_by_card.get(card.get("card_name"))
        audit_decision = (rule_audit or {}).get("decision")
        if keys:
            rule_status = "ready"
        elif card.get("card_name") in materialized_cards:
            rule_status = "materialized_in_equal_gate_candidate"
        elif card.get("card_name") == thor_audit.get("card") and thor_audit.get("decision"):
            rule_status = "local_reviewed_rule_pending_sync"
        elif audit_decision == "deck_rule_materialization_gap":
            rule_status = "source_rule_ready_needs_materialization"
        elif audit_decision == "missing_battle_rule_model":
            rule_status = "missing_battle_rule_model"
        else:
            rule_status = "missing_aggregate"
        reason = card_synergy_reason(card)
        decision, decision_reason = card_decision(card, rule_audit, thor_audit)
        status = card_status(card, rule_audit, thor_audit)
        if card.get("card_name") in materialized_cards and status == "unresolved_rule_or_aggregate_gap":
            status = "materialized_rule_in_equal_gate_candidate"
        lines.append(
            "| {name} | {qty} | {db_role} | {effective_role} | {lane} | {decision}: {decision_reason} | {status} | {rule_status} | {reason} |".format(
                name=card.get("card_name"),
                qty=card.get("quantity"),
                db_role=card.get("primary_role"),
                effective_role=effective_card_role(card),
                lane=card_package_lane(card),
                decision=decision,
                decision_reason=decision_reason,
                status=status,
                rule_status=rule_status,
                reason=reason,
            )
        )
    lines.append("")
    lines.append("## Unresolved Rows")
    lines.append("")
    missing = deck.get("missing_battle_rule_cards") or []
    if missing:
        for card_name in missing:
            decision = (rule_audit_by_card.get(card_name) or {}).get("decision", "unclassified")
            if card_name in materialized_cards:
                decision = "materialized_rule_in_equal_gate_candidate"
            if card_name == thor_audit.get("card") and thor_audit.get("decision"):
                decision = thor_audit.get("decision")
            lines.append(f"- {card_name}: `{decision}`")
    else:
        lines.append("- none")
    lines.append("")
    return "\n".join(lines)


def build_report(args: argparse.Namespace) -> dict[str, Any]:
    conn = sqlite3.connect(args.db)
    conn.row_factory = sqlite3.Row
    try:
        deck_summaries = {str(deck_id): deck_summary(conn, deck_id) for deck_id in args.deck_ids}
        comparison_6_607 = compare_decks(conn, 6, 607)
    finally:
        conn.close()

    matrix, matrix_by_key = load_matrix_by_key(args.matrix)
    ranked_keys = matrix.get("ranked_deck_keys") or []
    ranked = []
    for index, key in enumerate(ranked_keys, start=1):
        if key in matrix_by_key:
            ranked.append({"rank": index, **matrix_by_key[key]})

    squee_gates = aggregate_squee_gates(args.squee_gates)
    general_confirm = load_general_synergy_confirm(args.general_synergy_confirm)
    squee_seed_diagnostic = read_json(args.squee_seed_diagnostic)
    squee_rule_materialization_audit = read_json(args.squee_rule_materialization_audit)
    unresolved_rule_rows_audit = read_json(args.unresolved_rule_rows_audit)
    thor_rule_runtime_audit = read_json(args.thor_rule_runtime_audit)
    thor_rule_gate_audit = read_json(args.thor_rule_gate_audit)
    runtime_package_readiness = aggregate_runtime_package_readiness(
        proposal_paths=args.runtime_package_proposal,
        manifest_paths=args.runtime_package_manifest,
        blocker_paths=args.runtime_package_blocker,
    )
    post_squee_package_gates = aggregate_post_squee_package_gates(args.post_squee_package_gate)
    safe_package_gates = aggregate_safe_package_gates(args.safe_package_gate)
    library_leng_telemetry_gates = aggregate_library_leng_telemetry_gates(args.library_leng_telemetry_gate)
    loss_failure_classifier = read_json(args.loss_failure_classifier)
    card_decision_manifest = build_card_decision_manifest(
        deck_summaries.get("6") or {},
        unresolved_rule_rows_audit,
        thor_rule_runtime_audit,
        squee_rule_materialization_audit,
    )
    cut_safety_manifest = build_cut_safety_manifest(
        post_squee_package_gates,
        card_decision_manifest,
    )
    strategy_dependency_map = build_strategy_dependency_map(
        squee_gates=squee_gates,
        matrix_ranked=ranked,
        post_squee_package_gates=post_squee_package_gates,
        safe_package_gates=safe_package_gates,
        library_leng_telemetry_gates=library_leng_telemetry_gates,
        loss_failure_classifier=loss_failure_classifier,
        cut_safety_manifest=cut_safety_manifest,
    )

    open_questions = [
        "Use the per-game Squee diagnostic to decide whether the next improvement is topdeck consistency, explicit discard/rummage enablement, or a different closing package.",
        "Treat Squee as a provisional micro-upgrade, not a promoted final deck slot, until a support package or alternative cut shows a larger reproducible edge.",
        "Make all decisive battle gates run with `PYTHONHASHSEED=0`, `--isolate-deck-process`, and per-game timeout; same simulation seed without fixed hash seed/process isolation is not enough for deck promotion.",
        "Review DB-role versus effective-role divergences surfaced by the card-role manifest, especially cards stored as `draw` or `unknown` while functioning as protection, removal, miracle engine, or board wipe.",
        "`Thor, God of Thunder` now has a local reviewed runtime rule and one natural synced-rule battle exposure for 7 damage, but the checked 21-game candidate sample had +0.00 pp win-rate delta; keep it as modeled-but-not-proven until a stratified or larger gate proves deck value.",
        "Separate finalizer slots from engine slots: Dance with Calamity and Aetherflux Reservoir have now failed the Storm Herd slot benchmark; remaining finalizer work should focus on other closing packages or different cuts, not repeating those two swaps.",
        "Re-test 615 and 614 only as controlled packages against the 607+Squee champion; their full-deck changes are too broad to diagnose one cause.",
        "Keep runtime-rule readiness in the decision loop; a card with a good paper function cannot be rejected until the battle model understands the relevant effect family.",
        "Treat PG245 cards as modeled-but-not-durable hypotheses: Twinflame Tyrant and Verge Rangers now have runtime-backed package proposals, but PostgreSQL precheck is blocked, so they need PG apply/sync or isolated materialized gates before deck-value judgment.",
        "Library of Leng is now measurable in battle telemetry; separate missing-engine games from games where discard-to-top happens but fails to convert before life-total pressure.",
        "The first Library/pressure retest rejected Brainstone, Ghostly Prison, and The One Ring over Hexing Squelcher; future tests need a new cut logic or a narrower per-game failure target.",
        "Angel's Grace over Dawn's Truce confirms that one-mana life-floor protection can improve a weak seed but is not free; cutting the existing protection shell breaks seed 42 completely.",
        "Birgi + Seething Song over Pearl/Ruby Medallion confirms the ritual lane can help weak seeds, but cutting both medallions breaks seed 42; treat medallions as protected until a same-lane benchmark proves a safer cut.",
        "Primal Amulet over Bender's Waterskin confirms the revised top-freecast/cost-reduction lane can help weak seeds, but the Bender cut still breaks seed 42; treat Bender as protected until a same-slot benchmark preserves the strong seed.",
        "Gamble over Creative Technique is now a resolved probation clue: it improves aggregate and weak seeds but breaks seed 42, so the tutor lane needs a different cut or stronger exposure before promotion.",
        "Gamble or Enlightened Tutor over Thor failed seed-42 triage; do not treat Thor as the obvious tutor-access cut just because Thor is not deck-proven yet.",
        "Galvanoth over Thor also failed seed-42 triage; Thor is not a clean cut for either the tutor-access lane or the topdeck/freecast lane from current evidence.",
        "Boseiju, Who Shelters All over Reliquary Tower failed seed-42 triage; anti-counter land-slot protection does not address the observed life-zero combat-pressure losses by itself.",
        "Boros Charm over Fated Clash failed seed-42 triage at 0-9; protect Fated Clash until a same-lane replacement proves it can preserve the strong seed.",
        "The cut-safety manifest now blocks repeated cuts that already collapsed seed 42 and separates them from unresolved flex slots; use that manifest before generating another package.",
        "The safe queue v3 proves that avoiding protected cuts is necessary but not sufficient: all seven cut-safe smoke packages were still worse than the baseline, so a future package needs a positive strategic reason plus a clean cut, not only cut-safety clearance.",
    ]
    next_gates = [
        "Keep the regression assertion that every `squee_upkeep_return` has an earlier same-game `squee_to_graveyard` or equivalent zone-entry event with source reason.",
        "Build the next pressure/conversion package only after selecting a cut that preserves Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, and the three-mana ramp shell unless a direct same-slot benchmark proves otherwise.",
        "Do not repeat Brainstone, Ghostly Prison, or The One Ring over Hexing Squelcher from the current evidence; only retest them if the failure classifier identifies a different cut or a narrower matchup-specific role.",
        "Do not promote Angel's Grace over Dawn's Truce; any future Angel's Grace test must be a different cut and must preserve seed 42.",
        "Do not promote Faithless Looting from the current package gate; it did not increase Squee graveyard/return enough and lost aggregate win rate.",
        "Do not promote Galvanoth, Dance with Calamity, or Aetherflux Reservoir from current gates; each either loses aggregate or breaks the known strong seed 42.",
        "Do not promote Birgi + Seething Song over Pearl/Ruby Medallion; any future ritual package must preserve at least one medallion or prove the medallion cut with a stronger seed-42 result.",
        "Do not promote Primal Amulet over Bender's Waterskin; future topdeck/freecast work needs a different cut or a deeper Galvanoth-style exposure gate that preserves seed 42.",
        "Do not promote Gamble over Creative Technique from the current gate; if continuing tutor access, preserve seed 42 and test a different cut or a narrower access package rather than assuming the tutor lane is solved.",
        "Do not continue tutor-access testing by cutting Thor unless a new hypothesis explains why the seed-42 collapse would not repeat.",
        "Do not continue topdeck/freecast testing by cutting Thor unless a new hypothesis explains why the seed-42 collapse would not repeat.",
        "Do not promote Boseiju over Reliquary Tower from the current land-slot gate; future spell-protection work should include pressure absorption or a conversion-speed gain, not only anti-counter text.",
        "Do not cut Fated Clash for cheap pressure protection from the current evidence; if Boros Charm is retested, it needs a different cut with an explicit reason.",
        "Before registering any new package, reject the candidate if every proposed cut is locked or protected by the cut-safety manifest and the package has no explicit same-lane proof rationale.",
        "Before deep-gating any future cut-safe package, require either a positive smoke result, a matchup-specific failure classifier target, or an explicit reason why a negative smoke should be overridden; the v3 safe queue produced no direct promotion.",
        "Use the generated card-role manifest to mark each card as core, flex, or unresolved before proposing the next swap.",
        "Use deck-wide rule materialization in the equal-gate loader for every candidate snapshot, then run battle-card-specific tests only for cards with no active reviewed/runtime rule row.",
        "For PG245 runtime-package cards, rerun PostgreSQL precheck first; if PG remains unavailable, test them only through an isolated candidate DB with the generated rule rows materialized and clearly labelled as non-durable.",
        "For Thor, the next decisive test is a stratified exposure gate or larger sample; temporary graveyard recast from ETB is still a separate runtime/model gap.",
    ]

    return {
        "generated_at": utc_now(),
        "source_db": str(args.db),
        "matrix_path": str(args.matrix),
        "commander_intent": COMMANDER_INTENT,
        "external_method_sources": EXTERNAL_METHOD_SOURCES,
        "current_champion_key": current_champion_key(squee_gates),
        "deck_ids": args.deck_ids,
        "deck_summaries": deck_summaries,
        "comparison_6_607": comparison_6_607,
        "matrix_generated_at": matrix.get("generated_at"),
        "matrix_ranked": ranked,
        "squee_gates": squee_gates,
        "squee_seed_diagnostic_path": str(args.squee_seed_diagnostic),
        "squee_seed_diagnostic": squee_seed_diagnostic,
        "squee_rule_materialization_audit_path": str(args.squee_rule_materialization_audit),
        "squee_rule_materialization_audit": squee_rule_materialization_audit,
        "unresolved_rule_rows_audit_path": str(args.unresolved_rule_rows_audit),
        "unresolved_rule_rows_audit": unresolved_rule_rows_audit,
        "thor_rule_runtime_audit_path": str(args.thor_rule_runtime_audit),
        "thor_rule_runtime_audit": thor_rule_runtime_audit,
        "thor_rule_gate_audit_path": str(args.thor_rule_gate_audit),
        "thor_rule_gate_audit": thor_rule_gate_audit,
        "runtime_package_readiness": runtime_package_readiness,
        "general_synergy_confirm": general_confirm,
        "post_squee_package_gates": post_squee_package_gates,
        "safe_package_gates": safe_package_gates,
        "library_leng_telemetry_gates": library_leng_telemetry_gates,
        "loss_failure_classifier_path": str(args.loss_failure_classifier),
        "loss_failure_classifier": loss_failure_classifier,
        "card_decision_manifest": card_decision_manifest,
        "cut_safety_manifest": cut_safety_manifest,
        "strategy_dependency_map": strategy_dependency_map,
        "open_questions": open_questions,
        "next_gates": next_gates,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--squee-gate", dest="squee_gates", type=Path, action="append")
    parser.add_argument("--squee-seed-diagnostic", type=Path, default=DEFAULT_SQUEE_SEED_DIAGNOSTIC)
    parser.add_argument(
        "--squee-rule-materialization-audit",
        type=Path,
        default=DEFAULT_SQUEE_RULE_MATERIALIZATION_AUDIT,
    )
    parser.add_argument(
        "--unresolved-rule-rows-audit",
        type=Path,
        default=DEFAULT_UNRESOLVED_RULE_ROWS_AUDIT,
    )
    parser.add_argument(
        "--thor-rule-runtime-audit",
        type=Path,
        default=DEFAULT_THOR_RULE_RUNTIME_AUDIT,
    )
    parser.add_argument(
        "--thor-rule-gate-audit",
        type=Path,
        default=DEFAULT_THOR_RULE_GATE_AUDIT,
    )
    parser.add_argument("--runtime-package-proposal", type=Path, action="append")
    parser.add_argument("--runtime-package-manifest", type=Path, action="append")
    parser.add_argument("--runtime-package-blocker", type=Path, action="append")
    parser.add_argument("--general-synergy-confirm", type=Path, default=DEFAULT_GENERAL_SYNERGY_CONFIRM)
    parser.add_argument("--post-squee-package-gate", type=Path, action="append")
    parser.add_argument("--safe-package-gate", type=Path, action="append")
    parser.add_argument("--library-leng-telemetry-gate", type=Path, action="append")
    parser.add_argument("--loss-failure-classifier", type=Path, default=DEFAULT_LOSS_FAILURE_CLASSIFIER)
    parser.add_argument("--deck-ids", default=",".join(str(value) for value in DEFAULT_DECK_IDS))
    parser.add_argument("--stem", default="lorehold_strategy_learning_audit_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    args.deck_ids = [int(part.strip()) for part in args.deck_ids.split(",") if part.strip()]
    if not args.squee_gates:
        args.squee_gates = DEFAULT_SQUEE_GATES
    if not args.post_squee_package_gate:
        args.post_squee_package_gate = DEFAULT_POST_SQUEE_PACKAGE_GATES
    if not args.safe_package_gate:
        args.safe_package_gate = DEFAULT_SAFE_PACKAGE_GATES
    if not args.library_leng_telemetry_gate:
        args.library_leng_telemetry_gate = DEFAULT_LIBRARY_LENG_TELEMETRY_GATES
    if not args.runtime_package_proposal:
        args.runtime_package_proposal = DEFAULT_RUNTIME_PACKAGE_PROPOSALS
    if not args.runtime_package_manifest:
        args.runtime_package_manifest = DEFAULT_RUNTIME_PACKAGE_MANIFESTS
    if not args.runtime_package_blocker:
        args.runtime_package_blocker = DEFAULT_RUNTIME_PACKAGE_BLOCKERS

    report = build_report(args)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    roles_path = REPORT_DIR / f"{args.stem}_card_roles.md"
    json_path.write_text(json.dumps(report, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    roles_path.write_text(render_card_roles_markdown(report), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(f"wrote {roles_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
