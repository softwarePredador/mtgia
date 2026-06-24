#!/usr/bin/env python3
"""Build the active Lorehold ideal-deck candidate matrix.

This is the deterministic routing layer between:

- Lorehold deck variants staged in Hermes SQLite;
- XMage/ManaLoom rule-readiness evidence;
- the safe master optimizer battle benchmark flow.

It does not mutate SQLite, PostgreSQL, or deck rows. The output is an evidence
matrix used to decide what must be rule-ready first and which cards are worth
benchmarking after the rules lane is closed.
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
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_PROPOSAL_REPORT = (
    REPORT_DIR / "xmage_current_replay_batch_pipeline_20260624_mapper_runtime_batch_v2_proposals.json"
)
DEFAULT_DECK_IDS = (6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616)
DEFAULT_ACTIVE_DECK_ID = 6
PREMIUM_MOX_BLOCKLIST = {"chrome mox", "mox diamond", "mox opal"}

TARGET_PROFILE = {
    "land": 33,
    "ramp": 20,
    "draw": 18,
    "removal": 8,
    "tutor": 5,
    "engine": 37,
    "wincon": 13,
    "protection": 13,
    "recursion": 4,
    "board_wipe": 2,
}

ROLE_PRIORITY = [
    "land",
    "tutor",
    "protection",
    "draw",
    "engine",
    "ramp",
    "wincon",
    "removal",
    "board_wipe",
    "recursion",
    "stax",
    "unknown",
]

ROLE_WEIGHTS = {
    "tutor": 18.0,
    "protection": 17.0,
    "draw": 15.0,
    "engine": 14.0,
    "ramp": 13.0,
    "wincon": 12.0,
    "removal": 11.0,
    "board_wipe": 10.0,
    "recursion": 9.0,
    "stax": 8.0,
    "land": 7.0,
    "unknown": 0.0,
}

ROLE_ALIASES = {
    "attack_limit": "protection",
    "attack_tax": "protection",
    "boardwipe": "board_wipe",
    "board_wipe": "board_wipe",
    "card_advantage": "draw",
    "copy": "engine",
    "copy_spell": "engine",
    "copy_spell_engine": "engine",
    "counter": "protection",
    "damage_wipe": "board_wipe",
    "draw_cards": "draw",
    "draw_engine": "draw",
    "extra_turn": "wincon",
    "finisher": "wincon",
    "graveyard": "recursion",
    "graveyard_to_battlefield": "recursion",
    "indestructible": "protection",
    "life_drain_engine": "wincon",
    "mill_spell": "wincon",
    "phase_out": "protection",
    "ramp_engine": "ramp",
    "ramp_permanent": "ramp",
    "ramp_ritual": "ramp",
    "recursion": "recursion",
    "remove_creature": "removal",
    "remove_permanent": "removal",
    "removal_destroy": "removal",
    "silence_opponents": "protection",
    "spell_copy": "engine",
    "static_cost_reducer": "ramp",
    "static_cost_reduction": "ramp",
    "token_maker": "wincon",
    "topdeck_manipulation": "draw",
    "treasure_maker": "ramp",
    "tutor_to_hand": "tutor",
    "wipe": "board_wipe",
}

RULE_RISK = {
    "battle_ready": 15.0,
    "package_ready": 8.0,
    "package_already_prepared": 6.0,
    "split_scope": -8.0,
    "runtime_needed": -12.0,
    "mapper_manual": -16.0,
    "blocked_missing_xmage_source": -80.0,
    "no_rule_signal": -10.0,
}

STRATEGIC_KEYWORDS = {
    "miracle": 7.0,
    "instant or sorcery": 4.0,
    "copy": 4.0,
    "graveyard": 3.0,
    "draw": 2.5,
    "discard": 2.0,
    "treasure": 2.0,
    "add ": 1.5,
    "search your library": 3.0,
    "can't cast": 2.5,
    "counter target": 2.5,
    "phase out": 2.5,
    "indestructible": 2.5,
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_name(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip().lower())


def parse_deck_ids(raw: str | None) -> list[int]:
    if not raw:
        return list(DEFAULT_DECK_IDS)
    ids: list[int] = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        ids.append(int(part))
    return ids


def json_list(value: object) -> list[Any]:
    if value is None or value == "":
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
    if value is None or value == "":
        return {}
    try:
        decoded = json.loads(str(value))
    except Exception:
        return {}
    return decoded if isinstance(decoded, dict) else {}


def normalize_role(value: object) -> str:
    role = normalize_name(value).replace(" ", "_")
    return ROLE_ALIASES.get(role, role if role in ROLE_WEIGHTS else "unknown")


def ordered_roles(values: set[str]) -> list[str]:
    cleaned = {role for role in values if role and role != "unknown"}
    if not cleaned:
        cleaned = {"unknown"}
    return sorted(
        cleaned,
        key=lambda role: (ROLE_PRIORITY.index(role) if role in ROLE_PRIORITY else 999, role),
    )


def row_has(row: sqlite3.Row, column: str) -> bool:
    return column in row.keys()


def table_exists(conn: sqlite3.Connection, table: str) -> bool:
    return (
        conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
            (table,),
        ).fetchone()
        is not None
    )


def load_proposals(path: Path | None) -> dict[str, dict[str, Any]]:
    if not path or not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    status_rank = {
        "blocked_missing_xmage_source": 90,
        "runtime_family_implementation_required": 80,
        "split_family_scope_review_required": 70,
        "mapper_metadata_or_test_scenario_required": 60,
        "manual_model_required": 60,
        "oracle_hash_required_before_batch_pg": 50,
        "batch_pg_candidate_after_precheck": 40,
    }
    proposals: dict[str, dict[str, Any]] = {}
    for proposal in payload.get("proposals", []):
        if not isinstance(proposal, dict):
            continue
        normalized = normalize_name(proposal.get("normalized_name") or proposal.get("card_name"))
        if not normalized:
            continue
        current = proposals.get(normalized)
        current_rank = status_rank.get(str((current or {}).get("proposal_status") or ""), 0)
        next_rank = status_rank.get(str(proposal.get("proposal_status") or ""), 0)
        if current is None or next_rank >= current_rank:
            proposals[normalized] = dict(proposal)
    return proposals


def load_battle_rules(conn: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    if not table_exists(conn, "battle_card_rules"):
        return {}
    rows = conn.execute(
        """
        SELECT normalized_name, card_name, logical_rule_key, effect_json,
               deck_role_json, review_status, execution_status, confidence
        FROM battle_card_rules
        WHERE execution_status != 'disabled'
        """
    ).fetchall()
    grouped: dict[str, dict[str, Any]] = {}
    for row in rows:
        normalized = normalize_name(row["normalized_name"] or row["card_name"])
        item = grouped.setdefault(
            normalized,
            {
                "rule_count": 0,
                "executable_rule_count": 0,
                "review_statuses": set(),
                "execution_statuses": set(),
                "effects": set(),
                "scopes": set(),
                "roles": set(),
                "logical_rule_keys": [],
                "max_confidence": 0.0,
            },
        )
        item["rule_count"] += 1
        review_status = str(row["review_status"] or "")
        execution_status = str(row["execution_status"] or "")
        item["review_statuses"].add(review_status)
        item["execution_statuses"].add(execution_status)
        if execution_status == "auto" and review_status in {"verified", "active", "needs_review"}:
            item["executable_rule_count"] += 1
        effect = json_dict(row["effect_json"])
        role = json_dict(row["deck_role_json"])
        if effect.get("effect"):
            item["effects"].add(str(effect["effect"]))
            item["roles"].add(normalize_role(effect["effect"]))
        if effect.get("battle_model_scope"):
            item["scopes"].add(str(effect["battle_model_scope"]))
        if role.get("category"):
            item["roles"].add(normalize_role(role["category"]))
        if row["logical_rule_key"]:
            item["logical_rule_keys"].append(str(row["logical_rule_key"]))
        try:
            item["max_confidence"] = max(float(item["max_confidence"]), float(row["confidence"] or 0))
        except Exception:
            pass
    result: dict[str, dict[str, Any]] = {}
    for normalized, item in grouped.items():
        result[normalized] = {
            **item,
            "review_statuses": sorted(item["review_statuses"]),
            "execution_statuses": sorted(item["execution_statuses"]),
            "effects": sorted(item["effects"]),
            "scopes": sorted(item["scopes"]),
            "roles": ordered_roles(item["roles"]),
        }
    return result


def _roles_from_deck_row(row: sqlite3.Row) -> set[str]:
    roles: set[str] = set()
    type_line = str(row["type_line"] or "")
    if "Land" in type_line:
        roles.add("land")
    if row_has(row, "functional_tag") and row["functional_tag"]:
        roles.add(normalize_role(row["functional_tag"]))
    if row_has(row, "functional_tags_json"):
        for value in json_list(row["functional_tags_json"]):
            if isinstance(value, dict):
                value = value.get("tag") or value.get("role") or value.get("category")
            roles.add(normalize_role(value))
    if row_has(row, "battle_rules_json"):
        for rule in json_list(row["battle_rules_json"]):
            if not isinstance(rule, dict):
                continue
            roles.add(normalize_role((rule.get("deck_role_json") or {}).get("category")))
            roles.add(normalize_role((rule.get("effect_json") or {}).get("effect")))
    return {role for role in roles if role and role != "unknown"}


def load_deck_cards(conn: sqlite3.Connection, deck_ids: list[int]) -> dict[str, dict[str, Any]]:
    placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT *
        FROM deck_cards
        WHERE deck_id IN ({placeholders})
        ORDER BY deck_id, is_commander DESC, card_name
        """,
        tuple(deck_ids),
    ).fetchall()
    cards: dict[str, dict[str, Any]] = {}
    for row in rows:
        normalized = normalize_name(row["card_name"])
        if not normalized:
            continue
        quantity = int(row["quantity"] or 0)
        item = cards.setdefault(
            normalized,
            {
                "card_name": str(row["card_name"]),
                "normalized_name": normalized,
                "deck_quantities": defaultdict(int),
                "source_names": set(),
                "roles": set(),
                "is_commander": False,
                "cmc": None,
                "type_line": "",
                "oracle_text": "",
                "card_id": "",
            },
        )
        item["deck_quantities"][int(row["deck_id"])] += quantity
        item["source_names"].add(str(row["card_name"]))
        item["roles"].update(_roles_from_deck_row(row))
        item["is_commander"] = bool(item["is_commander"] or int(row["is_commander"] or 0))
        if item["cmc"] is None and row_has(row, "cmc"):
            item["cmc"] = row["cmc"]
        for column in ("type_line", "oracle_text", "card_id"):
            if row_has(row, column) and not item[column] and row[column]:
                item[column] = str(row[column])
    for item in cards.values():
        item["deck_quantities"] = dict(sorted(item["deck_quantities"].items()))
        item["deck_ids"] = sorted(item["deck_quantities"])
        item["source_names"] = sorted(item["source_names"])
        item["roles"] = set(item["roles"])
    return cards


