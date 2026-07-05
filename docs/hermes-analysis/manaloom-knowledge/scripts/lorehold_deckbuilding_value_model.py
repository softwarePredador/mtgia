#!/usr/bin/env python3
"""Build a Lorehold deckbuilding value model from current evidence.

The model is deliberately conservative: it explains card value, protected
anchors, land/ramp/staple policy, and current watchlist cards without promoting
any deck change. Battle gates remain the only promotion path.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter, defaultdict
from collections.abc import Iterable, Mapping, Sequence
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
KNOWLEDGE_DB = SCRIPT_DIR / "knowledge.db"

DEFAULT_DECK_ID = 607
DEFAULT_VARIANT_DECK_IDS = tuple(range(608, 617))
DEFAULT_PREFLIGHT = REPORT_DIR / "lorehold_miracle_access_first_preflight_20260704_current.json"
DEFAULT_TRACE_MINER = REPORT_DIR / "lorehold_miracle_trace_failure_miner_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current"

PROTECTED_ANCHORS = {
    "Approach of the Second Sun",
    "Bender's Waterskin",
    "Creative Technique",
    "Insurrection",
    "Land Tax",
    "Library of Leng",
    "Lorehold, the Historian",
    "Mizzix's Mastery",
    "Molecule Man",
    "Monument to Endurance",
    "Scroll Rack",
    "Sensei's Divining Top",
    "Storm Herd",
    "The Mind Stone",
    "The Scarlet Witch",
    "Victory Chimes",
}
TOPDECK_ENGINE = {
    "Land Tax",
    "Library of Leng",
    "Lorehold, the Historian",
    "Molecule Man",
    "Scroll Rack",
    "Sensei's Divining Top",
    "The Mind Stone",
    "The Scarlet Witch",
    "Urza's Saga",
}
MIRACLE_CONVERSION_FINISHERS = {
    "Approach of the Second Sun",
    "Call Forth the Tempest",
    "Creative Technique",
    "Everything Comes to Dust",
    "Hit the Mother Lode",
    "Insurrection",
    "Mizzix's Mastery",
    "Rise of the Eldrazi",
    "Storm Herd",
    "Surge to Victory",
}
STRUCTURAL_RAMP_FLOOR = {
    "Arcane Signet",
    "Boros Signet",
    "Fellwar Stone",
    "Pearl Medallion",
    "Ruby Medallion",
    "Smothering Tithe",
    "Sol Ring",
    "Talisman of Conviction",
}
FAST_PRESSURE_GUARDS = {
    "Avatar's Wrath",
    "Dawn's Truce",
    "Deflecting Swat",
    "Farewell",
    "Flawless Maneuver",
    "Giver of Runes",
    "Lightning Greaves",
    "Mother of Runes",
    "Redirect Lightning",
    "Swiftfoot Boots",
    "Teferi's Protection",
    "Tibalt's Trickery",
}
PRIOR_TESTED_REJECTS = {
    "Birgi, God of Storytelling // Harnfel, Horn of Bounty": "same-macro signal but not confirmed as final 607 change",
    "Cloud Key": "lost same-lane Bender's Waterskin benchmark and regressed miracle cadence",
    "Electro, Assaulting Battery": "lost same-lane Bender's Waterskin benchmark and regressed Winota",
    "Enlightened Tutor": "coherent tutor, but tested 607 cuts lost natural confirmation",
    "Gamble": "coherent tutor, but tested 607 cuts lost natural confirmation",
    "Mana Vault": "internally available and runtime-modeled, but one-card Bender's Waterskin replacement lost",
    "Possibility Storm": "same-lane Creative Technique benchmark lost and had weak used-game outcome sample",
    "Storm-Kiln Artist": "real runtime signal, but Arcane Signet replacement regressed fast pressure",
    "The One Ring": "internally available and runtime-modeled, but tested value/draw cuts lost to 607",
}
LAND_GROUPS = {
    "basic_floor": {
        "Mountain // Mountain",
        "Plains // Plains",
    },
    "fetch_or_search_fixing": {
        "Arid Mesa",
        "Bloodstained Mire",
        "Flooded Strand",
        "Marsh Flats",
        "Prismatic Vista",
        "Scalding Tarn",
        "Windswept Heath",
        "Wooded Foothills",
    },
    "typed_dual_or_fetch_target": {
        "Elegant Parlor",
        "Glittering Massif",
        "Radiant Summit",
        "Sacred Foundry",
        "Turbulent Steppe",
    },
    "untapped_or_multiplayer_fixing": {
        "Battlefield Forge",
        "Command Tower",
        "Exotic Orchard",
        "Spectator Seating",
        "Sunbillow Verge",
    },
    "utility_engine_land": {
        "Ancient Tomb",
        "Command Beacon",
        "Eiganjo, Seat of the Empire",
        "Plaza of Heroes",
        "Reliquary Tower",
        "Sunbaked Canyon",
        "Urza's Saga",
        "War Room",
    },
}

EXTERNAL_RESEARCH = [
    {
        "source": "Wizards Commander format",
        "url": "https://magic.wizards.com/en/formats/commander",
        "learning": "Official format and color identity are entry gates, not proof of card quality.",
    },
    {
        "source": "Scryfall Lorehold Oracle",
        "url": "https://scryfall.com/card/sos/201/lorehold-the-historian",
        "learning": "Lorehold grants miracle to instants and sorceries and rummages on each opponent upkeep.",
    },
    {
        "source": "EDHREC Optimized Topdeck Lorehold",
        "url": "https://edhrec.com/commanders/lorehold-the-historian/optimized/topdeck",
        "learning": "Current commander-context signal is Topdeck plus Spellslinger; Scroll Rack and Sensei's Top are high-synergy cards.",
    },
    {
        "source": "EDHREC Miracles Every Turn",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "learning": "Library of Leng plus upkeep rummage is a core miracle setup pattern.",
    },
    {
        "source": "EDHREC Ramp in Commander",
        "url": "https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander",
        "learning": "Ramp is about outpacing the curve; in Lorehold it must also preserve commander timing and miracle cadence.",
    },
    {
        "source": "Card Kingdom ramp/draw article",
        "url": "https://blog.cardkingdom.com/whats-better-in-commander-card-draw-or-ramp/",
        "learning": "Ramp and draw are structural pillars, but pillar counts do not replace commander-specific package proof.",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def normalize_name(value: str) -> str:
    return " ".join(value.lower().replace("\u2019", "'").split())


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def as_float(value: Any) -> float:
    try:
        return float(value or 0.0)
    except Exception:
        return 0.0


def sqlite_rows(db_path: Path, query: str, params: Sequence[Any] = ()) -> list[dict[str, Any]]:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        return [dict(row) for row in conn.execute(query, params).fetchall()]
    finally:
        conn.close()


def deck_rows(db_path: Path, deck_id: int) -> list[dict[str, Any]]:
    return sqlite_rows(
        db_path,
        """
        SELECT id, deck_id, card_name, quantity, functional_tag, tag_confidence,
               is_commander, cmc, type_line, oracle_text, card_id,
               functional_tags_json, battle_rules_json
        FROM deck_cards
        WHERE deck_id = ?
        ORDER BY is_commander DESC, functional_tag, card_name
        """,
        (deck_id,),
    )


def battle_rule_index(db_path: Path) -> dict[str, list[dict[str, Any]]]:
    rules = sqlite_rows(
        db_path,
        """
        SELECT normalized_name, card_name, logical_rule_key, effect_json,
               deck_role_json, source, confidence, review_status,
               execution_status, rule_version
        FROM battle_card_rules
        ORDER BY normalized_name, logical_rule_key
        """,
    )
    out: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for rule in rules:
        out[normalize_name(str(rule.get("normalized_name") or rule.get("card_name") or ""))].append(rule)
    return out


def format_staple_index(db_path: Path) -> dict[str, dict[str, Any]]:
    rows = sqlite_rows(
        db_path,
        """
        SELECT card_name, format, archetype, category, color_identity,
               edhrec_rank, is_banned
        FROM format_staples
        WHERE format = 'commander'
        ORDER BY card_name, edhrec_rank
        """,
    )
    grouped: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(str(row.get("card_name") or ""))
        target = grouped.setdefault(
            key,
            {
                "card_name": row.get("card_name"),
                "best_edhrec_rank": None,
                "categories": set(),
                "archetypes": set(),
                "is_banned": False,
            },
        )
        rank = as_int(row.get("edhrec_rank"))
        if rank and (target["best_edhrec_rank"] is None or rank < target["best_edhrec_rank"]):
            target["best_edhrec_rank"] = rank
        for field in ("category", "archetype"):
            value = str(row.get(field) or "").strip()
            if value:
                target[f"{field}s"].add(value)
        target["is_banned"] = target["is_banned"] or bool(as_int(row.get("is_banned")))
    return {
        key: {
            **value,
            "categories": sorted(value["categories"]),
            "archetypes": sorted(value["archetypes"]),
        }
        for key, value in grouped.items()
    }


def variant_watchlist(db_path: Path, deck_id: int, variant_deck_ids: Sequence[int]) -> list[dict[str, Any]]:
    placeholders = ",".join("?" for _ in variant_deck_ids)
    rows = sqlite_rows(
        db_path,
        f"""
        SELECT lower(v.card_name) AS key_name,
               MIN(v.card_name) AS card_name,
               COUNT(DISTINCT v.deck_id) AS variant_deck_count,
               GROUP_CONCAT(DISTINCT v.deck_id) AS variant_deck_ids,
               MIN(v.functional_tag) AS example_functional_tag,
               MIN(v.cmc) AS cmc,
               MIN(v.type_line) AS type_line
        FROM deck_cards v
        WHERE v.deck_id IN ({placeholders})
          AND lower(v.card_name) NOT IN (
            SELECT lower(card_name)
            FROM deck_cards
            WHERE deck_id = ?
          )
        GROUP BY lower(v.card_name)
        ORDER BY variant_deck_count DESC, card_name
        """,
        (*variant_deck_ids, deck_id),
    )
    return rows


def land_group(card_name: str) -> str:
    for group, names in LAND_GROUPS.items():
        if card_name in names:
            return group
    return "other_land"


def has_runtime(rule_rows: Iterable[Mapping[str, Any]]) -> bool:
    for rule in rule_rows:
        if str(rule.get("execution_status")) == "auto" and str(rule.get("review_status")) in {"active", "verified"}:
            return True
    return False


def staple_tier(staple: Mapping[str, Any] | None) -> str:
    if not staple:
        return "not_format_staple"
    rank = as_int(staple.get("best_edhrec_rank"))
    if rank and rank <= 100:
        return "global_top_100"
    if rank and rank <= 500:
        return "global_top_500"
    if rank:
        return "format_staple_long_tail"
    return "format_staple_unranked"


def classify_card(row: Mapping[str, Any], staple: Mapping[str, Any] | None, runtime_ready: bool) -> dict[str, Any]:
    name = str(row.get("card_name") or "")
    tag = str(row.get("functional_tag") or "")
    type_line = str(row.get("type_line") or "")
    lanes: list[str] = []
    if as_int(row.get("is_commander")):
        lanes.append("commander_center")
    if tag == "land":
        lanes.extend(["mana_base", land_group(name)])
    if name in TOPDECK_ENGINE:
        lanes.append("topdeck_miracle_engine")
    if name in MIRACLE_CONVERSION_FINISHERS:
        lanes.append("miracle_conversion_finisher")
    if name in STRUCTURAL_RAMP_FLOOR:
        lanes.append("structural_ramp_floor")
    if name in FAST_PRESSURE_GUARDS:
        lanes.append("fast_pressure_guard")
    if tag and tag not in lanes:
        lanes.append(tag)
    if "Artifact" in type_line:
        lanes.append("artifact")
    if "Instant" in type_line or "Sorcery" in type_line:
        lanes.append("instant_sorcery_spell")
    if staple:
        lanes.append(staple_tier(staple))

    score = 0
    if name in PROTECTED_ANCHORS:
        score += 100
    if as_int(row.get("is_commander")):
        score += 80
    if name in TOPDECK_ENGINE:
        score += 40
    if name in MIRACLE_CONVERSION_FINISHERS:
        score += 28
    if name in STRUCTURAL_RAMP_FLOOR:
        score += 20
    if tag == "land":
        score += 18
    if name in FAST_PRESSURE_GUARDS:
        score += 18
    if runtime_ready:
        score += 10
    tier = staple_tier(staple)
    if tier == "global_top_100":
        score += 9
    elif tier == "global_top_500":
        score += 6
    elif tier == "format_staple_long_tail":
        score += 3

    if name in PROTECTED_ANCHORS or as_int(row.get("is_commander")):
        value_tier = "tier_0_protected_engine_or_anchor"
        cut_policy = "no_generic_cut_same_lane_battle_proof_required"
    elif tag == "land" or name in STRUCTURAL_RAMP_FLOOR or name in FAST_PRESSURE_GUARDS:
        value_tier = "tier_1_structural_floor"
        cut_policy = "protect_floor_same_role_upgrade_and_gate_required"
    elif name in MIRACLE_CONVERSION_FINISHERS or "instant_sorcery_spell" in lanes:
        value_tier = "tier_2_commander_contextual_synergy"
        cut_policy = "same_lane_or_package_proof_required"
    else:
        value_tier = "tier_3_role_filler_with_battle_context"
        cut_policy = "review_with_exposure_trace_before_cut"

    return {
        "card_name": name,
        "quantity": as_int(row.get("quantity")),
        "functional_tag": tag,
        "cmc": as_float(row.get("cmc")),
        "type_line": type_line,
        "is_commander": bool(as_int(row.get("is_commander"))),
        "lanes": sorted(set(lanes)),
        "runtime_ready": runtime_ready,
        "staple_tier": tier,
        "best_edhrec_rank": staple.get("best_edhrec_rank") if staple else None,
        "value_score": score,
        "value_tier": value_tier,
        "cut_policy": cut_policy,
        "protected_anchor": name in PROTECTED_ANCHORS,
    }


def classify_watchlist_card(row: Mapping[str, Any], staple: Mapping[str, Any] | None, runtime_ready: bool) -> dict[str, Any]:
    name = str(row.get("card_name") or "")
    reason = PRIOR_TESTED_REJECTS.get(name)
    status = "watchlist_unproven_do_not_auto_include"
    if reason:
        status = "prior_tested_reject_or_caveat_do_not_auto_include"
    return {
        "card_name": name,
        "variant_deck_count": as_int(row.get("variant_deck_count")),
        "variant_deck_ids": [as_int(item) for item in str(row.get("variant_deck_ids") or "").split(",") if item],
        "example_functional_tag": row.get("example_functional_tag"),
        "cmc": as_float(row.get("cmc")),
        "type_line": row.get("type_line"),
        "runtime_ready": runtime_ready,
        "staple_tier": staple_tier(staple),
        "best_edhrec_rank": staple.get("best_edhrec_rank") if staple else None,
        "candidate_status": status,
        "reason": reason or "appears in variants but lacks current 607 safe-cut and equal-gate proof",
    }


def role_profile(cards: Iterable[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for card in cards:
        counts[str(card.get("functional_tag") or "unknown")] += as_int(card.get("quantity"))
    return dict(sorted(counts.items()))


def lane_profile(cards: Iterable[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for card in cards:
        for lane in card.get("lanes") or []:
            counts[str(lane)] += as_int(card.get("quantity"))
    return dict(sorted(counts.items()))


def mana_foundation(cards: Iterable[Mapping[str, Any]]) -> dict[str, Any]:
    card_list = list(cards)
    lands = [card for card in card_list if card.get("functional_tag") == "land"]
    ramp = [card for card in card_list if card.get("functional_tag") == "ramp"]
    land_groups: Counter[str] = Counter()
    for card in lands:
        for lane in card.get("lanes") or []:
            if lane in LAND_GROUPS or lane == "other_land":
                land_groups[lane] += as_int(card.get("quantity"))
    artifact_ramp = sum(as_int(card.get("quantity")) for card in ramp if "artifact" in (card.get("lanes") or []))
    instant_sorcery_ramp = sum(
        as_int(card.get("quantity")) for card in ramp if "instant_sorcery_spell" in (card.get("lanes") or [])
    )
    enchantment_ramp = sum(as_int(card.get("quantity")) for card in ramp if "Enchantment" in str(card.get("type_line") or ""))
    return {
        "land_quantity": sum(as_int(card.get("quantity")) for card in lands),
        "land_rows": len(lands),
        "land_groups": dict(sorted(land_groups.items())),
        "ramp_quantity": sum(as_int(card.get("quantity")) for card in ramp),
        "artifact_ramp_quantity": artifact_ramp,
        "instant_sorcery_ramp_quantity": instant_sorcery_ramp,
        "enchantment_ramp_quantity": enchantment_ramp,
        "mana_sources_land_plus_ramp": sum(as_int(card.get("quantity")) for card in lands + ramp),
        "interpretation": (
            "The 607 mana plan is not just more fast mana: it combines 34 lands, fetch/dual fixing, "
            "artifact ramp, spell ramp, and opponent-turn mana rocks that feed miracle windows."
        ),
    }


def top_cards(cards: Sequence[Mapping[str, Any]], tier: str, limit: int = 20) -> list[dict[str, Any]]:
    filtered = [dict(card) for card in cards if card.get("value_tier") == tier]
    filtered.sort(key=lambda row: (-as_int(row.get("value_score")), str(row.get("card_name"))))
    return filtered[:limit]


def build_payload(
    *,
    db_path: Path = KNOWLEDGE_DB,
    deck_id: int = DEFAULT_DECK_ID,
    variant_deck_ids: Sequence[int] = DEFAULT_VARIANT_DECK_IDS,
    preflight_path: Path = DEFAULT_PREFLIGHT,
    trace_path: Path = DEFAULT_TRACE_MINER,
) -> dict[str, Any]:
    rows = deck_rows(db_path, deck_id)
    rules = battle_rule_index(db_path)
    staples = format_staple_index(db_path)
    classified = []
    for row in rows:
        key = normalize_name(str(row.get("card_name") or ""))
        classified.append(classify_card(row, staples.get(key), has_runtime(rules.get(key, []))))
    classified.sort(key=lambda row: (-as_int(row.get("value_score")), str(row.get("card_name"))))

    watchlist_rows = variant_watchlist(db_path, deck_id, variant_deck_ids)
    watchlist = []
    for row in watchlist_rows:
        key = normalize_name(str(row.get("card_name") or ""))
        if row.get("card_name") in PRIOR_TESTED_REJECTS or as_int(row.get("variant_deck_count")) >= 3:
            watchlist.append(classify_watchlist_card(row, staples.get(key), has_runtime(rules.get(key, []))))
    watchlist.sort(
        key=lambda row: (
            0 if row["card_name"] in PRIOR_TESTED_REJECTS else 1,
            -as_int(row.get("variant_deck_count")),
            str(row.get("card_name")),
        )
    )

    preflight = read_json(preflight_path)
    trace = read_json(trace_path)
    tier_names = [
        "tier_0_protected_engine_or_anchor",
        "tier_1_structural_floor",
        "tier_2_commander_contextual_synergy",
        "tier_3_role_filler_with_battle_context",
    ]
    payload = {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_deckbuilding_value_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [rel(preflight_path), rel(trace_path)],
        "external_research": EXTERNAL_RESEARCH,
        "status": "lorehold_value_model_ready_607_remains_protected",
        "summary": {
            "deck_id": deck_id,
            "card_rows": len(rows),
            "quantity_total": sum(as_int(row.get("quantity")) for row in rows),
            "commander_count": sum(as_int(row.get("quantity")) for row in rows if as_int(row.get("is_commander"))),
            "role_profile": role_profile(classified),
            "lane_profile": lane_profile(classified),
            "mana_foundation": mana_foundation(classified),
            "preflight_status": preflight.get("status"),
            "gate_ready_now_count": as_int((preflight.get("summary") or {}).get("gate_ready_now_count")),
            "trace_status": trace.get("status"),
            "keep_607_as_protected_baseline": True,
            "promotion_allowed": False,
        },
        "value_tiers": {tier: top_cards(classified, tier) for tier in tier_names},
        "all_card_values": classified,
        "variant_watchlist": watchlist[:40],
        "policy": {
            "lands": "Protect the 34-land mana foundation unless a same-function mana-source model and battle gate prove improvement.",
            "ramp": "Prefer ramp that preserves commander timing and opponent-turn miracle windows; fast mana alone is not sufficient.",
            "artifacts": "Artifact value is high only when it serves topdeck, miracle, ramp timing, or protection lanes.",
            "staples": "Global staples are candidates or floors, not automatic cuts over protected commander engines.",
            "cuts": "Any cut must be same-lane or package-declared and must satisfy miracle_access_first_shell_v1 before natural gate.",
        },
        "decision": {
            "current_best_baseline": "deck_607",
            "current_best_baseline_reason": (
                "Current evidence has no gate-ready challenger, and the protected 607 list preserves the strongest "
                "combination of mana foundation, topdeck/miracle anchors, protection, and proven finishers."
            ),
            "next_action": "use_value_model_to_design_multi_card_shell_or_forced_access_diagnostic_before_any_natural_gate",
        },
    }
    return payload


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    mana = summary["mana_foundation"]
    lines = [
        "# Lorehold Deckbuilding Value Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- quantity_total: `{summary['quantity_total']}`",
        f"- commander_count: `{summary['commander_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- keep_607_as_protected_baseline: `{str(summary['keep_607_as_protected_baseline']).lower()}`",
        f"- preflight_status: `{summary['preflight_status']}`",
        f"- gate_ready_now_count: `{summary['gate_ready_now_count']}`",
        "",
        "## Role And Mana Model",
        "",
        f"- role_profile: `{json.dumps(summary['role_profile'], sort_keys=True)}`",
        f"- land_quantity: `{mana['land_quantity']}`",
        f"- ramp_quantity: `{mana['ramp_quantity']}`",
        f"- mana_sources_land_plus_ramp: `{mana['mana_sources_land_plus_ramp']}`",
        f"- land_groups: `{json.dumps(mana['land_groups'], sort_keys=True)}`",
        f"- interpretation: {mana['interpretation']}",
        "",
        "## Value Tiers",
        "",
    ]
    for tier, cards in payload["value_tiers"].items():
        lines.append(f"### {tier}")
        for card in cards[:12]:
            lines.append(
                "- `{name}` score `{score}` lanes `{lanes}` cut_policy `{policy}`".format(
                    name=card["card_name"],
                    score=card["value_score"],
                    lanes=",".join(card["lanes"]),
                    policy=card["cut_policy"],
                )
            )
        lines.append("")

    lines.extend(["## Variant Watchlist", ""])
    for card in payload.get("variant_watchlist") or []:
        lines.append(
            "- `{name}` variants `{count}` status `{status}` reason: {reason}".format(
                name=card["card_name"],
                count=card["variant_deck_count"],
                status=card["candidate_status"],
                reason=card["reason"],
            )
        )

    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")

    lines.extend(["", "## External Research", ""])
    for item in payload.get("external_research") or []:
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - {item['learning']}")

    lines.extend(["", "## Decision", ""])
    lines.append(f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`")
    lines.append(f"- reason: {payload['decision']['current_best_baseline_reason']}")
    lines.append(f"- next_action: `{payload['decision']['next_action']}`")
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
    parser.add_argument("--db", type=Path, default=KNOWLEDGE_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_DECK_ID)
    parser.add_argument("--preflight", type=Path, default=DEFAULT_PREFLIGHT)
    parser.add_argument("--trace", type=Path, default=DEFAULT_TRACE_MINER)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        db_path=args.db,
        deck_id=args.deck_id,
        preflight_path=args.preflight,
        trace_path=args.trace,
    )
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
