#!/usr/bin/env python3
"""Validate Lorehold mana-base swaps before any noisy battle gate.

This read-only helper compares variant land candidates against the current
deck-6 mana base. It is intentionally deterministic: a land swap can be marked
ready only when it preserves red/white source access and does not cut a unique
mana-base role such as fetch access, Ancient Tomb acceleration, or Command
Beacon commander recovery.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = (
    REPORT_DIR
    / "lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob"
    / "knowledge_candidate.db"
)
DEFAULT_MINER_REPORT = (
    REPORT_DIR / "lorehold_variant_gap_miner_20260627_v3_post_austere_tradeoff.json"
)
DEFAULT_PRIOR_LAND_GATE_REPORTS = [
    REPORT_DIR
    / "lorehold_spell_protection_land_gate_20260627_seed42_v1_spell_protection_land_v1_boseiju_spell_protection_land.json",
]

BOROS_COLORS = {"R", "W"}
ACTIVE_RULE_STATUSES = {"active", "auto", "reviewed", "verified"}
ACTIVE_REVIEW_STATUSES = {"active", "reviewed", "verified", "needs_review"}
MEANINGFUL_UTILITY_ROLES = {
    "card_draw",
    "channel_removal",
    "channel_utility",
    "cycling",
    "no_max_hand_size",
    "surveil",
}
PROTECTED_UTILITY_ROLES = {
    "basic_source_count",
    "commander_recast",
    "commander_any_color",
    "commander_legendary_mana",
    "fast_colorless_acceleration",
    "fetch_dual_access",
    "legendary_protection",
    "saga_artifact_tutor",
}
LAND_OVERRIDES = {
    "plateau": {
        "type_line": "Land - Mountain Plains",
        "oracle_text": "Tap: Add R or W.",
    },
    "clifftop retreat": {
        "type_line": "Land",
        "oracle_text": "This land enters tapped unless you control a Mountain or a Plains. Tap: Add R or W.",
    },
    "boseiju who shelters all": {
        "type_line": "Legendary Land",
        "oracle_text": "Boseiju enters tapped. Tap, Pay 2 life: Add C. If that mana is spent on an instant or sorcery spell, that spell cannot be countered.",
    },
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_existing_json(paths: Iterable[Path]) -> list[tuple[Path, dict[str, Any]]]:
    return [(path, read_json(path)) for path in paths if path.exists()]


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def json_list(value: object) -> list[Any]:
    if isinstance(value, list):
        return value
    if value in (None, ""):
        return []
    try:
        decoded = json.loads(str(value))
    except Exception:
        return []
    return decoded if isinstance(decoded, list) else []


def db_card_oracle(conn: sqlite3.Connection, card_name: str) -> dict[str, Any] | None:
    rows = conn.execute(
        """
        SELECT name, type_line, oracle_text
        FROM card_oracle_cache
        WHERE lower(name) = lower(?)
           OR replace(replace(lower(name), ',', ''), '''', '') = ?
           OR replace(replace(lower(normalized_name), ',', ''), '''', '') = ?
        LIMIT 1
        """,
        (
            card_name,
            normalize_key(card_name).replace(" ", ""),
            normalize_key(card_name).replace(" ", ""),
        ),
    ).fetchall()
    if not rows:
        return None
    row = rows[0]
    return {
        "card_name": row["name"] or card_name,
        "type_line": row["type_line"] or "",
        "oracle_text": row["oracle_text"] or "",
        "source": "card_oracle_cache",
    }


def load_deck_lands(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT card_name, quantity, type_line, oracle_text, battle_rules_json
        FROM deck_cards
        WHERE deck_id = ?
          AND (lower(type_line) LIKE '%land%' OR functional_tag = 'land')
        ORDER BY card_name
        """,
        (deck_id,),
    ).fetchall()
    lands = []
    for row in rows:
        lands.append(
            {
                "card_name": row["card_name"],
                "quantity": int(row["quantity"] or 1),
                "type_line": row["type_line"] or "",
                "oracle_text": row["oracle_text"] or "",
                "battle_rules": json_list(row["battle_rules_json"]),
                "source": "deck_cards",
            }
        )
    return lands


