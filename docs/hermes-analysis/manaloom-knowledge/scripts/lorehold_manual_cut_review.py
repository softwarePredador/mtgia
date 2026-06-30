#!/usr/bin/env python3
"""Review Lorehold manual cuts before spending battle-gate time.

This is a read-only analysis helper. It explains why a promising variant card
still is not automatically testable when the only available cut is an engine,
locked role, or strategically unresolved slot in the current Lorehold champion.
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
DEFAULT_STRATEGY_AUDIT = REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
DEFAULT_CUT_MODEL = REPORT_DIR / "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"
DEFAULT_EXPOSURE_PROFILES = [
    REPORT_DIR / "lorehold_card_exposure_profile_20260627_v2_role_fix.json",
    REPORT_DIR / "lorehold_cut_exposure_profile_20260628_v1.json",
]
DEFAULT_EXPOSURE_PROFILE = DEFAULT_EXPOSURE_PROFILES[0]
DEFAULT_SAFE_CUT_REPLANNER = (
    REPORT_DIR / "lorehold_safe_cut_replanner_20260630_post_pg276_squee_access_density_lane_corrected.json"
)
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_LOREHOLD_VARIANT_DECK_IDS = tuple(range(607, 617))
DEFAULT_BASELINE_DECK_ID = 607

ACTIVE_EXECUTION_STATUSES = {"active", "verified", "auto", "reviewed"}
ACTIVE_REVIEW_STATUSES = {"verified", "active", "needs_review", "reviewed"}
SAFE_CUT_DECISIONS = {"engine_flex", "manual_review", "support_flex"}
STRUCTURAL_BLOCKERS = {
    "cut_is_early_mana_floor_support",
    "cut_is_miracle_core_big_spell",
    "cut_is_protection_shell",
    "never_cut_lane",
}
HIGH_CUT_EXPOSURE_MIN = 100
MEASURED_CUT_EXPOSURE_MIN = 25

EXTERNAL_RESEARCH_SOURCES = [
    {
        "title": "EDHREC - Miracles Every Turn With Lorehold, the Historian",
        "url": "https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander",
        "finding": (
            "Lorehold's core loop is first-draw miracle timing, opponent-upkeep rummage, "
            "topdeck manipulation, Library of Leng, and high-impact instant/sorcery hits."
        ),
        "use": "heuristic_context_only",
    },
    {
        "title": "EDHREC - Lorehold, the Historian: Boros Miracles on a Budget",
        "url": "https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget",
        "finding": (
            "The deck needs a high instant/sorcery density so miracle draws do not become dead "
            "non-spell hits."
        ),
        "use": "heuristic_context_only",
    },
    {
        "title": "Card Kingdom - 10 Crazy Synergy Cards for Lorehold, the Historian",
        "url": "https://blog.cardkingdom.com/10-crazy-synergy-cards-for-lorehold-the-historian-secrets-of-strixhaven/",
        "finding": (
            "Community deck tech highlights Library of Leng and reanimation/discard routes as "
            "real Lorehold subpackages."
        ),
        "use": "heuristic_context_only",
    },
    {
        "title": "Reddit r/EDHBrews - Commander Deck Tech: Lorehold, the Historian",
        "url": "https://www.reddit.com/r/EDHBrews/comments/1ssny05/commander_deck_tech_lorehold_the_historian/",
        "finding": (
            "Community discussion reinforces discard, topdeck control, suspend/miracle, and "
            "reanimation as plausible lanes, but not as promotion evidence by itself."
        ),
        "use": "heuristic_context_only",
    },
]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_optional_json(path: Path | None) -> dict[str, Any]:
    if not path or not path.exists():
        return {}
    return read_json(path)


def read_existing_json(paths: Iterable[Path]) -> list[tuple[Path, dict[str, Any]]]:
    loaded = []
    for path in paths:
        if path.exists():
            loaded.append((path, read_json(path)))
    return loaded


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def card_decision_lookup(strategy_audit: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        normalize_key(row.get("card_name")): row
        for row in (strategy_audit.get("card_decision_manifest") or {}).get("cards") or []
        if row.get("card_name")
    }


def cut_safety_lookup(strategy_audit: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        normalize_key(row.get("card_name")): row
        for row in (strategy_audit.get("cut_safety_manifest") or {}).get("cuts") or []
        if row.get("card_name")
    }


def exposure_lookup(
    exposure_profiles: dict[str, Any] | list[tuple[Path | None, dict[str, Any]]] | None,
) -> dict[str, dict[str, Any]]:
    if not exposure_profiles:
        return {}
    if isinstance(exposure_profiles, dict):
        profile_rows: list[tuple[Path | None, dict[str, Any]]] = [(None, exposure_profiles)]
    else:
        profile_rows = exposure_profiles
    out: dict[str, dict[str, Any]] = {}
    for path, payload in profile_rows:
        for row in payload.get("card_profiles") or []:
            if not row.get("card_name"):
                continue
            key = normalize_key(row.get("card_name"))
            candidate = dict(row)
            if path:
                candidate["exposure_profile"] = str(path)
            current = out.get(key)
            if current is None or int(candidate.get("unique_exposure_count") or 0) >= int(
                current.get("unique_exposure_count") or 0
            ):
                out[key] = candidate
    return out


def cut_exposure_summary(cut_exposure: dict[str, Any]) -> dict[str, Any]:
    decision = cut_exposure.get("decision") or {}
    return {
        "unique_exposure_count": int(cut_exposure.get("unique_exposure_count") or 0),
        "direct_event_count": int(cut_exposure.get("direct_event_count") or 0),
        "summary_metric_count": int(cut_exposure.get("summary_metric_count") or 0),
        "inferred_role": cut_exposure.get("inferred_role") or "unmeasured",
        "role_confidence": cut_exposure.get("role_confidence") or "unmeasured",
        "role_signals": list(cut_exposure.get("role_signals") or [])[:8],
        "decision_status": decision.get("status") or "unmeasured",
        "next_action": decision.get("next_action") or "",
        "exposure_profile": cut_exposure.get("exposure_profile") or "",
    }


def package_learning_rows(strategy_audit: dict[str, Any], candidate_name: str) -> list[dict[str, Any]]:
    learning = (strategy_audit.get("strategy_dependency_map") or {}).get("package_learning") or {}
    post_squee = learning.get("post_squee") or {}
    rows = []
    for section in ("hard_reject_sample", "probation_or_watch"):
        for row in post_squee.get(section) or []:
            if normalize_key(candidate_name) in {normalize_key(card) for card in row.get("adds") or []}:
                rows.append({**row, "source_section": section})
    rows.sort(
        key=lambda row: (
            row.get("source_section") != "probation_or_watch",
            float(row.get("strong_seed_delta_pp") or 0),
            row.get("package_key") or "",
        )
    )
    return rows


def load_rule_summaries(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in names if name}
    summaries: dict[str, dict[str, Any]] = {
        key: {
            "card_name": name,
            "active_rule_count": 0,
            "rule_count": 0,
            "execution_statuses": Counter(),
            "review_statuses": Counter(),
            "sources": Counter(),
            "effects": Counter(),
            "battle_model_scopes": Counter(),
        }
        for key, name in wanted.items()
    }
    if not wanted:
        return {}
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, execution_status, review_status, source, effect_json
        FROM battle_card_rules
        ORDER BY card_name, execution_status, review_status
        """
    ).fetchall()
    for row in rows:
        forms = {normalize_key(row["card_name"]), normalize_key(row["normalized_name"])}
        key = next((form for form in forms if form in wanted), "")
        if not key:
            continue
        summary = summaries[key]
        execution_status = str(row["execution_status"] or "")
        review_status = str(row["review_status"] or "")
        summary["rule_count"] += 1
        summary["execution_statuses"][execution_status] += 1
        summary["review_statuses"][review_status] += 1
        if row["source"]:
            summary["sources"][str(row["source"])] += 1
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
    return {key: finalize_counter_dicts(value) for key, value in summaries.items()}


