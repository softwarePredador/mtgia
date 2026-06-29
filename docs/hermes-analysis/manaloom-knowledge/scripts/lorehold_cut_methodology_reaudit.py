#!/usr/bin/env python3
"""Reaudit Lorehold 607 cut methodology after the 615 mana-engine candidate.

This audit is deliberately read-only. It separates "the added card is useful"
from "the removed card was the correct slot to cut", because those are different
claims in the Commander deckbuilding contract.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

from lorehold_strategy_profile import STRATEGY_VERSION, strategy_tags_for_card


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_SOURCE_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_VALIDATION_REPORT = REPORT_DIR / "lorehold_molecule_scarlet_validation_20260629.json"
DEFAULT_CANDIDATE_REPORT = (
    REPORT_DIR / "lorehold_607_research_candidate_20260629_v615_mana_engine_v1.json"
)


EXTERNAL_STATS_SNAPSHOT = {
    "source": "EDHREC Lorehold, the Historian commander page",
    "source_url": "https://edhrec.com/commanders/lorehold-the-historian",
    "retrieved_at": "2026-06-29",
    "cards": {
        "Molecule Man": {
            "inclusion_pct": 10.0,
            "deck_count": 115,
            "denominator": 1190,
            "synergy_pct": 9.0,
            "note": "direct topdeck/miracle support bucket",
        },
        "The Scarlet Witch": {
            "inclusion_pct": 6.3,
            "deck_count": 103,
            "denominator": 1650,
            "synergy_pct": 5.0,
            "note": "MV4+ instant/sorcery cost-reduction support bucket",
        },
        "The One Ring": {
            "inclusion_pct": 8.4,
            "deck_count": 744,
            "denominator": 8880,
            "synergy_pct": 2.0,
            "note": "generic draw/protection value bucket",
        },
        "Mana Vault": {
            "inclusion_pct": 5.6,
            "deck_count": 500,
            "denominator": 8880,
            "synergy_pct": 2.0,
            "note": "fast-mana bucket",
        },
        "Bender's Waterskin": {
            "inclusion_pct": 71.0,
            "deck_count": 6300,
            "denominator": 8880,
            "synergy_pct": 65.0,
            "note": "commander-release mana-rock bucket",
        },
        "Birgi, God of Storytelling // Harnfel, Horn of Bounty": {
            "inclusion_pct": 7.3,
            "deck_count": 647,
            "denominator": 8880,
            "synergy_pct": 4.0,
            "note": "spell-chain mana and Harnfel impulse bucket",
        },
    },
}


SCRYFALL_ORACLE_SOURCES = {
    "Lorehold, the Historian": "https://scryfall.com/card/sos/201/lorehold-the-historian",
    "Molecule Man": "https://scryfall.com/card/msc/9/molecule-man",
    "The Scarlet Witch": "https://scryfall.com/card/msh/151/the-scarlet-witch",
    "The One Ring": "https://scryfall.com/card/ltr/246/the-one-ring",
    "Mana Vault": "https://scryfall.com/card/2x2/308/mana-vault",
    "Bender's Waterskin": "https://scryfall.com/card/tla/255/benders-waterskin",
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty": (
        "https://scryfall.com/card/khm/123/birgi-god-of-storytelling-harnfel-horn-of-bounty"
    ),
}


CARD_LANE_MODEL = {
    "mana vault": {
        "primary_lane": "early_mana",
        "macro_lane": "mana_engine",
        "secondary_lanes": ["spell_chain_mana", "fast_mana"],
        "commander_directness": 7,
    },
    "benders waterskin": {
        "primary_lane": "early_mana",
        "macro_lane": "mana_engine",
        "secondary_lanes": ["mana_fixing", "opponent_turn_mana"],
        "commander_directness": 8,
    },
    "birgi god of storytelling harnfel horn of bounty": {
        "primary_lane": "spell_chain_mana",
        "macro_lane": "spell_chain_conversion",
        "secondary_lanes": ["hand_filter", "impulse_access"],
        "commander_directness": 8,
    },
    "the scarlet witch": {
        "primary_lane": "mv4_spell_cost_reduction",
        "macro_lane": "spell_chain_conversion",
        "secondary_lanes": ["expensive_instant_sorcery_discount"],
        "commander_directness": 8,
    },
    "the one ring": {
        "primary_lane": "draw_protection_value",
        "macro_lane": "value_protection",
        "secondary_lanes": ["hand_velocity", "protection_window", "mind_stone_reset"],
        "commander_directness": 5,
    },
    "molecule man": {
        "primary_lane": "miracle_zero_engine",
        "macro_lane": "topdeck_miracle_engine",
        "secondary_lanes": ["topdeck_miracle_setup", "spell_chain_conversion"],
        "commander_directness": 10,
    },
}


PROMOTED_PAIRS = [
    {
        "add": "Mana Vault",
        "cut": "Bender's Waterskin",
        "original_claim": "faster ramp / early mana replacement",
    },
    {
        "add": "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
        "cut": "The Scarlet Witch",
        "original_claim": "spell-chain mana over spell cost-reduction slot",
    },
    {
        "add": "The One Ring",
        "cut": "Molecule Man",
        "original_claim": "draw/protection value over low-observed miracle-zero engine",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def normalize_name(value: object) -> str:
    text = str(value or "") if value else ""
    text = text.replace("'", "")
    text = re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()
    return re.sub(r"\s+", " ", text)


def pair_key(add: str, cut: str) -> str:
    return f"{normalize_name(add).replace(' ', '_')}_over_{normalize_name(cut).replace(' ', '_')}"


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def parse_json_list(value: object) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value if item]
    if not isinstance(value, str) or not value.strip():
        return []
    try:
        payload = json.loads(value)
    except Exception:
        return []
    if not isinstance(payload, list):
        return []
    return [str(item) for item in payload if item]


def fetch_card_row(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    rows = conn.execute(
        """
        SELECT deck_id, card_name, functional_tag, functional_tags_json, cmc,
               type_line, oracle_text
        FROM deck_cards
        WHERE lower(card_name) = lower(?)
        ORDER BY CASE deck_id
            WHEN 6 THEN 0
            WHEN 607 THEN 1
            WHEN 615 THEN 2
            ELSE 3
        END, deck_id
        """,
        (card_name,),
    ).fetchall()
    if not rows:
        return {"card_name": card_name, "missing": True}
    row = dict(rows[0])
    roles = parse_json_list(row.get("functional_tags_json"))
    if row.get("functional_tag") and str(row.get("functional_tag")) not in roles:
        roles.append(str(row.get("functional_tag")))
    card = {
        "card_name": row.get("card_name"),
        "name": row.get("card_name"),
        "roles": roles,
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line"),
        "oracle_text": row.get("oracle_text"),
        "is_land": "land" in str(row.get("type_line") or "").lower(),
    }
    row["roles"] = roles
    row["strategy_tags"] = sorted(strategy_tags_for_card(card))
    row["source_deck_id"] = row.get("deck_id")
    return row


def external_stats(card_name: str) -> dict[str, Any]:
    return dict(EXTERNAL_STATS_SNAPSHOT["cards"].get(card_name, {}))


def card_profile(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    row = fetch_card_row(conn, card_name)
    lane = dict(CARD_LANE_MODEL.get(normalize_name(card_name), {}))
    stats = external_stats(card_name)
    protected_reasons: list[str] = []
    if card_name == "Molecule Man":
        protected_reasons.append("direct miracle-zero engine for Lorehold's commander text")
    if card_name == "The Scarlet Witch":
        protected_reasons.append("direct MV4+ instant/sorcery cost-reduction engine")
    if card_name == "Bender's Waterskin":
        protected_reasons.append("prior cut-safety manifest marked it risky_cut_only_same_lane")
    if float(stats.get("synergy_pct") or 0.0) >= 5.0:
        protected_reasons.append("external commander-specific synergy >= 5%")
    if row.get("deck_id") == 607:
        protected_reasons.append("present in protected deck_607 baseline")
    return {
        "card_name": card_name,
        "source_deck_id": row.get("source_deck_id"),
        "roles": row.get("roles", []),
        "functional_tag": row.get("functional_tag"),
        "cmc": row.get("cmc"),
        "type_line": row.get("type_line"),
        "oracle_excerpt": str(row.get("oracle_text") or "")[:240],
        "strategy_tags": row.get("strategy_tags", []),
        "lane_model": lane,
        "external_stats": stats,
        "oracle_source_url": SCRYFALL_ORACLE_SOURCES.get(card_name),
        "protected_reasons": protected_reasons,
        "protected_anchor": bool(protected_reasons),
        "missing": bool(row.get("missing")),
    }


def lane_gate(add_profile: Mapping[str, Any], cut_profile: Mapping[str, Any]) -> dict[str, Any]:
    add_lane = add_profile.get("lane_model") or {}
    cut_lane = cut_profile.get("lane_model") or {}
    add_primary = str(add_lane.get("primary_lane") or "")
    cut_primary = str(cut_lane.get("primary_lane") or "")
    add_macro = str(add_lane.get("macro_lane") or "")
    cut_macro = str(cut_lane.get("macro_lane") or "")
    add_secondary = set(add_lane.get("secondary_lanes") or [])
    cut_secondary = set(cut_lane.get("secondary_lanes") or [])

    if add_primary and add_primary == cut_primary:
        status = "strict_same_lane"
        score = 40
    elif add_macro and add_macro == cut_macro:
        status = "same_macro_lane_needs_confirmation"
        score = 24
    elif add_primary in cut_secondary or cut_primary in add_secondary:
        status = "secondary_overlap_needs_explicit_hypothesis"
        score = 16
    else:
        status = "blocked_cross_lane_cut"
        score = 0

    return {
        "status": status,
        "score": score,
        "add_primary_lane": add_primary,
        "cut_primary_lane": cut_primary,
        "add_macro_lane": add_macro,
        "cut_macro_lane": cut_macro,
        "secondary_overlap": sorted(add_secondary.intersection(cut_secondary)),
    }


def metric_count(natural: Mapping[str, Any], deck_key: str, card_name: str, metric: str) -> int:
    card_events = ((natural.get(deck_key) or {}).get("card_events") or {}).get(card_name) or {}
    try:
        return int(card_events.get(metric) or 0)
    except Exception:
        return 0


def focus_count(natural: Mapping[str, Any], deck_key: str, card_name: str, metric: str) -> int:
    focus = ((natural.get(deck_key) or {}).get("focus") or {}).get(card_name) or {}
    try:
        return int(focus.get(metric) or 0)
    except Exception:
        return 0


def battle_row(natural: Mapping[str, Any], deck_key: str, card_name: str) -> dict[str, Any]:
    deck = natural.get(deck_key) or {}
    winota = deck.get("winota") or {}
    return {
        "deck_key": deck_key,
        "games": int(deck.get("games") or 0),
        "wins": int(deck.get("wins") or 0),
        "win_rate": float(deck.get("win_rate") or 0.0),
        "winota_wins": int(winota.get("wins") or 0),
        "winota_games": int(winota.get("games") or 0),
        "accessed_games": focus_count(natural, deck_key, card_name, "accessed_games"),
        "drawn_games": focus_count(natural, deck_key, card_name, "drawn_games"),
        "cost_paid": metric_count(natural, deck_key, card_name, "cost_paid"),
        "spell_cast": metric_count(natural, deck_key, card_name, "spell_cast"),
        "spell_resolved": metric_count(natural, deck_key, card_name, "spell_resolved"),
        "trigger_resolved": metric_count(natural, deck_key, card_name, "trigger_resolved"),
        "utility_artifact_activated": metric_count(natural, deck_key, card_name, "utility_artifact_activated"),
    }


def classify_pair(pair: Mapping[str, Any], lane: Mapping[str, Any], add: Mapping[str, Any], cut: Mapping[str, Any]) -> dict[str, Any]:
    add_name = str(pair["add"])
    cut_name = str(pair["cut"])
    add_stats = add.get("external_stats") or {}
    cut_stats = cut.get("external_stats") or {}
    add_synergy = float(add_stats.get("synergy_pct") or 0.0)
    cut_synergy = float(cut_stats.get("synergy_pct") or 0.0)
    external_delta = round(add_synergy - cut_synergy, 2)

    if lane["status"] == "blocked_cross_lane_cut":
        return {
            "status": "blocked_cross_lane_cut",
            "score": lane["score"],
            "decision": "do_not_use_this_cut_as_deck-quality_proof",
            "reason": (
                f"{add_name} and {cut_name} do different jobs. The added card may be useful, "
                "but this cut does not prove the right deck slot was removed."
            ),
        }
    if lane["status"] == "same_macro_lane_needs_confirmation":
        return {
            "status": "confirmation_required",
            "score": lane["score"] + (8 if external_delta >= 0 else 0),
            "decision": "same_macro_lane_but_not_final",
            "reason": (
                "The pair shares a macro spell-chain lane, but the local retest and "
                "external commander evidence are mixed enough to require a confirmation gate."
            ),
        }
    if add_name == "Mana Vault" and cut_name == "Bender's Waterskin":
        return {
            "status": "valid_same_lane_with_external_caveat",
            "score": lane["score"] + 16,
            "decision": "allowed_as_local_battle_supported_ramp_upgrade",
            "reason": (
                "This is a real early-mana slot comparison. EDHREC favors Bender strongly, "
                "so Mana Vault needs local battle/use proof instead of being treated as universally superior."
            ),
        }
    return {
        "status": "needs_confirmation",
        "score": lane["score"],
        "decision": "manual_confirmation_required",
        "reason": "Lane is not blocked, but the package still needs equal-gate and card-use proof.",
    }


def evaluate_pair(
    conn: sqlite3.Connection,
    pair: Mapping[str, Any],
    natural: Mapping[str, Any],
) -> dict[str, Any]:
    add_profile = card_profile(conn, str(pair["add"]))
    cut_profile = card_profile(conn, str(pair["cut"]))
    lane = lane_gate(add_profile, cut_profile)
    classification = classify_pair(pair, lane, add_profile, cut_profile)
    key = pair_key(str(pair["add"]), str(pair["cut"]))
    battle_evidence = {
        "promoted_candidate_add": battle_row(natural, "candidate_607_v615_mana_engine_v1", str(pair["add"])),
        "baseline_cut": battle_row(natural, "deck_607", str(pair["cut"])),
    }
    if pair["add"] == "The One Ring":
        battle_evidence["molecule_retest_cut_card"] = battle_row(
            natural, "candidate_607_v615_mana_engine_molecule_retest_v1", "Molecule Man"
        )
    if pair["add"] == "Birgi, God of Storytelling // Harnfel, Horn of Bounty":
        battle_evidence["scarlet_retest_cut_card"] = battle_row(
            natural, "candidate_607_v615_mana_engine_scarlet_retest_v1", "The Scarlet Witch"
        )
        battle_evidence["paired_restore_cut_card"] = battle_row(
            natural, "candidate_607_v615_mana_engine_molecule_scarlet_retest_v1", "The Scarlet Witch"
        )
    if pair["add"] == "Mana Vault":
        battle_evidence["paired_restore_add"] = battle_row(
            natural, "candidate_607_v615_mana_engine_molecule_scarlet_retest_v1", "Mana Vault"
        )
    add_stats = add_profile.get("external_stats") or {}
    cut_stats = cut_profile.get("external_stats") or {}
    return {
        "pair_key": key,
        "add": pair["add"],
        "cut": pair["cut"],
        "original_claim": pair.get("original_claim"),
        "lane_gate": lane,
        "classification": classification,
        "add_profile": add_profile,
        "cut_profile": cut_profile,
        "external_evidence": {
            "add_inclusion_pct": add_stats.get("inclusion_pct"),
            "cut_inclusion_pct": cut_stats.get("inclusion_pct"),
            "add_synergy_pct": add_stats.get("synergy_pct"),
            "cut_synergy_pct": cut_stats.get("synergy_pct"),
            "synergy_delta_pp": round(float(add_stats.get("synergy_pct") or 0.0) - float(cut_stats.get("synergy_pct") or 0.0), 2),
            "source_url": EXTERNAL_STATS_SNAPSHOT["source_url"],
        },
        "battle_evidence": battle_evidence,
    }


def build_report(
    source_db: Path = DEFAULT_SOURCE_DB,
    validation_report: Path = DEFAULT_VALIDATION_REPORT,
    candidate_report: Path = DEFAULT_CANDIDATE_REPORT,
) -> dict[str, Any]:
    validation = read_json(validation_report)
    candidate = read_json(candidate_report)
    natural = validation.get("natural") or {}
    with sqlite3.connect(source_db) as conn:
        conn.row_factory = sqlite3.Row
        pair_rows = [evaluate_pair(conn, pair, natural) for pair in PROMOTED_PAIRS]

    blocked_pairs = [
        row["pair_key"] for row in pair_rows if row["classification"]["status"] == "blocked_cross_lane_cut"
    ]
    confirmation_pairs = [
        row["pair_key"] for row in pair_rows if row["classification"]["status"] == "confirmation_required"
    ]
    allowed_pairs = [
        row["pair_key"]
        for row in pair_rows
        if row["classification"]["status"] == "valid_same_lane_with_external_caveat"
    ]

    return {
        "status": "ready",
        "generated_at": utc_now(),
        "strategy_version": STRATEGY_VERSION,
        "postgres_writes": False,
        "source_db_mutated": False,
        "source_db": rel(source_db),
        "validation_report": rel(validation_report),
        "candidate_report": rel(candidate_report),
        "external_stats_snapshot": EXTERNAL_STATS_SNAPSHOT,
        "scryfall_oracle_sources": SCRYFALL_ORACLE_SOURCES,
        "promoted_candidate_key": candidate.get("candidate_key") or "candidate_607_v615_mana_engine_v1",
        "metric_contract": [
            "hard lane equivalence: same primary lane, same macro lane, or explicit package hypothesis",
            "commander directness: how directly the card advances Lorehold miracle/spell-chain intent",
            "external commander evidence: EDHREC inclusion/synergy and public guide support",
            "local battle evidence: equal seed/opponent result plus drawn/cast/used events",
            "cut safety: protected anchors and previously failed cut signatures",
            "runtime readiness: rule is modeled before the battle result is trusted",
        ],
        "pairs": pair_rows,
        "decision": {
            "current_candidate_status": "battle_cleared_with_cut_methodology_caveat",
            "ready_for_real_deck_change": False,
            "blocked_pairs": blocked_pairs,
            "confirmation_pairs": confirmation_pairs,
            "allowed_pairs": allowed_pairs,
            "summary": (
                "The Mana Vault ramp swap is methodologically valid. Birgi over Scarlet is "
                "same-macro but needs confirmation. The One Ring over Molecule Man is a "
                "cross-lane cut and must not be used as proof that Molecule belongs out."
            ),
        },
        "next_deckbuilding_actions": [
            {
                "action": "freeze_cross_lane_cut_guard",
                "detail": "Future package candidates must fail preflight if an added card removes a protected anchor outside its functional lane.",
            },
            {
                "action": "one_ring_recut_only_in_draw_protection_value_lane",
                "detail": "The One Ring may still be useful, but it must compete with draw/protection/value slots, not Molecule Man.",
            },
            {
                "action": "scarlet_birgi_confirmation_lane",
                "detail": "Birgi and The Scarlet Witch need a focused same-macro confirmation with mana-produced and mana-saved telemetry.",
            },
            {
                "action": "molecule_preservation_lane",
                "detail": "Molecule Man stays protected as a direct miracle-zero hypothesis until a same-lane topdeck/miracle replacement beats it.",
            },
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    lines = [
        "# Lorehold Cut Methodology Reaudit - 2026-06-29",
        "",
        f"- status: `{payload['status']}`",
        f"- postgres_writes: `{str(payload['postgres_writes']).lower()}`",
        f"- source_db_mutated: `{str(payload['source_db_mutated']).lower()}`",
        f"- promoted_candidate_key: `{payload['promoted_candidate_key']}`",
        "",
        "## Correction",
        "",
        (
            "The previous candidate proved that the imported 615 package is battle-usable, "
            "but it did not prove every removed card was the correct slot. The specific "
            "cut `The One Ring` over `Molecule Man` is now classified as a cross-lane "
            "cut: draw/protection value versus miracle-zero engine."
        ),
        "",
        "## Metric Contract",
        "",
    ]
    for item in payload["metric_contract"]:
        lines.append(f"- {item}")

    lines.extend(
        [
            "",
            "## Pair Reaudit",
            "",
            "| Add | Cut | Lane Gate | Decision | External Synergy Delta | Key Local Evidence |",
            "| --- | --- | --- | --- | ---: | --- |",
        ]
    )
    for row in payload["pairs"]:
        ext = row["external_evidence"]
        battle = row["battle_evidence"]["promoted_candidate_add"]
        local = (
            f"{battle['wins']}/{battle['games']} deck wins; "
            f"add cast={battle['spell_cast']}; trigger={battle['trigger_resolved']}; "
            f"utility={battle['utility_artifact_activated']}"
        )
        lines.append(
            "| {add} | {cut} | `{lane}` | `{decision}` | {delta} | {local} |".format(
                add=row["add"],
                cut=row["cut"],
                lane=row["lane_gate"]["status"],
                decision=row["classification"]["decision"],
                delta=ext["synergy_delta_pp"],
                local=local,
            )
        )

    lines.extend(
        [
            "",
            "## External Evidence Snapshot",
            "",
            "| Card | Inclusion | Decks | Synergy | Lane Note |",
            "| --- | ---: | ---: | ---: | --- |",
        ]
    )
    for card, stats in payload["external_stats_snapshot"]["cards"].items():
        lines.append(
            f"| {card} | {stats['inclusion_pct']}% | {stats['deck_count']}/{stats['denominator']} | "
            f"{stats['synergy_pct']}% | {stats['note']} |"
        )

    decision = payload["decision"]
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- current_candidate_status: `{decision['current_candidate_status']}`",
            f"- ready_for_real_deck_change: `{str(decision['ready_for_real_deck_change']).lower()}`",
            f"- blocked_pairs: `{', '.join(decision['blocked_pairs']) or 'none'}`",
            f"- confirmation_pairs: `{', '.join(decision['confirmation_pairs']) or 'none'}`",
            f"- allowed_pairs: `{', '.join(decision['allowed_pairs']) or 'none'}`",
            "",
            decision["summary"],
            "",
            "## Required Next Actions",
            "",
        ]
    )
    for action in payload["next_deckbuilding_actions"]:
        lines.append(f"- `{action['action']}`: {action['detail']}")
    lines.append("")
    return "\n".join(lines)


def write_report(payload: Mapping[str, Any], out_prefix: Path) -> None:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    out_prefix.with_suffix(".json").write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_prefix.with_suffix(".md").write_text(render_markdown(payload), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--validation-report", type=Path, default=DEFAULT_VALIDATION_REPORT)
    parser.add_argument("--candidate-report", type=Path, default=DEFAULT_CANDIDATE_REPORT)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_cut_methodology_reaudit_20260629",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        source_db=args.source_db,
        validation_report=args.validation_report,
        candidate_report=args.candidate_report,
    )
    write_report(payload, args.out_prefix)
    print(f"wrote {args.out_prefix.with_suffix('.json')}")
    print(f"wrote {args.out_prefix.with_suffix('.md')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