def load_rule_summary(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name) for name in names}
    out = {
        key: {
            "active_rule_count": 0,
            "rule_count": 0,
            "battle_model_scopes": [],
        }
        for key in wanted
    }
    rows = conn.execute(
        """
        SELECT card_name, execution_status, review_status, effect_json
        FROM battle_card_rules
        ORDER BY card_name
        """
    ).fetchall()
    for row in rows:
        key = normalize_key(row["card_name"])
        if key not in out:
            continue
        summary = out[key]
        summary["rule_count"] += 1
        execution_status = str(row["execution_status"] or "")
        review_status = str(row["review_status"] or "")
        if execution_status in ACTIVE_RULE_STATUSES and review_status in ACTIVE_REVIEW_STATUSES:
            summary["active_rule_count"] += 1
        try:
            effect = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect = {}
        if isinstance(effect, dict) and effect.get("battle_model_scope"):
            summary["battle_model_scopes"].append(str(effect["battle_model_scope"]))
    for row in out.values():
        row["battle_model_scopes"] = sorted(set(row["battle_model_scopes"]))
    return out


def mana_colors(type_line: str, oracle_text: str) -> set[str]:
    text = f"{type_line}\n{oracle_text}".lower()
    colors: set[str] = set()
    if "mountain" in text or "{r}" in text or " add r" in text or " r or " in text:
        colors.add("R")
    if "plains" in text or "{w}" in text or " add w" in text or " w or " in text:
        colors.add("W")
    if "any color in your commander's color identity" in text:
        colors.update(BOROS_COLORS)
    if "add one mana of any color" in text and (
        "legendary spell" in text or "legendary permanent" in text
    ):
        colors.update(BOROS_COLORS)
    if "any color that a land an opponent controls could produce" in text:
        colors.update(BOROS_COLORS)
    if "search your library" in text and (
        "mountain" in text or "plains" in text or "basic land" in text
    ):
        colors.update(BOROS_COLORS)
    if "{c}" in text or " add c" in text or "add one colorless" in text:
        colors.add("C")
    return colors


def etb_mode(oracle_text: str) -> str:
    text = oracle_text.lower()
    if "unless you have two or more opponents" in text:
        return "untapped_commander_multiplayer"
    if "enters tapped unless" in text or "enters the battlefield tapped unless" in text:
        return "conditional_tapped"
    if "if you don't, it enters tapped" in text:
        return "optional_life_untapped"
    if "enters tapped" in text or "enters the battlefield tapped" in text:
        return "always_tapped"
    return "untapped"


def etb_score(mode: str) -> int:
    return {
        "always_tapped": 0,
        "conditional_tapped": 1,
        "optional_life_untapped": 2,
        "untapped_commander_multiplayer": 3,
        "untapped": 3,
    }.get(mode, 1)


def utility_roles(card_name: str, type_line: str, oracle_text: str) -> set[str]:
    key = normalize_key(card_name)
    text = f"{type_line}\n{oracle_text}".lower()
    roles: set[str] = set()
    if "basic land" in type_line.lower():
        roles.add("basic_source_count")
    if "search your library" in text and "sacrifice" in text and (
        "mountain" in text or "plains" in text or "basic land" in text
    ):
        roles.add("fetch_dual_access")
    if "any color in your commander's color identity" in text:
        roles.add("commander_any_color")
    if "add one mana of any color" in text and (
        "legendary spell" in text or "legendary permanent" in text
    ):
        roles.add("commander_legendary_mana")
    if "hexproof and indestructible" in text and "legendary" in text:
        roles.add("legendary_protection")
    if key == "ancient tomb" or "{c}{c}" in text or "add cc" in text:
        roles.add("fast_colorless_acceleration")
    if "commander into your hand" in text:
        roles.add("commander_recast")
    if "no maximum hand size" in text:
        roles.add("no_max_hand_size")
    if "draw a card" in text:
        roles.add("card_draw")
    if "cycling" in text:
        roles.add("cycling")
    if "surveil" in text:
        roles.add("surveil")
    if key == "urza s saga" or ("artifact card with mana cost 0 or 1" in text):
        roles.add("saga_artifact_tutor")
    if "channel" in text:
        roles.add("channel_utility")
    if "channel" in text and ("damage" in text or "destroy" in text):
        roles.add("channel_removal")
    if "can't be countered" in text or "cannot be countered" in text:
        roles.add("spell_protection")
    if "mountain plains" in type_line.lower():
        roles.add("fetchable_boros_dual")
    if "deals 1 damage to you" in text:
        roles.add("colored_pain_cost")
    if "pay 2 life" in text:
        roles.add("spell_protection_life_cost")
    return roles


