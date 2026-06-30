#!/usr/bin/env python3
"""Build a same-lane cut model for Lorehold access/topdeck packages.

This read-only helper answers the post-matrix question: which cuts, if any, are
safe enough to retest access cards such as Brainstone, Penance, Enlightened
Tutor, Gamble, or Hidden Retreat? It combines runtime rule status, Lorehold
variant frequency, the latest seed matrix, and cut-safety evidence.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_STRATEGY_REPORT = REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
DEFAULT_SEED_MATRIX = REPORT_DIR / "lorehold_seed_matrix_all_20260628_v1_run.json"
DEFAULT_SQUEE_PROBE = REPORT_DIR / "lorehold_squee_graveyard_entry_probe_20260628_v1.json"
DEFAULT_HIDDEN_RETREAT_PACKAGE_MANIFEST = (
    REPORT_DIR / "pg271_hidden_retreat_damage_prevention_20260630_manifest.json"
)
DEFAULT_RUNTIME_PACKAGE_PROPOSAL_REPORTS: tuple[Path, ...] = ()
DEFAULT_CANDIDATES = [
    "Brainstone",
    "Penance",
    "Enlightened Tutor",
    "Gamble",
    "Hidden Retreat",
]
DEFAULT_BASELINE_DECK_ID = 607
ACCESS_TARGETS = [
    "Squee, Goblin Nabob",
    "Sensei's Divining Top",
    "Scroll Rack",
    "Library of Leng",
]
DEFAULT_VARIANT_DECK_IDS = tuple(range(607, 617))
ACTIVE_EXECUTION_STATUSES = {"auto", "active"}
ACTIVE_REVIEW_STATUSES = {"verified", "active"}
REJECT_DECISIONS = {"reject_regresses_strong_seed", "reject_or_rework"}
KNOWN_ENGINE_CUTS = {
    "Approach of the Second Sun",
    "Bender's Waterskin",
    "Dawn's Truce",
    "Deflecting Swat",
    "Flawless Maneuver",
    "Giver of Runes",
    "Hexing Squelcher",
    "Land Tax",
    "Library of Leng",
    "Lightning Greaves",
    "Artist's Talent",
    "Esper Sentinel",
    "Molecule Man",
    "Monument to Endurance",
    "Mother of Runes",
    "Pearl Medallion",
    "Ruby Medallion",
    "Scroll Rack",
    "Sensei's Divining Top",
    "Squee, Goblin Nabob",
    "Swiftfoot Boots",
    "Teferi's Protection",
    "The Mind Stone",
    "Urza's Saga",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


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


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT card_name, quantity, functional_tag, functional_tags_json,
               type_line, oracle_text, cmc, is_commander
        FROM deck_cards
        WHERE deck_id=?
        ORDER BY is_commander DESC, functional_tag, card_name
        """,
        (deck_id,),
    ).fetchall()
    return [
        {
            "card_name": row["card_name"],
            "quantity": int(row["quantity"] or 1),
            "functional_tag": row["functional_tag"],
            "functional_tags": json_list(row["functional_tags_json"]),
            "type_line": row["type_line"],
            "oracle_text": row["oracle_text"],
            "cmc": float(row["cmc"] or 0),
            "is_commander": bool(row["is_commander"]),
        }
        for row in rows
    ]


def lane_for_card(row: dict[str, Any]) -> str:
    name = str(row.get("card_name") or "")
    tag = str(row.get("functional_tag") or "")
    type_line = str(row.get("type_line") or "")
    oracle_tags = {str(value) for value in (row.get("functional_tags") or [])}
    if name in {"Sensei's Divining Top", "Scroll Rack", "Brainstone"}:
        return "topdeck_setup"
    if name in {"Library of Leng", "Squee, Goblin Nabob", "Artist's Talent", "Monument to Endurance"}:
        return "discard_recursion_engine"
    if tag == "tutor" or name in {"Land Tax", "Enlightened Tutor", "Gamble"}:
        return "access_tutor"
    if tag == "ramp":
        return "early_mana"
    if tag == "protection" or "protection" in oracle_tags:
        return "protection"
    if tag == "board_wipe" or "board_wipe" in oracle_tags:
        return "pressure_reset"
    if tag == "wincon" or "wincon" in oracle_tags:
        return "wincon"
    if "Land" in type_line:
        return "mana_base"
    if tag == "draw":
        return "draw_value"
    return tag or "contextual"