def build_active_profile(cards: dict[str, dict[str, Any]], active_deck_id: int) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for item in cards.values():
        quantity = int(item["deck_quantities"].get(active_deck_id, 0))
        if not quantity:
            continue
        roles = item["roles"] or {"unknown"}
        for role in roles:
            counts[role] += quantity
    return dict(sorted(counts.items()))


def proposal_rule_status(proposal: dict[str, Any] | None) -> str | None:
    if not proposal:
        return None
    status = str(proposal.get("proposal_status") or "")
    if status == "blocked_missing_xmage_source":
        return "blocked_missing_xmage_source"
    if status == "runtime_family_implementation_required":
        return "runtime_needed"
    if status == "split_family_scope_review_required":
        return "split_scope"
    if status in {"mapper_metadata_or_test_scenario_required", "manual_model_required"}:
        return "mapper_manual"
    if status in {"batch_pg_candidate_after_precheck", "oracle_hash_required_before_batch_pg"}:
        return "package_ready"
    return None


def infer_rule_status(
    item: dict[str, Any],
    battle_rule: dict[str, Any] | None,
    proposal: dict[str, Any] | None,
) -> str:
    if battle_rule and int(battle_rule.get("executable_rule_count") or 0) > 0:
        return "battle_ready"
    proposed = proposal_rule_status(proposal)
    if proposed:
        return proposed
    if battle_rule and int(battle_rule.get("rule_count") or 0) > 0:
        return "package_already_prepared"
    return "no_rule_signal"