def land_profile(card: dict[str, Any], rules: dict[str, dict[str, Any]] | None = None) -> dict[str, Any]:
    name = str(card.get("card_name") or "")
    type_line = str(card.get("type_line") or "")
    oracle_text = str(card.get("oracle_text") or "")
    key = normalize_key(name)
    mode = etb_mode(oracle_text)
    colors = mana_colors(type_line, oracle_text)
    roles = utility_roles(name, type_line, oracle_text)
    rule_summary = (rules or {}).get(key) or {}
    return {
        "card_name": name,
        "quantity": int(card.get("quantity") or 1),
        "type_line": type_line,
        "oracle_text": oracle_text,
        "source": card.get("source") or "",
        "colors": sorted(colors),
        "produces_red": "R" in colors,
        "produces_white": "W" in colors,
        "produces_colorless": "C" in colors,
        "boros_source_count": int("R" in colors) + int("W" in colors),
        "etb_mode": mode,
        "etb_score": etb_score(mode),
        "utility_roles": sorted(roles),
        "active_rule_count": int(rule_summary.get("active_rule_count") or 0),
        "rule_count": int(rule_summary.get("rule_count") or 0),
        "battle_model_scopes": rule_summary.get("battle_model_scopes") or [],
    }


def candidate_card(conn: sqlite3.Connection, card_name: str) -> dict[str, Any]:
    db_row = db_card_oracle(conn, card_name)
    if db_row:
        return db_row
    override = LAND_OVERRIDES.get(normalize_key(card_name))
    if override:
        return {
            "card_name": card_name,
            "quantity": 1,
            "type_line": override["type_line"],
            "oracle_text": override["oracle_text"],
            "source": "local_override",
        }
    return {
        "card_name": card_name,
        "quantity": 1,
        "type_line": "",
        "oracle_text": "",
        "source": "missing_oracle",
    }


def mana_candidate_names(miner_report: dict[str, Any]) -> list[str]:
    names = []
    for row in miner_report.get("pairing_hypotheses") or []:
        if row.get("lane") == "mana_base" and row.get("candidate"):
            names.append(str(row["candidate"]))
    return sorted(set(names), key=normalize_key)


def miner_cut_option_lookup(miner_report: dict[str, Any]) -> dict[tuple[str, str], dict[str, Any]]:
    out = {}
    for row in miner_report.get("pairing_hypotheses") or []:
        candidate = normalize_key(row.get("candidate"))
        if row.get("lane") != "mana_base" or not candidate:
            continue
        for option in row.get("cut_options") or []:
            cut = normalize_key(option.get("card_name"))
            if cut:
                out[(candidate, cut)] = option
    return out


def previous_land_gate_lookup(reports: list[tuple[Path, dict[str, Any]]]) -> dict[tuple[str, str], dict[str, Any]]:
    out: dict[tuple[str, str], dict[str, Any]] = {}
    for path, payload in reports:
        results = payload.get("results") or []
        for row in results:
            package_key = str(row.get("package_key") or "")
            if package_key == "boseiju_spell_protection_land":
                out[
                    (normalize_key("Boseiju, Who Shelters All"), normalize_key("Reliquary Tower"))
                ] = {
                    "source_report": str(path),
                    "package_key": package_key,
                    "status": "prior_negative_seed42_land_gate",
                    "candidate_wins": row.get("candidate_wins"),
                    "candidate_losses": row.get("candidate_losses"),
                    "baseline_wins": row.get("baseline_wins"),
                    "baseline_losses": row.get("baseline_losses"),
                    "delta_pp": row.get("delta_pp"),
                    "strong_seed_delta_pp": row.get("strong_seed_delta_pp"),
                }
    return out


