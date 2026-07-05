#!/usr/bin/env python3
"""Evaluate Lorehold 607 mana-base land candidates before any battle gate.

The model is intentionally conservative. It compares candidate lands against
the current protected 607 land package and emits safe-cut hypotheses, not deck
changes. A positive pair here is only ready for candidate materialization and
preflight, never direct promotion.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Mapping, Sequence
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
KNOWLEDGE_DB = SCRIPT_DIR / "knowledge.db"

DEFAULT_DECK_ID = 607
DEFAULT_HYPOTHESIS_QUEUE = REPORT_DIR / "lorehold_hypothesis_queue_from_value_model_20260705_current.json"
DEFAULT_VALUE_MODEL = REPORT_DIR / "lorehold_deckbuilding_value_model_20260704_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_mana_base_safe_cut_model_20260705_current"

MANA_BASE_CANDIDATES = (
    "Plateau",
    "Clifftop Retreat",
    "Boseiju, Who Shelters All",
    "Rugged Prairie",
    "Sundown Pass",
    "Boros Garrison",
    "Cavern of Souls",
)

PROTECTED_UTILITY_LANDS = {
    "Ancient Tomb": "fast_mana_life_cost_floor",
    "Command Beacon": "commander_tax_recovery",
    "Command Tower": "best_any_color_commander_source",
    "Eiganjo, Seat of the Empire": "untapped_white_plus_combat_removal",
    "Plaza of Heroes": "legendary_casting_and_lorehold_protection",
    "Reliquary Tower": "hand_size_for_rummage_and_big_draw",
    "Sunbaked Canyon": "untapped_color_source_plus_card_flow",
    "Urza's Saga": "artifact_tutor_for_topdeck_engine",
    "War Room": "colorless_card_flow",
}

TYPED_DUALS_WITH_TIMING_RISK = {
    "Elegant Parlor",
    "Glittering Massif",
    "Radiant Summit",
    "Turbulent Steppe",
}

EXTERNAL_RESEARCH_REFRESH = [
    {
        "source": "Scryfall Boros land oracle data",
        "url": "https://scryfall.com/search?as=grid&order=edhrec&q=t%3Aland+ci%3Drw&unique=cards",
        "learning": "Candidate land text must be judged by actual Oracle text, not only by EDH popularity.",
    },
    {
        "source": "Scryfall Plateau",
        "url": "https://scryfall.com/card/3ed/284/plateau",
        "learning": "Plateau is an untapped Mountain Plains, so it preserves fetch-target type while improving tempo over tapped typed lands.",
    },
    {
        "source": "EDHREC Lorehold average topdeck deck",
        "url": "https://edhrec.com/average-decks/lorehold-the-historian/topdeck",
        "learning": "Public topdeck shells include common Boros fixing such as Clifftop Retreat, but public average lists are evidence lanes, not cuts.",
    },
    {
        "source": "EDHREC Lorehold budget miracles",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "learning": "Lorehold mana base needs lands and utility that avoid dead miracle draws and support opponent-turn spell windows.",
    },
    {
        "source": "Draftsim Lorehold guide",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "learning": "External decklists also use Boseiju, Clifftop Retreat, Rugged Prairie, Sundown Pass, and utility lands, but still frame mana-base changes as budget/meta choices.",
    },
    {
        "source": "Commander deckbuilding contract",
        "url": "docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
        "learning": "Mana foundation, same-lane cuts, protected anchors, and battle/replay validation are separate gates.",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def as_int(value: Any) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def read_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def sqlite_rows(db_path: Path, query: str, params: Sequence[Any] = ()) -> list[dict[str, Any]]:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        return [dict(row) for row in conn.execute(query, params).fetchall()]
    finally:
        conn.close()


def normalize_name(name: str) -> str:
    return " ".join(name.lower().replace("\u2019", "'").split())


def deck_land_rows(db_path: Path, deck_id: int) -> list[dict[str, Any]]:
    return sqlite_rows(
        db_path,
        """
        SELECT card_name, quantity, type_line, oracle_text, functional_tag, cmc, card_id
        FROM deck_cards
        WHERE deck_id = ? AND functional_tag = 'land'
        ORDER BY card_name
        """,
        (deck_id,),
    )


def oracle_rows(db_path: Path, card_names: Sequence[str]) -> dict[str, dict[str, Any]]:
    if not card_names:
        return {}
    placeholders = ",".join("?" for _ in card_names)
    rows = sqlite_rows(
        db_path,
        f"""
        SELECT name AS card_name, type_line, oracle_text, cmc, card_id, scryfall_id,
               color_identity_json
        FROM card_oracle_cache
        WHERE lower(name) IN ({placeholders})
           OR lower(normalized_name) IN ({placeholders})
        ORDER BY name
        """,
        tuple(name.lower() for name in card_names) * 2,
    )
    return {normalize_name(str(row["card_name"])): row for row in rows}


def enters_tapped_profile(oracle_text: str) -> str:
    text = oracle_text.lower()
    if "enters tapped unless" in text:
        if "two or more opponents" in text:
            return "commander_expected_untapped"
        return "conditional_tapped"
    if "as this land enters, you may pay" in text:
        return "optional_untapped_life"
    if "enters tapped" in text or "boseiju enters tapped" in text:
        return "always_tapped"
    return "reliably_untapped"


def direct_color_profile(type_line: str, oracle_text: str) -> dict[str, bool]:
    text = oracle_text.lower()
    type_text = type_line.lower()
    red = "{r}" in text or "add {r}" in text or "mountain" in type_text
    white = "{w}" in text or "add {w}" in text or "plains" in type_text
    commander_any = "commander's color identity" in text
    opponent_any = "opponent controls could produce" in text
    restricted_any = "add one mana of any color" in text and not commander_any and not opponent_any
    if commander_any or opponent_any:
        red = True
        white = True
    return {
        "red": red,
        "white": white,
        "commander_any": commander_any,
        "opponent_any": opponent_any,
        "restricted_any": restricted_any,
        "colorless_only": "{c}" in text and not red and not white and not commander_any and not opponent_any,
    }


def fetch_profile(type_line: str, oracle_text: str) -> dict[str, bool]:
    text = oracle_text.lower()
    type_text = type_line.lower()
    return {
        "typed_mountain_plains": "mountain" in type_text and "plains" in type_text,
        "fetch_or_search_land": "search your library" in text and "land" in text,
        "fetches_red": "mountain" in text or "basic land" in text,
        "fetches_white": "plains" in text or "basic land" in text,
        "basic": type_text.startswith("basic land"),
    }


def utility_profile(card_name: str, oracle_text: str, type_line: str) -> list[str]:
    text = oracle_text.lower()
    utilities: set[str] = set()
    if "draw a card" in text:
        utilities.add("card_flow")
    if "surveil" in text or "scry" in text:
        utilities.add("topdeck_selection")
    if "cycling" in text:
        utilities.add("cycling")
    if "commander" in text:
        utilities.add("commander_support")
    if "hexproof" in text or "indestructible" in text:
        utilities.add("protection")
    if "can't be countered" in text:
        utilities.add("anti_countermagic")
    if "channel" in text:
        utilities.add("spell_slot_utility")
    if "search your library for an artifact" in text:
        utilities.add("artifact_tutor")
    if "add {c}{c}" in text:
        utilities.add("fast_colorless_mana")
    if "return a land you control" in text:
        utilities.add("bounce_land_tempo_risk")
    if "mountain plains" in type_line.lower() and card_name in TYPED_DUALS_WITH_TIMING_RISK:
        utilities.add("typed_fetch_target")
    return sorted(utilities)


def land_features(row: Mapping[str, Any], *, in_deck_607: bool, variant_count: int = 0) -> dict[str, Any]:
    name = str(row.get("card_name") or row.get("name") or "")
    type_line = str(row.get("type_line") or "")
    oracle_text = str(row.get("oracle_text") or "")
    colors = direct_color_profile(type_line, oracle_text)
    fetch = fetch_profile(type_line, oracle_text)
    utilities = utility_profile(name, oracle_text, type_line)
    tapped = enters_tapped_profile(oracle_text)
    quantity = as_int(row.get("quantity") or 1)
    return {
        "card_name": name,
        "quantity": quantity,
        "in_deck_607": in_deck_607,
        "variant_deck_count": variant_count,
        "type_line": type_line,
        "oracle_text": oracle_text,
        "card_id": row.get("card_id"),
        "scryfall_id": row.get("scryfall_id"),
        "red_source": colors["red"],
        "white_source": colors["white"],
        "commander_any_source": colors["commander_any"],
        "opponent_any_source": colors["opponent_any"],
        "restricted_any_source": colors["restricted_any"],
        "colorless_only": colors["colorless_only"],
        "typed_mountain_plains": fetch["typed_mountain_plains"],
        "fetch_or_search_land": fetch["fetch_or_search_land"],
        "fetches_red": fetch["fetches_red"],
        "fetches_white": fetch["fetches_white"],
        "basic": fetch["basic"],
        "enters_tapped_profile": tapped,
        "utility_roles": utilities,
        "protected_utility_reason": PROTECTED_UTILITY_LANDS.get(name),
    }


def source_quality_score(features: Mapping[str, Any]) -> int:
    score = 50
    if features.get("red_source") and features.get("white_source"):
        score += 24
    elif features.get("red_source") or features.get("white_source"):
        score += 10
    if features.get("typed_mountain_plains"):
        score += 18
    if features.get("fetch_or_search_land"):
        score += 12
    tapped = features.get("enters_tapped_profile")
    if tapped == "reliably_untapped":
        score += 15
    elif tapped == "commander_expected_untapped":
        score += 12
    elif tapped == "optional_untapped_life":
        score += 9
    elif tapped == "conditional_tapped":
        score -= 4
    elif tapped == "always_tapped":
        score -= 18
    if features.get("colorless_only"):
        score -= 24
    if features.get("restricted_any_source") and not features.get("red_source") and not features.get("white_source"):
        score -= 8
    if "bounce_land_tempo_risk" in features.get("utility_roles", []):
        score -= 18
    score += min(14, as_int(features.get("variant_deck_count")) * 2)
    return score


def cut_risk_score(features: Mapping[str, Any]) -> int:
    score = 50
    if features.get("protected_utility_reason"):
        score += 35
    if features.get("fetch_or_search_land"):
        score += 24
    if features.get("basic"):
        score += 18
    if features.get("typed_mountain_plains"):
        score += 14
    utilities = set(features.get("utility_roles") or [])
    if utilities:
        score += 7 * len(utilities)
    if features.get("enters_tapped_profile") == "always_tapped":
        score -= 18
    elif features.get("enters_tapped_profile") == "conditional_tapped":
        score -= 10
    elif features.get("enters_tapped_profile") == "optional_untapped_life":
        score += 6
    if features.get("red_source") and features.get("white_source"):
        score += 8
    if features.get("colorless_only") and not features.get("protected_utility_reason"):
        score -= 8
    return score


def mana_base_counts(features: Sequence[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for item in features:
        quantity = as_int(item.get("quantity"))
        counts["land_quantity"] += quantity
        if item.get("red_source") or item.get("fetches_red"):
            counts["red_access_rows"] += quantity
        if item.get("white_source") or item.get("fetches_white"):
            counts["white_access_rows"] += quantity
        if item.get("red_source") and item.get("white_source"):
            counts["direct_rw_rows"] += quantity
        if item.get("typed_mountain_plains"):
            counts["typed_mountain_plains_rows"] += quantity
        if item.get("fetch_or_search_land"):
            counts["fetch_or_search_rows"] += quantity
        if item.get("colorless_only"):
            counts["colorless_only_rows"] += quantity
        if item.get("enters_tapped_profile") == "always_tapped":
            counts["always_tapped_rows"] += quantity
        if item.get("enters_tapped_profile") == "conditional_tapped":
            counts["conditional_tapped_rows"] += quantity
        if item.get("protected_utility_reason"):
            counts["protected_utility_rows"] += quantity
        if set(item.get("utility_roles") or []) & {"card_flow", "topdeck_selection", "cycling", "artifact_tutor"}:
            counts["topdeck_or_card_flow_land_rows"] += quantity
    return dict(sorted(counts.items()))


def variant_counts_from_queue(queue_payload: Mapping[str, Any]) -> dict[str, int]:
    out: dict[str, int] = {}
    for row in (queue_payload.get("lane_queue") or {}).get("mana_base_review") or []:
        out[str(row.get("card_name"))] = as_int(row.get("variant_deck_count"))
    return out


def classify_pair(candidate: Mapping[str, Any], cut: Mapping[str, Any]) -> tuple[str, list[str]]:
    reasons: list[str] = []
    status = "diagnostic_only"
    if cut.get("protected_utility_reason"):
        reasons.append(f"cut_protected_utility:{cut['protected_utility_reason']}")
        status = "blocked_cut_protected_utility"
    if cut.get("basic"):
        reasons.append("cut_basic_reduces_land_tax_and_color_floor")
        status = "blocked_cut_basic_floor"
    if cut.get("fetch_or_search_land"):
        reasons.append("cut_fetch_reduces_shuffle_and_color_access")
        status = "blocked_cut_fetch_or_search"
    if candidate.get("colorless_only") and (cut.get("red_source") or cut.get("white_source")):
        reasons.append("candidate_loses_colored_source")
        status = "blocked_color_source_regression"
    if "bounce_land_tempo_risk" in candidate.get("utility_roles", []):
        reasons.append("candidate_has_bounce_tempo_risk")
        if not status.startswith("blocked"):
            status = "diagnostic_only_tempo_risk"
    if candidate.get("enters_tapped_profile") == "always_tapped" and cut.get("enters_tapped_profile") != "always_tapped":
        reasons.append("candidate_increases_always_tapped_count")
        if not status.startswith("blocked"):
            status = "diagnostic_only_tapped_regression"
    if cut.get("typed_mountain_plains") and not candidate.get("typed_mountain_plains"):
        reasons.append("cut_loses_fetchable_mountain_plains_type")
        if status == "diagnostic_only":
            status = "diagnostic_only_loses_fetch_target_type"
    if set(cut.get("utility_roles") or []) & {"card_flow", "topdeck_selection", "cycling", "artifact_tutor"}:
        if not set(candidate.get("utility_roles") or []) & {"card_flow", "topdeck_selection", "cycling", "artifact_tutor"}:
            reasons.append("cut_loses_topdeck_or_card_flow_land_utility")
            if status == "diagnostic_only":
                status = "diagnostic_only_loses_topdeck_utility"
    improves_tempo = candidate.get("enters_tapped_profile") in {"reliably_untapped", "optional_untapped_life"} and cut.get(
        "enters_tapped_profile"
    ) in {"always_tapped", "conditional_tapped"}
    preserves_color = (
        (not cut.get("red_source") or candidate.get("red_source"))
        and (not cut.get("white_source") or candidate.get("white_source"))
        and (not cut.get("typed_mountain_plains") or candidate.get("typed_mountain_plains"))
    )
    if not reasons and improves_tempo and preserves_color:
        status = "model_ready_for_candidate_materialization"
        reasons.append("tempo_upgrade_preserves_color_and_fetch_target_type")
    elif not reasons:
        reasons.append("no_clear_upgrade_without_forced_diagnostic")
    return status, reasons


def pair_candidates(candidate_features: Sequence[Mapping[str, Any]], current_features: Sequence[Mapping[str, Any]]) -> list[dict[str, Any]]:
    pairs: list[dict[str, Any]] = []
    for candidate in candidate_features:
        for cut in current_features:
            candidate_score = source_quality_score(candidate)
            cut_risk = cut_risk_score(cut)
            status, reasons = classify_pair(candidate, cut)
            pair_score = candidate_score - cut_risk
            if status.startswith("blocked"):
                pair_score -= 100
            elif status.startswith("diagnostic_only"):
                pair_score -= 20
            pairs.append(
                {
                    "add": candidate["card_name"],
                    "cut": cut["card_name"],
                    "status": status,
                    "pair_score": pair_score,
                    "candidate_source_quality_score": candidate_score,
                    "cut_risk_score": cut_risk,
                    "reasons": reasons,
                    "candidate_profile": {
                        "enters_tapped_profile": candidate["enters_tapped_profile"],
                        "typed_mountain_plains": candidate["typed_mountain_plains"],
                        "colorless_only": candidate["colorless_only"],
                        "utility_roles": candidate["utility_roles"],
                    },
                    "cut_profile": {
                        "enters_tapped_profile": cut["enters_tapped_profile"],
                        "typed_mountain_plains": cut["typed_mountain_plains"],
                        "protected_utility_reason": cut["protected_utility_reason"],
                        "utility_roles": cut["utility_roles"],
                    },
                }
            )
    pairs.sort(key=lambda row: (-as_int(row["pair_score"]), str(row["add"]), str(row["cut"])))
    return pairs


def build_payload(
    *,
    db_path: Path = KNOWLEDGE_DB,
    deck_id: int = DEFAULT_DECK_ID,
    hypothesis_queue_path: Path = DEFAULT_HYPOTHESIS_QUEUE,
    value_model_path: Path = DEFAULT_VALUE_MODEL,
) -> dict[str, Any]:
    queue_payload = read_json(hypothesis_queue_path)
    value_model = read_json(value_model_path)
    variant_counts = variant_counts_from_queue(queue_payload)
    current = [
        land_features(row, in_deck_607=True)
        for row in deck_land_rows(db_path, deck_id)
    ]
    oracle = oracle_rows(db_path, MANA_BASE_CANDIDATES)
    candidates = []
    for name in MANA_BASE_CANDIDATES:
        row = oracle.get(normalize_name(name))
        if row:
            candidates.append(land_features(row, in_deck_607=False, variant_count=variant_counts.get(name, 0)))
    for item in current:
        item["source_quality_score"] = source_quality_score(item)
        item["cut_risk_score"] = cut_risk_score(item)
    for item in candidates:
        item["source_quality_score"] = source_quality_score(item)
    pairs = pair_candidates(candidates, current)
    ready_pairs = [row for row in pairs if row["status"] == "model_ready_for_candidate_materialization"]
    diagnostic_pairs = [row for row in pairs if row["status"].startswith("diagnostic_only")]
    blocked_pairs = [row for row in pairs if row["status"].startswith("blocked")]
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_mana_base_safe_cut_model",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "source_reports": [rel(hypothesis_queue_path), rel(value_model_path)],
        "external_research_refresh": EXTERNAL_RESEARCH_REFRESH,
        "status": "lorehold_mana_base_safe_cut_model_ready",
        "summary": {
            "deck_id": deck_id,
            "current_land_rows": len(current),
            "current_land_quantity": sum(as_int(row.get("quantity")) for row in current),
            "candidate_count": len(candidates),
            "model_ready_pair_count": len(ready_pairs),
            "diagnostic_pair_count": len(diagnostic_pairs),
            "blocked_pair_count": len(blocked_pairs),
            "current_mana_base_counts": mana_base_counts(current),
            "queue_natural_gate_ready_count": as_int((queue_payload.get("summary") or {}).get("natural_gate_ready_count")),
            "value_model_gate_ready_now_count": as_int((value_model.get("summary") or {}).get("gate_ready_now_count")),
            "promotion_allowed": False,
            "allow_battle_gate_now": False,
            "keep_607_as_protected_baseline": True,
        },
        "current_lands": current,
        "candidate_lands": candidates,
        "top_model_ready_pairs": ready_pairs[:12],
        "top_diagnostic_pairs": diagnostic_pairs[:12],
        "blocked_pair_examples": blocked_pairs[:12],
        "all_pairs": pairs,
        "policy": {
            "land_count": "Keep 34 lands for the 607 shell unless a later battle result explicitly proves a different count.",
            "typed_fetch_targets": "Typed Mountain Plains lands are not interchangeable with non-typed fixing when fetch density and Land Tax/Scroll Rack shuffling matter.",
            "utility_lands": "Protected utility lands require exact same-function proof before cutting.",
            "battle_gate": "A model-ready land swap must still be materialized, structure-checked, miracle-access preflighted, and battle-gated before promotion.",
        },
        "decision": {
            "current_best_baseline": "deck_607",
            "best_structural_learning_pair": ready_pairs[0] if ready_pairs else None,
            "promotion_allowed": False,
            "reason": (
                "The mana-base model found structural candidates, but no land swap has yet passed candidate materialization, "
                "miracle-access preflight, equal battle gate, and replay trace checks."
            ),
            "next_action": "materialize the highest scoring model-ready land pair only as a diagnostic candidate, then rerun structural and miracle-access gates",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Mana Base Safe-Cut Model",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "- deck_607_mutated: `false`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- current_land_quantity: `{summary['current_land_quantity']}`",
        f"- candidate_count: `{summary['candidate_count']}`",
        f"- model_ready_pair_count: `{summary['model_ready_pair_count']}`",
        f"- diagnostic_pair_count: `{summary['diagnostic_pair_count']}`",
        f"- blocked_pair_count: `{summary['blocked_pair_count']}`",
        f"- promotion_allowed: `{str(summary['promotion_allowed']).lower()}`",
        f"- allow_battle_gate_now: `{str(summary['allow_battle_gate_now']).lower()}`",
        "",
        "## Current Mana Base Counts",
        "",
        f"- counts: `{json.dumps(summary['current_mana_base_counts'], sort_keys=True)}`",
        "",
        "## Model-Ready Pairs",
        "",
    ]
    if payload["top_model_ready_pairs"]:
        lines.append("| Score | Add | Cut | Reasons |")
        lines.append("| --- | --- | --- | --- |")
        for row in payload["top_model_ready_pairs"]:
            lines.append(
                f"| `{row['pair_score']}` | `{row['add']}` | `{row['cut']}` | {', '.join(row['reasons'])} |"
            )
    else:
        lines.append("- none")
    lines.extend(["", "## Diagnostic Pairs", ""])
    lines.append("| Score | Status | Add | Cut | Reasons |")
    lines.append("| --- | --- | --- | --- | --- |")
    for row in payload["top_diagnostic_pairs"]:
        lines.append(
            f"| `{row['pair_score']}` | `{row['status']}` | `{row['add']}` | `{row['cut']}` | {', '.join(row['reasons'])} |"
        )
    lines.extend(["", "## Candidate Lands", ""])
    for row in payload["candidate_lands"]:
        lines.append(
            "- `{name}` score `{score}` tapped `{tapped}` typed `{typed}` colorless `{colorless}` utility `{utility}` variants `{variants}`".format(
                name=row["card_name"],
                score=row["source_quality_score"],
                tapped=row["enters_tapped_profile"],
                typed=str(row["typed_mountain_plains"]).lower(),
                colorless=str(row["colorless_only"]).lower(),
                utility=",".join(row["utility_roles"]) or "none",
                variants=row["variant_deck_count"],
            )
        )
    lines.extend(["", "## Protected Current Lands", ""])
    for row in payload["current_lands"]:
        if row.get("protected_utility_reason"):
            lines.append(f"- `{row['card_name']}`: {row['protected_utility_reason']}")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.extend(["", "## External Research Refresh", ""])
    for item in payload["external_research_refresh"]:
        lines.append(f"- {item['source']}: {item['url']}")
        lines.append(f"  - {item['learning']}")
    lines.extend(["", "## Decision", ""])
    lines.append(f"- current_best_baseline: `{payload['decision']['current_best_baseline']}`")
    lines.append(f"- promotion_allowed: `{str(payload['decision']['promotion_allowed']).lower()}`")
    best = payload["decision"].get("best_structural_learning_pair")
    if best:
        lines.append(f"- best_structural_learning_pair: `+{best['add']} / -{best['cut']}`")
    lines.append(f"- reason: {payload['decision']['reason']}")
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
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--value-model", type=Path, default=DEFAULT_VALUE_MODEL)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_payload(
        db_path=args.db,
        deck_id=args.deck_id,
        hypothesis_queue_path=args.hypothesis_queue,
        value_model_path=args.value_model,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "model_ready_pair_count": payload["summary"]["model_ready_pair_count"],
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