def load_deck_presence(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, list[dict[str, Any]]]:
    wanted = {normalize_key(name): str(name) for name in names if name}
    presence: dict[str, list[dict[str, Any]]] = {key: [] for key in wanted}
    if not wanted:
        return {}
    rows = conn.execute(
        """
        SELECT deck_id, card_name, quantity, functional_tag, cmc, type_line, functional_tags_json
        FROM deck_cards
        ORDER BY deck_id, card_name
        """
    ).fetchall()
    for row in rows:
        key = normalize_key(row["card_name"])
        if key not in wanted:
            continue
        presence[key].append(
            {
                "deck_id": int(row["deck_id"]),
                "card_name": row["card_name"],
                "quantity": int(row["quantity"] or 1),
                "functional_tag": row["functional_tag"],
                "cmc": row["cmc"],
                "type_line": row["type_line"],
                "functional_tags_json": row["functional_tags_json"],
            }
        )
    return presence


def table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {row[1] for row in conn.execute(f"PRAGMA table_info({table})")}


def load_current_deck_cards(
    conn: sqlite3.Connection,
    deck_id: int = DEFAULT_BASELINE_DECK_ID,
) -> list[dict[str, Any]]:
    columns = table_columns(conn, "deck_cards")
    select_columns = [
        "deck_id",
        "card_name",
        "quantity",
        "functional_tag",
        "cmc",
        "type_line",
    ]
    optional = {
        "is_commander": "0 AS is_commander",
        "functional_tags_json": "'[]' AS functional_tags_json",
        "oracle_text": "'' AS oracle_text",
    }
    select_sql = []
    for column in select_columns:
        select_sql.append(column if column in columns else f"NULL AS {column}")
    for column, fallback in optional.items():
        select_sql.append(column if column in columns else fallback)
    rows = conn.execute(
        f"""
        SELECT {", ".join(select_sql)}
        FROM deck_cards
        WHERE deck_id=?
        ORDER BY is_commander DESC, card_name
        """,
        (deck_id,),
    ).fetchall()
    out = []
    for row in rows:
        out.append(
            {
                "deck_id": int(row["deck_id"] or deck_id),
                "card_name": row["card_name"],
                "quantity": int(row["quantity"] or 1),
                "functional_tag": row["functional_tag"],
                "cmc": float(row["cmc"] or 0),
                "type_line": row["type_line"],
                "is_commander": bool(row["is_commander"]),
                "functional_tags_json": row["functional_tags_json"],
                "oracle_text": row["oracle_text"],
            }
        )
    return out


