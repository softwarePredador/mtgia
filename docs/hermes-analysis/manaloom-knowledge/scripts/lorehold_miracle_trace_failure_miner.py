#!/usr/bin/env python3
"""Mine recent Lorehold challenger gates for miracle/topdeck failure learning.

This is read-only. It compares protected deck_607 against recent full-shell
challengers and turns aggregate battle results into deckbuilding constraints:
which cards or lanes are allowed to matter, and which claims remain unproven.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
KNOWLEDGE_DB = SCRIPT_DIR / "knowledge.db"

BASELINE_KEY = "deck_607"
FIXED_607_OPPONENT = "Fixed Lorehold deck 607"
DEFAULT_GATE_PATHS = [
    REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_pressure_mana_conversion_deoverfill_fixed607_gate.json",
    REPORT_DIR / "lorehold_from_scratch_challengers_20260704_spell_volume_access_depressure_fixed607_gate.json",
]
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current"

MIRACLE_EVENTS = (
    "miracle_cast",
    "topdeck_manipulation_activated",
    "discard_to_top_replacement",
    "lorehold_rummage_discard_to_top",
)
SPELL_ENGINE_EVENTS = (
    "lorehold_cost_paid",
    "lorehold_spell_cast",
    "lorehold_upkeep_rummage",
    "static_cost_reduction_total",
    "spell_cast_mana_trigger",
    "birgi_spell_cast_mana",
)
STRATEGIC_EVENTS = MIRACLE_EVENTS + SPELL_ENGINE_EVENTS
STRATEGIC_GAME_EVENTS = STRATEGIC_EVENTS + (
    "hand_to_topdeck_activation",
    "lorehold_spell_rummage",
    "static_cost_reduction_casts",
)
FOCUS_CARDS = (
    "Land Tax",
    "Library of Leng",
    "Lorehold, the Historian",
    "Scroll Rack",
    "Sensei's Divining Top",
    "The Mind Stone",
    "Urza's Saga",
    "Bender's Waterskin",
    "Victory Chimes",
    "The Scarlet Witch",
    "Molecule Man",
    "Mana Vault",
    "The One Ring",
)
TOPDECK_ANCHORS = (
    "Land Tax",
    "Library of Leng",
    "Scroll Rack",
    "Sensei's Divining Top",
    "The Mind Stone",
    "Urza's Saga",
)
PRESSURE_CARDS = (
    "Guttersnipe",
    "Storm-Kiln Artist",
    "Young Pyromancer",
    "Monastery Mentor",
)
PRESSURE_CONVERSION_PREFIXES = (
    "damage_dealt",
    "noncreature_damage",
    "spell_resolved",
    "treasure_created",
    "trigger_resolved",
)

EXTERNAL_LEARNING = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "learning": (
            "Color identity and singleton legality are entry gates only; colorless "
            "cards can be legal, but legality does not prove deck value."
        ),
    },
    {
        "source": "EDHREC Lorehold commander page",
        "url": "https://edhrec.com/commanders/lorehold-the-historian",
        "learning": (
            "The current public Lorehold surface is tagged around Topdeck, "
            "Spellslinger, Discard, and Burn; high-synergy cards include Library "
            "of Leng, Storm Herd, Sensei's Divining Top, Approach of the Second "
            "Sun, and Scroll Rack."
        ),
    },
    {
        "source": "EDHREC Miracles Every Turn article",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "learning": (
            "Lorehold's upkeep rummage creates first-draw miracle windows on "
            "opponents' turns; top-library tools and Library of Leng are core "
            "engine cards, not replaceable generic utility."
        ),
    },
    {
        "source": "EDHREC Boros Miracles budget article",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "learning": (
            "The deck wants a high instant/sorcery density and spell-lands so the "
            "first draw each turn is not a dud for miracle."
        ),
    },
]

EXTERNAL_CARD_LEGALITY_SNAPSHOT = {
    "Mana Vault": {
        "source": "https://scryfall.com/card/2x2/308/mana-vault",
        "commander": "legal",
        "color_identity": [],
        "produced_mana": ["C"],
        "edhrec_rank": 145,
        "game_changer": True,
        "interpretation": (
            "Externally legal and powerful. In the current ManaLoom corpus it is "
            "also internally available and runtime-modeled, so the 607 blocker is "
            "safe-cut plus equal battle proof, not color identity."
        ),
    },
    "The One Ring": {
        "source": "https://scryfall.com/card/ltr/246/the-one-ring",
        "commander": "legal",
        "color_identity": [],
        "edhrec_rank": 90,
        "game_changer": True,
        "interpretation": (
            "Externally legal and colorless. In the current ManaLoom corpus it is "
            "also internally available and runtime-modeled, but a generic "
            "protection/draw staple is not automatically better than a Lorehold "
            "miracle/topdeck anchor."
        ),
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def result_rows(gate: Mapping[str, Any]) -> list[dict[str, Any]]:
    return [dict(row) for row in gate.get("results") or [] if isinstance(row, Mapping)]


def gate_row(gate: Mapping[str, Any], deck_key: str) -> dict[str, Any]:
    for row in result_rows(gate):
        if row.get("deck_key") == deck_key:
            return row
    return {}


def candidate_rows(gate: Mapping[str, Any], baseline_key: str = BASELINE_KEY) -> list[dict[str, Any]]:
    return [row for row in result_rows(gate) if row.get("deck_key") != baseline_key]


def telemetry(row: Mapping[str, Any]) -> Mapping[str, Any]:
    value = row.get("telemetry")
    return value if isinstance(value, Mapping) else {}


def strategic_counts(row: Mapping[str, Any], event_names: Iterable[str] = STRATEGIC_EVENTS) -> dict[str, int]:
    events = telemetry(row).get("strategic_event_counts")
    source = events if isinstance(events, Mapping) else {}
    return {name: as_int(source.get(name)) for name in event_names}


def strategic_game_counts(row: Mapping[str, Any], event_names: Iterable[str] = STRATEGIC_GAME_EVENTS) -> dict[str, int]:
    games = telemetry(row).get("strategic_games")
    source = games if isinstance(games, Mapping) else {}
    out: dict[str, int] = {}
    for name in event_names:
        value = source.get(name)
        out[name] = as_int(value.get("games")) if isinstance(value, Mapping) else as_int(value)
    return out


def focus_card(row: Mapping[str, Any], card_name: str) -> dict[str, int]:
    focus = telemetry(row).get("focus_card_access_summary")
    source = focus if isinstance(focus, Mapping) else {}
    payload = source.get(card_name)
    values = payload if isinstance(payload, Mapping) else {}
    fields = (
        "trace_games",
        "accessed_games",
        "near_access_games",
        "drawn_games",
        "opening_hand_games",
        "library_only_games",
        "trace_count",
    )
    return {field: as_int(values.get(field)) for field in fields}


def focus_access_delta(candidate: Mapping[str, Any], baseline: Mapping[str, Any]) -> dict[str, dict[str, int]]:
    out: dict[str, dict[str, int]] = {}
    for card in FOCUS_CARDS:
        c_values = focus_card(candidate, card)
        b_values = focus_card(baseline, card)
        if not any(c_values.values()) and not any(b_values.values()):
            continue
        out[card] = {
            "candidate_accessed_games": c_values["accessed_games"],
            "baseline_accessed_games": b_values["accessed_games"],
            "delta_accessed_games": c_values["accessed_games"] - b_values["accessed_games"],
            "candidate_near_access_games": c_values["near_access_games"],
            "baseline_near_access_games": b_values["near_access_games"],
            "delta_near_access_games": c_values["near_access_games"] - b_values["near_access_games"],
            "candidate_drawn_games": c_values["drawn_games"],
            "baseline_drawn_games": b_values["drawn_games"],
            "delta_drawn_games": c_values["drawn_games"] - b_values["drawn_games"],
            "candidate_library_only_games": c_values["library_only_games"],
            "baseline_library_only_games": b_values["library_only_games"],
            "delta_library_only_games": c_values["library_only_games"] - b_values["library_only_games"],
        }
    return out


def opponent_record(row: Mapping[str, Any], opponent_name: str) -> dict[str, int]:
    for opponent in row.get("opponents") or []:
        if isinstance(opponent, Mapping) and opponent.get("opponent") == opponent_name:
            wins = as_int(opponent.get("wins"))
            losses = as_int(opponent.get("losses"))
            stalls = as_int(opponent.get("stalls"))
            return {"wins": wins, "losses": losses, "stalls": stalls, "games": wins + losses + stalls}
    return {"wins": 0, "losses": 0, "stalls": 0, "games": 0}


def card_event_counts(row: Mapping[str, Any]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for game in row.get("game_results") or []:
        if not isinstance(game, Mapping):
            continue
        for event, count in (game.get("card_event_counts") or {}).items():
            counts[str(event)] += as_int(count)
    if counts:
        return counts
    for metric in telemetry(row).get("top_cards") or []:
        if isinstance(metric, Mapping):
            counts[str(metric.get("key") or "")] += as_int(metric.get("count"))
    return counts


def sqlite_query(db_path: Path, query: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    if not db_path.exists():
        return []
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        return [dict(row) for row in conn.execute(query, params).fetchall()]
    finally:
        conn.close()


def internal_accessibility_snapshot(db_path: Path = KNOWLEDGE_DB) -> dict[str, Any]:
    names = ("mana vault", "the one ring")
    placeholders = ",".join("?" for _ in names)
    oracle_rows = sqlite_query(
        db_path,
        f"""
        SELECT normalized_name, name, mana_cost, cmc, type_line, color_identity_json, card_id, source
        FROM card_oracle_cache
        WHERE normalized_name IN ({placeholders})
        ORDER BY normalized_name
        """,
        names,
    )
    rule_rows = sqlite_query(
        db_path,
        f"""
        SELECT normalized_name, card_name, logical_rule_key, source, review_status,
               execution_status, rule_version, effect_json
        FROM battle_card_rules
        WHERE normalized_name IN ({placeholders})
        ORDER BY normalized_name, logical_rule_key
        """,
        names,
    )
    staple_rows = sqlite_query(
        db_path,
        """
        SELECT lower(card_name) AS normalized_name, card_name, format, archetype,
               category, color_identity, edhrec_rank, is_banned
        FROM format_staples
        WHERE lower(card_name) IN (?, ?)
        ORDER BY card_name, format, archetype, category
        """,
        names,
    )
    deck_rows = sqlite_query(
        db_path,
        """
        SELECT lower(card_name) AS normalized_name, deck_id, card_name, quantity,
               functional_tag, cmc, type_line
        FROM deck_cards
        WHERE lower(card_name) IN (?, ?)
        ORDER BY deck_id, card_name
        """,
        names,
    )
    by_name: dict[str, dict[str, Any]] = {
        "Mana Vault": {
            "oracle_cache": [],
            "battle_rules": [],
            "format_staples": [],
            "deck_presence": [],
        },
        "The One Ring": {
            "oracle_cache": [],
            "battle_rules": [],
            "format_staples": [],
            "deck_presence": [],
        },
    }
    key_to_name = {"mana vault": "Mana Vault", "the one ring": "The One Ring"}
    for row in oracle_rows:
        by_name[key_to_name[str(row["normalized_name"])]]["oracle_cache"].append(row)
    for row in rule_rows:
        row = dict(row)
        row["effect_json"] = str(row.get("effect_json") or "")[:500]
        by_name[key_to_name[str(row["normalized_name"])]]["battle_rules"].append(row)
    for row in staple_rows:
        by_name[key_to_name[str(row["normalized_name"])]]["format_staples"].append(row)
    for row in deck_rows:
        by_name[key_to_name[str(row["normalized_name"])]]["deck_presence"].append(row)

    for card, payload in by_name.items():
        deck_ids = [as_int(row.get("deck_id")) for row in payload["deck_presence"]]
        has_oracle = bool(payload["oracle_cache"])
        executable_rules = [
            row
            for row in payload["battle_rules"]
            if row.get("execution_status") == "auto" and row.get("review_status") in {"active", "verified"}
        ]
        payload["summary"] = {
            "in_card_oracle_cache": has_oracle,
            "has_executable_runtime_rule": bool(executable_rules),
            "present_in_protected_607": 607 in deck_ids,
            "present_in_deck_615_challenger": 615 in deck_ids,
            "present_in_legacy_deck_6": 6 in deck_ids,
            "known_deck_ids": deck_ids,
            "blocker_for_607": (
                "not_in_protected_607_and_prior_cut_battle_evidence_rejected"
                if has_oracle and executable_rules and 607 not in deck_ids
                else "requires_current_corpus_review"
            ),
        }
    return {
        "source_db": rel(db_path),
        "cards": by_name,
    }


def card_event_subset(row: Mapping[str, Any], card_names: Iterable[str]) -> dict[str, int]:
    names = tuple(card_names)
    out: dict[str, int] = {}
    for event, count in card_event_counts(row).items():
        if any(f":{name}" in event for name in names):
            out[event] = as_int(count)
    return dict(sorted(out.items()))


def pressure_conversion_events(row: Mapping[str, Any]) -> dict[str, int]:
    out: dict[str, int] = {}
    for event, count in card_event_subset(row, PRESSURE_CARDS).items():
        if event.startswith(PRESSURE_CONVERSION_PREFIXES):
            out[event] = count
    for event in ("spell_cast_mana_trigger", "birgi_spell_cast_mana"):
        count = strategic_counts(row).get(event, 0)
        if count:
            out[event] = count
    return dict(sorted(out.items()))


def record(row: Mapping[str, Any]) -> dict[str, int]:
    wins = as_int(row.get("wins"))
    losses = as_int(row.get("losses"))
    stalls = as_int(row.get("stalls"))
    games = as_int(row.get("games")) or wins + losses + stalls
    return {"wins": wins, "losses": losses, "stalls": stalls, "games": games}


def delta(candidate_values: Mapping[str, int], baseline_values: Mapping[str, int]) -> dict[str, int]:
    keys = sorted(set(candidate_values) | set(baseline_values))
    return {key: as_int(candidate_values.get(key)) - as_int(baseline_values.get(key)) for key in keys}


def sum_deltas(focus_delta: Mapping[str, Mapping[str, int]], cards: Iterable[str], field: str) -> int:
    return sum(as_int(focus_delta.get(card, {}).get(field)) for card in cards)


def known_candidate_decision(deck_key: str) -> str:
    if "depressure" in deck_key:
        return "reject_current_depressure_shell"
    if "deoverfill" in deck_key:
        return "do_not_promote_pressure_unproven"
    if "pressure" in deck_key:
        return "do_not_promote_pressure_shell_without_causality"
    return "do_not_promote_current_shell"


def candidate_summary(
    *,
    gate: Mapping[str, Any],
    gate_path: Path,
    baseline: Mapping[str, Any],
    candidate: Mapping[str, Any],
) -> dict[str, Any]:
    deck_key = str(candidate.get("deck_key") or "")
    candidate_record = record(candidate)
    baseline_record = record(baseline)
    c_strategic = strategic_counts(candidate)
    b_strategic = strategic_counts(baseline)
    c_games = strategic_game_counts(candidate)
    b_games = strategic_game_counts(baseline)
    focus_delta = focus_access_delta(candidate, baseline)
    fixed_607 = opponent_record(candidate, FIXED_607_OPPONENT)
    pressure_slice = opponent_record(candidate, "Winota, Joiner of Forces #39 (real)")
    pressure_events = card_event_subset(candidate, PRESSURE_CARDS)
    conversion_events = pressure_conversion_events(candidate)
    topdeck_anchor_delta = sum_deltas(focus_delta, TOPDECK_ANCHORS, "delta_accessed_games")
    flags: list[str] = []

    if fixed_607["games"] and fixed_607["wins"] <= fixed_607["losses"]:
        flags.append("head_to_head_not_won")
    if candidate_record["wins"] < baseline_record["wins"]:
        flags.append("aggregate_below_baseline")
    if c_strategic.get("miracle_cast", 0) <= 0 or c_games.get("miracle_cast", 0) <= 0:
        flags.append("miracle_trace_missing")
    if c_strategic.get("topdeck_manipulation_activated", 0) <= 0:
        flags.append("topdeck_activation_missing")
    if c_strategic.get("miracle_cast", 0) < b_strategic.get("miracle_cast", 0):
        flags.append("miracle_volume_regressed")
    if c_strategic.get("topdeck_manipulation_activated", 0) < b_strategic.get("topdeck_manipulation_activated", 0):
        flags.append("topdeck_activation_regressed")
    if topdeck_anchor_delta < 0:
        flags.append("topdeck_anchor_access_regressed")
    if "pressure" in deck_key and not pressure_events:
        flags.append("pressure_causality_unproven")
    if "pressure" in deck_key and not conversion_events:
        flags.append("pressure_conversion_unproven")
    if (
        c_strategic.get("birgi_spell_cast_mana", 0) + c_strategic.get("spell_cast_mana_trigger", 0) > 0
        and candidate_record["wins"] == 0
    ):
        flags.append("mana_event_without_conversion_to_wins")
    if pressure_slice["games"] and pressure_slice["wins"] < pressure_slice["losses"]:
        flags.append("fast_pressure_slice_not_protected")

    return {
        "source_gate": rel(gate_path),
        "gate_status": str(gate.get("status") or ""),
        "candidate_key": deck_key,
        "baseline_key": BASELINE_KEY,
        "candidate_record": candidate_record,
        "baseline_record": baseline_record,
        "head_to_head_vs_607": fixed_607,
        "fast_pressure_slice": pressure_slice,
        "strategic_counts": c_strategic,
        "baseline_strategic_counts": b_strategic,
        "strategic_count_delta": delta(c_strategic, b_strategic),
        "strategic_game_counts": c_games,
        "baseline_strategic_game_counts": b_games,
        "strategic_game_delta": delta(c_games, b_games),
        "focus_access_delta": focus_delta,
        "topdeck_anchor_access_delta_total": topdeck_anchor_delta,
        "pressure_card_event_counts": pressure_events,
        "pressure_card_event_total": sum(pressure_events.values()),
        "pressure_conversion_event_counts": conversion_events,
        "pressure_conversion_event_total": sum(conversion_events.values()),
        "failure_flags": sorted(set(flags)),
        "promotion_allowed": False,
        "decision": known_candidate_decision(deck_key),
    }


def build_payload(gate_paths: Iterable[Path]) -> dict[str, Any]:
    candidate_summaries: list[dict[str, Any]] = []
    source_reports: list[str] = []
    for gate_path in gate_paths:
        gate = read_json(gate_path)
        source_reports.append(rel(gate_path))
        baseline = gate_row(gate, BASELINE_KEY)
        for candidate in candidate_rows(gate):
            candidate_summaries.append(
                candidate_summary(gate=gate, gate_path=gate_path, baseline=baseline, candidate=candidate)
            )

    flags = Counter(flag for item in candidate_summaries for flag in item["failure_flags"])
    blocking = [
        "head_to_head_not_won",
        "miracle_trace_missing",
        "topdeck_activation_missing",
        "topdeck_anchor_access_regressed",
        "pressure_causality_unproven",
        "pressure_conversion_unproven",
        "fast_pressure_slice_not_protected",
    ]
    payload = {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_miracle_trace_failure_miner",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": source_reports,
        "external_learning": EXTERNAL_LEARNING,
        "external_card_legality_snapshot": EXTERNAL_CARD_LEGALITY_SNAPSHOT,
        "internal_accessibility_snapshot": internal_accessibility_snapshot(),
        "status": "lorehold_miracle_trace_failure_learning_ready",
        "summary": {
            "candidate_count": len(candidate_summaries),
            "promotion_allowed": False,
            "keep_607_as_protected_baseline": True,
            "failure_flag_counts": dict(sorted(flags.items())),
            "blocking_failure_flags": [flag for flag in blocking if flags.get(flag)],
            "learned_priority_order": [
                "legal_identity_and_card_availability",
                "commander_intent_and_topdeck_miracle_density",
                "natural_access_to_topdeck_anchors",
                "trace_proof_that_miracle_window_executes",
                "pressure_or_mana_conversion_after_engine_floor_is_preserved",
                "same_seed_battle_gate_ties_or_beats_607",
            ],
            "next_shell_contract": "miracle_access_first_shell",
        },
        "candidate_summaries": candidate_summaries,
        "decision": {
            "promotion_allowed": False,
            "keep_607_as_protected_baseline": True,
            "do_not_expand_pressure_or_mana_without_miracle_trace": True,
            "recommended_next_actions": [
                "treat_mana_vault_and_the_one_ring_as_external_legal_staples_but_internal_unproven",
                "predeclare_anchor_access_floors_for_land_tax_scroll_rack_top_library_mind_stone_urzas_saga",
                "require_nonzero_miracle_cast_and_topdeck_activation_before_confirm_gate",
                "reject_any_candidate_that_loses_head_to_head_to_fixed_607_even_if_structural_matrix_ranks_high",
            ],
        },
    }
    return payload


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Miracle Trace Failure Miner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- candidate_count: `{summary['candidate_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- keep_607_as_protected_baseline: `{str(summary['keep_607_as_protected_baseline']).lower()}`",
        f"- next_shell_contract: `{summary['next_shell_contract']}`",
        f"- blocking_failure_flags: `{json.dumps(summary['blocking_failure_flags'])}`",
        "",
        "## Candidate Gate Summary",
        "",
        "| Candidate | Record | vs 607 | Miracle | Topdeck | Anchor Access Delta | Flags | Decision |",
        "| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |",
    ]
    for item in payload.get("candidate_summaries") or []:
        record_text = (
            f"{item['candidate_record']['wins']}W/"
            f"{item['candidate_record']['losses']}L/"
            f"{item['candidate_record']['stalls']}S"
        )
        h2h = item["head_to_head_vs_607"]
        h2h_text = f"{h2h['wins']}W/{h2h['losses']}L/{h2h['stalls']}S"
        lines.append(
            "| {candidate} | `{record}` | `{h2h}` | `{miracle}` | `{topdeck}` | `{anchor}` | `{flags}` | `{decision}` |".format(
                candidate=item["candidate_key"],
                record=record_text,
                h2h=h2h_text,
                miracle=item["strategic_counts"].get("miracle_cast", 0),
                topdeck=item["strategic_counts"].get("topdeck_manipulation_activated", 0),
                anchor=item["topdeck_anchor_access_delta_total"],
                flags=json.dumps(item["failure_flags"]),
                decision=item["decision"],
            )
        )

    lines.extend(
        [
            "",
            "## External Learning Applied",
            "",
        ]
    )
    for item in payload.get("external_learning") or []:
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - {item['learning']}")

    lines.extend(["", "## Staple Accessibility Snapshot", ""])
    for name, card in (payload.get("external_card_legality_snapshot") or {}).items():
        lines.append(
            "- {name}: commander `{commander}`, color_identity `{identity}`, edhrec_rank `{rank}`, source {source}".format(
                name=name,
                commander=card["commander"],
                identity=json.dumps(card["color_identity"]),
                rank=card.get("edhrec_rank"),
                source=card["source"],
            )
        )
        lines.append(f"  - {card['interpretation']}")

    internal = payload.get("internal_accessibility_snapshot") or {}
    lines.extend(
        [
            "",
            "## Internal Accessibility Snapshot",
            "",
            f"- source_db: `{internal.get('source_db', '')}`",
        ]
    )
    for name, payload_card in (internal.get("cards") or {}).items():
        card_summary = payload_card.get("summary") or {}
        rule_rows = payload_card.get("battle_rules") or []
        rule_statuses = [
            f"{row.get('review_status')}/{row.get('execution_status')}"
            for row in rule_rows
        ]
        lines.append(
            "- {name}: oracle_cache `{oracle}`, runtime_rule `{runtime}`, in_607 `{in607}`, in_615 `{in615}`, blocker `{blocker}`".format(
                name=name,
                oracle=str(card_summary.get("in_card_oracle_cache")).lower(),
                runtime=str(card_summary.get("has_executable_runtime_rule")).lower(),
                in607=str(card_summary.get("present_in_protected_607")).lower(),
                in615=str(card_summary.get("present_in_deck_615_challenger")).lower(),
                blocker=card_summary.get("blocker_for_607"),
            )
        )
        lines.append(f"  - rule_statuses: `{json.dumps(rule_statuses)}`")
        lines.append(f"  - known_deck_ids: `{json.dumps(card_summary.get('known_deck_ids') or [])}`")

    lines.extend(
        [
            "",
            "## Learned Priority Order",
            "",
        ]
    )
    for index, item in enumerate(summary["learned_priority_order"], start=1):
        lines.append(f"{index}. {item}")

    lines.extend(["", "## Decision", ""])
    for action in payload["decision"]["recommended_next_actions"]:
        lines.append(f"- {action}")
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
    parser.add_argument("--gate", action="append", type=Path, dest="gates")
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    gate_paths = args.gates or DEFAULT_GATE_PATHS
    payload = build_payload(gate_paths)
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "promotion_allowed": payload["summary"]["promotion_allowed"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