def role_gap_boost(roles: list[str], active_profile: dict[str, int]) -> float:
    boost = 0.0
    for role in roles:
        target = TARGET_PROFILE.get(role)
        if target is None:
            continue
        gap = target - int(active_profile.get(role, 0))
        if gap > 0:
            boost += min(8.0, gap * 1.5)
    return min(boost, 12.0)


def keyword_bonus(oracle_text: str, type_line: str) -> float:
    text = f"{type_line}\n{oracle_text}".lower()
    bonus = 0.0
    for needle, value in STRATEGIC_KEYWORDS.items():
        if needle in text:
            bonus += value
    if "Instant" in type_line or "Sorcery" in type_line:
        bonus += 4.0
    return min(bonus, 18.0)


def cmc_adjustment(cmc: object, roles: list[str], type_line: str) -> float:
    try:
        value = float(cmc if cmc is not None else 0)
    except Exception:
        return -1.0
    if "Land" in type_line or "land" in roles:
        return 0.0
    if value <= 2:
        return 4.0
    if value <= 4:
        return 2.0
    if value <= 6:
        return 0.0
    if {"wincon", "board_wipe"}.intersection(roles):
        return -min(5.0, value - 6.0)
    return -min(10.0, (value - 6.0) * 1.5)


def score_candidate(
    item: dict[str, Any],
    roles: list[str],
    rule_status: str,
    active_profile: dict[str, int],
    active_deck_id: int,
) -> tuple[float, dict[str, float]]:
    normalized = item["normalized_name"]
    if normalized in PREMIUM_MOX_BLOCKLIST:
        return -1000.0, {"policy_block": -1000.0}
    variant_decks = [deck_id for deck_id in item["deck_ids"] if deck_id != active_deck_id]
    role_weight = max(ROLE_WEIGHTS.get(role, 0.0) for role in roles)
    breakdown = {
        "role_weight": role_weight,
        "active_deck_bonus": 10.0 if item["deck_quantities"].get(active_deck_id) else 0.0,
        "variant_support": min(20.0, len(variant_decks) * 2.0),
        "rule_readiness": RULE_RISK.get(rule_status, 0.0),
        "role_gap": role_gap_boost(roles, active_profile),
        "keyword_synergy": keyword_bonus(str(item.get("oracle_text") or ""), str(item.get("type_line") or "")),
        "cmc": cmc_adjustment(item.get("cmc"), roles, str(item.get("type_line") or "")),
    }
    return round(sum(breakdown.values()), 3), breakdown