def source_deltas(add: dict[str, Any], cut: dict[str, Any]) -> dict[str, Any]:
    return {
        "red_source_delta": int(add["produces_red"]) - int(cut["produces_red"]),
        "white_source_delta": int(add["produces_white"]) - int(cut["produces_white"]),
        "boros_source_delta": int(add["boros_source_count"]) - int(cut["boros_source_count"]),
        "etb_score_delta": int(add["etb_score"]) - int(cut["etb_score"]),
        "active_rule_delta": int(add["active_rule_count"]) - int(cut["active_rule_count"]),
    }


def readiness_score(
    add: dict[str, Any],
    cut: dict[str, Any],
    deltas: dict[str, Any],
    gained_roles: set[str],
    lost_roles: set[str],
) -> int:
    score = 0
    score += int(deltas["red_source_delta"]) * 25
    score += int(deltas["white_source_delta"]) * 25
    score += int(deltas["etb_score_delta"]) * 12
    if "fetchable_boros_dual" in gained_roles:
        score += 8
    if "colored_pain_cost" in lost_roles:
        score += 6
    if "spell_protection" in gained_roles:
        score += 5
    score -= 50 * len(PROTECTED_UTILITY_ROLES & lost_roles)
    score -= 15 * len(MEANINGFUL_UTILITY_ROLES & lost_roles)
    if add["source"] == "missing_oracle":
        score -= 100
    return score


def evaluate_swap(
    add: dict[str, Any],
    cut: dict[str, Any],
    *,
    miner_cut_option: dict[str, Any] | None = None,
    previous_land_gates: dict[tuple[str, str], dict[str, Any]] | None = None,
) -> dict[str, Any]:
    add_roles = set(add.get("utility_roles") or [])
    cut_roles = set(cut.get("utility_roles") or [])
    gained_roles = add_roles - cut_roles
    lost_roles = cut_roles - add_roles
    deltas = source_deltas(add, cut)
    blockers: list[str] = []
    warnings: list[str] = []
    status = "mana_model_observed_no_auto_swap"

    prior = (previous_land_gates or {}).get(
        (normalize_key(add["card_name"]), normalize_key(cut["card_name"]))
    )
    if prior:
        blockers.append("prior_negative_land_gate")
    if add["source"] == "missing_oracle":
        blockers.append("missing_candidate_oracle")
    if "fetch_dual_access" in lost_roles:
        blockers.append("would_cut_fetch_dual_access")
    if "fast_colorless_acceleration" in lost_roles:
        blockers.append("would_cut_fast_colorless_acceleration")
    if "commander_recast" in lost_roles:
        blockers.append("would_cut_commander_recast_utility")
    for role in sorted(PROTECTED_UTILITY_ROLES & lost_roles):
        blocker = f"would_cut_{role}"
        if blocker not in blockers:
            blockers.append(blocker)
    if deltas["red_source_delta"] < 0 or deltas["white_source_delta"] < 0:
        blockers.append("would_reduce_boros_color_sources")
    if deltas["etb_score_delta"] < 0 and "spell_protection" not in gained_roles:
        blockers.append("would_reduce_mana_timing")
    if MEANINGFUL_UTILITY_ROLES & lost_roles:
        warnings.append("meaningful_utility_loss_requires_manual_package")
    if miner_cut_option and miner_cut_option.get("status") in {
        "blocked_core_cut",
        "blocked_locked_cut",
    }:
        warnings.append(str(miner_cut_option["status"]))

    score = readiness_score(add, cut, deltas, gained_roles, lost_roles)
    if blockers:
        status = "blocked"
    elif warnings:
        status = "manual_review_required"
    elif score > 0 and (
        deltas["etb_score_delta"] > 0
        or "colored_pain_cost" in lost_roles
        or (deltas["boros_source_delta"] > 0 and not lost_roles)
    ):
        status = "preflight_land_swap_ready"

    return {
        "candidate": add["card_name"],
        "cut": cut["card_name"],
        "status": status,
        "score": score,
        "deltas": deltas,
        "candidate_profile": profile_public_fields(add),
        "cut_profile": profile_public_fields(cut),
        "gained_roles": sorted(gained_roles),
        "lost_roles": sorted(lost_roles),
        "blockers": blockers,
        "warnings": warnings,
        "miner_cut_option_status": (miner_cut_option or {}).get("status") or "",
        "miner_gate_readiness": (miner_cut_option or {}).get("gate_readiness") or "",
        "prior_land_gate": prior or {},
    }