def candidate_lane(card_name: str) -> str:
    lanes = {
        "Brainstone": "topdeck_setup",
        "Penance": "topdeck_protection",
        "Hidden Retreat": "topdeck_protection",
        "Enlightened Tutor": "access_tutor",
        "Gamble": "access_tutor",
    }
    return lanes.get(card_name, "access")


def candidate_access_targets(card_name: str) -> list[str]:
    targets = {
        "Brainstone": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng"],
        "Penance": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng"],
        "Hidden Retreat": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng"],
        "Enlightened Tutor": ["Sensei's Divining Top", "Scroll Rack", "Library of Leng"],
        "Gamble": list(ACCESS_TARGETS),
    }
    return targets.get(card_name, [])


def squee_probe_summary(squee_probe_report: dict[str, Any] | None) -> dict[str, Any]:
    summary = (squee_probe_report or {}).get("summary") or {}
    return {
        "status": summary.get("status", ""),
        "next_action": summary.get("next_action", ""),
        "modeled_when_accessed": bool(summary.get("modeled_when_accessed")),
        "weak_focus_missing_squee_access_seeds": summary.get("weak_focus_missing_squee_access_seeds") or [],
        "weak_material_missing_squee_seeds": summary.get("weak_material_missing_squee_seeds") or [],
        "seed42_anchor_record": summary.get("seed42_anchor_record") or {},
    }


def compatible_cut_lanes(candidate: str) -> set[str]:
    lane = candidate_lane(candidate)
    if lane == "topdeck_setup":
        return {"topdeck_setup", "draw_value"}
    if lane == "topdeck_protection":
        return {"topdeck_setup", "protection", "pressure_reset"}
    if lane == "access_tutor":
        return {"access_tutor", "topdeck_setup"}
    return {lane}