def recommendation_lane(item: dict[str, Any], score: float, rule_status: str) -> str:
    normalized = item["normalized_name"]
    active = bool(item.get("in_active_deck"))
    if normalized in PREMIUM_MOX_BLOCKLIST:
        return "policy_blocked"
    if rule_status in {
        "blocked_missing_xmage_source",
        "runtime_needed",
        "split_scope",
        "mapper_manual",
        "no_rule_signal",
    }:
        return "needs_rule_before_strategy"
    if active and score >= 45:
        return "core_keep"
    if not active and score >= 45:
        return "priority_benchmark_candidate"
    if not active and score >= 32:
        return "watchlist_candidate"
    if active:
        return "active_low_confidence_review"
    return "low_priority"


def next_action_for(lane: str, rule_status: str) -> str:
    if lane == "policy_blocked":
        return "exclude_from_lorehold_no_premium_mox_policy"
    if lane == "needs_rule_before_strategy":
        if rule_status == "split_scope":
            return "split_xmage_scope_then_promote_rule_before_swap_testing"
        if rule_status == "runtime_needed":
            return "implement_runtime_family_with_focused_test_before_swap_testing"
        if rule_status == "blocked_missing_xmage_source":
            return "isolate_missing_xmage_source_exception"
        return "map_or_verify_rule_before_strategy_scoring"
    if lane in {"priority_benchmark_candidate", "watchlist_candidate"}:
        return "run_safe_slot_benchmark_after_baseline_hash_guard"
    if lane == "core_keep":
        return "keep_as_current_core_unless_battle_evidence_regresses"
    if lane == "active_low_confidence_review":
        return "review_current_slot_after_higher_priority_candidates"
    return "defer"