def profile_public_fields(profile: dict[str, Any]) -> dict[str, Any]:
    return {
        "card_name": profile["card_name"],
        "source": profile["source"],
        "colors": profile["colors"],
        "boros_source_count": profile["boros_source_count"],
        "etb_mode": profile["etb_mode"],
        "etb_score": profile["etb_score"],
        "utility_roles": profile["utility_roles"],
        "active_rule_count": profile["active_rule_count"],
        "battle_model_scopes": profile["battle_model_scopes"],
    }


def build_report(
    *,
    conn: sqlite3.Connection,
    miner_report: dict[str, Any],
    prior_land_gate_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    db_path: Path = DEFAULT_DB,
    miner_path: Path = DEFAULT_MINER_REPORT,
    deck_id: int = 6,
) -> dict[str, Any]:
    deck_lands = load_deck_lands(conn, deck_id)
    candidate_names = mana_candidate_names(miner_report)
    candidates = [candidate_card(conn, name) for name in candidate_names]
    all_names = [row["card_name"] for row in deck_lands] + [row["card_name"] for row in candidates]
    rules = load_rule_summary(conn, all_names)
    deck_profiles = [land_profile(row, rules) for row in deck_lands]
    candidate_profiles = [land_profile(row, rules) for row in candidates]
    miner_options = miner_cut_option_lookup(miner_report)
    prior_lookup = previous_land_gate_lookup(prior_land_gate_reports or [])

    evaluations = []
    for add in candidate_profiles:
        for cut in deck_profiles:
            if normalize_key(add["card_name"]) == normalize_key(cut["card_name"]):
                continue
            evaluations.append(
                evaluate_swap(
                    add,
                    cut,
                    miner_cut_option=miner_options.get(
                        (normalize_key(add["card_name"]), normalize_key(cut["card_name"]))
                    ),
                    previous_land_gates=prior_lookup,
                )
            )
    evaluations.sort(
        key=lambda row: (
            row["status"] != "preflight_land_swap_ready",
            row["status"] != "manual_review_required",
            -int(row["score"]),
            row["candidate"],
            row["cut"],
        )
    )
    ready = [row for row in evaluations if row["status"] == "preflight_land_swap_ready"]
    manual = [row for row in evaluations if row["status"] == "manual_review_required"]
    blocked = [row for row in evaluations if row["status"] == "blocked"]
    status_counts: dict[str, int] = {}
    for row in evaluations:
        status_counts[row["status"]] = status_counts.get(row["status"], 0) + 1
    source_counts = {
        "lands": sum(int(row["quantity"]) for row in deck_profiles),
        "red_sources": sum(1 for row in deck_profiles if row["produces_red"]),
        "white_sources": sum(1 for row in deck_profiles if row["produces_white"]),
        "colorless_sources": sum(1 for row in deck_profiles if row["produces_colorless"]),
        "always_or_conditionally_tapped": sum(
            1
            for row in deck_profiles
            if row["etb_mode"] in {"always_tapped", "conditional_tapped"}
        ),
    }
    recommended = ready[0] if ready else None
    return {
        "generated_at": utc_now(),
        "source_db": str(db_path),
        "miner_report": str(miner_path),
        "deck_id": deck_id,
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "candidate_count": len(candidate_profiles),
            "deck_land_unique_count": len(deck_profiles),
            "deck_land_quantity": source_counts["lands"],
            "source_counts": source_counts,
            "evaluation_count": len(evaluations),
            "status_counts": dict(sorted(status_counts.items())),
            "ready_swap_count": len(ready),
            "manual_review_count": len(manual),
            "blocked_swap_count": len(blocked),
            "recommended_next_action": (
                "run_mana_base_validated_preflight"
                if ready
                else "batch_xmage_runtime_rule_gaps"
            ),
            "recommended_swap": recommended_summary(recommended),
        },
        "candidate_profiles": [profile_public_fields(row) for row in candidate_profiles],
        "deck_land_profiles": [profile_public_fields(row) for row in deck_profiles],
        "ready_swaps": ready[:20],
        "manual_review_swaps": manual[:20],
        "blocked_swaps_sample": blocked[:20],
        "all_evaluations": evaluations,
        "method_notes": [
            "This validator is deterministic and read-only.",
            "It may override the generic land-core blocker only for strict mana-source upgrades.",
            "Fetch lands, Ancient Tomb acceleration, and Command Beacon commander utility remain protected cuts.",
            "Prior negative land gates are carried forward as blockers.",
            "Battle gates are reserved for packages whose advantage cannot be isolated by mana-source math.",
        ],
    }