def lorehold_variant_presence(
    conn: sqlite3.Connection,
    names: Iterable[str],
    variant_deck_ids: Iterable[int] = DEFAULT_LOREHOLD_VARIANT_DECK_IDS,
) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in names if str(name).strip()}
    out: dict[str, dict[str, Any]] = {
        key: {"card_name": name, "deck_count": 0, "deck_ids": []}
        for key, name in wanted.items()
    }
    if not wanted:
        return out
    deck_ids = list(variant_deck_ids)
    deck_placeholders = ",".join("?" for _ in deck_ids)
    rows = conn.execute(
        f"""
        SELECT card_name, deck_id
        FROM deck_cards
        WHERE deck_id IN ({deck_placeholders})
        ORDER BY card_name, deck_id
        """,
        deck_ids,
    ).fetchall()
    for row in rows:
        key = normalize_key(row["card_name"])
        if key in out:
            out[key]["deck_ids"].append(int(row["deck_id"]))
    for row in out.values():
        row["deck_ids"] = sorted(set(row["deck_ids"]))
        row["deck_count"] = len(row["deck_ids"])
    return out


def safe_cut_blockers_by_card(safe_cut_report: dict[str, Any] | None) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    if not safe_cut_report:
        return out
    for row in safe_cut_report.get("followups") or []:
        cuts = row.get("cuts") or []
        if not cuts:
            continue
        key = normalize_key(cuts[0])
        entry = out.setdefault(
            key,
            {
                "card_name": cuts[0],
                "followup_count": 0,
                "blocker_counts": Counter(),
                "source_packages": Counter(),
            },
        )
        entry["followup_count"] += 1
        for blocker in row.get("blockers") or []:
            entry["blocker_counts"][str(blocker)] += 1
        if row.get("source_package_key"):
            entry["source_packages"][str(row["source_package_key"])] += 1
    finalized: dict[str, dict[str, Any]] = {}
    for key, value in out.items():
        finalized[key] = {
            "card_name": value["card_name"],
            "followup_count": value["followup_count"],
            "blocker_counts": dict(sorted(value["blocker_counts"].items())),
            "source_packages": dict(sorted(value["source_packages"].items())),
        }
    return finalized


def finalize_counter_dicts(value: dict[str, Any]) -> dict[str, Any]:
    finalized = dict(value)
    for key in ("execution_statuses", "review_statuses", "sources", "effects", "battle_model_scopes"):
        finalized[key] = dict(sorted((value.get(key) or {}).items()))
    return finalized


def classify_manual_pair(
    *,
    candidate: str,
    cut: str,
    candidate_rule: dict[str, Any],
    cut_rule: dict[str, Any],
    cut_decision: dict[str, Any],
    cut_safety: dict[str, Any],
    cut_exposure: dict[str, Any] | None = None,
) -> tuple[str, str, list[str]]:
    cut_key = normalize_key(cut)
    reasons: list[str] = []
    if cut_key == normalize_key("Squee, Goblin Nabob"):
        if cut_decision.get("decision") == "probation_engine":
            reasons.append("Squee is the current champion's probation recursion engine.")
        if cut_decision.get("rule_materialized_in_equal_gate_candidate"):
            reasons.append("Squee's graveyard return is already materialized in the equal-gate candidate.")
        reasons.append("Variant recursion cards must prove a non-Squee cut or a multi-card recursion package.")
        return "do_not_cut_current_champion_engine", "blocked", reasons
    if cut_key == normalize_key("Emeria's Call // Emeria, Shattered Skyclave"):
        exposure_decision = (cut_exposure or {}).get("decision") or {}
        if (
            (cut_exposure or {}).get("inferred_role") == "token_protection_rebuild"
            and exposure_decision.get("status") == "not_safe_as_blind_cut"
        ):
            exposure_count = int((cut_exposure or {}).get("unique_exposure_count") or 0)
            reasons.append(
                f"Emeria has measured token/protection exposure in {exposure_count} deduplicated local events."
            )
            reasons.append(
                "Austere Command is a board-wipe role, not a same-role replacement for rebuild/protection."
            )
            reasons.append(
                "Gate only as an explicit wipe-over-rebuild tradeoff, not as an automatic cut."
            )
            return "manual_tradeoff_not_blind_cut", "manual_tradeoff_gate_only", reasons
        if cut_decision.get("status") == "materialization_gap_ready_rule":
            reasons.append("Emeria has a ready local rule but still needs durable role sync.")
        if not cut_decision.get("effective_role") or cut_decision.get("effective_role") == "unknown":
            reasons.append("Emeria's strategic role is still unknown, so cutting it hides whether the deck needs board/protection density.")
        reasons.append("Austere-style board wipes can be tested only after Emeria exposure/role is measured or a safer cut is found.")
        return "manual_review_role_gap_before_gate", "manual_review", reasons
    if cut_safety.get("status") == "locked_do_not_cut":
        reasons.append("Cut is locked by prior strong-seed regression.")
        return "blocked_locked_cut", "blocked", reasons
    if int(cut_rule.get("active_rule_count") or 0) <= 0:
        reasons.append("Cut has no active local battle rule, so its current contribution is not measurable.")
        return "manual_review_missing_cut_rule", "manual_review", reasons
    if int(candidate_rule.get("active_rule_count") or 0) <= 0:
        reasons.append("Candidate has no active local battle rule.")
        return "blocked_candidate_runtime_gap", "blocked", reasons
    reasons.append("Candidate and cut are runtime-ready, but the lane role is not safe enough for automatic gate.")
    return "manual_cut_review_required", "manual_review", reasons