def build_candidate_matrix(
    conn: sqlite3.Connection,
    *,
    active_deck_id: int,
    deck_ids: list[int],
    proposals: dict[str, dict[str, Any]] | None = None,
) -> dict[str, Any]:
    conn.row_factory = sqlite3.Row
    proposals = proposals or {}
    cards = load_deck_cards(conn, deck_ids)
    battle_rules = load_battle_rules(conn)
    active_profile = build_active_profile(cards, active_deck_id)
    rows: list[dict[str, Any]] = []

    for normalized, item in cards.items():
        battle_rule = battle_rules.get(normalized)
        proposal = proposals.get(normalized)
        roles = set(item["roles"])
        if battle_rule:
            roles.update(battle_rule.get("roles") or [])
        if proposal:
            role = json_dict(proposal.get("deck_role_json")).get("category")
            effect = json_dict(proposal.get("effect_json")).get("effect") or proposal.get("effect")
            roles.add(normalize_role(role))
            roles.add(normalize_role(effect))
        ordered = ordered_roles(roles)
        rule_status = infer_rule_status(item, battle_rule, proposal)
        item["in_active_deck"] = bool(item["deck_quantities"].get(active_deck_id))
        score, breakdown = score_candidate(item, ordered, rule_status, active_profile, active_deck_id)
        lane = recommendation_lane(item, score, rule_status)
        rows.append(
            {
                "card_name": item["card_name"],
                "normalized_name": normalized,
                "deck_ids": item["deck_ids"],
                "deck_quantities": item["deck_quantities"],
                "in_active_deck": item["in_active_deck"],
                "roles": ordered,
                "cmc": item.get("cmc"),
                "type_line": item.get("type_line") or "",
                "rule_status": rule_status,
                "battle_rule_count": int((battle_rule or {}).get("rule_count") or 0),
                "executable_rule_count": int((battle_rule or {}).get("executable_rule_count") or 0),
                "battle_rule_effects": (battle_rule or {}).get("effects") or [],
                "battle_model_scopes": sorted(
                    set((battle_rule or {}).get("scopes") or [])
                    | {str(proposal.get("battle_model_scope") or "") if proposal else ""}
                    - {""}
                ),
                "proposal_status": (proposal or {}).get("proposal_status"),
                "promotion_lane": (proposal or {}).get("promotion_lane"),
                "family_id": (proposal or {}).get("family_id"),
                "focused_test_scenario_count": (proposal or {}).get("focused_test_scenario_count"),
                "score": score,
                "score_breakdown": breakdown,
                "recommendation_lane": lane,
                "next_action": next_action_for(lane, rule_status),
            }
        )

    lane_rank = {
        "policy_blocked": 0,
        "needs_rule_before_strategy": 1,
        "priority_benchmark_candidate": 2,
        "core_keep": 3,
        "watchlist_candidate": 4,
        "active_low_confidence_review": 5,
        "low_priority": 6,
    }
    rows.sort(
        key=lambda row: (
            lane_rank.get(str(row["recommendation_lane"]), 99),
            -float(row["score"]),
            row["card_name"],
        )
    )

    summary = {
        "generated_at": utc_now(),
        "status": "ready",
        "active_deck_id": active_deck_id,
        "deck_ids": deck_ids,
        "target_profile": TARGET_PROFILE,
        "active_profile": active_profile,
        "row_count": len(rows),
        "recommendation_lane_counts": dict(Counter(row["recommendation_lane"] for row in rows)),
        "rule_status_counts": dict(Counter(row["rule_status"] for row in rows)),
        "role_counts_in_matrix": dict(Counter(role for row in rows for role in row["roles"])),
        "policy": {
            "premium_mox_blocklist": sorted(PREMIUM_MOX_BLOCKLIST),
            "no_deck_mutations": True,
            "postgres_writes": False,
        },
    }
    return {"summary": summary, "rows": rows}


