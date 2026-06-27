#!/usr/bin/env python3
"""Mine Lorehold variant cards before building the next battle gate queue.

This is a read-only analysis helper. It compares the current Lorehold champion
deck against registered Lorehold variants, aggregates local runtime rule
coverage, imports prior negative gate evidence, and surfaces which candidates
still need a safe cut model before another expensive battle gate is justified.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from reviewed_battle_card_rules import DEFAULT_REVIEWED_RULES_PATH, load_reviewed_rule_rows


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = Path(
    os.environ.get(
        "MANALOOM_KNOWLEDGE_DB",
        REPORT_DIR
        / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
        / "knowledge_candidate.db",
    )
)
DEFAULT_STRATEGY_AUDIT = REPORT_DIR / "lorehold_strategy_learning_audit_20260627_v3.json"
DEFAULT_QUEUE_REPORT = REPORT_DIR / "lorehold_next_hypothesis_queue_20260627_v9.json"
DEFAULT_BASE_DECK_ID = 6
DEFAULT_VARIANT_DECK_IDS = tuple(range(608, 617))
ACTIVE_EXECUTION_STATUSES = {"active", "verified", "auto", "reviewed"}
ACTIVE_REVIEW_STATUSES = {"verified", "active", "needs_review", "reviewed"}
LOCKED_CUT_STATUSES = {"locked_do_not_cut", "blocked_locked_cut"}
RISKY_CUT_STATUSES = {"risky_cut_only_same_lane", "risky_same_lane_only"}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", normalize_name(value)).strip()


def json_list(value: object) -> list[Any]:
    if value in (None, ""):
        return []
    if isinstance(value, list):
        return value
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def json_dict(value: object) -> dict[str, Any]:
    if isinstance(value, dict):
        return value
    if value in (None, ""):
        return {}
    try:
        decoded = json.loads(str(value))
    except Exception:
        return {}
    return decoded if isinstance(decoded, dict) else {}


def parse_deck_ids(raw: str | None) -> tuple[int, ...]:
    if not raw:
        return DEFAULT_VARIANT_DECK_IDS
    return tuple(int(part.strip()) for part in raw.split(",") if part.strip())


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def canonical_card_name(row: sqlite3.Row | dict[str, Any]) -> str:
    return str(row["card_name"])


def card_roles_from_row(row: sqlite3.Row | dict[str, Any]) -> list[str]:
    roles: set[str] = set()
    tag = row["functional_tag"] if "functional_tag" in row.keys() else row.get("functional_tag")
    if tag:
        roles.add(str(tag))
    tags_json = (
        row["functional_tags_json"]
        if "functional_tags_json" in row.keys()
        else row.get("functional_tags_json")
    )
    for value in json_list(tags_json):
        if isinstance(value, dict):
            value = value.get("tag") or value.get("role") or value.get("category")
        if value:
            roles.add(str(value))
    type_line = row["type_line"] if "type_line" in row.keys() else row.get("type_line")
    if "Land" in str(type_line or ""):
        roles.add("land")
    return sorted(roles)


def row_value(row: sqlite3.Row | dict[str, Any], key: str, default: Any = None) -> Any:
    if isinstance(row, sqlite3.Row):
        return row[key] if key in row.keys() else default
    return row.get(key, default)


def load_deck_cards(
    conn: sqlite3.Connection,
    deck_ids: Iterable[int],
) -> dict[int, dict[str, dict[str, Any]]]:
    deck_ids = tuple(deck_ids)
    if not deck_ids:
        return {}
    placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT deck_id, card_name, quantity, functional_tag, cmc, type_line,
               functional_tags_json, is_commander
        FROM deck_cards
        WHERE deck_id IN ({placeholders})
        ORDER BY deck_id, card_name
        """,
        deck_ids,
    ).fetchall()
    grouped: dict[int, dict[str, dict[str, Any]]] = defaultdict(dict)
    for row in rows:
        deck_id = int(row["deck_id"])
        name = canonical_card_name(row)
        key = normalize_key(name)
        quantity = int(row["quantity"] or 1)
        existing = grouped[deck_id].get(key)
        if existing:
            existing["quantity"] += quantity
            existing["source_rows"] += 1
            existing["roles"] = sorted(set(existing["roles"]) | set(card_roles_from_row(row)))
            continue
        grouped[deck_id][key] = {
            "card_name": name,
            "normalized_key": key,
            "quantity": quantity,
            "functional_tag": row["functional_tag"],
            "cmc": row["cmc"],
            "type_line": row["type_line"],
            "roles": card_roles_from_row(row),
            "is_commander": bool(row["is_commander"]),
            "source_rows": 1,
        }
    return {deck_id: dict(cards) for deck_id, cards in grouped.items()}