def classify_contextual_candidate(
    *,
    candidate: str,
    rule: dict[str, Any],
    evidence_rows: list[dict[str, Any]],
) -> tuple[str, str, list[str]]:
    reasons: list[str] = []
    if int(rule.get("active_rule_count") or 0) <= 0:
        return "blocked_candidate_runtime_gap", "blocked", ["Candidate has no active local battle rule."]
    if not evidence_rows:
        return (
            "needs_lane_model_before_gate",
            "manual_review",
            ["Candidate is runtime-ready but has no safe cut model in the current champion lane map."],
        )
    positive = [
        row for row in evidence_rows
        if float(row.get("delta_pp") or 0) > 0 and row.get("decision") != "reject_or_rework"
    ]
    strong_seed_regressions = [
        row for row in evidence_rows
        if float(row.get("strong_seed_delta_pp") or 0) < 0
    ]
    if positive:
        reasons.append("Aggregate upside exists in at least one prior gate.")
    if strong_seed_regressions:
        worst = min(float(row.get("strong_seed_delta_pp") or 0) for row in strong_seed_regressions)
        reasons.append(f"Prior evidence regressed the protected strong seed by {worst:+.2f} pp.")
    if strong_seed_regressions:
        return "tutor_lane_probation_needs_seed_safe_cut", "manual_review", reasons
    return "needs_specific_cut_before_gate", "manual_review", reasons or [
        "Runtime is ready, but no same-lane safe cut is proven."
    ]


def is_miracle_core_slot(card: dict[str, Any], decision: dict[str, Any]) -> bool:
    functional_tag = str(card.get("functional_tag") or "")
    type_line = str(card.get("type_line") or "")
    oracle_text = str(card.get("oracle_text") or "").lower()
    cmc = float(card.get("cmc") or 0)
    tags: set[str] = set()
    try:
        decoded = json.loads(str(card.get("functional_tags_json") or "[]"))
        if isinstance(decoded, list):
            tags = {str(tag) for tag in decoded}
    except Exception:
        tags = set()
    effective_role = str(decision.get("effective_role") or "")
    package_lane = str(decision.get("package_lane") or "")
    if functional_tag in {"board_wipe", "wincon"} or effective_role in {"board_wipe", "wincon"}:
        return True
    if tags & {"board_wipe", "wincon", "topdeck_miracle_setup"}:
        return True
    if package_lane == "topdeck_miracle_setup":
        return True
    if ("Instant" in type_line or "Sorcery" in type_line) and cmc >= 4:
        return True
    if "instant or sorcery" in oracle_text and functional_tag in {"draw", "engine", "wincon"}:
        return True
    return False