def render_markdown(report: dict[str, Any], proposal_report: Path | None) -> str:
    summary = report["summary"]
    rows = report["rows"]
    lines = [
        "# Lorehold Ideal Deck Candidate Matrix",
        "",
        f"- Generated at: `{summary['generated_at']}`",
        f"- Status: `{summary['status']}`",
        f"- Active deck id: `{summary['active_deck_id']}`",
        f"- Lorehold deck ids: `{json.dumps(summary['deck_ids'])}`",
        f"- Proposal report: `{proposal_report if proposal_report else '-'}`",
        f"- PostgreSQL writes: `{summary['policy']['postgres_writes']}`",
        f"- Deck mutations: `{not summary['policy']['no_deck_mutations']}`",
        "",
        "## Operating Decision",
        "",
        "Use this matrix before any Lorehold swap work. Cards in",
        "`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence",
        "closed before battle benchmarking. Cards in",
        "`priority_benchmark_candidate` are the first safe candidates for",
        "`slot_optimizer.py` after the baseline hash guard passes.",
        "",
        "## Summary",
        "",
        f"- Rows: `{summary['row_count']}`",
        f"- Recommendation lanes: `{json.dumps(summary['recommendation_lane_counts'], sort_keys=True)}`",
        f"- Rule statuses: `{json.dumps(summary['rule_status_counts'], sort_keys=True)}`",
        f"- Active profile: `{json.dumps(summary['active_profile'], sort_keys=True)}`",
        "",
        "## Top Rule-First Cards",
        "",
        "| Card | Score | Roles | Rule status | Scope/family | Next action |",
        "| --- | ---: | --- | --- | --- | --- |",
    ]
    for row in [r for r in rows if r["recommendation_lane"] == "needs_rule_before_strategy"][:30]:
        scope = ", ".join(row["battle_model_scopes"][:2]) or str(row.get("family_id") or "-")
        lines.append(
            f"| {row['card_name']} | {row['score']} | {', '.join(row['roles'])} | "
            f"{row['rule_status']} | {scope} | {row['next_action']} |"
        )
    lines.extend(
        [
            "",
            "## Top Benchmark Candidates",
            "",
            "| Card | Score | Roles | Decks | Rule status | Next action |",
            "| --- | ---: | --- | --- | --- | --- |",
        ]
    )
    candidates = [
        r
        for r in rows
        if r["recommendation_lane"] in {"priority_benchmark_candidate", "watchlist_candidate"}
    ][:30]
    for row in candidates:
        lines.append(
            f"| {row['card_name']} | {row['score']} | {', '.join(row['roles'])} | "
            f"{json.dumps(row['deck_ids'])} | {row['rule_status']} | {row['next_action']} |"
        )
    lines.extend(
        [
            "",
            "## Core Keeps",
            "",
            "| Card | Score | Roles | Rule status |",
            "| --- | ---: | --- | --- |",
        ]
    )
    for row in [r for r in rows if r["recommendation_lane"] == "core_keep"][:30]:
        lines.append(
            f"| {row['card_name']} | {row['score']} | {', '.join(row['roles'])} | {row['rule_status']} |"
        )
    return "\n".join(lines) + "\n"


def write_outputs(report: dict[str, Any], output_prefix: Path, proposal_report: Path | None) -> tuple[Path, Path]:
    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = output_prefix.with_suffix(".json")
    md_path = output_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=True, sort_keys=True), encoding="utf-8")
    md_path.write_text(render_markdown(report, proposal_report), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--active-deck-id", type=int, default=DEFAULT_ACTIVE_DECK_ID)
    parser.add_argument("--deck-ids", default=",".join(str(deck_id) for deck_id in DEFAULT_DECK_IDS))
    parser.add_argument("--proposal-report", type=Path, default=DEFAULT_PROPOSAL_REPORT)
    parser.add_argument(
        "--output-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_ideal_candidate_matrix_20260624_v1",
    )
    parser.add_argument("--no-write", action="store_true")
    args = parser.parse_args()

    deck_ids = parse_deck_ids(args.deck_ids)
    proposals = load_proposals(args.proposal_report)
    conn = sqlite3.connect(args.db)
    conn.row_factory = sqlite3.Row
    try:
        report = build_candidate_matrix(
            conn,
            active_deck_id=args.active_deck_id,
            deck_ids=deck_ids,
            proposals=proposals,
        )
    finally:
        conn.close()

    if args.no_write:
        print(json.dumps(report["summary"], indent=2, sort_keys=True))
        return 0
    json_path, md_path = write_outputs(report, args.output_prefix, args.proposal_report)
    print(f"status={report['summary']['status']}")
    print(f"rows={report['summary']['row_count']}")
    print(f"json={json_path}")
    print(f"markdown={md_path}")
    print(
        "recommendation_lane_counts="
        + json.dumps(report["summary"]["recommendation_lane_counts"], sort_keys=True)
    )
    print("rule_status_counts=" + json.dumps(report["summary"]["rule_status_counts"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
