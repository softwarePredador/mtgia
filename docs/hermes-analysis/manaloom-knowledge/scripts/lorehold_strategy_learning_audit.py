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
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed42_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed99_20260627_v1.json",
    REPORT_DIR / "lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260627_v1.json",
]
DEFAULT_GENERAL_SYNERGY_CONFIRM = (
    REPORT_DIR / "lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json"
)
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
    "The Mind Stone": "two-mana rock that can cash in for a card later",
    "Tragic Arrogance": "selective board wipe; unresolved aggregate rule status matters",
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
    "Thor, God of Thunder": "removal",
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
    lines.append("- The 3-seed suite keeps Squee ahead but shows high seed sensitivity: champion `13W/14L/0S` (`48.15%`) vs `deck_607` `7W/20L/0S` (`25.93%`) and source `deck_6` `2W/25L/0S` (`7.41%`).")
    lines.append("- Zone-trace evidence proves `Squee` can be cast, move to graveyard, and return during games, not only in a unit test. Across the 3-seed suite it has `squee_to_graveyard=9`, `squee_upkeep_return=6`, `squee_return_after_known_graveyard_entry=6`, and `squee_return_without_known_graveyard_entry=0`.")
    lines.append("- Proven Squee routes in this suite are battlefield-to-graveyard through combat/wipes plus one opponent mill (`Brain Freeze`).")
    lines.append("- Important caveat: the trace gate still did not show `Squee` being discarded by Lorehold rummage or spell-rummage. Treat the discard-fuel loop as a hypothesis; the proven loop is graveyard recurrence after observed zone entries.")
    lines.append("- `Squee` still has an aggregate-loader gap: the verified runtime rule exists in `battle_card_rules`, but the candidate snapshot row keeps `deck_cards.battle_rules_json=[]` for that card.")
    lines.append("- The broad synergy-confirm gate rejected the tested Past in Flames, Overmaster, and combined spellchain packages; do not promote them from the current evidence.")
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
    lines.append("Interpretation: under fixed hash-seed, process-isolated, timeout-bounded conditions, the Squee candidate remains the best current candidate across the 3-seed suite, but the result is not final because seed 99 and seed 20260627 were much less favorable than seed 42. The trace evidence still proves every observed `squee_upkeep_return` occurred after an observed Squee graveyard entry, mostly battlefield-to-graveyard movement plus one mill event. It did not prove `lorehold_rummage_discards_squee` or `lorehold_spell_rummage_discards_squee`, so the exact discard-fuel loop remains a targeted next hypothesis rather than a closed fact.")
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
    lines.append("## Current Champion Card-Role Coverage")
    lines.append("")
    champion = report["deck_summaries"].get("6") or {}
    lines.append(f"- Quantity: `{champion.get('quantity_total')}` across `{champion.get('row_count')}` rows.")
    lines.append(f"- Primary role counts: `{json.dumps(champion.get('role_counts', {}), sort_keys=True)}`")
    lines.append(f"- Missing aggregated battle-rule rows: `{len(champion.get('missing_battle_rule_cards', []))}` cards: {', '.join(champion.get('missing_battle_rule_cards', [])) or 'none'}.")
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


def card_status(card: dict[str, Any]) -> str:
    name = card.get("card_name") or ""
    role = effective_card_role(card)
    keys = card.get("battle_rule_keys") or []
    if name == "Lorehold, the Historian":
        return "core_commander"
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
        rule_status = "ready" if keys else "missing_aggregate"
        reason = card_synergy_reason(card)
        lines.append(
            "| {name} | {qty} | {db_role} | {effective_role} | {status} | {rule_status} | {reason} |".format(
                name=card.get("card_name"),
                qty=card.get("quantity"),
                db_role=card.get("primary_role"),
                effective_role=effective_card_role(card),
                status=card_status(card),
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
            lines.append(f"- {card_name}")
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

    open_questions = [
        "Scale the trusted gate from the current 3-seed suite to a 5-seed or 10-seed process-isolated suite before promoting the deck as final.",
        "Diagnose seed sensitivity: seed 42 strongly favors Squee, while seeds 99 and 20260627 show the candidate still leading but at a much lower win rate.",
        "Make all decisive battle gates run with `PYTHONHASHSEED=0`, `--isolate-deck-process`, and per-game timeout; same simulation seed without fixed hash seed/process isolation is not enough for deck promotion.",
        "Review DB-role versus effective-role divergences surfaced by the card-role manifest, especially cards stored as `draw` or `unknown` while functioning as protection, removal, miracle engine, or board wipe.",
        "Separate finalizer slots from engine slots: Insurrection, Storm Herd, Approach, Rise of the Eldrazi, and Aetherflux Reservoir should be benchmarked as closing packages, not generic wincon labels.",
        "Re-test 615 and 614 only as controlled packages against the 607+Squee champion; their full-deck changes are too broad to diagnose one cause.",
        "Keep runtime-rule readiness in the decision loop; a card with a good paper function cannot be rejected until the battle model understands the relevant effect family.",
    ]
    next_gates = [
        "Keep the regression assertion that every `squee_upkeep_return` has an earlier same-game `squee_to_graveyard` or equivalent zone-entry event with source reason.",
        "Run a 5-seed or 10-seed equal gate with `PYTHONHASHSEED=0`, process isolation, and timeout: trusted Squee champion vs `deck_607` vs the source deck 6, same real opponents.",
        "Build two narrow packages from 615: one Birgi/ritual package and one topdeck-freecast package, each with one or two cuts only, then gate them against the Squee champion.",
        "Use the generated card-role manifest to mark each card as core, flex, or unresolved before proposing the next swap.",
        "If a candidate uses a rule missing from aggregated deck rows, run the battle-card-specific test plus one replay trace before trusting the battle result.",
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
        "general_synergy_confirm": general_confirm,
        "open_questions": open_questions,
        "next_gates": next_gates,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--matrix", type=Path, default=DEFAULT_MATRIX)
    parser.add_argument("--squee-gate", dest="squee_gates", type=Path, action="append")
    parser.add_argument("--general-synergy-confirm", type=Path, default=DEFAULT_GENERAL_SYNERGY_CONFIRM)
    parser.add_argument("--deck-ids", default=",".join(str(value) for value in DEFAULT_DECK_IDS))
    parser.add_argument("--stem", default="lorehold_strategy_learning_audit_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    args.deck_ids = [int(part.strip()) for part in args.deck_ids.split(",") if part.strip()]
    if not args.squee_gates:
        args.squee_gates = DEFAULT_SQUEE_GATES

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