def load_deck_metadata(conn: sqlite3.Connection, deck_ids: Iterable[int]) -> dict[int, dict[str, Any]]:
    deck_ids = tuple(deck_ids)
    if not deck_ids:
        return {}
    placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"SELECT id, deck_name, archetype, total_cards FROM decks WHERE id IN ({placeholders})",
        deck_ids,
    ).fetchall()
    return {
        int(row["id"]): {
            "deck_id": int(row["id"]),
            "deck_name": row["deck_name"],
            "archetype": row["archetype"] or "unknown",
            "total_cards": int(row["total_cards"] or 0),
        }
        for row in rows
    }


def empty_rule_entry(card_name: str) -> dict[str, Any]:
    return {
        "card_name": card_name,
        "active_rule_count": 0,
        "rule_count": 0,
        "review_only_rule_count": 0,
        "disabled_rule_count": 0,
        "effects": Counter(),
        "battle_model_scopes": Counter(),
        "execution_statuses": Counter(),
        "review_statuses": Counter(),
        "reviewed_rule_override_count": 0,
    }


def add_rule_to_index(
    index: dict[str, dict[str, Any]],
    *,
    card_name: str,
    execution_status: str,
    review_status: str,
    effect_json: object,
    reviewed_override: bool = False,
) -> None:
    key = normalize_key(card_name)
    entry = index.setdefault(key, empty_rule_entry(card_name))
    entry["rule_count"] += 1
    entry["execution_statuses"][execution_status] += 1
    entry["review_statuses"][review_status] += 1
    effect_data = effect_json if isinstance(effect_json, dict) else json_dict(effect_json)
    effect = effect_data.get("effect")
    if effect:
        entry["effects"][str(effect)] += 1
    scope = effect_data.get("battle_model_scope")
    if scope:
        entry["battle_model_scopes"][str(scope)] += 1
    if execution_status == "review_only":
        entry["review_only_rule_count"] += 1
    if execution_status == "disabled":
        entry["disabled_rule_count"] += 1
    if execution_status in ACTIVE_EXECUTION_STATUSES and review_status in ACTIVE_REVIEW_STATUSES:
        entry["active_rule_count"] += 1
    if reviewed_override:
        entry["reviewed_rule_override_count"] += 1