def classify_cut_slot(
    *,
    card: dict[str, Any],
    decision: dict[str, Any],
    safety: dict[str, Any],
    variant_presence: dict[str, Any],
    safe_cut_evidence: dict[str, Any],
    cut_exposure: dict[str, Any] | None = None,
) -> tuple[str, str, list[str]]:
    reasons: list[str] = []
    blockers = set((safe_cut_evidence.get("blocker_counts") or {}).keys())
    decision_key = str(decision.get("decision") or "")
    lane = str(decision.get("package_lane") or "")
    effective_role = str(decision.get("effective_role") or card.get("functional_tag") or "")
    type_line = str(card.get("type_line") or "")
    exposure_count = int((cut_exposure or {}).get("unique_exposure_count") or 0)
    exposure_role = str((cut_exposure or {}).get("inferred_role") or "unmeasured")
    exposure_signals = ", ".join(str(signal) for signal in (cut_exposure or {}).get("role_signals") or [])
    if card.get("is_commander"):
        return "never_cut", "commander", ["Commander defines the deck objective."]
    if "Land" in type_line or lane == "mana_base":
        return "never_cut", "mana_base", ["Mana base must be tuned as a package, not blind one-for-one cuts."]
    if safety.get("status") in {"locked_do_not_cut", "protected_until_same_lane_win", "protected_until_same_function_replacement_wins"}:
        reasons.append(f"Cut-safety status is {safety.get('status')}.")
        return "blocked_by_cut_safety", "blocked", reasons
    if safety.get("status") == "risky_cut_only_same_lane":
        reasons.append("Cut-safety permits only a same-lane win after prior strong-seed regression.")
        return "same_lane_only", "requires_same_lane_gate", reasons
    if "prior_rejected_cut" in blockers:
        reasons.append("Safe-cut replanner found prior rejected evidence for this cut slot.")
        return "blocked_by_prior_rejection", "blocked", reasons
    if STRUCTURAL_BLOCKERS & blockers:
        reasons.append("Safe-cut replanner marks this as structural: " + ", ".join(sorted(STRUCTURAL_BLOCKERS & blockers)) + ".")
        return "structural_dependency", "blocked", reasons
    if effective_role == "protection" or lane == "pressure_absorber_or_protection":
        reasons.append("Protection/pressure lane keeps the commander alive through setup turns.")
        return "structural_dependency", "blocked", reasons
    if is_miracle_core_slot(card, decision):
        reasons.append("Slot contributes to instant/sorcery density, miracle setup, wipe, or wincon plan.")
        return "structural_dependency", "blocked", reasons
    if exposure_count >= HIGH_CUT_EXPOSURE_MIN:
        reasons.append(
            f"Replay profile measured {exposure_count} deduplicated exposures for this cut slot."
        )
        reasons.append(f"Measured role is {exposure_role}.")
        if exposure_signals:
            reasons.append(f"Exposure signals: {exposure_signals}.")
        return "measured_high_cut_exposure", "blocked", reasons
    if exposure_count >= MEASURED_CUT_EXPOSURE_MIN:
        reasons.append(
            f"Replay profile measured {exposure_count} deduplicated exposures, so this is not a blind low-use cut."
        )
        reasons.append(f"Measured role is {exposure_role}.")
        if exposure_signals:
            reasons.append(f"Exposure signals: {exposure_signals}.")
        return "measured_cut_exposure_needs_same_lane_benchmark", "manual_same_lane_only", reasons
    if decision_key and decision_key not in SAFE_CUT_DECISIONS:
        reasons.append(f"Strategy decision is {decision_key}, not a flex decision.")
        if "missing_cut_safety_row" in blockers:
            reasons.append("No explicit cut-safety row exists yet.")
        return "needs_exposure_before_cut", "model_cut_exposure", reasons
    if "missing_cut_safety_row" in blockers:
        reasons.append("No explicit cut-safety row exists yet.")
        if int(variant_presence.get("deck_count") or 0) <= 2:
            reasons.append("Low Lorehold variant presence makes it a reasonable exposure-model candidate.")
            return "cut_exposure_candidate", "model_cut_exposure", reasons
        return "needs_exposure_before_cut", "model_cut_exposure", reasons
    reasons.append("Flex decision exists and no current blocker was found, but no automatic package is ready.")
    return "manual_same_lane_probe_candidate", "manual_same_lane_only", reasons


def build_cut_evidence_expansion(
    *,
    conn: sqlite3.Connection,
    strategy_audit: dict[str, Any],
    cut_safety: dict[str, dict[str, Any]],
    exposures: dict[str, dict[str, Any]],
    safe_cut_report: dict[str, Any] | None,
    deck_id: int = DEFAULT_BASELINE_DECK_ID,
) -> dict[str, Any]:
    decisions = card_decision_lookup(strategy_audit)
    deck_cards = load_current_deck_cards(conn, deck_id)
    variant_presence = lorehold_variant_presence(conn, [row["card_name"] for row in deck_cards])
    safe_cut_by_card = safe_cut_blockers_by_card(safe_cut_report)
    rows = []
    status_counts: Counter[str] = Counter()
    action_counts: Counter[str] = Counter()
    for card in deck_cards:
        key = normalize_key(card["card_name"])
        status, action, reasons = classify_cut_slot(
            card=card,
            decision=decisions.get(key, {}),
            safety=cut_safety.get(key, {}),
            variant_presence=variant_presence.get(key, {}),
            safe_cut_evidence=safe_cut_by_card.get(key, {}),
            cut_exposure=exposures.get(key, {}),
        )
        status_counts[status] += 1
        action_counts[action] += 1
        rows.append(
            {
                "card_name": card["card_name"],
                "status": status,
                "recommended_action": action,
                "reasons": reasons,
                "strategy_decision": {
                    key_name: value
                    for key_name, value in (decisions.get(key) or {}).items()
                    if key_name in {"decision", "effective_role", "package_lane", "status", "tags"}
                },
                "cut_safety": cut_safety.get(key, {}),
                "lorehold_variant_presence": variant_presence.get(key, {}),
                "safe_cut_replanner_evidence": safe_cut_by_card.get(key, {}),
                "cut_exposure": cut_exposure_summary(exposures.get(key, {})),
            }
        )
    rows.sort(
        key=lambda row: (
            {
                "cut_exposure_candidate": 0,
                "manual_same_lane_probe_candidate": 1,
                "needs_exposure_before_cut": 2,
                "same_lane_only": 3,
                "measured_cut_exposure_needs_same_lane_benchmark": 4,
                "measured_high_cut_exposure": 5,
            }.get(row["status"], 9),
            int((row.get("lorehold_variant_presence") or {}).get("deck_count") or 0),
            row["card_name"],
        )
    )
    return {
        "summary": {
            "deck_card_count": len(deck_cards),
            "lorehold_variant_deck_ids": list(DEFAULT_LOREHOLD_VARIANT_DECK_IDS),
            "status_counts": dict(sorted(status_counts.items())),
            "recommended_action_counts": dict(sorted(action_counts.items())),
            "model_cut_exposure_count": action_counts.get("model_cut_exposure", 0),
            "manual_same_lane_only_count": action_counts.get("manual_same_lane_only", 0),
        },
        "rows": rows,
        "top_exposure_candidates": [
            row
            for row in rows
            if row["status"] in {"cut_exposure_candidate", "needs_exposure_before_cut"}
        ][:20],
        "top_same_lane_candidates": [
            row
            for row in rows
            if row["status"]
            in {
                "measured_cut_exposure_needs_same_lane_benchmark",
                "manual_same_lane_probe_candidate",
                "same_lane_only",
            }
        ][:20],
        "top_protected_exposure_slots": [
            row
            for row in rows
            if row["status"] == "measured_high_cut_exposure"
        ][:20],
    }


