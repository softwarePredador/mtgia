#!/usr/bin/env python3
"""Synthesize card value priorities for protected Lorehold deck 607.

This read-only layer consolidates the current mana, staple, access, interaction,
and payoff reports into a per-card priority model. It does not recommend a
replacement by itself; it explains which current cards are protected anchors,
which are structural floor, which are same-lane support, and which rows need
role/tag review before any cut hypothesis can be trusted.
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

DIRECT_READY_DECISIONS = {"direct_swap_ready", "promotion_ready", "natural_gate_won"}

EXTERNAL_LEARNING = [
    {
        "source": "EDHREC How to Build a Commander Deck",
        "url": "https://edhrec.com/articles/how-to-build-a-commander-deck",
        "learning": (
            "Commander deckbuilding starts with role categories and win plans, but "
            "the final list still has to play the intended commander plan."
        ),
    },
    {
        "source": "EDHREC Digital Deckbuilding synergy guide",
        "url": "https://edhrec.com/articles/digital-deckbuilding-the-how-to-guide-to-building-a-commander-deck-using-edhrec-archidekt-and-commander-spellbook",
        "learning": (
            "Synergy is commander-relative inclusion above the color baseline; it is "
            "useful evidence, but not automatic replacement proof."
        ),
    },
    {
        "source": "Card Kingdom staples article",
        "url": "https://blog.cardkingdom.com/commander-staples-arent-always-the-right-cards/",
        "learning": (
            "Best-in-slot is deck-dependent. A staple can lose to a less famous card "
            "when the less famous card advances the deck plan better."
        ),
    },
    {
        "source": "GameTyrant Lorehold deck tech",
        "url": "https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech",
        "learning": (
            "Lorehold's value comes from topdeck setup, discard-as-resource, miracle "
            "timing, and turning preparation into a high-impact spell turn."
        ),
    },
    {
        "source": "Draftsim Lorehold guide",
        "url": "https://draftsim.com/lorehold-the-historian-edh-deck/",
        "learning": (
            "Library of Leng, Scroll Rack, Sensei's Divining Top, and Land Tax are "
            "central topdeck/miracle engines, not generic draw slots."
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


def default_mana_sequence_report() -> Path:
    return newest_report(
        "lorehold_mana_sequence_policy_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_mana_sequence_policy_synthesis_20260704_learning.json",
    )


def default_staple_policy_report() -> Path:
    return newest_report(
        "lorehold_staple_policy_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_staple_policy_synthesis_20260704_learning.json",
    )


def default_selection_report() -> Path:
    return newest_report(
        "lorehold_selection_access_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_selection_access_synthesis_20260704_learning.json",
    )


def default_interaction_report() -> Path:
    return newest_report(
        "lorehold_interaction_resilience_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_interaction_resilience_synthesis_20260704_learning.json",
    )


def default_payoff_report() -> Path:
    return newest_report(
        "lorehold_payoff_finisher_recursion_synthesis_20260704*.json",
        REPORT_DIR / "lorehold_payoff_finisher_recursion_synthesis_20260704_learning.json",
    )


def connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
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


def json_list(value: Any) -> list[Any]:
    if isinstance(value, list):
        return value
    if value in (None, ""):
        return []
    try:
        payload = json.loads(str(value))
    except Exception:
        return []
    return payload if isinstance(payload, list) else []


def read_json_if_exists(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def report_summary(report: Mapping[str, Any]) -> dict[str, Any]:
    summary = report.get("summary")
    return dict(summary) if isinstance(summary, Mapping) else {}


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
        card["quantity"] = as_int(card.get("quantity"), 1)
        card["functional_tags"] = json_list(card.get("functional_tags_json"))
        card["safe_cmc"] = safe_cmc_from_card(card, unknown_nonland_fallback=99.0)
        out.append(card)
    return out


def battle_rule_summary(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    if not sqlite_connection_has_table(conn, "battle_card_rules"):
        return {"rule_count": 0, "active_rule_count": 0, "scopes": []}
    rows = conn.execute(
        """
        SELECT execution_status, review_status, effect_json, deck_role_json
        FROM battle_card_rules
        WHERE normalized_name = ?
           OR lower(card_name) = lower(?)
        """,
        (normalize_name(card_name), card_name),
    ).fetchall()
    active = 0
    scopes: set[str] = set()
    categories: set[str] = set()
    for row in rows:
        if str(row["execution_status"] or "") in {"auto", "active", "verified"} and str(
            row["review_status"] or ""
        ) in {"active", "verified", "reviewed"}:
            active += 1
        for field in ("effect_json", "deck_role_json"):
            try:
                payload = json.loads(row[field] or "{}")
            except Exception:
                payload = {}
            if isinstance(payload, Mapping):
                if payload.get("battle_model_scope"):
                    scopes.add(str(payload["battle_model_scope"]))
                if payload.get("category"):
                    categories.add(str(payload["category"]))
    return {
        "rule_count": len(rows),
        "active_rule_count": active,
        "scopes": sorted(scopes),
        "role_categories": sorted(categories),
    }


def add_membership(
    memberships: dict[str, list[dict[str, Any]]],
    report_name: str,
    rows: Iterable[Any],
    *,
    card_field: str = "card_name",
    lane_field: str | None = None,
    policy_field: str | None = None,
    decision_field: str | None = None,
) -> None:
    for row in rows:
        if not isinstance(row, Mapping) or not row.get(card_field):
            continue
        key = normalize_name(str(row[card_field]))
        item: dict[str, Any] = {"source": report_name}
        if lane_field and row.get(lane_field):
            item["lane"] = row[lane_field]
        if policy_field and row.get(policy_field):
            item["policy_class"] = row[policy_field]
        if decision_field and row.get(decision_field):
            item["decision"] = row[decision_field]
        if row.get("edhrec_lorehold"):
            item["edhrec_lorehold"] = row["edhrec_lorehold"]
        if row.get("variant_usage"):
            item["variant_usage"] = row["variant_usage"]
        if row.get("battle_rule_summary"):
            item["battle_rule_summary"] = row["battle_rule_summary"]
        memberships[key].append(item)


def build_memberships(reports: Mapping[str, Mapping[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    memberships: dict[str, list[dict[str, Any]]] = defaultdict(list)
    add_membership(
        memberships,
        "selection_access.current_access_anchors",
        reports.get("selection") or {},
        card_field="card_name",
    )
    selection = reports.get("selection") or {}
    add_membership(
        memberships,
        "selection_access.current_access_anchors",
        selection.get("current_access_anchors") or [],
    )
    add_membership(
        memberships,
        "interaction.current_floor_profiles",
        (reports.get("interaction") or {}).get("current_floor_profiles") or [],
        lane_field="lane",
    )
    add_membership(
        memberships,
        "payoff.current_payoff_anchors",
        (reports.get("payoff") or {}).get("current_payoff_anchors") or [],
    )
    add_membership(
        memberships,
        "staple.current_staple_floor",
        (reports.get("staple") or {}).get("current_staple_floor") or [],
        policy_field="policy_class",
    )
    add_membership(
        memberships,
        "mana.current_mana_package",
        (reports.get("mana") or {}).get("current_mana_package") or [],
        lane_field="lane",
        policy_field="policy_class",
        decision_field="decision",
    )
    return memberships


def collect_candidate_rows(reports: Mapping[str, Mapping[str, Any]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for source_name, row_key in [
        ("selection", "candidate_access_cards"),
        ("interaction", "candidate_profiles"),
        ("payoff", "candidate_cards"),
        ("staple", "candidate_staple_backlog"),
        ("mana", "candidate_mana_backlog"),
    ]:
        source_rows = (reports.get(source_name) or {}).get(row_key)
        if not isinstance(source_rows, list):
            continue
        for row in source_rows:
            if isinstance(row, Mapping) and row.get("card_name"):
                rows.append(
                    {
                        "source": source_name,
                        "card_name": row.get("card_name"),
                        "decision": row.get("decision"),
                        "lane": row.get("lane") or (row.get("access_model") or {}).get("lane"),
                        "in_protected_607": bool(row.get("in_protected_607") or row.get("in_607")),
                    }
                )
    return rows


def inferred_text_lanes(card: Mapping[str, Any]) -> set[str]:
    text = f"{card.get('type_line') or ''}\n{card.get('oracle_text') or ''}".lower()
    tag = str(card.get("functional_tag") or "").lower()
    lanes: set[str] = set()
    if as_int(card.get("is_commander")):
        lanes.add("commander_intent")
    if tag == "land" or "land" in str(card.get("type_line") or "").lower():
        lanes.add("mana_base")
    if tag == "ramp" or "add " in text or "treasure token" in text or "cost {1} less" in text:
        lanes.add("ramp")
    if tag == "draw" or "draw" in text or "look at the top" in text or "exile cards from the top" in text:
        lanes.add("card_draw_selection")
    if "discard" in text and ("draw" in text or "top of your library" in text or "treasure" in text):
        lanes.add("hand_filter")
    if "top of your library" in text or "miracle" in text or "first card you draw" in text:
        lanes.add("topdeck_miracle_setup")
    if tag == "tutor" or "search your library" in text:
        lanes.add("tutors_access")
    if tag == "removal" or "destroy target" in text or "exile target" in text or "change the target" in text:
        lanes.add("interaction_removal")
    if tag == "protection" or "protection" in text or "hexproof" in text or "indestructible" in text:
        lanes.add("protection_resilience")
    if tag == "board_wipe" or "destroy all" in text or "exile all" in text or "each creature" in text:
        lanes.add("board_wipes")
    if "graveyard" in text or "flashback" in text or "escape" in text or "return target" in text:
        lanes.add("recursion_recovery")
    if tag == "wincon" or "win the game" in text or "create x" in text or "gain control of all creatures" in text:
        lanes.add("payoffs_finishers")
    if "instant or sorcery" in text or "noncreature spell" in text:
        lanes.add("commander_synergy_engine")
    return lanes


def lanes_from_membership(member_rows: Iterable[Mapping[str, Any]]) -> set[str]:
    lanes: set[str] = set()
    for row in member_rows:
        source = str(row.get("source") or "")
        lane = str(row.get("lane") or "")
        policy = str(row.get("policy_class") or "")
        if source.startswith("selection_access"):
            lanes.update({"card_draw_selection", "topdeck_miracle_setup"})
            if "Land Tax" in json.dumps(row):
                lanes.add("tutors_access")
        if source.startswith("interaction"):
            if "wipe" in lane:
                lanes.add("board_wipes")
            elif "removal" in lane:
                lanes.add("interaction_removal")
            else:
                lanes.add("protection_resilience")
        if source.startswith("payoff"):
            lanes.add("payoffs_finishers")
            if "recursion" in lane:
                lanes.add("recursion_recovery")
        if source.startswith("staple"):
            lanes.add("staple_floor_and_context")
            if policy == "commander_contextual_staple":
                lanes.add("commander_synergy_engine")
        if source.startswith("mana"):
            if "land" in lane:
                lanes.add("mana_base")
            else:
                lanes.add("ramp")
    return lanes


def primary_role_from_lanes(lanes: set[str], tag: str) -> str:
    order = [
        "commander_intent",
        "topdeck_miracle_setup",
        "tutors_access",
        "mana_base",
        "ramp",
        "interaction_removal",
        "protection_resilience",
        "board_wipes",
        "recursion_recovery",
        "payoffs_finishers",
        "commander_synergy_engine",
        "card_draw_selection",
        "staple_floor_and_context",
    ]
    for lane in order:
        if lane in lanes:
            return lane
    return tag or "unknown"


def priority_class(card: Mapping[str, Any], member_rows: list[Mapping[str, Any]], lanes: set[str]) -> str:
    name = str(card.get("card_name") or "")
    sources = {str(row.get("source") or "") for row in member_rows}
    policies = {str(row.get("policy_class") or "") for row in member_rows}
    if as_int(card.get("is_commander")):
        return "commander_core_anchor"
    if "selection_access.current_access_anchors" in sources:
        return "protected_topdeck_access_anchor"
    if name in {"Bender's Waterskin", "Victory Chimes"}:
        return "protected_turn_cycle_miracle_mana"
    if "payoff.current_payoff_anchors" in sources:
        return "protected_payoff_finisher_anchor"
    if "interaction.current_floor_profiles" in sources and (
        "protection_resilience" in lanes or "interaction_removal" in lanes or "board_wipes" in lanes
    ):
        return "protected_interaction_resilience_floor"
    if "structural_foundation" in policies:
        return "structural_foundation"
    if "commander_contextual_staple" in policies:
        return "commander_contextual_staple"
    if any(source.startswith("mana.") for source in sources):
        return "mana_foundation_support"
    if lanes & {"topdeck_miracle_setup", "commander_synergy_engine", "payoffs_finishers"}:
        return "commander_synergy_support"
    if lanes & {"interaction_removal", "protection_resilience", "board_wipes"}:
        return "role_density_support"
    return "review_watch_not_cut_proof"


def tag_divergence(card: Mapping[str, Any], lanes: set[str]) -> list[str]:
    tag = str(card.get("functional_tag") or "").lower()
    if not tag:
        return ["missing_primary_functional_tag"]
    lane_groups = {
        "land": {"mana_base"},
        "ramp": {"ramp", "mana_base"},
        "draw": {"card_draw_selection", "topdeck_miracle_setup", "hand_filter"},
        "tutor": {"tutors_access", "mana_base", "card_draw_selection"},
        "removal": {"interaction_removal"},
        "protection": {"protection_resilience", "interaction_removal", "board_wipes"},
        "board_wipe": {"board_wipes", "interaction_removal"},
        "wincon": {"payoffs_finishers", "commander_synergy_engine", "recursion_recovery"},
        "engine": {"commander_intent", "commander_synergy_engine", "topdeck_miracle_setup"},
        "creature": {"commander_synergy_engine", "protection_resilience", "payoffs_finishers"},
    }
    expected = lane_groups.get(tag)
    if expected is None:
        return [f"unmapped_primary_tag:{tag}"]
    if lanes and not (lanes & expected):
        return [f"primary_tag_{tag}_does_not_match_detected_lanes"]
    if tag == "draw" and lanes & {"interaction_removal", "protection_resilience", "board_wipes"}:
        return ["draw_tag_masks_interaction_or_protection_function"]
    if tag == "protection" and "board_wipes" in lanes:
        return ["protection_tag_masks_board_wipe_function"]
    return []


def cut_policy(priority: str, divergences: list[str]) -> str:
    if priority in {
        "commander_core_anchor",
        "protected_topdeck_access_anchor",
        "protected_turn_cycle_miracle_mana",
        "protected_payoff_finisher_anchor",
    }:
        return "protected_anchor_no_cut_without_explicit_package_and_equal_gate"
    if priority in {"structural_foundation", "commander_contextual_staple", "protected_interaction_resilience_floor"}:
        return "same_lane_only_with_card_use_and_equal_gate"
    if priority == "mana_foundation_support":
        return "mana_sequence_cut_requires_named_land_or_ramp_gate"
    if divergences:
        return "review_role_mapping_before_cut"
    return "same_lane_hypothesis_required_before_cut"


def value_score(priority: str, lanes: set[str], member_rows: list[Mapping[str, Any]], rules: Mapping[str, Any]) -> int:
    base_by_priority = {
        "commander_core_anchor": 100,
        "protected_topdeck_access_anchor": 92,
        "protected_turn_cycle_miracle_mana": 88,
        "protected_payoff_finisher_anchor": 84,
        "protected_interaction_resilience_floor": 80,
        "structural_foundation": 78,
        "commander_contextual_staple": 76,
        "mana_foundation_support": 70,
        "commander_synergy_support": 66,
        "role_density_support": 60,
        "review_watch_not_cut_proof": 45,
    }
    score = base_by_priority.get(priority, 50)
    score += min(8, len(member_rows) * 2)
    score += min(6, as_int(rules.get("active_rule_count")) * 2)
    if "topdeck_miracle_setup" in lanes:
        score += 3
    if "staple_floor_and_context" in lanes:
        score += 2
    return min(score, 100)


def classify_card(
    conn: sqlite3.Connection,
    card: Mapping[str, Any],
    memberships: Mapping[str, list[dict[str, Any]]],
) -> dict[str, Any]:
    name = str(card.get("card_name") or "")
    member_rows = list(memberships.get(normalize_name(name), []))
    lanes = inferred_text_lanes(card) | lanes_from_membership(member_rows)
    role = primary_role_from_lanes(lanes, str(card.get("functional_tag") or ""))
    divergences = tag_divergence(card, lanes)
    priority = priority_class(card, member_rows, lanes)
    rules = battle_rule_summary(conn, name)
    return {
        "card_name": name,
        "quantity": as_int(card.get("quantity"), 1),
        "functional_tag": card.get("functional_tag"),
        "primary_value_lane": role,
        "value_lanes": sorted(lanes),
        "priority_class": priority,
        "value_priority_index": value_score(priority, lanes, member_rows, rules),
        "cut_policy": cut_policy(priority, divergences),
        "role_mapping_watch": divergences,
        "safe_cmc": as_float(card.get("safe_cmc"), as_float(card.get("cmc"))),
        "report_memberships": member_rows,
        "battle_rule_summary": rules,
    }


def synthesize_status(card_rows: Iterable[Mapping[str, Any]], candidate_rows: Iterable[Mapping[str, Any]]) -> str:
    if any(str(row.get("decision")) in DIRECT_READY_DECISIONS for row in candidate_rows):
        return "card_value_priority_candidate_requires_gate_review"
    if any(row.get("role_mapping_watch") for row in card_rows):
        return "card_value_priority_keep_607_with_role_watch_items"
    return "card_value_priority_no_direct_cut_ready_current_607"


def build_synthesis(
    *,
    conn: sqlite3.Connection,
    db_path: Path,
    deck_id: int,
    mana_report_path: Path,
    staple_report_path: Path,
    selection_report_path: Path,
    interaction_report_path: Path,
    payoff_report_path: Path,
) -> dict[str, Any]:
    cards = load_deck_cards(conn, deck_id)
    reports = {
        "mana": read_json_if_exists(mana_report_path),
        "staple": read_json_if_exists(staple_report_path),
        "selection": read_json_if_exists(selection_report_path),
        "interaction": read_json_if_exists(interaction_report_path),
        "payoff": read_json_if_exists(payoff_report_path),
    }
    memberships = build_memberships(reports)
    card_rows = [classify_card(conn, card, memberships) for card in cards]
    candidate_rows = collect_candidate_rows(reports)
    status = synthesize_status(card_rows, candidate_rows)
    priority_counts = Counter(str(row["priority_class"]) for row in card_rows for _ in range(as_int(row["quantity"], 1)))
    cut_policy_counts = Counter(str(row["cut_policy"]) for row in card_rows for _ in range(as_int(row["quantity"], 1)))
    lane_counts = Counter(str(row["primary_value_lane"]) for row in card_rows for _ in range(as_int(row["quantity"], 1)))
    watch_rows = [row for row in card_rows if row["role_mapping_watch"]]
    ready_candidates = [row for row in candidate_rows if str(row.get("decision")) in DIRECT_READY_DECISIONS]
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_card_value_priority_synthesis",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "source_db": rel(db_path),
        "status": status,
        "source_reports": {
            "mana_sequence": rel(mana_report_path),
            "staple_policy": rel(staple_report_path),
            "selection_access": rel(selection_report_path),
            "interaction_resilience": rel(interaction_report_path),
            "payoff_finisher_recursion": rel(payoff_report_path),
        },
        "summary": {
            "total_rows": len(cards),
            "total_cards": sum(as_int(card.get("quantity"), 1) for card in cards),
            "priority_counts": dict(sorted(priority_counts.items())),
            "cut_policy_counts": dict(sorted(cut_policy_counts.items())),
            "primary_lane_counts": dict(sorted(lane_counts.items())),
            "role_mapping_watch_count": sum(as_int(row["quantity"], 1) for row in watch_rows),
            "ready_replacement_candidate_count": len(ready_candidates),
            "candidate_rows_considered": len(candidate_rows),
            "source_statuses": {
                key: value.get("status") for key, value in reports.items()
            },
        },
        "external_learning": EXTERNAL_LEARNING,
        "current_card_priorities": sorted(
            card_rows,
            key=lambda row: (-as_int(row["value_priority_index"]), row["primary_value_lane"], row["card_name"]),
        ),
        "role_mapping_watch_items": sorted(watch_rows, key=lambda row: row["card_name"]),
        "candidate_replacement_pressure": {
            "ready_candidates": ready_candidates,
            "blocked_or_hypothesis_count": len(candidate_rows) - len(ready_candidates),
        },
        "decision": {
            "keep_607_card_value_policy": not ready_candidates,
            "reason": (
                "Current 607 has protected anchors across topdeck access, turn-cycle miracle mana, "
                "payoff conversion, interaction, staples, and mana foundation. Current reports do not "
                "surface a direct replacement candidate; watch items are role/tag interpretation work, "
                "not evidence that a card should be cut."
            ),
            "next_action": (
                "use this priority map before any future package generator: candidates must name the "
                "same-lane card they challenge and prove the tradeoff in equal gate traces"
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Card Value Priority Synthesis",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- status: `{payload['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- total cards: `{summary['total_cards']}`",
        f"- ready replacement candidates: `{summary['ready_replacement_candidate_count']}`",
        f"- role mapping watch cards: `{summary['role_mapping_watch_count']}`",
        f"- priority counts: `{json.dumps(summary['priority_counts'], sort_keys=True)}`",
        f"- cut policy counts: `{json.dumps(summary['cut_policy_counts'], sort_keys=True)}`",
        "",
        "## Highest Priority Cards",
        "",
        "| Card | Lane | Priority | Score | Cut Policy | Watch |",
        "| --- | --- | --- | ---: | --- | --- |",
    ]
    for row in payload["current_card_priorities"][:45]:
        lines.append(
            "| {card} | `{lane}` | `{priority}` | {score} | `{policy}` | {watch} |".format(
                card=row["card_name"],
                lane=row["primary_value_lane"],
                priority=row["priority_class"],
                score=row["value_priority_index"],
                policy=row["cut_policy"],
                watch=", ".join(row.get("role_mapping_watch") or []) or "-",
            )
        )
    if payload.get("role_mapping_watch_items"):
        lines.extend(["", "## Role Mapping Watch", ""])
        for row in payload["role_mapping_watch_items"]:
            lines.append(
                f"- `{row['card_name']}`: tag `{row.get('functional_tag')}`; "
                f"lanes `{', '.join(row.get('value_lanes') or [])}`; "
                f"watch `{', '.join(row.get('role_mapping_watch') or [])}`."
            )
    lines.extend(["", "## Learning Sources", ""])
    for source in payload["external_learning"]:
        lines.append(f"- {source['source']}: {source['url']}")
    lines.extend(["", "## Decision", ""])
    decision = payload["decision"]
    lines.append(f"- keep_607_card_value_policy: `{str(decision['keep_607_card_value_policy']).lower()}`")
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
    parser.add_argument("--mana-report", type=Path, default=None)
    parser.add_argument("--staple-report", type=Path, default=None)
    parser.add_argument("--selection-report", type=Path, default=None)
    parser.add_argument("--interaction-report", type=Path, default=None)
    parser.add_argument("--payoff-report", type=Path, default=None)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_card_value_priority_synthesis",
    )
    args = parser.parse_args()
    with connect(args.db) as conn:
        payload = build_synthesis(
            conn=conn,
            db_path=args.db,
            deck_id=args.deck_id,
            mana_report_path=args.mana_report or default_mana_sequence_report(),
            staple_report_path=args.staple_report or default_staple_policy_report(),
            selection_report_path=args.selection_report or default_selection_report(),
            interaction_report_path=args.interaction_report or default_interaction_report(),
            payoff_report_path=args.payoff_report or default_payoff_report(),
        )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(json.dumps({"status": payload["status"], "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