def load_rule_index(conn: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, execution_status, review_status, effect_json
        FROM battle_card_rules
        ORDER BY card_name
        """
    ).fetchall()
    index: dict[str, dict[str, Any]] = {}
    for row in rows:
        add_rule_to_index(
            index,
            card_name=row["normalized_name"] or row["card_name"],
            execution_status=str(row["execution_status"] or ""),
            review_status=str(row["review_status"] or ""),
            effect_json=row["effect_json"],
        )
    for row in load_reviewed_rule_rows(DEFAULT_REVIEWED_RULES_PATH):
        add_rule_to_index(
            index,
            card_name=row["card_name"],
            execution_status=str(row.get("execution_status") or ""),
            review_status=str(row.get("review_status") or ""),
            effect_json=row.get("effect_json") or {},
            reviewed_override=True,
        )
    for entry in index.values():
        entry["effects"] = dict(sorted(entry["effects"].items()))
        entry["battle_model_scopes"] = dict(sorted(entry["battle_model_scopes"].items()))
        entry["execution_statuses"] = dict(sorted(entry["execution_statuses"].items()))
        entry["review_statuses"] = dict(sorted(entry["review_statuses"].items()))
    return index


def rule_quality_flags(card_name: str, rule: dict[str, Any]) -> list[str]:
    scopes = set((rule.get("battle_model_scopes") or {}).keys())
    effects = set((rule.get("effects") or {}).keys())
    flags: list[str] = []
    if "treasure_maker" in effects and "lands_controlled_treasure_count_v1" in scopes:
        return []
    if "single_treasure_creation_v1" in scopes:
        flags.append("single_treasure_model_review_required")
    if normalize_key(card_name) == normalize_key("Brass's Bounty") and "treasure_maker" in effects:
        flags.append("brass_bounty_should_scale_with_lands_controlled")
    return sorted(set(flags))


def strategy_lookups(strategy_audit: dict[str, Any]) -> tuple[
    dict[str, dict[str, Any]],
    dict[str, dict[str, Any]],
    dict[str, dict[str, Any]],
]:
    card_decisions = {
        normalize_key(row.get("card_name")): row
        for row in (strategy_audit.get("card_decision_manifest") or {}).get("cards") or []
        if row.get("card_name")
    }
    cut_safety = {
        normalize_key(row.get("card_name")): row
        for row in (strategy_audit.get("cut_safety_manifest") or {}).get("cuts") or []
        if row.get("card_name")
    }
    untested_flex = {
        normalize_key(row.get("card_name")): row
        for row in (strategy_audit.get("cut_safety_manifest") or {}).get("untested_flex_pool") or []
        if row.get("card_name")
    }
    return card_decisions, cut_safety, untested_flex


def load_prior_gate_reports(paths: Iterable[Path]) -> dict[str, Any]:
    negative_adds: dict[str, list[dict[str, Any]]] = defaultdict(list)
    negative_cuts: dict[str, list[dict[str, Any]]] = defaultdict(list)
    exact_negative: list[dict[str, Any]] = []
    loaded_reports: list[str] = []
    for path in paths:
        if not path.exists():
            continue
        try:
            payload = read_json(path)
        except Exception:
            continue
        loaded_reports.append(str(path))
        rows = payload.get("queue") or payload.get("packages") or []
        for row in rows:
            status = str(row.get("status") or "")
            prior = row.get("prior_gate") or {}
            gate = row.get("gate_summary") or {}
            delta = prior.get("delta_pp", gate.get("delta_pp"))
            try:
                delta_pp = float(delta)
            except (TypeError, ValueError):
                delta_pp = 0.0
            is_negative = status == "tested_negative_do_not_promote" or delta_pp < 0
            if not is_negative:
                continue
            evidence = {
                "package_key": row.get("package_key"),
                "status": status,
                "delta_pp": delta_pp,
                "source": str(path),
            }
            for card in row.get("adds") or []:
                negative_adds[normalize_key(card)].append({**evidence, "card_name": card})
            for card in row.get("cuts") or []:
                negative_cuts[normalize_key(card)].append({**evidence, "card_name": card})
            exact_negative.append(
                {
                    **evidence,
                    "adds": list(row.get("adds") or []),
                    "cuts": list(row.get("cuts") or []),
                }
            )
    def dedupe_evidence(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
        seen: set[tuple[Any, ...]] = set()
        deduped: list[dict[str, Any]] = []
        for row in rows:
            key = (
                row.get("package_key"),
                tuple(row.get("adds") or []),
                tuple(row.get("cuts") or []),
            )
            if key in seen:
                continue
            seen.add(key)
            deduped.append(row)
        return deduped

    negative_adds = {
        key: dedupe_evidence(rows)
        for key, rows in negative_adds.items()
    }
    negative_cuts = {
        key: dedupe_evidence(rows)
        for key, rows in negative_cuts.items()
    }
    exact_negative = dedupe_evidence(exact_negative)
    return {
        "loaded_reports": loaded_reports,
        "negative_adds": dict(negative_adds),
        "negative_cuts": dict(negative_cuts),
        "exact_negative": exact_negative,
    }


def default_prior_gate_report_paths() -> list[Path]:
    stems = [
        "lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json",
        "lorehold_spell_payoff_gate_20260627_v1_fixed.json",
        "lorehold_lapse_approach_gate_20260627_v1_fixed.json",
        "lorehold_next_hypothesis_queue_20260627_v9.json",
    ]
    return [REPORT_DIR / stem for stem in stems]


def candidate_lane(card: dict[str, Any], rule: dict[str, Any]) -> str:
    effects = set((rule or {}).get("effects") or {})
    roles = set(card.get("roles") or [])
    tag = str(card.get("functional_tag") or "")
    type_line = str(card.get("type_line") or "")
    all_signals = effects | roles | {tag}
    if "Land" in type_line or "land" in all_signals:
        return "mana_base"
    if all_signals & {"treasure_maker", "ramp_permanent", "ramp_engine", "ramp_ritual", "ramp"}:
        return "early_mana"
    if all_signals & {"hand_filter", "draw_cards", "draw_engine", "topdeck_manipulation", "exile_value", "draw"}:
        return "hand_filter"
    if all_signals & {"recursion", "free_cast", "graveyard_recursion"}:
        return "graveyard_recursion"
    if all_signals & {"board_wipe", "remove_creature", "remove_permanent", "removal"}:
        return "pressure_absorber_or_protection"
    if all_signals & {"counter", "silence_spell", "silence_opponents", "protection"}:
        return "protection_window"
    if all_signals & {"finisher", "deal_damage", "wincon"}:
        return "finisher_or_big_spell"
    return "contextual"


def cut_status(
    card: dict[str, Any],
    decision: dict[str, Any],
    cut_safety: dict[str, Any],
    untested_flex: dict[str, Any],
    negative_cut_evidence: list[dict[str, Any]],
) -> str:
    if cut_safety.get("status") in LOCKED_CUT_STATUSES:
        return "blocked_locked_cut"
    if negative_cut_evidence:
        return "tested_negative_cut"
    if cut_safety.get("status") in RISKY_CUT_STATUSES:
        return "risky_same_lane_only"
    if untested_flex:
        return "untested_flex_candidate"
    if decision.get("decision") in {"locked_core", "mana_base_core"}:
        return "blocked_core_cut"
    if decision.get("status") in {"core_support", "core_or_flex_engine"}:
        return "requires_same_lane_gate"
    if card.get("is_commander"):
        return "blocked_commander"
    return "manual_review_needed"


def mine_variant_candidates(
    *,
    deck_cards: dict[int, dict[str, dict[str, Any]]],
    base_deck_id: int,
    variant_deck_ids: Iterable[int],
    rule_index: dict[str, dict[str, Any]],
    gate_history: dict[str, Any],
) -> list[dict[str, Any]]:
    base_cards = deck_cards.get(base_deck_id, {})
    rows: list[dict[str, Any]] = []
    variant_presence: dict[str, dict[str, Any]] = {}
    for deck_id in variant_deck_ids:
        for key, card in deck_cards.get(deck_id, {}).items():
            if key in base_cards:
                continue
            entry = variant_presence.setdefault(
                key,
                {
                    **card,
                    "variant_decks": [],
                    "variant_deck_count": 0,
                    "variant_total_quantity": 0,
                    "functional_tags": Counter(),
                },
            )
            entry["variant_decks"].append(deck_id)
            entry["variant_deck_count"] += 1
            entry["variant_total_quantity"] += int(card.get("quantity") or 1)
            if card.get("functional_tag"):
                entry["functional_tags"][str(card["functional_tag"])] += 1
            for role in card.get("roles") or []:
                entry["functional_tags"][str(role)] += 1
    for key, card in variant_presence.items():
        rule = rule_index.get(key, {})
        active_rules = int(rule.get("active_rule_count") or 0)
        quality_flags = rule_quality_flags(card["card_name"], rule)
        negative_evidence = gate_history["negative_adds"].get(key, [])
        if active_rules <= 0:
            status = "blocked_runtime_rule_gap"
        elif quality_flags:
            status = "runtime_partial_needs_model_review"
        elif negative_evidence:
            status = "tested_negative_add_requires_new_cut"
        elif int(card["variant_deck_count"]) >= 4:
            status = "high_frequency_runtime_ready_unexplored"
        else:
            status = "runtime_ready_unexplored"
        score = (
            int(card["variant_deck_count"]) * 10
            + active_rules * 4
            + (20 if status == "high_frequency_runtime_ready_unexplored" else 0)
            + (-20 if status.startswith("blocked") else 0)
            + (-15 if quality_flags else 0)
            + (-10 if negative_evidence else 0)
        )
        rows.append(
            {
                "card_name": card["card_name"],
                "status": status,
                "score": score,
                "lane": candidate_lane(card, rule),
                "variant_decks": sorted(card["variant_decks"]),
                "variant_deck_count": int(card["variant_deck_count"]),
                "variant_total_quantity": int(card["variant_total_quantity"]),
                "functional_tags": dict(sorted(card["functional_tags"].items())),
                "cmc": card.get("cmc"),
                "type_line": card.get("type_line"),
                "active_rule_count": active_rules,
                "rule_count": int(rule.get("rule_count") or 0),
                "review_only_rule_count": int(rule.get("review_only_rule_count") or 0),
                "disabled_rule_count": int(rule.get("disabled_rule_count") or 0),
                "reviewed_rule_override_count": int(rule.get("reviewed_rule_override_count") or 0),
                "effects": sorted((rule.get("effects") or {}).keys()),
                "battle_model_scopes": sorted((rule.get("battle_model_scopes") or {}).keys()),
                "rule_quality_flags": quality_flags,
                "negative_add_count": len(negative_evidence),
                "negative_add_packages": [
                    evidence.get("package_key") for evidence in negative_evidence
                ],
            }
        )
    rows.sort(
        key=lambda row: (
            -int(row["score"]),
            -int(row["variant_deck_count"]),
            row["status"],
            row["card_name"],
        )
    )
    return rows


def build_cut_inventory(
    *,
    base_cards: dict[str, dict[str, Any]],
    card_decisions: dict[str, dict[str, Any]],
    cut_safety: dict[str, dict[str, Any]],
    untested_flex: dict[str, dict[str, Any]],
    gate_history: dict[str, Any],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for key, card in base_cards.items():
        decision = card_decisions.get(key, {})
        safety = cut_safety.get(key, {})
        flex = untested_flex.get(key, {})
        negative_evidence = gate_history["negative_cuts"].get(key, [])
        status = cut_status(card, decision, safety, flex, negative_evidence)
        rows.append(
            {
                "card_name": card["card_name"],
                "status": status,
                "lane": decision.get("package_lane") or card.get("functional_tag") or "contextual",
                "effective_role": decision.get("effective_role") or card.get("functional_tag"),
                "decision": decision.get("decision"),
                "decision_status": decision.get("status"),
                "quantity": int(card.get("quantity") or 1),
                "negative_cut_count": len(negative_evidence),
                "negative_cut_packages": [
                    evidence.get("package_key") for evidence in negative_evidence
                ],
                "cut_safety_status": safety.get("status"),
                "worst_delta_pp": safety.get("worst_delta_pp"),
                "worst_strong_seed_delta_pp": safety.get("worst_strong_seed_delta_pp"),
            }
        )
    rows.sort(key=lambda row: (row["status"], row["lane"], row["card_name"]))
    return rows


def propose_pairings(
    candidates: list[dict[str, Any]],
    cuts: list[dict[str, Any]],
    limit: int = 12,
) -> list[dict[str, Any]]:
    eligible_cut_statuses = {"untested_flex_candidate", "risky_same_lane_only", "manual_review_needed"}
    eligible_cuts = [row for row in cuts if row["status"] in eligible_cut_statuses]
    pairings: list[dict[str, Any]] = []
    for candidate in candidates:
        if candidate["status"] not in {
            "high_frequency_runtime_ready_unexplored",
            "runtime_ready_unexplored",
        }:
            continue
        lane = candidate["lane"]
        if lane == "contextual":
            pairings.append(
                {
                    "candidate": candidate["card_name"],
                    "candidate_status": candidate["status"],
                    "lane": lane,
                    "status": "needs_lane_model_before_gate",
                    "candidate_score": candidate["score"],
                    "cut_options": [],
                }
            )
            continue
        same_lane = [
            cut
            for cut in eligible_cuts
            if cut["lane"] == lane or lane in str(cut["lane"]) or str(cut["lane"]) in lane
        ]
        if not same_lane:
            pairings.append(
                {
                    "candidate": candidate["card_name"],
                    "candidate_status": candidate["status"],
                    "lane": lane,
                    "status": "needs_cut_model_before_gate",
                    "candidate_score": candidate["score"],
                    "cut_options": [],
                }
            )
            continue
        cut_options = [
            {
                "card_name": cut["card_name"],
                "status": cut["status"],
                "lane": cut["lane"],
                "negative_cut_count": cut["negative_cut_count"],
            }
            for cut in same_lane[:5]
        ]
        pairings.append(
            {
                "candidate": candidate["card_name"],
                "candidate_status": candidate["status"],
                "lane": lane,
                "status": "gate_candidate_requires_manual_review",
                "candidate_score": candidate["score"],
                "cut_options": cut_options,
            }
        )
    pairings.sort(key=lambda row: (-int(row["candidate_score"]), row["candidate"]))
    return pairings[:limit]


def build_report(
    *,
    conn: sqlite3.Connection,
    strategy_audit: dict[str, Any],
    prior_gate_paths: list[Path],
    base_deck_id: int = DEFAULT_BASE_DECK_ID,
    variant_deck_ids: Iterable[int] = DEFAULT_VARIANT_DECK_IDS,
) -> dict[str, Any]:
    variant_deck_ids = tuple(variant_deck_ids)
    all_deck_ids = (base_deck_id, *variant_deck_ids)
    deck_cards = load_deck_cards(conn, all_deck_ids)
    deck_metadata = load_deck_metadata(conn, all_deck_ids)
    rule_index = load_rule_index(conn)
    card_decisions, cut_safety, untested_flex = strategy_lookups(strategy_audit)
    gate_history = load_prior_gate_reports(prior_gate_paths)
    candidates = mine_variant_candidates(
        deck_cards=deck_cards,
        base_deck_id=base_deck_id,
        variant_deck_ids=variant_deck_ids,
        rule_index=rule_index,
        gate_history=gate_history,
    )
    cuts = build_cut_inventory(
        base_cards=deck_cards.get(base_deck_id, {}),
        card_decisions=card_decisions,
        cut_safety=cut_safety,
        untested_flex=untested_flex,
        gate_history=gate_history,
    )
    candidate_counts = Counter(row["status"] for row in candidates)
    cut_counts = Counter(row["status"] for row in cuts)
    pairings = propose_pairings(candidates, cuts)
    return {
        "generated_at": utc_now(),
        "source_db": str(DEFAULT_DB),
        "strategy_audit": str(DEFAULT_STRATEGY_AUDIT),
        "base_deck_id": base_deck_id,
        "variant_deck_ids": list(variant_deck_ids),
        "deck_metadata": {
            str(deck_id): deck_metadata.get(deck_id, {})
            for deck_id in all_deck_ids
        },
        "prior_gate_reports": gate_history["loaded_reports"],
        "summary": {
            "variant_only_card_count": len(candidates),
            "candidate_status_counts": dict(sorted(candidate_counts.items())),
            "cut_status_counts": dict(sorted(cut_counts.items())),
            "runtime_ready_unexplored_count": sum(
                candidate_counts.get(status, 0)
                for status in (
                    "high_frequency_runtime_ready_unexplored",
                    "runtime_ready_unexplored",
                )
            ),
            "blocked_runtime_rule_gap_count": candidate_counts.get("blocked_runtime_rule_gap", 0),
            "tested_negative_add_count": candidate_counts.get(
                "tested_negative_add_requires_new_cut", 0
            ),
            "tested_negative_cut_count": cut_counts.get("tested_negative_cut", 0),
            "pairing_count": len(pairings),
        },
        "top_variant_candidates": candidates[:60],
        "cut_inventory": cuts,
        "pairing_hypotheses": pairings,
        "negative_exact_packages": gate_history["exact_negative"],
        "method_notes": [
            "SQLite/Hermes was read as an audit cache only; no PostgreSQL write was performed.",
            "Battle rules were aggregated by card name before deck comparison to avoid multi-rule fanout.",
            "A candidate with a prior negative add is not rejected forever, but it requires a different cut model before retest.",
            "A cut with prior negative evidence is protected until a same-lane package gives stronger proof.",
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Variant Gap Miner - 2026-06-27",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Source DB: `{payload['source_db']}`",
        f"- Strategy audit: `{payload['strategy_audit']}`",
        f"- Base deck: `{payload['base_deck_id']}`",
        f"- Variant decks: `{', '.join(str(deck_id) for deck_id in payload['variant_deck_ids'])}`",
        "- PostgreSQL writes: `false`",
        "- SQLite source mutated: `false`",
        "",
        "## Summary",
        "",
    ]
    for key, value in payload["summary"].items():
        lines.append(f"- {key}: `{value}`")
    lines.extend(["", "## Top Variant Candidates", ""])
    lines.append(
        "| Rank | Card | Status | Score | Decks | Lane | Active Rules | Reviewed Overrides | Effects | Rule Quality Flags | Prior Negative Adds |"
    )
    lines.append("| ---: | --- | --- | ---: | --- | --- | ---: | ---: | --- | --- | ---: |")
    for index, row in enumerate(payload["top_variant_candidates"][:30], start=1):
        lines.append(
            "| {rank} | `{card}` | `{status}` | {score} | {decks} | `{lane}` | {rules} | {overrides} | {effects} | {flags} | {negative} |".format(
                rank=index,
                card=row["card_name"],
                status=row["status"],
                score=row["score"],
                decks=", ".join(str(deck_id) for deck_id in row["variant_decks"]),
                lane=row["lane"],
                rules=row["active_rule_count"],
                overrides=row.get("reviewed_rule_override_count") or 0,
                effects=", ".join(row["effects"]) or "none",
                flags=", ".join(row.get("rule_quality_flags") or []) or "none",
                negative=row["negative_add_count"],
            )
        )
    lines.extend(["", "## Cut Risk Inventory", ""])
    lines.append("| Card | Status | Lane | Negative Cut Count | Negative Packages |")
    lines.append("| --- | --- | --- | ---: | --- |")
    for row in payload["cut_inventory"]:
        if row["status"] in {
            "blocked_locked_cut",
            "tested_negative_cut",
            "risky_same_lane_only",
            "untested_flex_candidate",
        }:
            lines.append(
                "| `{card}` | `{status}` | `{lane}` | {count} | {packages} |".format(
                    card=row["card_name"],
                    status=row["status"],
                    lane=row["lane"],
                    count=row["negative_cut_count"],
                    packages=", ".join(str(pkg) for pkg in row["negative_cut_packages"]) or "none",
                )
            )
    lines.extend(["", "## Pairing Hypotheses", ""])
    if not payload["pairing_hypotheses"]:
        lines.append("- No automatic pairing is justified; choose a cut model before the next gate.")
    for row in payload["pairing_hypotheses"]:
        cuts = "; ".join(
            f"{cut['card_name']} ({cut['status']}, {cut['lane']})"
            for cut in row["cut_options"]
        ) or "none"
        lines.append(
            "- `{candidate}` -> `{status}` in lane `{lane}`; cut options: {cuts}".format(
                candidate=row["candidate"],
                status=row["status"],
                lane=row["lane"],
                cuts=cuts,
            )
        )
    lines.extend(["", "## Method Notes", ""])
    for note in payload["method_notes"]:
        lines.append(f"- {note}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--queue-report", type=Path, default=DEFAULT_QUEUE_REPORT)
    parser.add_argument("--prior-gate-report", type=Path, action="append")
    parser.add_argument("--base-deck-id", type=int, default=DEFAULT_BASE_DECK_ID)
    parser.add_argument("--variant-deck-ids", default=None)
    parser.add_argument("--stem", default="lorehold_variant_gap_miner_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    prior_gate_paths = args.prior_gate_report or default_prior_gate_report_paths()
    if args.queue_report and args.queue_report not in prior_gate_paths:
        prior_gate_paths.append(args.queue_report)
    strategy_audit = read_json(args.strategy_audit)
    with connect(args.db) as conn:
        payload = build_report(
            conn=conn,
            strategy_audit=strategy_audit,
            prior_gate_paths=prior_gate_paths,
            base_deck_id=args.base_deck_id,
            variant_deck_ids=parse_deck_ids(args.variant_deck_ids),
        )
    payload["source_db"] = str(args.db)
    payload["strategy_audit"] = str(args.strategy_audit)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