def build_review(
    *,
    strategy_audit: dict[str, Any],
    cut_model: dict[str, Any],
    conn: sqlite3.Connection,
    exposure_profile: dict[str, Any] | None = None,
    exposure_profiles: list[tuple[Path | None, dict[str, Any]]] | None = None,
    safe_cut_report: dict[str, Any] | None = None,
    strategy_path: Path = DEFAULT_STRATEGY_AUDIT,
    cut_model_path: Path = DEFAULT_CUT_MODEL,
    db_path: Path = DEFAULT_DB,
    exposure_profile_path: Path | None = DEFAULT_EXPOSURE_PROFILE,
    exposure_profile_paths: list[Path] | None = None,
    safe_cut_report_path: Path | None = DEFAULT_SAFE_CUT_REPLANNER,
) -> dict[str, Any]:
    card_decisions = card_decision_lookup(strategy_audit)
    cut_safety = cut_safety_lookup(strategy_audit)
    if exposure_profiles is None:
        exposure_profile_entries = (
            [(exposure_profile_path, exposure_profile)] if exposure_profile else []
        )
    else:
        exposure_profile_entries = exposure_profiles
    exposures = exposure_lookup(exposure_profile_entries)
    loaded_exposure_paths = [
        str(path)
        for path, payload in exposure_profile_entries
        if path is not None and payload
    ]
    if exposure_profile_paths and not loaded_exposure_paths:
        loaded_exposure_paths = [str(path) for path in exposure_profile_paths if path.exists()]
    manual_pairings = [
        row
        for row in cut_model.get("pairing_hypotheses") or []
        if row.get("status") == "manual_cut_review_required"
    ]
    contextual_pairings = [
        row
        for row in cut_model.get("pairing_hypotheses") or []
        if row.get("status") == "needs_lane_model_before_gate"
    ]
    relevant_names = {
        row.get("candidate")
        for row in manual_pairings + contextual_pairings
        if row.get("candidate")
    }
    for row in manual_pairings:
        for cut in row.get("cut_options") or []:
            if cut.get("card_name"):
                relevant_names.add(cut["card_name"])
    rule_summaries = load_rule_summaries(conn, sorted(relevant_names))
    deck_presence = load_deck_presence(conn, sorted(relevant_names))
    cut_evidence_expansion = build_cut_evidence_expansion(
        conn=conn,
        strategy_audit=strategy_audit,
        cut_safety=cut_safety,
        exposures=exposures,
        safe_cut_report=safe_cut_report,
    )

    manual_reviews = []
    for pairing in manual_pairings:
        candidate = str(pairing.get("candidate") or "")
        cut_options = pairing.get("cut_options") or []
        if not cut_options:
            continue
        cut = str(cut_options[0].get("card_name") or "")
        candidate_key = normalize_key(candidate)
        cut_key = normalize_key(cut)
        decision, gate_action, reasons = classify_manual_pair(
            candidate=candidate,
            cut=cut,
            candidate_rule=rule_summaries.get(candidate_key, {}),
            cut_rule=rule_summaries.get(cut_key, {}),
            cut_decision=card_decisions.get(cut_key, {}),
            cut_safety=cut_safety.get(cut_key, {}),
            cut_exposure=exposures.get(cut_key, {}),
        )
        manual_reviews.append(
            {
                "candidate": candidate,
                "cut": cut,
                "lane": pairing.get("lane") or cut_options[0].get("lane"),
                "decision": decision,
                "gate_action": gate_action,
                "reasons": reasons,
                "candidate_rule": rule_summaries.get(candidate_key, {}),
                "cut_rule": rule_summaries.get(cut_key, {}),
                "cut_decision": {
                    key: value
                    for key, value in (card_decisions.get(cut_key) or {}).items()
                    if key
                    in {
                        "decision",
                        "decision_reason",
                        "effective_role",
                        "package_lane",
                        "status",
                        "rule_materialized_in_equal_gate_candidate",
                    }
                },
                "cut_exposure": {
                    key: value
                    for key, value in (exposures.get(cut_key) or {}).items()
                    if key
                    in {
                        "unique_exposure_count",
                        "direct_event_count",
                        "summary_metric_count",
                        "role_signals",
                        "inferred_role",
                        "role_confidence",
                        "decision",
                    }
                },
                "cut_deck_presence": deck_presence.get(cut_key, []),
                "candidate_deck_presence": deck_presence.get(candidate_key, []),
                "pairing_signature": cut_options[0].get("signature"),
            }
        )

    contextual_reviews = []
    for pairing in contextual_pairings:
        candidate = str(pairing.get("candidate") or "")
        candidate_key = normalize_key(candidate)
        evidence = package_learning_rows(strategy_audit, candidate)
        decision, gate_action, reasons = classify_contextual_candidate(
            candidate=candidate,
            rule=rule_summaries.get(candidate_key, {}),
            evidence_rows=evidence,
        )
        contextual_reviews.append(
            {
                "candidate": candidate,
                "lane": pairing.get("lane") or "contextual",
                "decision": decision,
                "gate_action": gate_action,
                "reasons": reasons,
                "candidate_rule": rule_summaries.get(candidate_key, {}),
                "candidate_deck_presence": deck_presence.get(candidate_key, []),
                "prior_evidence": evidence,
                "recommended_cut_search": recommended_cut_search(candidate, evidence),
            }
        )

    status_counts = Counter(row["decision"] for row in manual_reviews + contextual_reviews)
    if status_counts.get("manual_tradeoff_not_blind_cut"):
        safe_next_action = (
            "Do not spend a gate on Squee cuts; test Austere over Emeria only as an explicit "
            "wipe-over-rebuild tradeoff, not a blind same-lane replacement."
        )
    else:
        safe_next_action = (
            "No automatic gate is justified from this cut review; build a seed-safe tutor cut, "
            "a non-Squee recursion package, or a lane-specific exposure model before battle."
        )
    return {
        "generated_at": utc_now(),
        "strategy_audit": str(strategy_path),
        "cut_model": str(cut_model_path),
        "exposure_profile": ", ".join(loaded_exposure_paths),
        "exposure_profiles": loaded_exposure_paths,
        "safe_cut_replanner": str(safe_cut_report_path) if safe_cut_report else "",
        "source_db": str(db_path),
        "postgres_writes": False,
        "source_db_mutated": False,
        "external_research_sources": EXTERNAL_RESEARCH_SOURCES,
        "summary": {
            "manual_cut_review_count": len(manual_reviews),
            "contextual_lane_review_count": len(contextual_reviews),
            "decision_counts": dict(sorted(status_counts.items())),
            "automatic_gate_ready_count": 0,
            "cut_evidence_expansion": cut_evidence_expansion["summary"],
            "safe_next_action": safe_next_action,
        },
        "manual_cut_reviews": manual_reviews,
        "contextual_lane_reviews": contextual_reviews,
        "cut_evidence_expansion": cut_evidence_expansion,
        "next_actions": [
            {
                "priority": 1,
                "action": "preserve_squee_while_testing_recursion_variants",
                "reason": "Squee is an observed champion/probation recursion engine; Volcanic Vision and Restoration Seminar need another cut or multi-card package.",
            },
            {
                "priority": 2,
                "action": "gate_austere_over_emeria_only_as_tradeoff",
                "reason": "Emeria now has measured token/protection exposure; Austere Command must prove board-reset value beats rebuild/protection loss.",
            },
            {
                "priority": 3,
                "action": "rebuild_tutor_tests_around_seed_safe_cuts",
                "reason": "Gamble and Enlightened Tutor are runtime-ready, but prior tests over Thor/Creative regressed the protected seed.",
            },
        ],
    }