def recommended_summary(row: dict[str, Any] | None) -> dict[str, Any]:
    if not row:
        return {}
    return {
        "candidate": row["candidate"],
        "cut": row["cut"],
        "score": row["score"],
        "why": ", ".join(
            [
                role
                for role in (
                    "preserves_R_source" if row["deltas"]["red_source_delta"] >= 0 else "",
                    "preserves_W_source" if row["deltas"]["white_source_delta"] >= 0 else "",
                    "improves_timing" if row["deltas"]["etb_score_delta"] > 0 else "",
                    "gains_fetchable_dual" if "fetchable_boros_dual" in row["gained_roles"] else "",
                    "removes_pain_cost" if "colored_pain_cost" in row["lost_roles"] else "",
                )
                if role
            ]
        ),
    }


def render_markdown(payload: dict[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Mana Base Validator - 2026-06-27",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Source DB: `{payload['source_db']}`",
        f"- Miner report: `{payload['miner_report']}`",
        f"- Deck ID: `{payload['deck_id']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Candidates: `{summary['candidate_count']}`",
        f"- Deck lands: `{summary['deck_land_quantity']}` total, `{summary['deck_land_unique_count']}` unique",
        f"- Source counts: `{json.dumps(summary['source_counts'], sort_keys=True)}`",
        f"- Evaluations: `{summary['evaluation_count']}`",
        f"- Status counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
        f"- Ready swaps: `{summary['ready_swap_count']}`",
        f"- Recommended next action: `{summary['recommended_next_action']}`",
        f"- Recommended swap: `{json.dumps(summary['recommended_swap'], sort_keys=True)}`",
        "",
        "## Ready Swaps",
        "",
        "| Score | Candidate | Cut | Deltas | Gained | Lost |",
        "| ---: | --- | --- | --- | --- | --- |",
    ]
    for row in payload["ready_swaps"]:
        lines.append(
            "| {score} | {candidate} | {cut} | `{deltas}` | {gained} | {lost} |".format(
                score=row["score"],
                candidate=row["candidate"],
                cut=row["cut"],
                deltas=json.dumps(row["deltas"], sort_keys=True),
                gained=", ".join(row["gained_roles"]) or "-",
                lost=", ".join(row["lost_roles"]) or "-",
            )
        )
    if not payload["ready_swaps"]:
        lines.append("|  | none | none |  |  |  |")
    lines.extend(["", "## Manual Review Swaps", ""])
    for row in payload["manual_review_swaps"][:10]:
        lines.append(
            "- `{candidate}` over `{cut}`: score `{score}`, warnings `{warnings}`.".format(
                candidate=row["candidate"],
                cut=row["cut"],
                score=row["score"],
                warnings=", ".join(row["warnings"]) or "-",
            )
        )
    if not payload["manual_review_swaps"]:
        lines.append("- none")
    lines.extend(["", "## Blocked Samples", ""])
    for row in payload["blocked_swaps_sample"][:10]:
        lines.append(
            "- `{candidate}` over `{cut}`: blockers `{blockers}`.".format(
                candidate=row["candidate"],
                cut=row["cut"],
                blockers=", ".join(row["blockers"]) or "-",
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
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--prior-land-gate-report", type=Path, action="append")
    parser.add_argument("--deck-id", type=int, default=6)
    parser.add_argument("--stem", default="lorehold_mana_base_validator_20260627_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    miner_report = read_json(args.miner_report)
    prior_reports = read_existing_json(args.prior_land_gate_report or DEFAULT_PRIOR_LAND_GATE_REPORTS)
    conn = connect(args.db)
    payload = build_report(
        conn=conn,
        miner_report=miner_report,
        prior_land_gate_reports=prior_reports,
        db_path=args.db,
        miner_path=args.miner_report,
        deck_id=args.deck_id,
    )
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
