#!/usr/bin/env python3
"""Collect trace or external evidence for same-lane stage-only cuts.

This read-only gate consumes the same-lane cut evidence plan, reuses existing
current-scope replay artifacts when available, and scans local report artifacts
for external/reference occurrences. It does not run new battles, mutate any DB,
reclassify cuts, copy candidates, or promote a package.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections import Counter
from collections.abc import Iterable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_contextual_usage_trace_generator import summarize_trace_files
from global_commander_deck_contract_audit import DEFAULT_SQLITE_DB, REPO_ROOT
from master_optimizer_common import normalize_name


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_EVIDENCE_PLAN_REPORT = (
    REPORT_DIR
    / "global_commander_same_lane_cut_evidence_plan_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_TRACE_GENERATOR_REPORT = (
    REPORT_DIR
    / "global_commander_contextual_usage_trace_generator_20260705_kaalia_value_safe_stage1_repair_scope1.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR
    / "global_commander_same_lane_stage_cut_trace_collector_20260705_kaalia_value_safe_stage1_repair_scope1"
)

TRACE_MARKERS = ("replay", "trace", "events", "battle_probe")
EXTERNAL_REFERENCE_MARKERS = ("external", "corpus", "edhrec", "moxfield", "archidekt", "spellbook")
NON_PROOF_PLANNING_MARKERS = (
    "same_lane_cut_evidence_plan",
    "same_lane_stage_cut_trace_collector",
    "same_lane_cut_pair_collector",
    "same_lane_package_source_synthesizer",
    "stage_only_cut_evidence_plan",
)
TEXT_SUFFIXES = {".json", ".jsonl", ".md", ".txt", ".out"}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def resolve_repo_path(value: object, fallback: Path) -> Path:
    text = str(value or "").strip()
    if not text:
        return fallback
    path = Path(text)
    return path if path.is_absolute() else REPO_ROOT / path


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def evidence_rows(payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = [
        dict(row)
        for row in payload.get("evidence_plan_rows") or []
        if isinstance(row, Mapping) and row.get("card_name")
    ]
    rows.sort(
        key=lambda row: (
            as_int(row.get("maximum_evidence_burden")),
            as_int(row.get("minimum_evidence_burden")),
            -as_int(row.get("score")),
            str(row.get("card_name") or ""),
        )
    )
    return rows


def unique_cards(rows: list[Mapping[str, Any]]) -> list[str]:
    seen: set[str] = set()
    cards: list[str] = []
    for row in rows:
        card = str(row.get("card_name") or "")
        key = normalize_name(card)
        if card and key not in seen:
            seen.add(key)
            cards.append(card)
    return cards


def resolve_cut_pair_report(evidence_plan_payload: Mapping[str, Any]) -> Path:
    inputs = evidence_plan_payload.get("input_artifacts") or {}
    return resolve_repo_path(
        inputs.get("cut_pair_report"),
        REPORT_DIR
        / "global_commander_same_lane_cut_pair_collector_20260705_kaalia_value_safe_stage1_repair_scope1.json",
    )


def resolve_selected_db(evidence_plan_payload: Mapping[str, Any], sqlite_db: Path | None) -> tuple[Path, dict[str, Any]]:
    if sqlite_db is not None:
        return sqlite_db, {
            "selected_db": rel(sqlite_db),
            "source": "cli_override",
            "selected_db_exists": sqlite_db.exists(),
        }
    cut_pair_report = resolve_cut_pair_report(evidence_plan_payload)
    cut_pair_payload = load_json(cut_pair_report) if cut_pair_report.exists() else {}
    inputs = cut_pair_payload.get("input_artifacts") or {}
    selected_db = resolve_repo_path(inputs.get("selected_db"), DEFAULT_SQLITE_DB)
    if selected_db.exists():
        return selected_db, {
            "selected_db": rel(selected_db),
            "source": "same_lane_cut_pair_report",
            "selected_db_exists": True,
            "cut_pair_report": rel(cut_pair_report),
        }
    return DEFAULT_SQLITE_DB, {
        "requested_db": rel(selected_db),
        "selected_db": rel(DEFAULT_SQLITE_DB),
        "source": "default_sqlite_fallback",
        "selected_db_exists": DEFAULT_SQLITE_DB.exists(),
        "cut_pair_report": rel(cut_pair_report),
    }


def table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1",
        (table_name,),
    ).fetchone()
    return bool(row)


def deck_context_by_name(db_path: Path, deck_id: str, cards: list[str]) -> dict[str, dict[str, Any]]:
    if not db_path.exists():
        return {}
    wanted = {normalize_name(card) for card in cards}
    conn = sqlite3.connect(db_path)
    try:
        if not table_exists(conn, "deck_cards"):
            return {}
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            """
            SELECT card_name, COALESCE(quantity, 1) AS quantity, functional_tag,
                   functional_tags_json, type_line, oracle_text, cmc,
                   COALESCE(is_commander, 0) AS is_commander
            FROM deck_cards
            WHERE CAST(deck_id AS TEXT)=?
            ORDER BY card_name
            """,
            (str(deck_id),),
        ).fetchall()
    finally:
        conn.close()
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(str(row["card_name"] or ""))
        if key in wanted:
            out[key] = dict(row)
    return out


def format_staples_by_name(db_path: Path, cards: list[str]) -> dict[str, dict[str, Any]]:
    if not db_path.exists():
        return {}
    wanted = {normalize_name(card) for card in cards}
    conn = sqlite3.connect(db_path)
    try:
        if not table_exists(conn, "format_staples"):
            return {}
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            """
            SELECT card_name, format, archetype, category, color_identity, edhrec_rank, is_banned
            FROM format_staples
            WHERE COALESCE(is_banned, 0)=0
            ORDER BY COALESCE(edhrec_rank, 999999), card_name
            """
        ).fetchall()
    finally:
        conn.close()
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        key = normalize_name(str(row["card_name"] or ""))
        if key not in wanted:
            continue
        rank = as_int(row["edhrec_rank"]) or 999999
        current = out.get(key)
        if current is None or rank < as_int(current.get("edhrec_rank")):
            out[key] = {
                "card_name": row["card_name"],
                "format": row["format"],
                "archetype": row["archetype"],
                "category": row["category"],
                "color_identity": row["color_identity"],
                "edhrec_rank": row["edhrec_rank"],
            }
    return out


def empty_trace_summary(cards: list[str]) -> dict[str, dict[str, Any]]:
    return {
        card: {
            "usage_event_count": 0,
            "exposure_event_count": 0,
            "decision_trace_count": 0,
            "reference_event_count": 0,
            "event_types": {},
            "first_usage_event": None,
            "first_exposure_event": None,
            "first_decision_trace": None,
        }
        for card in cards
    }


def resolve_path(value: object) -> Path:
    path = Path(str(value or ""))
    return path if path.is_absolute() else REPO_ROOT / path


def merge_trace(target: dict[str, Any], source: Mapping[str, Any]) -> None:
    for key in ("usage_event_count", "exposure_event_count", "decision_trace_count", "reference_event_count"):
        target[key] = as_int(target.get(key)) + as_int(source.get(key))
    target_events = target.setdefault("event_types", {})
    for event, count in (source.get("event_types") or {}).items():
        target_events[str(event)] = as_int(target_events.get(str(event))) + as_int(count)
    for key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
        if target.get(key) is None and source.get(key) is not None:
            target[key] = source.get(key)


def collect_existing_replay_traces(
    *,
    trace_generator_report: Path | None,
    cards: list[str],
    target_player: str,
) -> tuple[dict[str, dict[str, Any]], list[dict[str, Any]], dict[str, Any]]:
    aggregate = empty_trace_summary(cards)
    seed_rows: list[dict[str, Any]] = []
    if trace_generator_report is None or not trace_generator_report.exists():
        return aggregate, seed_rows, {
            "trace_generator_report": rel(trace_generator_report) if trace_generator_report else "",
            "available": False,
            "reason": "trace_generator_report_missing",
        }
    payload = load_json(trace_generator_report)
    for row in payload.get("seed_reports") or []:
        if not isinstance(row, Mapping):
            continue
        events_path = resolve_path(row.get("events_path"))
        decisions_path = resolve_path(row.get("decisions_path"))
        summary = summarize_trace_files(
            events_path=events_path,
            decisions_path=decisions_path,
            card_names=cards,
            target_player=target_player,
        )
        for card, card_summary in summary["cards"].items():
            merge_trace(aggregate[card], card_summary)
        seed_rows.append(
            {
                "seed": row.get("seed"),
                "events_path": rel(events_path),
                "decisions_path": rel(decisions_path),
                "event_count": summary["event_count"],
                "decision_count": summary["decision_count"],
            }
        )
    return aggregate, seed_rows, {
        "trace_generator_report": rel(trace_generator_report),
        "available": True,
        "seed_report_count": len(seed_rows),
        "source_status": payload.get("status"),
    }


def is_text_artifact(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in TEXT_SUFFIXES


def iter_artifacts(root: Path) -> Iterable[Path]:
    if root.is_file():
        if is_text_artifact(root):
            yield root
        return
    for path in root.rglob("*"):
        if is_text_artifact(path):
            yield path


def artifact_kind(path: Path) -> str:
    text = rel(path).lower()
    if any(marker in text for marker in NON_PROOF_PLANNING_MARKERS):
        return "planning_reference_not_proof"
    if any(marker in text for marker in EXTERNAL_REFERENCE_MARKERS):
        return "external_reference_artifact"
    if any(marker in text for marker in TRACE_MARKERS):
        return "trace_artifact_reference"
    return "other_reference"


def scan_artifact_references(
    *,
    scan_roots: list[Path],
    cards: list[str],
    max_occurrences_per_card: int,
) -> dict[str, list[dict[str, Any]]]:
    wanted = [(card, normalize_name(card)) for card in cards]
    occurrences: dict[str, list[dict[str, Any]]] = {card: [] for card in cards}
    for root in scan_roots:
        if not root.exists():
            continue
        for path in iter_artifacts(root):
            kind = artifact_kind(path)
            if kind == "other_reference":
                path_text = normalize_name(path.name)
                if not any(key in path_text for _card, key in wanted):
                    continue
            try:
                handle = path.open("r", encoding="utf-8", errors="ignore")
            except OSError:
                continue
            with handle:
                for line_number, line in enumerate(handle, start=1):
                    normalized_line = normalize_name(line)
                    for card, key in wanted:
                        if not key or key not in normalized_line:
                            continue
                        if len(occurrences[card]) >= max_occurrences_per_card:
                            continue
                        occurrences[card].append(
                            {
                                "path": rel(path),
                                "line": line_number,
                                "artifact_kind": kind,
                                "excerpt": " ".join(line.strip().split())[:220],
                            }
                        )
    return occurrences


def summarize_artifact_occurrences(rows: list[Mapping[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get("artifact_kind") or "unknown")] += 1
    return dict(counts)


def classify_card(
    *,
    plan_row: Mapping[str, Any],
    trace: Mapping[str, Any],
    deck_row: Mapping[str, Any] | None,
    staple: Mapping[str, Any] | None,
    artifact_refs: list[dict[str, Any]],
) -> dict[str, Any]:
    usage = as_int(trace.get("usage_event_count"))
    exposure = as_int(trace.get("exposure_event_count"))
    decisions = as_int(trace.get("decision_trace_count"))
    artifact_counts = summarize_artifact_occurrences(artifact_refs)
    external_refs = as_int(artifact_counts.get("external_reference_artifact"))
    if usage > 0:
        status = "same_lane_stage_cut_usage_trace_blocks_value_safe"
        next_evidence = "build_same_lane_replacement_or_find_new_cut_source"
    elif exposure > 0 or decisions > 0:
        status = "same_lane_stage_cut_seen_without_usage_needs_negative_review"
        next_evidence = "manual_negative_review_or_force_access_before_reclassification"
    elif external_refs > 0:
        status = "same_lane_stage_cut_external_reference_needs_internal_trace"
        next_evidence = "collect_current_scope_trace_for_external_reference_card"
    else:
        status = "same_lane_stage_cut_needs_trace_or_external_research"
        next_evidence = "generate_or_import_same_lane_stage_cut_usage_trace"
    return {
        "card_name": plan_row.get("card_name"),
        "target_cut_role": plan_row.get("target_cut_role"),
        "status": status,
        "evidence_lanes": plan_row.get("evidence_lanes") or [],
        "stage_reasons": plan_row.get("stage_reasons") or [],
        "profile_roles": plan_row.get("profile_roles") or [],
        "risk_flags": plan_row.get("risk_flags") or [],
        "maximum_evidence_burden": as_int(plan_row.get("maximum_evidence_burden")),
        "current_deck_present": deck_row is not None,
        "format_staple": staple or {},
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": trace.get("event_types") or {},
        "first_usage_event": trace.get("first_usage_event"),
        "first_exposure_event": trace.get("first_exposure_event"),
        "first_decision_trace": trace.get("first_decision_trace"),
        "artifact_reference_counts": artifact_counts,
        "artifact_reference_sample": artifact_refs[:5],
        "next_evidence": next_evidence,
        "value_safe_reclassification_allowed": False,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
    }


def group_counts(rows: list[Mapping[str, Any]], key: str) -> dict[str, int]:
    counts: Counter[str] = Counter()
    for row in rows:
        counts[str(row.get(key) or "unknown")] += 1
    return dict(counts)


def list_cards(rows: list[Mapping[str, Any]], status: str) -> list[str]:
    return [str(row.get("card_name") or "") for row in rows if row.get("status") == status]


def choose_status_and_next_gate(rows: list[Mapping[str, Any]]) -> tuple[str, str]:
    usage = list_cards(rows, "same_lane_stage_cut_usage_trace_blocks_value_safe")
    seen = list_cards(rows, "same_lane_stage_cut_seen_without_usage_needs_negative_review")
    external = list_cards(rows, "same_lane_stage_cut_external_reference_needs_internal_trace")
    if usage:
        return (
            "same_lane_stage_cut_trace_collection_blocks_used_cuts",
            "build_same_lane_replacement_or_find_new_cut_source_for_used_stage_cuts",
        )
    if seen:
        return (
            "same_lane_stage_cut_trace_collection_needs_negative_review",
            "manual_negative_review_or_force_access_for_seen_stage_cuts",
        )
    if external:
        return (
            "same_lane_stage_cut_trace_collection_has_external_references_only",
            "collect_current_scope_trace_for_external_reference_stage_cuts",
        )
    return (
        "same_lane_stage_cut_trace_collection_needs_trace_generation",
        "generate_or_import_same_lane_stage_cut_usage_traces",
    )


def build_report(
    *,
    evidence_plan_report: Path,
    trace_generator_report: Path | None = DEFAULT_TRACE_GENERATOR_REPORT,
    sqlite_db: Path | None = None,
    scan_roots: list[Path] | None = None,
    max_occurrences_per_card: int = 8,
) -> dict[str, Any]:
    evidence_payload = load_json(evidence_plan_report)
    summary = evidence_payload.get("summary") or {}
    deck_id = str(summary.get("deck_id") or "")
    commander = str(summary.get("commander") or "")
    rows = evidence_rows(evidence_payload)
    cards = unique_cards(rows)
    db_path, db_resolution = resolve_selected_db(evidence_payload, sqlite_db)
    deck_context = deck_context_by_name(db_path, deck_id, cards)
    staple_context = format_staples_by_name(db_path, cards)
    traces, seed_reports, trace_resolution = collect_existing_replay_traces(
        trace_generator_report=trace_generator_report,
        cards=cards,
        target_player=commander,
    )
    roots = scan_roots if scan_roots is not None else [REPORT_DIR]
    artifact_refs = scan_artifact_references(
        scan_roots=roots,
        cards=cards,
        max_occurrences_per_card=max_occurrences_per_card,
    )
    review_rows = []
    for row in rows:
        card = str(row.get("card_name") or "")
        key = normalize_name(card)
        review_rows.append(
            classify_card(
                plan_row=row,
                trace=traces.get(card, {}),
                deck_row=deck_context.get(key),
                staple=staple_context.get(key),
                artifact_refs=artifact_refs.get(card, []),
            )
        )
    status, next_gate = choose_status_and_next_gate(review_rows)
    usage_blocked_cards = list_cards(review_rows, "same_lane_stage_cut_usage_trace_blocks_value_safe")
    seen_cards = list_cards(review_rows, "same_lane_stage_cut_seen_without_usage_needs_negative_review")
    external_only_cards = list_cards(review_rows, "same_lane_stage_cut_external_reference_needs_internal_trace")
    needs_trace_cards = list_cards(review_rows, "same_lane_stage_cut_needs_trace_or_external_research")
    blockers = ["candidate_copy_closed_until_same_lane_stage_cuts_have_proof"]
    if usage_blocked_cards:
        blockers.append("used_stage_cuts_block_value_safe:" + ",".join(usage_blocked_cards))
    if seen_cards:
        blockers.append("seen_stage_cuts_need_negative_review:" + ",".join(seen_cards))
    if external_only_cards:
        blockers.append("external_reference_stage_cuts_need_internal_trace:" + ",".join(external_only_cards))
    if needs_trace_cards:
        blockers.append("stage_cuts_need_trace_or_external_research:" + ",".join(needs_trace_cards[:12]))
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_same_lane_stage_cut_trace_collector",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "battle_replay_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": False,
        "candidate_copy_allowed_now": False,
        "value_safe_reclassification_allowed_now": False,
        "input_artifacts": {
            "evidence_plan_report": rel(evidence_plan_report),
            "trace_generator_report": rel(trace_generator_report) if trace_generator_report else "",
            "selected_db": rel(db_path),
            "scan_roots": [rel(root) for root in roots],
        },
        "db_resolution": db_resolution,
        "trace_resolution": trace_resolution,
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "stage_cut_count": len(review_rows),
            "usage_blocked_count": len(usage_blocked_cards),
            "seen_without_usage_count": len(seen_cards),
            "external_reference_only_count": len(external_only_cards),
            "needs_trace_or_external_research_count": len(needs_trace_cards),
            "seed_report_count": len(seed_reports),
            "status_counts": group_counts(review_rows, "status"),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "candidate_copy_blockers": blockers,
        "review_rows": review_rows,
        "seed_reports": seed_reports[:20],
        "policy": {
            "trace_boundary": "This collector reuses existing traces and does not run a new battle.",
            "usage_boundary": "A same-lane stage cut used by the target deck blocks value-safe reclassification.",
            "external_boundary": "External/local corpus references do not override target-deck usage or absence of trace proof.",
            "promotion_boundary": "Candidate copy, battle gate, and promotion stay closed.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Same-Lane Stage Cut Trace Collector",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- stage_cut_count: `{summary['stage_cut_count']}`",
        f"- usage_blocked_count: `{summary['usage_blocked_count']}`",
        f"- seen_without_usage_count: `{summary['seen_without_usage_count']}`",
        f"- external_reference_only_count: `{summary['external_reference_only_count']}`",
        f"- needs_trace_or_external_research_count: `{summary['needs_trace_or_external_research_count']}`",
        f"- seed_report_count: `{summary['seed_report_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- value_safe_reclassification_allowed_now: `{str(payload['value_safe_reclassification_allowed_now']).lower()}`",
        f"- battle_replay_performed: `{str(payload['battle_replay_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Review Rows",
        "",
        "| Cut | Role | Status | Usage | Exposure | Decisions | Next Evidence |",
        "| --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["review_rows"][:40]:
        lines.append(
            "| `{card}` | `{role}` | `{status}` | {usage} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                role=row.get("target_cut_role"),
                status=row.get("status"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                next=row.get("next_evidence"),
            )
        )
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
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
    parser.add_argument("--evidence-plan-report", type=Path, default=DEFAULT_EVIDENCE_PLAN_REPORT)
    parser.add_argument("--trace-generator-report", type=Path, default=DEFAULT_TRACE_GENERATOR_REPORT)
    parser.add_argument("--db", type=Path)
    parser.add_argument("--scan-root", action="append", type=Path)
    parser.add_argument("--max-occurrences-per-card", type=int, default=8)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        evidence_plan_report=args.evidence_plan_report,
        trace_generator_report=args.trace_generator_report,
        sqlite_db=args.db,
        scan_roots=args.scan_root,
        max_occurrences_per_card=args.max_occurrences_per_card,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "summary": payload["summary"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