def recommended_cut_search(candidate: str, evidence: list[dict[str, Any]]) -> str:
    if normalize_key(candidate) == normalize_key("Gamble"):
        return (
            "Keep Gamble on probation only if the cut does not touch Thor and does not repeat "
            "Creative Technique without a seed-42 protection explanation."
        )
    if normalize_key(candidate) == normalize_key("Enlightened Tutor"):
        return (
            "Search artifact/enchantment access cuts separately; do not use Thor as the tutor-access cut."
        )
    if evidence:
        return "Use the prior package evidence to define a narrower same-lane cut."
    return "Define lane and same-lane cut before any battle gate."


def render_markdown(payload: dict[str, Any]) -> str:
    cut_summary = payload.get("cut_evidence_expansion", {}).get("summary") or {}
    lines = [
        "# Lorehold Manual Cut Review - 2026-06-28",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Strategy audit: `{payload['strategy_audit']}`",
        f"- Cut model: `{payload['cut_model']}`",
        f"- Exposure profiles: `{', '.join(payload.get('exposure_profiles') or []) or 'none'}`",
        f"- Safe-cut replanner: `{payload.get('safe_cut_replanner') or 'none'}`",
        f"- Source DB: `{payload['source_db']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Manual cut reviews: `{payload['summary']['manual_cut_review_count']}`",
        f"- Contextual lane reviews: `{payload['summary']['contextual_lane_review_count']}`",
        f"- Decision counts: `{json.dumps(payload['summary']['decision_counts'], sort_keys=True)}`",
        f"- Automatic gate-ready count: `{payload['summary']['automatic_gate_ready_count']}`",
        f"- Cut evidence status counts: `{json.dumps(cut_summary.get('status_counts') or {}, sort_keys=True)}`",
        f"- Cut evidence action counts: `{json.dumps(cut_summary.get('recommended_action_counts') or {}, sort_keys=True)}`",
        f"- Safe next action: {payload['summary']['safe_next_action']}",
        "",
        "## External Research Used As Heuristic Context",
        "",
    ]
    for source in payload["external_research_sources"]:
        lines.append(
            f"- [{source['title']}]({source['url']}): {source['finding']} "
            f"Use: `{source.get('use', 'heuristic_context_only')}`."
        )
    lines.extend(
        [
            "",
            "## Cut Evidence Expansion",
            "",
            "| Card | Status | Action | Lorehold Variants | Exposure | Reasons |",
            "| --- | --- | --- | ---: | ---: | --- |",
        ]
    )
    for row in (payload.get("cut_evidence_expansion") or {}).get("top_exposure_candidates") or []:
        presence = row.get("lorehold_variant_presence") or {}
        exposure = row.get("cut_exposure") or {}
        lines.append(
            "| {card} | `{status}` | `{action}` | {variants} | {exposure_count} | {reasons} |".format(
                card=row["card_name"],
                status=row["status"],
                action=row["recommended_action"],
                variants=int(presence.get("deck_count") or 0),
                exposure_count=int(exposure.get("unique_exposure_count") or 0),
                reasons="; ".join(row.get("reasons") or []),
            )
        )
    same_lane_rows = (payload.get("cut_evidence_expansion") or {}).get("top_same_lane_candidates") or []
    if same_lane_rows:
        lines.extend(
            [
                "",
                "## Profiled Same-Lane Cut Candidates",
                "",
                "| Card | Status | Action | Exposure | Role | Reasons |",
                "| --- | --- | --- | ---: | --- | --- |",
            ]
        )
        for row in same_lane_rows:
            exposure = row.get("cut_exposure") or {}
            lines.append(
                "| {card} | `{status}` | `{action}` | {exposure_count} | {role} | {reasons} |".format(
                    card=row["card_name"],
                    status=row["status"],
                    action=row["recommended_action"],
                    exposure_count=int(exposure.get("unique_exposure_count") or 0),
                    role=exposure.get("inferred_role") or "unmeasured",
                    reasons="; ".join(row.get("reasons") or []),
                )
            )
    protected_rows = (payload.get("cut_evidence_expansion") or {}).get("top_protected_exposure_slots") or []
    if protected_rows:
        lines.extend(
            [
                "",
                "## Protected By Measured Exposure",
                "",
                "| Card | Exposure | Role | Reasons |",
                "| --- | ---: | --- | --- |",
            ]
        )
        for row in protected_rows:
            exposure = row.get("cut_exposure") or {}
            lines.append(
                "| {card} | {exposure_count} | {role} | {reasons} |".format(
                    card=row["card_name"],
                    exposure_count=int(exposure.get("unique_exposure_count") or 0),
                    role=exposure.get("inferred_role") or "unmeasured",
                    reasons="; ".join(row.get("reasons") or []),
                )
            )
    lines.extend(
        [
            "",
            "## Manual Cut Reviews",
            "",
            "| Candidate | Proposed Cut | Decision | Action | Main Reasons |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["manual_cut_reviews"]:
        lines.append(
            "| {candidate} | {cut} | `{decision}` | `{action}` | {reasons} |".format(
                candidate=row["candidate"],
                cut=row["cut"],
                decision=row["decision"],
                action=row["gate_action"],
                reasons="; ".join(row["reasons"]),
            )
        )
    lines.extend(
        [
            "",
            "## Contextual Lane Reviews",
            "",
            "| Candidate | Decision | Action | Prior Evidence | Cut Search |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in payload["contextual_lane_reviews"]:
        evidence_bits = []
        for evidence in row.get("prior_evidence") or []:
            evidence_bits.append(
                "{key}: {delta:+.2f} pp / strong seed {seed:+.2f} pp".format(
                    key=evidence.get("package_key"),
                    delta=float(evidence.get("delta_pp") or 0),
                    seed=float(evidence.get("strong_seed_delta_pp") or 0),
                )
            )
        lines.append(
            "| {candidate} | `{decision}` | `{action}` | {evidence} | {cut_search} |".format(
                candidate=row["candidate"],
                decision=row["decision"],
                action=row["gate_action"],
                evidence="; ".join(evidence_bits) or "none",
                cut_search=row["recommended_cut_search"],
            )
        )
    lines.extend(["", "## Next Actions", ""])
    for row in payload["next_actions"]:
        lines.append(f"- P{row['priority']} `{row['action']}`: {row['reason']}")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--cut-model", type=Path, default=DEFAULT_CUT_MODEL)
    parser.add_argument("--exposure-profile", type=Path, action="append")
    parser.add_argument("--safe-cut-replanner", type=Path, default=DEFAULT_SAFE_CUT_REPLANNER)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--stem", default="lorehold_manual_cut_review_20260628_v1_safe_cut_expansion")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    strategy_audit = read_json(args.strategy_audit)
    cut_model = read_json(args.cut_model)
    exposure_paths = args.exposure_profile or DEFAULT_EXPOSURE_PROFILES
    exposure_profiles = read_existing_json(exposure_paths)
    safe_cut_report = read_optional_json(args.safe_cut_replanner)
    with connect(args.db) as conn:
        payload = build_review(
            strategy_audit=strategy_audit,
            cut_model=cut_model,
            conn=conn,
            exposure_profiles=exposure_profiles,
            safe_cut_report=safe_cut_report,
            strategy_path=args.strategy_audit,
            cut_model_path=args.cut_model,
            db_path=args.db,
            exposure_profile_paths=exposure_paths,
            safe_cut_report_path=args.safe_cut_replanner,
        )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(
        json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload) + "\n", encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
