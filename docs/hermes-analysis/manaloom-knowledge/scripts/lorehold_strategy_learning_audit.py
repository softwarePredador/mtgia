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
DEFAULT_POST_SQUEE_PACKAGE_GATES = [
    REPORT_DIR / "lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_post_squee_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json",
    REPORT_DIR / "lorehold_squee_refinement_package_gate_20260627_v1_seed20260625_hash0_isolated_timeout.json",
]
DEFAULT_DECK_IDS = [6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]

EXTERNAL_METHOD_SOURCES = [
    {
        "name": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "use": "commander-specific package comparison lane",
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
    "Molecule Man": "miracle_engine",
    "Promise of Loyalty": "board_wipe",
    "Redirect Lightning": "removal",
    "Squee, Goblin Nabob": "recursion_engine",
    "Starfall Invocation": "board_wipe",
    "The Mind Stone": "ramp",
    "Thor, God of Thunder": "spell_damage_engine",
    "Tragic Arrogance": "board_wipe",
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
        "lorehold_spell_rummage",
        "lorehold_upkeep_rummage",
        "miracle_cast",
        "topdeck_manipulation_activated",
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
            candidate_events = (candidate.get("telemetry") or {}).get("strategic_event_counts") or {}
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
                    metric: int(candidate_events.get(metric) or 0) - int(baseline_events.get(metric) or 0)
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


def render_markdown(report: dict[str, Any]) -> str:
    lines: list[str] = []
    lines.append("# Lorehold Strategy Learning Audit - 2026-06-27")
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
    lines.append("- The broad synergy-confirm gate rejected the tested Past in Flames, Overmaster, and combined spellchain packages; do not promote them from the current evidence.")
    post_squee = report.get("post_squee_package_gates") or {}
    post_squee_rows = post_squee.get("rows") or []
    if post_squee_rows:
        best = post_squee_rows[0]
        lines.append(
            "- Post-Squee package gates now cover Brainstone, Faithless Looting, Galvanoth, Birgi, and Penance against the Squee champion. "
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
        if penance:
            delta = penance.get("strategic_delta") or {}
            lines.append(
                f"- Penance is not a proven topdeck engine yet: observed `hand_to_topdeck_activation` delta was `{int(delta.get('hand_to_topdeck_activation') or 0):+d}` "
                f"and the package lost `{penance['delta_pp']:+.2f}` pp aggregate."
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
        lines.append("## Post-Squee Package Gates")
        lines.append("")
        lines.append("These gates use the Squee champion as source deck id `6`, fixed `PYTHONHASHSEED=0`, process isolation, and per-game timeout. The promotion bar is stricter than a single positive seed: the package must improve aggregate results without breaking the known strong seed.")
        lines.append("")
        lines.append("| Package | Adds | Cuts | Aggregate Baseline | Aggregate Candidate | Delta pp | Seed 42 pp | Miracle | Topdeck | Hand-Top | Spell | Mana | Birgi Mana | Squee GY | Squee Return | Decision |")
        lines.append("| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
        for row in post_squee_rows:
            delta = row.get("strategic_delta") or {}
            lines.append(
                "| `{package}` | {adds} | {cuts} | {base_w}-{base_l} | {cand_w}-{cand_l} | {delta_pp:+.2f} | {strong:+.2f} | {miracle:+d} | {topdeck:+d} | {hand_top:+d} | {spell:+d} | {mana:+d} | {birgi_mana:+d} | {squee_gy:+d} | {squee_return:+d} | {decision} |".format(
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
                    hand_top=int(delta.get("hand_to_topdeck_activation") or 0),
                    spell=int(delta.get("lorehold_spell_cast") or 0),
                    mana=int(delta.get("spell_cast_mana_trigger") or 0),
                    birgi_mana=int(delta.get("birgi_spell_cast_mana") or 0),
                    squee_gy=int(delta.get("squee_to_graveyard") or 0),
                    squee_return=int(delta.get("squee_upkeep_return") or 0),
                    decision=row["decision"],
                )
            )
        lines.append("")
        lines.append("Read: Brainstone adds topdeck manipulation but does not convert wins. Faithless Looting does not prove the intended Squee-discard loop here and loses badly overall. The original Galvanoth/Bender's Waterskin swap is the only positive aggregate signal, but it loses the strong seed 42; the follow-up Galvanoth/Hexing Squelcher swap is worse, so Galvanoth stays a probation hypothesis, not a deck insert. Birgi proves the new spell-cast mana telemetry can fire, but it does not improve results. Penance did not fire its hand-to-library activation in this gate, so it is not evidence for a working topdeck-protection engine yet.")
        lines.append("")
    lines.append("## Current Champion Card-Role Coverage")
    lines.append("")
    champion = report["deck_summaries"].get("6") or {}
    lines.append(f"- Quantity: `{champion.get('quantity_total')}` across `{champion.get('row_count')}` rows.")
    lines.append(f"- Primary role counts: `{json.dumps(champion.get('role_counts', {}), sort_keys=True)}`")
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
    effective_missing_cards = [
        card
        for card in missing_cards
        if card not in materialized_cards
        and card not in audit_materialization_cards
        and card not in thor_local_runtime_cards
    ]
    lines.append(
        f"- Missing aggregated battle-rule rows in the legacy champion DB: `{len(missing_cards)}` cards: {', '.join(missing_cards) or 'none'}."
    )
    if materialized_cards:
        lines.append(
            f"- Superseded by rule-materialization audit: `{', '.join(sorted(materialized_cards))}` now has materialized rule evidence in the equal-gate candidate."
        )
        lines.append(
            f"- Effective unresolved rule rows after that audit: `{len(effective_missing_cards)}` cards: {', '.join(effective_missing_cards) or 'none'}."
        )
    if audit_materialization_cards:
        lines.append(
            f"- Reclassified by remaining-row audit as deck materialization gaps: `{', '.join(sorted(audit_materialization_cards))}`."
        )
        lines.append(
            f"- Effective unresolved rule/model rows after all current materialization evidence: `{len(effective_missing_cards)}` cards: {', '.join(effective_missing_cards) or 'none'}."
        )
    if thor_local_runtime_cards:
        lines.append(
            f"- Reclassified by Thor runtime audit as local reviewed rule added pending durable sync: `{', '.join(sorted(thor_local_runtime_cards))}`."
        )
        lines.append(
            f"- Effective unresolved local runtime/model rows after Thor audit: `{len(effective_missing_cards)}` cards: {', '.join(effective_missing_cards) or 'none'}."
        )
    lines.append("- Full per-card role, tags, and rule keys are in the companion JSON under `deck_summaries.6.cards`.")
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
    if role in {"draw", "engine", "wincon"}:
        return "core_or_flex_engine"
    return "flex_or_contextual"


def render_card_roles_markdown(report: dict[str, Any]) -> str:
    deck = report["deck_summaries"].get("6") or {}
    cards = deck.get("cards") or []
    rule_audit_by_card = {
        row.get("card"): row for row in (report.get("unresolved_rule_rows_audit") or {}).get("rows", [])
    }
    thor_audit = report.get("thor_rule_runtime_audit") or {}
    lines = [
        "# Lorehold Current Champion Card Roles - 2026-06-27",
        "",
        f"- Source DB: `{report['source_db']}`",
        "- Deck scope: current champion candidate loaded as deck id `6` in this candidate DB.",
        "- Comparison vs registered `deck_607`: champion has `Squee, Goblin Nabob`; registered 607 has `Insurrection`.",
        "- PostgreSQL writes: `false`",
        "",
        "| Card | Qty | DB Role | Effective Role | Status | Battle Rule | Synergy Reason |",
        "| --- | ---: | --- | --- | --- | --- | --- |",
    ]
    for card in sorted(cards, key=lambda item: (item.get("primary_role") or "", item.get("card_name") or "")):
        keys = card.get("battle_rule_keys") or []
        rule_audit = rule_audit_by_card.get(card.get("card_name"))
        audit_decision = (rule_audit or {}).get("decision")
        if keys:
            rule_status = "ready"
        elif card.get("card_name") == thor_audit.get("card") and thor_audit.get("decision"):
            rule_status = "local_reviewed_rule_pending_sync"
        elif audit_decision == "deck_rule_materialization_gap":
            rule_status = "source_rule_ready_needs_materialization"
        elif audit_decision == "missing_battle_rule_model":
            rule_status = "missing_battle_rule_model"
        else:
            rule_status = "missing_aggregate"
        reason = card_synergy_reason(card)
        lines.append(
            "| {name} | {qty} | {db_role} | {effective_role} | {status} | {rule_status} | {reason} |".format(
                name=card.get("card_name"),
                qty=card.get("quantity"),
                db_role=card.get("primary_role"),
                effective_role=effective_card_role(card),
                status=card_status(card, rule_audit, thor_audit),
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
    post_squee_package_gates = aggregate_post_squee_package_gates(args.post_squee_package_gate)

    open_questions = [
        "Use the per-game Squee diagnostic to decide whether the next improvement is topdeck consistency, explicit discard/rummage enablement, or a different closing package.",
        "Treat Squee as a provisional micro-upgrade, not a promoted final deck slot, until a support package or alternative cut shows a larger reproducible edge.",
        "Make all decisive battle gates run with `PYTHONHASHSEED=0`, `--isolate-deck-process`, and per-game timeout; same simulation seed without fixed hash seed/process isolation is not enough for deck promotion.",
        "Review DB-role versus effective-role divergences surfaced by the card-role manifest, especially cards stored as `draw` or `unknown` while functioning as protection, removal, miracle engine, or board wipe.",
        "`Thor, God of Thunder` now has a local reviewed runtime rule and one natural synced-rule battle exposure for 7 damage, but the checked 21-game candidate sample had +0.00 pp win-rate delta; keep it as modeled-but-not-proven until a stratified or larger gate proves deck value.",
        "Separate finalizer slots from engine slots: Insurrection, Storm Herd, Approach, Rise of the Eldrazi, and Aetherflux Reservoir should be benchmarked as closing packages, not generic wincon labels.",
        "Re-test 615 and 614 only as controlled packages against the 607+Squee champion; their full-deck changes are too broad to diagnose one cause.",
        "Keep runtime-rule readiness in the decision loop; a card with a good paper function cannot be rejected until the battle model understands the relevant effect family.",
    ]
    next_gates = [
        "Keep the regression assertion that every `squee_upkeep_return` has an earlier same-game `squee_to_graveyard` or equivalent zone-entry event with source reason.",
        "Build one topdeck consistency package against the 607+Squee champion, because seed 42 wins with topdeck=30/miracle=33 while the failure seeds are topdeck-poor.",
        "Do not promote Faithless Looting from the current package gate; it did not increase Squee graveyard/return enough and lost aggregate win rate.",
        "Retest Galvanoth only as a probation topdeck-freecast hypothesis with a better cut than Bender's Waterskin, because the current gate is aggregate-positive but breaks seed 42.",
        "Build two narrow packages from 615: one Birgi/ritual package and one revised topdeck-freecast package, each with one or two cuts only, then gate them against the Squee champion.",
        "Use the generated card-role manifest to mark each card as core, flex, or unresolved before proposing the next swap.",
        "Use deck-wide rule materialization in the equal-gate loader for every candidate snapshot, then run battle-card-specific tests only for cards with no active reviewed/runtime rule row.",
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
        "general_synergy_confirm": general_confirm,
        "post_squee_package_gates": post_squee_package_gates,
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
    parser.add_argument("--general-synergy-confirm", type=Path, default=DEFAULT_GENERAL_SYNERGY_CONFIRM)
    parser.add_argument("--post-squee-package-gate", type=Path, action="append")
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
