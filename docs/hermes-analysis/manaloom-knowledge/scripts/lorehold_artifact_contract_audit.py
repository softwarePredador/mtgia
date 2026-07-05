#!/usr/bin/env python3
"""Normalize and audit Lorehold deckbuilding evidence artifacts.

This is the gate that prevents historical JSON reports from being interpreted
as if they all had the same schema. It is read-only: it never mutates
PostgreSQL, Hermes SQLite, or deck contents.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Mapping

from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
CURRENT_MATRIX = REPORT_DIR / "lorehold_variant_strategy_matrix_20260629_deckbuilding_contract.json"
REQUIRED_DECK_IDS = tuple(range(607, 617))
PROTECTED_BASELINE_KEY = "deck_607"
LIVE_CHALLENGER_KEYS = {"deck_614", "deck_615"}


@dataclass
class ArtifactClassification:
    path: str
    file_name: str
    artifact_kind: str
    schema_version: str
    status: str
    detail: str
    canonical_summary: dict[str, Any]

    def as_dict(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "file_name": self.file_name,
            "artifact_kind": self.artifact_kind,
            "schema_version": self.schema_version,
            "status": self.status,
            "detail": self.detail,
            "canonical_summary": self.canonical_summary,
        }


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def as_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except Exception:
        return default


def as_int(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def normalize_strategy_matrix(payload: Mapping[str, Any]) -> dict[str, Any]:
    decks = payload.get("decks")
    schema = "strategy_matrix_current_v1"
    if not isinstance(decks, list):
        decks = payload.get("ranked_decks")
        schema = "strategy_matrix_legacy_ranked_decks_v0"
    decks = decks if isinstance(decks, list) else []
    ranked_keys = payload.get("ranked_deck_keys")
    if not isinstance(ranked_keys, list) or not ranked_keys:
        ranked_keys = [
            str(deck.get("deck_key"))
            for deck in decks
            if isinstance(deck, Mapping) and deck.get("deck_key")
        ]
        schema = f"{schema}_rank_inferred"
    rank_by_key = {str(key): index + 1 for index, key in enumerate(ranked_keys)}
    deck_rows: list[dict[str, Any]] = []
    for deck in decks:
        if not isinstance(deck, Mapping):
            continue
        deck_key = str(deck.get("deck_key") or "")
        if not deck_key:
            continue
        ready_ratio = deck.get("battle_rule_ready_ratio")
        if ready_ratio is None and deck.get("battle_rule_ready_pct") is not None:
            ready_ratio = as_float(deck.get("battle_rule_ready_pct")) / 100.0
        deck_rows.append(
            {
                "deck_key": deck_key,
                "deck_id": deck.get("deck_id"),
                "rank": rank_by_key.get(deck_key),
                "strategy_score": deck.get("strategy_score"),
                "commander_intent_score": deck.get("commander_intent_score"),
                "battle_rule_ready_ratio": ready_ratio,
                "objective": deck.get("objective"),
                "primary_risks": deck.get("primary_risks") or [],
            }
        )
    missing_required = [
        key
        for key in [PROTECTED_BASELINE_KEY, *sorted(LIVE_CHALLENGER_KEYS)]
        if key not in {row["deck_key"] for row in deck_rows}
    ]
    return {
        "schema_version": schema,
        "deck_count": len(deck_rows),
        "ranked_deck_keys": list(ranked_keys),
        "protected_baseline_rank": rank_by_key.get(PROTECTED_BASELINE_KEY),
        "live_challenger_ranks": {
            key: rank_by_key.get(key)
            for key in sorted(LIVE_CHALLENGER_KEYS)
        },
        "missing_required_decks": missing_required,
        "top_decks": sorted(
            deck_rows,
            key=lambda row: row.get("rank") or 9999,
        )[:5],
    }


def normalize_equal_battle_gate(payload: Mapping[str, Any]) -> dict[str, Any]:
    results = payload.get("results") or []
    rows: list[dict[str, Any]] = []
    for result in results if isinstance(results, list) else []:
        if not isinstance(result, Mapping):
            continue
        telemetry = result.get("telemetry") if isinstance(result.get("telemetry"), Mapping) else {}
        strategic_games = telemetry.get("strategic_games") if isinstance(telemetry, Mapping) else {}
        focus_summary = telemetry.get("focus_card_access_summary") if isinstance(telemetry, Mapping) else {}
        rows.append(
            {
                "deck_key": result.get("deck_key"),
                "battle_rank": result.get("battle_rank"),
                "structural_rank": result.get("structural_rank"),
                "games": as_int(result.get("games")),
                "wins": as_int(result.get("wins")),
                "losses": as_int(result.get("losses")),
                "stalls": as_int(result.get("stalls")),
                "win_rate": as_float(result.get("win_rate")),
                "miracle_games": as_int((strategic_games.get("miracle_cast") or {}).get("games"))
                if isinstance(strategic_games, Mapping)
                else 0,
                "topdeck_games": as_int(
                    (strategic_games.get("topdeck_manipulation_activated") or {}).get("games")
                )
                if isinstance(strategic_games, Mapping)
                else 0,
                "focus_card_count": len(focus_summary) if isinstance(focus_summary, Mapping) else 0,
            }
        )
    return {
        "schema_version": "equal_battle_gate_v1",
        "status": payload.get("status"),
        "forced_access_mode": payload.get("forced_access_mode", "none"),
        "games_per_opponent": payload.get("games_per_opponent"),
        "opponent_kind": payload.get("opponent_kind"),
        "opponent_seed": payload.get("opponent_seed"),
        "simulation_seed": payload.get("simulation_seed"),
        "deck_process_isolation": payload.get("deck_process_isolation"),
        "game_timeout_seconds": payload.get("game_timeout_seconds"),
        "result_count": len(rows),
        "contains_baseline": any(row.get("deck_key") == PROTECTED_BASELINE_KEY for row in rows),
        "contains_live_challenger": any(row.get("deck_key") in LIVE_CHALLENGER_KEYS for row in rows),
        "result_rows": rows,
    }


def normalize_promotion_decision(path: Path, payload: Mapping[str, Any]) -> dict[str, Any]:
    decision = payload.get("decision") if isinstance(payload.get("decision"), Mapping) else {}
    return {
        "path": rel(path),
        "status": decision.get("status"),
        "protected_baseline": decision.get("protected_baseline"),
        "candidate_keys": decision.get("candidate_keys") or [],
        "promoted_deck_keys": decision.get("promoted_deck_keys") or [],
        "ready_for_real_deck_change": bool(decision.get("ready_for_real_deck_change")),
        "summary": decision.get("summary"),
        "recommended_next_action": decision.get("recommended_next_action"),
    }


def summarize_package_rows(payload: Mapping[str, Any]) -> dict[str, Any]:
    packages = payload.get("packages") or []
    return {
        "package_count": len(packages) if isinstance(packages, list) else 0,
        "games_per_opponent": payload.get("games_per_opponent"),
        "opponent_seed": payload.get("opponent_seed"),
        "simulation_seed": payload.get("simulation_seed"),
        "package_status_counts": payload.get("package_status_counts") or {},
        "source_db_mutated": payload.get("source_db_mutated", False),
        "postgres_writes": payload.get("postgres_writes", False),
        "preflight_only": payload.get("preflight_only"),
        "forced_access_mode": payload.get("forced_access_mode", "none"),
    }


def summarize_profiled_cut_package_manifest(payload: Mapping[str, Any]) -> dict[str, Any]:
    packages = payload.get("packages") or []
    packages = packages if isinstance(packages, list) else []
    valid_rows = [
        row
        for row in packages
        if isinstance(row, Mapping)
        and row.get("package_key")
        and isinstance(row.get("adds"), list)
        and isinstance(row.get("cuts"), list)
    ]
    return {
        "source": payload.get("source"),
        "package_count": len(packages),
        "valid_package_row_count": len(valid_rows),
        "prior_package_report_count": len(payload.get("prior_package_reports") or []),
        "manual_review": payload.get("manual_review"),
        "source_db_mutated": payload.get("source_db_mutated", False),
        "postgres_writes": payload.get("postgres_writes", False),
        "package_keys": [str(row.get("package_key")) for row in valid_rows],
    }


def summarize_prior_package_decision(payload: Mapping[str, Any]) -> dict[str, Any]:
    packages = payload.get("packages") or []
    packages = packages if isinstance(packages, list) else []
    valid_rows = [
        row
        for row in packages
        if isinstance(row, Mapping)
        and row.get("package_key")
        and isinstance(row.get("adds"), list)
        and isinstance(row.get("cuts"), list)
        and row.get("decision")
    ]
    decision_counts: dict[str, int] = {}
    for row in valid_rows:
        decision = str(row.get("decision"))
        decision_counts[decision] = decision_counts.get(decision, 0) + 1
    return {
        "source": payload.get("source"),
        "baseline_deck_id": payload.get("baseline_deck_id"),
        "package_count": len(packages),
        "valid_package_row_count": len(valid_rows),
        "decision_counts": decision_counts,
        "source_db_mutated": payload.get("source_db_mutated", False),
        "postgres_writes": payload.get("postgres_writes", False),
        "package_keys": [str(row.get("package_key")) for row in valid_rows],
    }


def summarize_exposure_aware_gate_queue(payload: Mapping[str, Any]) -> dict[str, Any]:
    packages = payload.get("packages") or []
    ready_queue = payload.get("ready_queue") or []
    summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
    return {
        "package_count": len(packages) if isinstance(packages, list) else 0,
        "ready_count": len(ready_queue) if isinstance(ready_queue, list) else 0,
        "natural_gate_ready_count": as_int(summary.get("natural_gate_ready_count")),
        "forced_exposure_probe_ready_count": as_int(summary.get("forced_exposure_probe_ready_count")),
        "recommended_next_action": summary.get("recommended_next_action"),
        "status_counts": summary.get("status_counts") or {},
        "readiness_report": payload.get("readiness_report"),
        "source_db_mutated": payload.get("source_db_mutated", False),
        "postgres_writes": payload.get("postgres_writes", False),
    }


def lorehold_learning_domain(artifact_type: str) -> str:
    checks = [
        ("mana", "mana_and_lands"),
        ("land", "mana_and_lands"),
        ("staple", "staples"),
        ("accessibility", "staples"),
        ("value", "card_value"),
        ("priority", "card_value"),
        ("cut", "cuts"),
        ("safe_cut", "cuts"),
        ("promotion", "promotion"),
        ("runtime", "runtime_rules"),
        ("brain", "runtime_rules"),
        ("entreat", "runtime_rules"),
        ("external", "external_learning"),
        ("identity", "external_learning"),
        ("topdeck", "topdeck_miracle"),
        ("miracle", "topdeck_miracle"),
        ("pressure", "pressure_conversion"),
        ("spell", "pressure_conversion"),
        ("restoration", "recursion"),
        ("soulfire", "interaction_removal"),
    ]
    for needle, domain in checks:
        if needle in artifact_type:
            return domain
    return "general_learning"


def summarize_governed_lorehold_artifact(payload: Mapping[str, Any]) -> dict[str, Any]:
    artifact_type = str(payload.get("artifact_type") or "")
    summary = payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {}
    decision = payload.get("decision") if isinstance(payload.get("decision"), Mapping) else {}
    return {
        "artifact_type": artifact_type,
        "learning_domain": lorehold_learning_domain(artifact_type),
        "status": payload.get("status"),
        "decision_status": summary.get("decision_status") or decision.get("status"),
        "summary": summary,
        "source_db_mutated": bool(payload.get("source_db_mutated")),
        "postgres_writes": bool(payload.get("postgres_writes")),
        "deck_607_mutated": bool(payload.get("deck_607_mutated")),
        "candidate_deck_materialization_allowed_now": bool(
            summary.get("candidate_deck_materialization_allowed_now")
            or decision.get("candidate_deck_materialization_allowed_now")
        ),
        "natural_battle_gate_allowed_now": bool(
            summary.get("natural_battle_gate_allowed_now")
            or summary.get("natural_gate_allowed_now")
            or decision.get("natural_battle_allowed_now")
            or decision.get("natural_gate_allowed_now")
        ),
        "promotion_allowed_now": bool(
            summary.get("promotion_allowed_now")
            or decision.get("promotion_allowed")
            or decision.get("promotion_allowed_now")
        ),
    }


def classify_payload(path: Path, payload: Mapping[str, Any]) -> ArtifactClassification:
    keys = set(payload.keys())
    file_name = path.name
    base = {
        "path": rel(path),
        "file_name": file_name,
    }

    if "ranked_deck_keys" in keys and ("decks" in keys or "ranked_decks" in keys):
        summary = normalize_strategy_matrix(payload)
        is_current_matrix = path.resolve() == CURRENT_MATRIX.resolve()
        status = "pass" if (not is_current_matrix or not summary["missing_required_decks"]) else "fail"
        return ArtifactClassification(
            **base,
            artifact_kind="strategy_matrix",
            schema_version=summary["schema_version"],
            status=status,
            detail=(
                "current matrix shape"
                if is_current_matrix
                else "candidate matrix shape"
                if "decks" in keys
                else "legacy ranked_decks shape"
            ),
            canonical_summary=summary,
        )

    if "results" in keys and "games_per_opponent" in keys:
        summary = normalize_equal_battle_gate(payload)
        status = "pass" if summary["result_count"] > 0 else "warn"
        return ArtifactClassification(
            **base,
            artifact_kind="equal_battle_gate",
            schema_version="equal_battle_gate_v1",
            status=status,
            detail="battle results normalized from results[]",
            canonical_summary=summary,
        )

    if payload.get("status") == "compact_gate_summary" and "results" in keys:
        summary = normalize_equal_battle_gate(payload)
        summary["schema_version"] = "compact_gate_summary_v1"
        status = "pass" if summary["result_count"] > 0 else "warn"
        return ArtifactClassification(
            **base,
            artifact_kind="compact_gate_summary",
            schema_version="compact_gate_summary_v1",
            status=status,
            detail="compact battle gate summary for planner consumption",
            canonical_summary=summary,
        )

    if "package_rollups" in keys and "packages" in keys:
        summary = {
            "schema_version": "exposure_outcome_audit_v2",
            "package_count": len(payload.get("packages") or []),
            "package_rollup_count": len(payload.get("package_rollups") or []),
            "summary": payload.get("summary") or {},
        }
        return ArtifactClassification(
            **base,
            artifact_kind="exposure_outcome_audit",
            schema_version="exposure_outcome_audit_v2",
            status="pass",
            detail="per-card exposure outcome rollups",
            canonical_summary=summary,
        )

    if "packages" in keys and "games_per_opponent" in keys:
        summary = summarize_package_rows(payload)
        return ArtifactClassification(
            **base,
            artifact_kind="package_gate",
            schema_version="package_gate_v1",
            status="pass",
            detail="package gate; not an equal deck battle gate",
            canonical_summary=summary,
        )

    if (
        "packages" in keys
        and "baseline_deck_id" in keys
        and "source" in keys
        and "postgres_writes" in keys
        and "source_db_mutated" in keys
    ):
        summary = summarize_prior_package_decision(payload)
        return ArtifactClassification(
            **base,
            artifact_kind="prior_package_decision",
            schema_version="prior_package_decision_compact_v1",
            status="pass" if summary["package_count"] == summary["valid_package_row_count"] else "warn",
            detail="compact prior package decision rows for package-reject memory",
            canonical_summary=summary,
        )

    if (
        payload.get("source") == "lorehold_profiled_cut_benchmark_generator"
        and "manual_review" in keys
        and "prior_package_reports" in keys
        and "packages" in keys
    ):
        summary = summarize_profiled_cut_package_manifest(payload)
        return ArtifactClassification(
            **base,
            artifact_kind="profiled_cut_package_manifest",
            schema_version="profiled_cut_package_manifest_v1",
            status="pass" if summary["package_count"] == summary["valid_package_row_count"] else "warn",
            detail="profiled cut benchmark package manifest",
            canonical_summary=summary,
        )

    if "ready_queue" in keys and "readiness_report" in keys and "packages" in keys and "summary" in keys:
        summary = summarize_exposure_aware_gate_queue(payload)
        return ArtifactClassification(
            **base,
            artifact_kind="exposure_aware_gate_queue",
            schema_version="exposure_aware_gate_queue_v1",
            status="pass",
            detail="exposure-aware package gate queue",
            canonical_summary=summary,
        )

    if (
        payload.get("artifact_type") == "lorehold_topdeck_access_first_sidecar_shell_contract"
        and {"contract", "decision", "source_evidence", "summary"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_topdeck_access_first_sidecar_shell_contract",
            schema_version="lorehold_topdeck_access_first_sidecar_shell_contract_v1",
            status="pass",
            detail="Lorehold topdeck access-first sidecar shell contract",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "contract_key": (payload.get("contract") or {}).get("contract_key")
                if isinstance(payload.get("contract"), Mapping)
                else None,
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_named_same_lane_cut_frontier"
        and {"decision", "mana_frontier", "source_evidence", "summary", "topdeck_frontier"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_named_same_lane_cut_frontier",
            schema_version="lorehold_named_same_lane_cut_frontier_v1",
            status="pass",
            detail="Lorehold named same-lane cut frontier router",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_brain_seed_safe_cut_unlock_audit"
        and {"decision", "external_deckbuilding_lessons", "source_summaries", "summary", "unlock_rows"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_brain_seed_safe_cut_unlock_audit",
            schema_version="lorehold_brain_seed_safe_cut_unlock_audit_v1",
            status="pass",
            detail="Lorehold Brain in a Jar seed-safe cut unlock audit",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_brain_cut_slot_trace_miner"
        and {"decision", "floor_trace_rows", "source_evidence", "summary", "target_floor_summaries"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_brain_cut_slot_trace_miner",
            schema_version="lorehold_brain_cut_slot_trace_miner_v1",
            status="pass",
            detail="Lorehold Brain cut-slot trace miner",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_topdeck_mana_trace_gap_scout"
        and {"decision", "mana_trace_gap", "source_evidence", "summary", "trace_gap_rows"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_topdeck_mana_trace_gap_scout",
            schema_version="lorehold_topdeck_mana_trace_gap_scout_v1",
            status="pass",
            detail="Lorehold topdeck and mana trace gap scout",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_gap_floor_trace_miner"
        and {"decision", "floor_trace_rows", "source_evidence", "summary", "target_floor_summaries"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_gap_floor_trace_miner",
            schema_version="lorehold_gap_floor_trace_miner_v1",
            status="pass",
            detail="Lorehold protected-607 gap floor trace miner",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_topdeck_sidecar_cut_model_planner"
        and {"cut_model_targets", "decision", "source_evidence", "summary"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_topdeck_sidecar_cut_model_planner",
            schema_version="lorehold_topdeck_sidecar_cut_model_planner_v1",
            status="pass",
            detail="Lorehold topdeck sidecar cut model planner with floor blockers",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_non_floor_probe_evidence_closure"
        and {"closure_rows", "decision", "source_evidence", "summary"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_non_floor_probe_evidence_closure",
            schema_version="lorehold_non_floor_probe_evidence_closure_v1",
            status="pass",
            detail="Lorehold non-floor sidecar probe evidence closure",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_post_named_frontier_next_evidence_router"
        and {"decision", "evidence_routes", "source_evidence", "summary"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_post_named_frontier_next_evidence_router",
            schema_version="lorehold_post_named_frontier_next_evidence_router_v1",
            status="pass",
            detail="Lorehold post-named frontier next evidence router",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    if (
        payload.get("artifact_type") == "lorehold_topdeck_new_cut_evidence_scout"
        and {"decision", "evidence_requests", "source_evidence", "summary"} <= keys
    ):
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_topdeck_new_cut_evidence_scout",
            schema_version="lorehold_topdeck_new_cut_evidence_scout_v1",
            status="pass",
            detail="Lorehold topdeck new cut evidence scout",
            canonical_summary={
                "schema_keys": sorted(keys),
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": payload.get("source_db_mutated", False),
                "postgres_writes": payload.get("postgres_writes", False),
                "deck_607_mutated": payload.get("deck_607_mutated", False),
            },
        )

    support_signatures: list[tuple[str, set[str], str]] = [
        ("candidate_matrix", {"rows", "summary"}, "candidate matrix rows"),
        ("variant_staging", {"reports", "valid_count", "invalid_count"}, "variant staging report"),
        ("card_exposure_profile", {"card_profiles", "scan_summary"}, "card exposure profile"),
        ("battle_forensic", {"replay_files", "rule_findings", "turn_findings"}, "battle forensic report"),
        ("canonical_snapshot", {"canonical_decisions", "cards", "local_summary"}, "canonical snapshot"),
        (
            "from_scratch_challenger_summary",
            {"candidates", "corpus_deck_ids", "fixed_opponent_deck_id_for_gate", "protected_baseline_deck_id"},
            "from-scratch challenger summary",
        ),
        (
            "from_scratch_challenger_candidate",
            {"battle_gate_command", "candidate_key", "final_deck", "mode", "protected_baseline_deck_id"},
            "from-scratch challenger candidate",
        ),
        ("generated_candidate", {"final_deck", "validation", "candidate_hash"}, "generated candidate"),
        ("generator_source_mix", {"runtime_source_mix_counts", "total_card_entries"}, "generator source mix"),
        ("cut_model", {"pair_evaluations", "top_pair_evaluations", "guardrails"}, "cut model"),
        ("next_action_planner", {"action_queue", "hypothesis_queue", "method_notes"}, "next action planner"),
        ("strategy_learning_audit", {"matrix_ranked", "current_champion_key"}, "strategy learning audit"),
        ("sync_report", {"apply_pg", "apply_sqlite_from_pg", "sqlite_inserted_or_updated"}, "sync report"),
        ("research_candidate", {"base_deck_id", "final_deck", "strategy_package_counts"}, "research candidate"),
        ("access_cut_model", {"access_density_context", "top_manual_review_candidates"}, "access cut model"),
        ("hypothesis_registry", {"acceptance_rule", "protected_baseline", "tested"}, "hypothesis registry"),
        ("failure_targeted_synergy", {"weak_seed_findings", "hypothesis_queue"}, "failure targeted synergy"),
        ("failure_targeted_trace", {"hypothesis_assessments", "focus_cards"}, "failure targeted trace"),
        ("focus_access_package_queue", {"package_candidates", "guardrail_contract"}, "focus access package queue"),
        (
            "deckbuilder_alignment_reaudit",
            {"current_flow", "decision", "evidence", "next_work"},
            "deckbuilder handoff alignment reaudit",
        ),
        (
            "focus_access_decision_wrapper",
            {"generated_at", "packages", "source_wrapper", "status", "summary"},
            "focus/package decision wrapper",
        ),
        (
            "expanded_package_manifest",
            {"correction_note", "generated_from", "packages", "purpose"},
            "expanded package manifest",
        ),
        (
            "hidden_retreat_unblock_readiness",
            {"blocker_chain", "env_status", "manifest_extract", "postgres_precheck"},
            "Hidden Retreat unblock readiness",
        ),
        ("learning_evidence_ledger", {"actionable_confirmation_queue", "package_groups"}, "learning evidence ledger"),
        ("loss_failure_classifier", {"loss_rows", "primary_cause_counts"}, "loss failure classifier"),
        ("mana_base_validator", {"ready_swaps", "manual_review_swaps"}, "mana base validator"),
        ("manual_cut_review", {"manual_cut_reviews", "next_actions"}, "manual cut review"),
        ("next_hypothesis_queue", {"queue", "promotion_contract"}, "next hypothesis queue"),
        ("profiled_cut_generator", {"selected_pairs", "blocked_cut_rows"}, "profiled cut generator"),
        ("candidate_hypothesis_registry", {"current_leader", "untested_queue"}, "candidate hypothesis registry"),
        ("strategy_audit", {"deck_summaries", "next_gates", "runtime_package_readiness"}, "strategy audit"),
        ("exposure_outcome_audit", {"decision_rules", "packages", "source_reports"}, "exposure outcome audit"),
        ("runtime_candidate_readiness", {"runtime_queue", "precheck_blockers"}, "runtime candidate readiness"),
        ("runtime_gap_family_queue", {"proposals", "mutations_performed"}, "runtime gap family queue"),
        ("runtime_gap_family_queue", {"family_queue", "validity_report"}, "runtime gap family queue"),
        (
            "runtime_gap_blocked_coherence",
            {"cards", "source_miner_summary", "severity_counts", "total_cards"},
            "runtime gap blocked coherence subreport",
        ),
        (
            "runtime_gap_family_subreport",
            {"cards", "families", "mutations_performed", "source", "status", "summary"},
            "runtime gap family subreport",
        ),
        (
            "runtime_gap_xmage_index_subreport",
            {"cards", "mutations_performed", "source", "status", "summary", "xmage_root"},
            "runtime gap XMage index subreport",
        ),
        (
            "runtime_gap_validity_subreport",
            {"cards", "mutations_performed", "source", "status", "summary"},
            "runtime gap validity subreport",
        ),
        ("safe_cut_replanner", {"manifest_ready_packages", "cut_safety"}, "safe cut replanner"),
        (
            "seed_safe_cut_hypothesis",
            {"cut_slots", "seed_safe_cut_candidates", "same_lane_only_cut_slots"},
            "seed-safe cut hypothesis synthesis",
        ),
        (
            "from_scratch_shell_failure_synthesis",
            {"learning_constraints", "next_hypothesis_requirements", "shell_gate_rows"},
            "from-scratch shell failure synthesis",
        ),
        (
            "closing_window_trace_miner",
            {"closing_window_comparisons", "hypothesis_queue", "protected_baseline"},
            "closing-window trace miner",
        ),
        (
            "trace_targeted_micro_package_model",
            {"blocked_hypotheses", "protected_anchor_evidence", "ready_packages"},
            "trace-targeted micro-package model",
        ),
        (
            "lorehold_current_champion_snapshot",
            {"cards", "champion_decision", "protected_anchors"},
            "Lorehold current champion snapshot",
        ),
        (
            "trace_cut_evidence_expansion_queue",
            {"all_cut_slots", "hard_blocked_queue", "reviewable_evidence_gap_queue"},
            "trace cut evidence expansion queue",
        ),
        (
            "lorehold_deckbuilding_final_closure",
            {"final_decision", "source_reports", "validation"},
            "Lorehold deckbuilding final closure",
        ),
        (
            "safe_cut_package_manifest",
            {"generated_at", "packages", "purpose", "source_ledger"},
            "safe cut package manifest",
        ),
        (
            "seed_safe_cut_manifest",
            {"generated_at", "cut_slots", "purpose", "deck_id"},
            "seed-safe cut manifest",
        ),
        ("action_critic", {"actions", "findings"}, "single replay action critic"),
        ("decision_audit", {"decision_findings", "baseline_findings"}, "single replay decision audit"),
        ("squee_rebaseline_summary", {"baseline", "candidate_key", "swap"}, "Squee rebaseline summary"),
        ("squee_graveyard_probe", {"runtime_gate_rows", "trace_seed_rows"}, "Squee graveyard probe"),
        ("squee_rule_materialization", {"source_gate_jsons", "finding"}, "Squee rule materialization audit"),
        ("squee_seed_diagnostic", {"diagnostic_gates", "suite_summary"}, "Squee seed diagnostic"),
        ("thor_rule_runtime_audit", {"reviewed_rule", "runtime_test_verification"}, "Thor runtime audit"),
        ("tutor_cut_model", {"cut_pair_evaluations", "top_direct_gate_candidates"}, "tutor cut model"),
        ("variant_gap_miner", {"top_variant_candidates", "pairing_hypotheses"}, "variant gap miner"),
        (
            "cut_methodology_reaudit",
            {"candidate_report", "validation_report", "pairs", "metric_contract", "decision"},
            "Lorehold cut methodology decision audit",
        ),
        (
            "molecule_scarlet_validation",
            {"natural", "forced_opening_diagnostic", "structural_matrix", "decision"},
            "Molecule Man and The Scarlet Witch validation decision",
        ),
        (
            "commander_learned_deck_import",
            {"source_system", "source_ref", "commander_name", "card_list", "card_count"},
            "Commander learned deck import payload",
        ),
        ("artifact_contract_audit", {"artifacts", "continuation_gate", "current_matrix"}, "artifact contract audit"),
        (
            "equal_battle_gate_checkpoint",
            {"events", "latest", "completed_games", "total_games"},
            "equal battle gate checkpoint",
        ),
        (
            "promotion_gate_decision_audit",
            {"gate_paths", "decision", "deck_aggregates", "candidate_assessments"},
            "Lorehold promotion gate decision audit",
        ),
    ]
    for artifact_kind, required, detail in support_signatures:
        if required <= keys:
            return ArtifactClassification(
                **base,
                artifact_kind=artifact_kind,
                schema_version=f"{artifact_kind}_recognized_v1",
                status="pass",
                detail=detail,
                canonical_summary={
                    "schema_keys": sorted(keys),
                    "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else None,
                    "source_db_mutated": payload.get("source_db_mutated", False),
                    "postgres_writes": payload.get("postgres_writes", False),
                },
            )

    if keys == {"summary"} and file_name.startswith("lorehold_target_pressure_replay_"):
        return ArtifactClassification(
            **base,
            artifact_kind="target_pressure_replay",
            schema_version="target_pressure_replay_recognized_v1",
            status="pass",
            detail="single target pressure replay summary",
            canonical_summary={"summary": payload.get("summary")},
        )

    if {"package_key", "adds", "cuts", "observations", "decision_rules", "summary"} <= keys:
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_mana_vault_evidence_synthesis",
            schema_version="lorehold_mana_vault_evidence_synthesis_v1",
            status="pass",
            detail="Lorehold Mana Vault evidence synthesis",
            canonical_summary={
                "package_key": payload.get("package_key"),
                "adds": payload.get("adds") if isinstance(payload.get("adds"), list) else [],
                "cuts": payload.get("cuts") if isinstance(payload.get("cuts"), list) else [],
                "observation_count": len(payload.get("observations") or [])
                if isinstance(payload.get("observations"), list)
                else 0,
                "summary": payload.get("summary") if isinstance(payload.get("summary"), Mapping) else {},
                "source_db_mutated": bool(payload.get("source_db_mutated")),
                "postgres_writes": bool(payload.get("postgres_writes")),
            },
        )

    if file_name.startswith("lorehold_ramp_package_evaluation_") and {"generated_at", "packages", "source_db"} <= keys:
        return ArtifactClassification(
            **base,
            artifact_kind="lorehold_ramp_package_evaluation",
            schema_version="lorehold_ramp_package_evaluation_v1",
            status="pass",
            detail="Lorehold ramp package evaluation",
            canonical_summary={
                "package_count": len(payload.get("packages") or [])
                if isinstance(payload.get("packages"), list)
                else 0,
                "source_db": payload.get("source_db"),
            },
        )

    artifact_type = str(payload.get("artifact_type") or "")
    if (
        artifact_type.startswith("lorehold_")
        and "generated_at" in keys
        and ("summary" in keys or "decision" in keys)
    ):
        summary = summarize_governed_lorehold_artifact(payload)
        has_historical_mutation = (
            summary["source_db_mutated"]
            or summary["postgres_writes"]
            or summary["deck_607_mutated"]
        )
        return ArtifactClassification(
            **base,
            artifact_kind=artifact_type,
            schema_version=f"{artifact_type}_governed_v1",
            status="warn" if has_historical_mutation else "pass",
            detail="governed Lorehold learning artifact with explicit mutation flags",
            canonical_summary=summary,
        )

    return ArtifactClassification(
        **base,
        artifact_kind="unknown",
        schema_version="unknown",
        status="fail",
        detail="unrecognized Lorehold artifact schema",
        canonical_summary={"schema_keys": sorted(keys)},
    )


def scan_artifacts(paths: Iterable[Path]) -> list[ArtifactClassification]:
    rows: list[ArtifactClassification] = []
    for path in sorted(paths):
        if not path.exists() or path.suffix != ".json":
            continue
        try:
            payload = read_json(path)
        except Exception as exc:
            rows.append(
                ArtifactClassification(
                    path=rel(path),
                    file_name=path.name,
                    artifact_kind="invalid_json",
                    schema_version="invalid_json",
                    status="fail",
                    detail=str(exc),
                    canonical_summary={},
                )
            )
            continue
        rows.append(classify_payload(path, payload))
    return rows


def validate_deck_universe(db_path: Path, deck_ids: Iterable[int] = REQUIRED_DECK_IDS) -> dict[str, Any]:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        f"""
        SELECT
          deck_id,
          COUNT(*) AS row_count,
          COALESCE(SUM(quantity), 0) AS quantity_total,
          SUM(CASE WHEN COALESCE(card_id, '') = '' THEN 1 ELSE 0 END) AS missing_card_id_count,
          SUM(CASE WHEN COALESCE(card_name, '') = '' THEN 1 ELSE 0 END) AS missing_card_name_count
        FROM deck_cards
        WHERE deck_id IN ({','.join('?' for _ in deck_ids)})
        GROUP BY deck_id
        ORDER BY deck_id
        """,
        tuple(deck_ids),
    ).fetchall()
    conn.close()
    by_id = {int(row["deck_id"]): dict(row) for row in rows}
    missing_deck_ids = [deck_id for deck_id in deck_ids if deck_id not in by_id]
    invalid_decks = []
    for deck_id in deck_ids:
        row = by_id.get(deck_id)
        if not row:
            continue
        if (
            int(row["quantity_total"] or 0) != 100
            or int(row["missing_card_id_count"] or 0) != 0
            or int(row["missing_card_name_count"] or 0) != 0
        ):
            invalid_decks.append(row)
    return {
        "status": "pass" if not missing_deck_ids and not invalid_decks else "fail",
        "db_path": str(db_path),
        "required_deck_ids": list(deck_ids),
        "deck_count": len(by_id),
        "missing_deck_ids": missing_deck_ids,
        "invalid_decks": invalid_decks,
        "decks": [by_id[deck_id] for deck_id in deck_ids if deck_id in by_id],
    }


def build_report(
    *,
    db_path: Path = DEFAULT_DB,
    matrix_path: Path = CURRENT_MATRIX,
    promotion_decision_path: Path | None = None,
    artifact_paths: Iterable[Path] | None = None,
) -> dict[str, Any]:
    paths = list(artifact_paths or REPORT_DIR.glob("lorehold*.json"))
    classifications = scan_artifacts(paths)
    classification_counts: dict[str, int] = {}
    status_counts: dict[str, int] = {}
    for row in classifications:
        classification_counts[row.artifact_kind] = classification_counts.get(row.artifact_kind, 0) + 1
        status_counts[row.status] = status_counts.get(row.status, 0) + 1
    unknowns = [row for row in classifications if row.status == "fail"]
    current_matrix_rows = [row for row in classifications if Path(row.path).name == matrix_path.name]
    current_matrix = current_matrix_rows[0].as_dict() if current_matrix_rows else None
    deck_universe = validate_deck_universe(db_path)

    matrix_pass = bool(current_matrix and current_matrix.get("status") == "pass")
    artifact_contract_pass = not unknowns and matrix_pass
    deck_universe_pass = deck_universe["status"] == "pass"
    can_run_equal_battle_gate = artifact_contract_pass and deck_universe_pass
    promotion_decision = None
    if promotion_decision_path and promotion_decision_path.exists():
        promotion_decision = normalize_promotion_decision(
            promotion_decision_path,
            read_json(promotion_decision_path),
        )
    ready_for_real_deck_change = bool(
        can_run_equal_battle_gate
        and promotion_decision
        and promotion_decision.get("ready_for_real_deck_change")
    )

    continuation_gate = {
        "artifact_contract_status": "pass" if artifact_contract_pass else "fail",
        "deck_universe_status": deck_universe["status"],
        "current_matrix_status": "pass" if matrix_pass else "fail",
        "can_run_equal_battle_gate": can_run_equal_battle_gate,
        "promotion_decision": promotion_decision,
        "ready_for_real_deck_change": ready_for_real_deck_change,
        "real_deck_change_blocker": (
            "none"
            if ready_for_real_deck_change
            else (
                "requires explicit promotion decision audit with ready_for_real_deck_change=true"
                if not promotion_decision
                else str(promotion_decision.get("summary") or "promotion decision did not clear the gate")
            )
        ),
    }

    return {
        "generated_at": utc_now(),
        "status": "pass" if can_run_equal_battle_gate else "fail",
        "postgres_writes": False,
        "source_db_mutated": False,
        "current_matrix": current_matrix,
        "deck_universe": deck_universe,
        "continuation_gate": continuation_gate,
        "summary": {
            "artifact_count": len(classifications),
            "classification_counts": dict(sorted(classification_counts.items())),
            "status_counts": dict(sorted(status_counts.items())),
            "unknown_or_invalid_count": len(unknowns),
        },
        "unknown_or_invalid_artifacts": [row.as_dict() for row in unknowns],
        "artifacts": [row.as_dict() for row in classifications],
    }


def write_markdown(report: Mapping[str, Any], path: Path) -> None:
    gate = report["continuation_gate"]
    promotion_decision = gate.get("promotion_decision") or {}
    matrix_summary = ((report.get("current_matrix") or {}).get("canonical_summary") or {})
    lines = [
        "# Lorehold Artifact Contract Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Artifact count: `{report['summary']['artifact_count']}`",
        f"- Unknown/invalid artifacts: `{report['summary']['unknown_or_invalid_count']}`",
        f"- Artifact contract: `{gate['artifact_contract_status']}`",
        f"- Deck universe: `{gate['deck_universe_status']}`",
        f"- Current matrix: `{gate['current_matrix_status']}`",
        f"- Can run equal battle gate: `{str(gate['can_run_equal_battle_gate']).lower()}`",
        f"- Ready for real deck change: `{str(gate['ready_for_real_deck_change']).lower()}`",
        f"- Real deck change blocker: {gate['real_deck_change_blocker']}",
        f"- Promotion decision: `{promotion_decision.get('path', 'none')}`",
        f"- Promoted deck keys: `{json.dumps(promotion_decision.get('promoted_deck_keys') or [])}`",
        "",
        "## Current Matrix",
        "",
        f"- Schema: `{((report.get('current_matrix') or {}).get('schema_version') or 'missing')}`",
        f"- Protected baseline rank: `{matrix_summary.get('protected_baseline_rank')}`",
        f"- Live challenger ranks: `{json.dumps(matrix_summary.get('live_challenger_ranks') or {}, sort_keys=True)}`",
        f"- Missing required decks: `{json.dumps(matrix_summary.get('missing_required_decks') or [])}`",
        "",
        "## Deck Universe",
        "",
        "| Deck ID | Rows | Quantity | Missing Card IDs | Missing Names |",
        "| ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in report["deck_universe"]["decks"]:
        lines.append(
            f"| {row['deck_id']} | {row['row_count']} | {row['quantity_total']} | "
            f"{row['missing_card_id_count']} | {row['missing_card_name_count']} |"
        )
    lines.extend(
        [
            "",
            "## Classification Counts",
            "",
            "| Kind | Count |",
            "| --- | ---: |",
        ]
    )
    for kind, count in sorted(report["summary"]["classification_counts"].items()):
        lines.append(f"| `{kind}` | {count} |")
    if report["unknown_or_invalid_artifacts"]:
        lines.extend(["", "## Unknown Or Invalid Artifacts", ""])
        for row in report["unknown_or_invalid_artifacts"]:
            lines.append(f"- `{row['path']}`: {row['detail']}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--matrix", type=Path, default=CURRENT_MATRIX)
    parser.add_argument("--promotion-decision", type=Path, default=None)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "lorehold_artifact_contract_audit_20260629_current",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(
        db_path=args.db,
        matrix_path=args.matrix,
        promotion_decision_path=args.promotion_decision,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=True, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