def rule_summary(conn: sqlite3.Connection, card_names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in card_names if str(name).strip()}
    summaries: dict[str, dict[str, Any]] = {
        key: {
            "card_name": name,
            "rule_count": 0,
            "active_rule_count": 0,
            "review_only_rule_count": 0,
            "execution_statuses": Counter(),
            "review_statuses": Counter(),
            "effects": Counter(),
            "battle_model_scopes": Counter(),
        }
        for key, name in wanted.items()
    }
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, review_status, execution_status, effect_json
        FROM battle_card_rules
        ORDER BY card_name
        """
    ).fetchall()
    for row in rows:
        keys = {normalize_key(row["card_name"]), normalize_key(row["normalized_name"])}
        key = next((item for item in keys if item in wanted), None)
        if key is None:
            continue
        summary = summaries[key]
        review_status = str(row["review_status"] or "")
        execution_status = str(row["execution_status"] or "")
        summary["rule_count"] += 1
        summary["review_statuses"][review_status] += 1
        summary["execution_statuses"][execution_status] += 1
        if execution_status == "review_only":
            summary["review_only_rule_count"] += 1
        if execution_status in ACTIVE_EXECUTION_STATUSES and review_status in ACTIVE_REVIEW_STATUSES:
            summary["active_rule_count"] += 1
        try:
            effect_json = json.loads(row["effect_json"] or "{}")
        except Exception:
            effect_json = {}
        if isinstance(effect_json, dict):
            if effect_json.get("effect"):
                summary["effects"][str(effect_json["effect"])] += 1
            if effect_json.get("battle_model_scope"):
                summary["battle_model_scopes"][str(effect_json["battle_model_scope"])] += 1
    for summary in summaries.values():
        for key in ("execution_statuses", "review_statuses", "effects", "battle_model_scopes"):
            summary[key] = dict(sorted(summary[key].items()))
    return summaries


def runtime_package_rule_summary(
    proposal_paths: Iterable[Path],
    card_names: Iterable[str],
) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in card_names if str(name).strip()}
    summaries: dict[str, dict[str, Any]] = {}
    if not wanted:
        return summaries

    for path in proposal_paths:
        if not path.exists():
            continue
        try:
            payload = read_json(path)
        except (OSError, json.JSONDecodeError):
            continue
        proposals = payload.get("proposals") if isinstance(payload, dict) else []
        if not isinstance(proposals, list):
            continue
        for proposal in proposals:
            if not isinstance(proposal, dict):
                continue
            card_name = str(proposal.get("card_name") or "").strip()
            key = normalize_key(card_name)
            if key not in wanted:
                continue
            effect_json = proposal.get("effect_json") or {}
            if not isinstance(effect_json, dict) or not effect_json:
                continue
            review_status = str(proposal.get("review_status") or "")
            execution_status = str(proposal.get("execution_status") or "")
            summary = summaries.setdefault(
                key,
                {
                    "card_name": card_name or wanted[key],
                    "rule_count": 0,
                    "active_rule_count": 0,
                    "review_only_rule_count": 0,
                    "execution_statuses": Counter(),
                    "review_statuses": Counter(),
                    "effects": Counter(),
                    "battle_model_scopes": Counter(),
                    "runtime_package_proposal_reports": [],
                },
            )
            summary["rule_count"] += 1
            summary["execution_statuses"][execution_status] += 1
            summary["review_statuses"][review_status] += 1
            if execution_status == "review_only":
                summary["review_only_rule_count"] += 1
            if execution_status in ACTIVE_EXECUTION_STATUSES and review_status in ACTIVE_REVIEW_STATUSES:
                summary["active_rule_count"] += 1
            if effect_json.get("effect"):
                summary["effects"][str(effect_json["effect"])] += 1
            if effect_json.get("battle_model_scope"):
                summary["battle_model_scopes"][str(effect_json["battle_model_scope"])] += 1
            summary["runtime_package_proposal_reports"].append(str(path))

    for summary in summaries.values():
        for key in ("execution_statuses", "review_statuses", "effects", "battle_model_scopes"):
            summary[key] = dict(sorted(summary[key].items()))
        summary["runtime_package_proposal_reports"] = sorted(
            set(summary.get("runtime_package_proposal_reports") or [])
        )
    return summaries


def merge_rule_summaries(
    base: dict[str, dict[str, Any]],
    overlay: dict[str, dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    merged = {key: dict(value) for key, value in base.items()}
    for key, overlay_row in overlay.items():
        row = merged.setdefault(key, {"card_name": overlay_row.get("card_name")})
        for count_key in ("rule_count", "active_rule_count", "review_only_rule_count"):
            row[count_key] = int(row.get(count_key) or 0) + int(overlay_row.get(count_key) or 0)
        for counter_key in ("execution_statuses", "review_statuses", "effects", "battle_model_scopes"):
            counts = Counter(row.get(counter_key) or {})
            counts.update(overlay_row.get(counter_key) or {})
            row[counter_key] = dict(sorted(counts.items()))
        reports = set(row.get("runtime_package_proposal_reports") or [])
        reports.update(overlay_row.get("runtime_package_proposal_reports") or [])
        if reports:
            row["runtime_package_proposal_reports"] = sorted(reports)
            row["runtime_package_overlay_count"] = len(reports)
    return merged


def variant_usage(
    conn: sqlite3.Connection,
    card_names: Iterable[str],
    variant_deck_ids: Iterable[int],
) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in card_names if str(name).strip()}
    out = {
        key: {"card_name": name, "deck_count": 0, "deck_ids": []}
        for key, name in wanted.items()
    }
    if not out:
        return out
    placeholders = ",".join("?" for _ in out)
    deck_placeholders = ",".join("?" for _ in variant_deck_ids)
    rows = conn.execute(
        f"""
        SELECT card_name, deck_id
        FROM deck_cards
        WHERE lower(card_name) IN ({placeholders})
          AND deck_id IN ({deck_placeholders})
        ORDER BY card_name, deck_id
        """,
        [key for key in out] + list(variant_deck_ids),
    ).fetchall()
    for row in rows:
        key = normalize_key(row["card_name"])
        if key not in out:
            continue
        out[key]["deck_ids"].append(int(row["deck_id"]))
    for row in out.values():
        row["deck_ids"] = sorted(set(row["deck_ids"]))
        row["deck_count"] = len(row["deck_ids"])
    return out


def load_cut_safety(strategy_report: dict[str, Any]) -> dict[str, Any]:
    manifest = strategy_report.get("cut_safety_manifest") or {}
    cuts = {
        normalize_key(row.get("card_name")): row
        for row in manifest.get("cuts", [])
        if isinstance(row, dict) and row.get("card_name")
    }
    flex = {
        normalize_key(row.get("card_name")): row
        for row in manifest.get("untested_flex_pool", [])
        if isinstance(row, dict) and row.get("card_name")
    }
    return {
        "summary": manifest.get("summary") or {},
        "cuts": cuts,
        "flex": flex,
    }


def load_seed_matrix(matrix_report: dict[str, Any]) -> dict[str, Any]:
    exact: dict[tuple[str, str], dict[str, Any]] = {}
    negative_cut_counts: Counter[str] = Counter()
    for row in matrix_report.get("packages") or []:
        adds = [normalize_key(card) for card in (row.get("adds") or []) if normalize_key(card)]
        cuts = [normalize_key(card) for card in (row.get("cuts") or []) if normalize_key(card)]
        aggregate = row.get("aggregate") or {}
        decision = str(aggregate.get("decision") or row.get("status") or "")
        result = {
            "package_key": row.get("package_key"),
            "decision": decision,
            "baseline_record": aggregate.get("baseline_record"),
            "candidate_record": aggregate.get("candidate_record"),
            "delta_pp_total": aggregate.get("delta_pp_total"),
            "strong_seed_regressions": aggregate.get("strong_seed_regressions") or [],
            "status": row.get("status"),
        }
        if len(adds) == 1 and len(cuts) == 1:
            exact[(adds[0], cuts[0])] = result
        if decision in REJECT_DECISIONS:
            for cut in cuts:
                negative_cut_counts[cut] += 1
    return {
        "exact": exact,
        "negative_cut_counts": negative_cut_counts,
    }


def candidate_status(
    card_name: str,
    rules: dict[str, dict[str, Any]],
    usage: dict[str, dict[str, Any]],
    deck_cards_by_name: dict[str, dict[str, Any]],
) -> tuple[str, list[str], int]:
    blockers: list[str] = []
    score = 0
    key = normalize_key(card_name)
    rule = rules.get(key) or {}
    if key in deck_cards_by_name:
        blockers.append("candidate_already_in_current_deck")
    active_rule_count = int(rule.get("active_rule_count") or 0)
    if active_rule_count <= 0:
        if int(rule.get("review_only_rule_count") or 0) > 0:
            blockers.append("candidate_runtime_review_only")
        else:
            blockers.append("candidate_missing_executable_rule")
    else:
        score += 35
    scopes = set(rule.get("battle_model_scopes") or {})
    if any("unexecuted" in scope for scope in scopes):
        blockers.append("candidate_scope_warns_unexecuted")
        score -= 8
    variant_count = int((usage.get(key) or {}).get("deck_count") or 0)
    score += min(24, variant_count * 4)
    if variant_count >= 4:
        score += 8
    status = "blocked" if any(blocker.startswith("candidate_runtime") or blocker.startswith("candidate_missing") or blocker == "candidate_already_in_current_deck" for blocker in blockers) else "ready"
    return status, blockers, score


def classify_pair(
    *,
    candidate: str,
    cut: dict[str, Any],
    rules: dict[str, dict[str, Any]],
    usage: dict[str, dict[str, Any]],
    deck_cards_by_name: dict[str, dict[str, Any]],
    cut_safety: dict[str, Any],
    seed_matrix: dict[str, Any],
) -> dict[str, Any]:
    candidate_key = normalize_key(candidate)
    cut_name = str(cut["card_name"])
    cut_key = normalize_key(cut_name)
    candidate_runtime_status, candidate_blockers, candidate_score = candidate_status(
        candidate,
        rules,
        usage,
        deck_cards_by_name,
    )
    blockers = list(candidate_blockers)
    cut_lane = lane_for_card(cut)
    candidate_lane_name = candidate_lane(candidate)
    score = candidate_score
    exact_prior = (seed_matrix.get("exact") or {}).get((candidate_key, cut_key), {})
    negative_cut_count = int((seed_matrix.get("negative_cut_counts") or {}).get(cut_key, 0))
    safety_row = (cut_safety.get("cuts") or {}).get(cut_key, {})
    flex_row = (cut_safety.get("flex") or {}).get(cut_key, {})

    if cut.get("is_commander"):
        blockers.append("cut_is_commander")
    if "Land" in str(cut.get("type_line") or ""):
        blockers.append("cut_is_land")
    if cut_name in KNOWN_ENGINE_CUTS:
        blockers.append("cut_is_known_engine_or_seed42_shell")
    if is_miracle_core_cut(cut):
        blockers.append("cut_is_miracle_core_big_spell")
    if cut_lane == "protection":
        blockers.append("cut_is_protection_shell")
    if safety_row.get("status") == "locked_do_not_cut":
        blockers.append("cut_locked_do_not_cut")
    if safety_row.get("status") == "risky_cut_only_same_lane" and cut_lane not in compatible_cut_lanes(candidate):
        blockers.append("cut_risky_cross_lane")
    if exact_prior.get("decision") in REJECT_DECISIONS:
        blockers.append("prior_exact_seed_matrix_reject")
    if negative_cut_count >= 2:
        blockers.append(f"cut_repeated_seed_matrix_rejects:{negative_cut_count}")
    if flex_row and candidate_lane_name != "early_mana" and cut_lane == "early_mana":
        blockers.append("cut_is_early_mana_floor_support")

    compatible = cut_lane in compatible_cut_lanes(candidate)
    if compatible:
        score += 30
    else:
        score -= 20
        blockers.append(f"cut_cross_lane:{cut_lane}")
    if safety_row:
        score -= 20
    if negative_cut_count:
        score -= min(40, negative_cut_count * 12)
    cut_variant_count = int((usage.get(cut_key) or {}).get("deck_count") or 0)
    if cut_variant_count <= 2:
        score += 8
    elif cut_variant_count >= 5:
        score -= 10

    hard_blockers = [
        blocker
        for blocker in blockers
        if blocker.startswith(
            (
                "candidate_runtime",
                "candidate_missing",
                "candidate_already",
                "cut_is_commander",
                "cut_is_land",
                "cut_is_known",
                "cut_is_miracle_core",
                "cut_is_protection",
                "cut_locked",
                "prior_exact",
                "cut_repeated",
                "cut_is_early_mana",
            )
        )
    ]
    if candidate_runtime_status == "blocked":
        status = "blocked_candidate_runtime"
    elif hard_blockers:
        status = "blocked_cut_or_prior_evidence"
    elif not compatible:
        status = "manual_same_lane_cut_required"
    elif score >= 75:
        status = "preflight_access_candidate_ready"
    else:
        status = "manual_review_required"

    return {
        "candidate": candidate,
        "cut": cut_name,
        "status": status,
        "score": score,
        "candidate_lane": candidate_lane_name,
        "cut_lane": cut_lane,
        "blockers": sorted(set(blockers)),
        "candidate_rule_summary": rules.get(candidate_key) or {},
        "candidate_variant_usage": usage.get(candidate_key) or {},
        "cut_variant_usage": usage.get(cut_key) or {},
        "cut_metadata": cut,
        "cut_safety": safety_row,
        "cut_flex": flex_row,
        "negative_cut_count": negative_cut_count,
        "prior_exact_seed_matrix": exact_prior,
    }


def is_miracle_core_cut(cut: dict[str, Any]) -> bool:
    functional_tag = str(cut.get("functional_tag") or "")
    functional_tags = {str(tag) for tag in (cut.get("functional_tags") or [])}
    type_line = str(cut.get("type_line") or "")
    oracle_text = str(cut.get("oracle_text") or "").lower()
    cmc = float(cut.get("cmc") or 0)
    if functional_tag in {"board_wipe", "wincon"}:
        return True
    if functional_tags & {"board_wipe", "wincon"}:
        return True
    if ("Instant" in type_line or "Sorcery" in type_line) and cmc >= 4:
        return True
    if "instant or sorcery" in oracle_text and functional_tag in {"draw", "engine", "wincon"}:
        return True
    return False


def build_model(
    *,
    conn: sqlite3.Connection,
    strategy_report: dict[str, Any],
    seed_matrix_report: dict[str, Any],
    squee_probe_report: dict[str, Any] | None = None,
    candidates: list[str] = DEFAULT_CANDIDATES,
    deck_id: int = DEFAULT_BASELINE_DECK_ID,
    variant_deck_ids: Iterable[int] = DEFAULT_VARIANT_DECK_IDS,
    db_path: Path = DEFAULT_DB,
    strategy_path: Path = DEFAULT_STRATEGY_REPORT,
    seed_matrix_path: Path = DEFAULT_SEED_MATRIX,
    squee_probe_path: Path = DEFAULT_SQUEE_PROBE,
    runtime_package_proposal_reports: Iterable[Path] | None = None,
) -> dict[str, Any]:
    deck_cards = load_deck_cards(conn, deck_id)
    deck_cards_by_name = {normalize_key(row["card_name"]): row for row in deck_cards}
    all_names = sorted({*candidates, *(row["card_name"] for row in deck_cards)})
    proposal_paths = list(runtime_package_proposal_reports or [])
    local_rules = rule_summary(conn, all_names)
    overlay_rules = runtime_package_rule_summary(proposal_paths, all_names)
    rules = merge_rule_summaries(local_rules, overlay_rules)
    usage = variant_usage(conn, all_names, variant_deck_ids)
    cut_safety = load_cut_safety(strategy_report)
    seed_matrix = load_seed_matrix(seed_matrix_report)
    squee_summary = squee_probe_summary(squee_probe_report)

    pair_rows: list[dict[str, Any]] = []
    for candidate in candidates:
        for cut in deck_cards:
            if normalize_key(candidate) == normalize_key(cut["card_name"]):
                continue
            pair_rows.append(
                classify_pair(
                    candidate=candidate,
                    cut=cut,
                    rules=rules,
                    usage=usage,
                    deck_cards_by_name=deck_cards_by_name,
                    cut_safety=cut_safety,
                    seed_matrix=seed_matrix,
                )
            )
    pair_rows.sort(key=lambda row: (-int(row["score"]), row["status"], row["candidate"], row["cut"]))
    candidate_rows = []
    for candidate in candidates:
        key = normalize_key(candidate)
        status, blockers, score = candidate_status(candidate, rules, usage, deck_cards_by_name)
        candidate_rows.append(
            {
                "card_name": candidate,
                "status": status,
                "score": score,
                "lane": candidate_lane(candidate),
                "access_targets": candidate_access_targets(candidate),
                "target_failure_modes": [
                    "seed7_missing_engine_access",
                    "seed20260625_conversion_under_pressure",
                    "squee_graveyard_entry_route",
                ],
                "blockers": blockers,
                "rule_summary": rules.get(key) or {},
                "variant_usage": usage.get(key) or {},
            }
        )

    status_counts = Counter(row["status"] for row in pair_rows)
    preflight_rows = [row for row in pair_rows if row["status"] == "preflight_access_candidate_ready"]
    manual_rows = [row for row in pair_rows if row["status"] in {"manual_same_lane_cut_required", "manual_review_required"}]
    hidden_retreat_local_rule = local_rules.get(normalize_key("Hidden Retreat")) or {}
    hidden_retreat_overlay_rule = overlay_rules.get(normalize_key("Hidden Retreat")) or {}
    hidden_retreat_local_active = int(hidden_retreat_local_rule.get("active_rule_count") or 0)
    hidden_retreat_overlay_active = int(hidden_retreat_overlay_rule.get("active_rule_count") or 0)
    hidden_retreat_package_status = (
        "applied_synced"
        if hidden_retreat_local_active > 0
        else (
            "prepared_read_only_pending_apply_approval"
            if DEFAULT_HIDDEN_RETREAT_PACKAGE_MANIFEST.exists()
            else "not_prepared"
        )
    )
    hidden_retreat_runtime_model_status = (
        "local_db_active"
        if hidden_retreat_local_active > 0
        else (
            "runtime_proposal_overlay_active"
            if hidden_retreat_overlay_active > 0
            else "local_db_runtime_only"
        )
    )
    return {
        "generated_at": utc_now(),
        "source_db": str(db_path),
        "strategy_report": str(strategy_path),
        "seed_matrix_report": str(seed_matrix_path),
        "squee_probe_report": str(squee_probe_path) if squee_probe_report else "",
        "runtime_package_proposal_reports": [str(path) for path in proposal_paths],
        "deck_id": deck_id,
        "variant_deck_ids": list(variant_deck_ids),
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "candidate_count": len(candidate_rows),
            "deck_card_rows": len(deck_cards),
            "evaluated_pair_count": len(pair_rows),
            "preflight_access_candidate_ready_count": len(preflight_rows),
            "manual_review_count": len(manual_rows),
            "status_counts": dict(sorted(status_counts.items())),
            "access_density_status": (
                "squee_route_modeled_access_density_needed"
                if squee_summary.get("status") == "squee_route_modeled_but_access_gap_remains"
                else "squee_access_context_unresolved"
            ),
            "squee_probe_status": squee_summary.get("status", ""),
            "weak_access_seeds": squee_summary.get("weak_material_missing_squee_seeds") or [],
            "target_access_cards": list(ACCESS_TARGETS),
            "recommended_next_action": (
                f"gate_{preflight_rows[0]['candidate']}_over_{preflight_rows[0]['cut']}"
                if preflight_rows
                else (
                    "no_access_swap_ready; build_new_seed_safe_cut"
                    if hidden_retreat_package_status == "applied_synced"
                    else (
                        "no_access_swap_ready; apply_or_sync_hidden_retreat_package_then_gate_new_seed_safe_cut"
                        if hidden_retreat_package_status == "prepared_read_only_pending_apply_approval"
                        else "no_access_swap_ready; build_new_seed_safe_cut_or_upgrade_hidden_retreat_runtime"
                    )
                )
            ),
            "hidden_retreat_package_status": hidden_retreat_package_status,
            "hidden_retreat_runtime_model_status": hidden_retreat_runtime_model_status,
            "hidden_retreat_package_manifest": (
                str(DEFAULT_HIDDEN_RETREAT_PACKAGE_MANIFEST)
                if hidden_retreat_package_status
                in {"prepared_read_only_pending_apply_approval", "applied_synced"}
                else ""
            ),
            "runtime_package_overlay_card_count": sum(
                1 for row in rules.values() if row.get("runtime_package_proposal_reports")
            ),
        },
        "access_density_context": {
            "target_access_cards": list(ACCESS_TARGETS),
            "squee_probe": squee_summary,
            "package_constraint": (
                "Any access package must improve reach to Squee/Top/Rack/Library while preserving "
                "seed-42 Squee, miracle, and topdeck telemetry."
            ),
        },
        "candidates": candidate_rows,
        "preflight_access_candidates": preflight_rows[:10],
        "top_manual_review_candidates": manual_rows[:25],
        "top_pair_evaluations": pair_rows[:50],
        "pair_evaluations": pair_rows,
        "guardrails": [
            {
                "guardrail_key": "preserve_seed42_shell",
                "reason": "Seed 42 is the known success anchor; a package that regresses it cannot be promoted.",
            },
            {
                "guardrail_key": "do_not_cut_repeated_reject_slots",
                "reason": "Promise of Loyalty, Avatar's Wrath, Tibalt's Trickery, Prismari Pianist, and similar slots need a new rationale after repeated matrix regressions.",
            },
            {
                "guardrail_key": "runtime_package_overlay_is_read_only",
                "reason": (
                    "Runtime proposal overlays make candidate modeling possible in copied DB gates, "
                    "but PostgreSQL/product truth still requires explicit approved apply/sync."
                ),
            },
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Access Cut Model - 2026-06-28",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- source_db: `{payload['source_db']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- strategy_report: `{payload['strategy_report']}`",
        f"- seed_matrix_report: `{payload['seed_matrix_report']}`",
        f"- squee_probe_report: `{payload.get('squee_probe_report') or '-'}`",
        f"- runtime_package_proposal_reports: `{', '.join(payload.get('runtime_package_proposal_reports') or []) or '-'}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Summary",
        "",
        f"- candidate_count: `{payload['summary']['candidate_count']}`",
        f"- evaluated_pair_count: `{payload['summary']['evaluated_pair_count']}`",
        f"- preflight_access_candidate_ready_count: `{payload['summary']['preflight_access_candidate_ready_count']}`",
        f"- manual_review_count: `{payload['summary']['manual_review_count']}`",
        f"- status_counts: `{json.dumps(payload['summary']['status_counts'], sort_keys=True)}`",
        f"- access_density_status: `{payload['summary']['access_density_status']}`",
        f"- squee_probe_status: `{payload['summary'].get('squee_probe_status') or '-'}`",
        f"- target_access_cards: `{', '.join(payload['summary']['target_access_cards'])}`",
        f"- recommended_next_action: `{payload['summary']['recommended_next_action']}`",
        f"- hidden_retreat_package_status: `{payload['summary'].get('hidden_retreat_package_status') or '-'}`",
        f"- hidden_retreat_runtime_model_status: `{payload['summary'].get('hidden_retreat_runtime_model_status') or '-'}`",
        f"- hidden_retreat_package_manifest: `{payload['summary'].get('hidden_retreat_package_manifest') or '-'}`",
        f"- runtime_package_overlay_card_count: `{payload['summary'].get('runtime_package_overlay_card_count') or 0}`",
        "",
        "## Access Candidates",
        "",
        "| Candidate | Status | Lane | Score | Access Targets | Variant Decks | Active Rules | Blockers |",
        "| --- | --- | --- | ---: | --- | --- | ---: | --- |",
    ]
    for row in payload["candidates"]:
        usage = row.get("variant_usage") or {}
        rules = row.get("rule_summary") or {}
        lines.append(
            "| {card} | `{status}` | `{lane}` | {score} | {targets} | {decks} | {rules} | {blockers} |".format(
                card=row["card_name"],
                status=row["status"],
                lane=row["lane"],
                score=row["score"],
                targets=", ".join(row.get("access_targets") or []) or "-",
                decks=",".join(str(deck) for deck in usage.get("deck_ids") or []) or "-",
                rules=int(rules.get("active_rule_count") or 0),
                blockers="; ".join(row.get("blockers") or []) or "none",
            )
        )
    lines.extend(["", "## Preflight Access Candidates", ""])
    if not payload["preflight_access_candidates"]:
        lines.append("- None.")
    else:
        lines.extend(
            [
                "| Rank | Candidate | Cut | Score | Candidate Lane | Cut Lane | Blockers |",
                "| ---: | --- | --- | ---: | --- | --- | --- |",
            ]
        )
        for index, row in enumerate(payload["preflight_access_candidates"], start=1):
            lines.append(
                f"| {index} | {row['candidate']} | {row['cut']} | {row['score']} | `{row['candidate_lane']}` | `{row['cut_lane']}` | {'; '.join(row['blockers']) or 'none'} |"
            )
    lines.extend(
        [
            "",
            "## Top Manual Review Candidates",
            "",
            "| Rank | Candidate | Cut | Status | Score | Candidate Lane | Cut Lane | Negative Cut Count | Blockers |",
            "| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |",
        ]
    )
    for index, row in enumerate(payload["top_manual_review_candidates"], start=1):
        lines.append(
            "| {rank} | {candidate} | {cut} | `{status}` | {score} | `{candidate_lane}` | `{cut_lane}` | {negative} | {blockers} |".format(
                rank=index,
                candidate=row["candidate"],
                cut=row["cut"],
                status=row["status"],
                score=row["score"],
                candidate_lane=row["candidate_lane"],
                cut_lane=row["cut_lane"],
                negative=row["negative_cut_count"],
                blockers="; ".join(row["blockers"]) or "none",
            )
        )
    lines.extend(["", "## Guardrails", ""])
    for row in payload["guardrails"]:
        lines.append(f"- `{row['guardrail_key']}`: {row['reason']}")
    lines.append("")
    return "\n".join(lines)


def compact_report_payload(payload: dict[str, Any]) -> dict[str, Any]:
    compact = dict(payload)
    pair_evaluations = list(payload.get("pair_evaluations") or [])
    compact["pair_evaluations_omitted_count"] = len(pair_evaluations)
    compact.pop("pair_evaluations", None)
    return compact


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--strategy-report", type=Path, default=DEFAULT_STRATEGY_REPORT)
    parser.add_argument("--seed-matrix-report", type=Path, default=DEFAULT_SEED_MATRIX)
    parser.add_argument("--squee-probe", type=Path, default=DEFAULT_SQUEE_PROBE)
    parser.add_argument(
        "--runtime-package-proposals",
        type=Path,
        action="append",
        help="Read-only runtime proposal reports to overlay while scoring candidates.",
    )
    parser.add_argument("--candidate", action="append")
    parser.add_argument("--deck-id", type=int, default=DEFAULT_BASELINE_DECK_ID)
    parser.add_argument("--stem", default="lorehold_access_cut_model_20260628_v2")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    with connect(args.db) as conn:
        runtime_package_proposals = (
            args.runtime_package_proposals
            if args.runtime_package_proposals is not None
            else list(DEFAULT_RUNTIME_PACKAGE_PROPOSAL_REPORTS)
        )
        payload = build_model(
            conn=conn,
            strategy_report=read_json(args.strategy_report),
            seed_matrix_report=read_json(args.seed_matrix_report),
            squee_probe_report=read_json(args.squee_probe) if args.squee_probe.exists() else None,
            candidates=args.candidate or DEFAULT_CANDIDATES,
            deck_id=args.deck_id,
            db_path=args.db,
            strategy_path=args.strategy_report,
            seed_matrix_path=args.seed_matrix_report,
            squee_probe_path=args.squee_probe,
            runtime_package_proposal_reports=runtime_package_proposals,
        )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    report_payload = compact_report_payload(payload)
    json_path.write_text(
        json.dumps(report_payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
