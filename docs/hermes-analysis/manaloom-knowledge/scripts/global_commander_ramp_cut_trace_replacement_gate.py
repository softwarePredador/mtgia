#!/usr/bin/env python3
"""Run trace/replacement evidence for ramp cut follow-up gates.

This read-only gate consumes ``global_commander_ramp_cut_followup_router``. It
runs natural current-scope replay traces for trace-required ramp cuts, reviews
text trace candidates that were not structured proof, and mines local
Commander staple/oracle evidence for same-lane ramp replacements for
usage-blocked cuts. It does not copy decks, mutate databases, run promotion
battles, or authorize an add/cut pair.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import subprocess
from collections.abc import Callable, Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import global_commander_core_role_audit as core_roles
from global_commander_contextual_usage_trace_generator import (
    empty_card_summary,
    run_replay_seed,
    summarize_trace_files,
)
from global_commander_deck_contract_audit import REPO_ROOT, rel
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_ROUTER_REPORT = REPORT_DIR / "global_commander_ramp_cut_followup_router_20260706_current.json"
DEFAULT_RAMP_POLICY_REPORT = REPORT_DIR / "global_commander_ramp_axis_nonland_cut_policy_model_20260706_current.json"
DEFAULT_SCOUT_REPORT = REPORT_DIR / "global_commander_ramp_cut_usage_same_lane_proof_scout_20260706_current.json"
DEFAULT_BATTLE_REPLAY = SCRIPT_DIR / "battle_replay_v10_3.py"
DEFAULT_REPLAY_DIR = REPORT_DIR / "global_commander_ramp_cut_trace_replays_20260706_current"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_cut_trace_replacement_gate_20260706_current"
COMMANDER_IDENTITY = {"B", "R", "W"}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def artifact_rel(path: Path) -> str:
    candidate = path if path.is_absolute() else REPO_ROOT / path
    try:
        return rel(candidate)
    except ValueError:
        return str(path)


def resolve_path(value: object, *, default: Path) -> Path:
    raw = str(value or "").strip()
    if not raw:
        return default
    path = Path(raw)
    return path if path.is_absolute() else REPO_ROOT / path


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def as_list(value: object) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if str(item or "").strip()]


def merge_card_summary(target: dict[str, Any], source: Mapping[str, Any]) -> None:
    for key in ("usage_event_count", "exposure_event_count", "decision_trace_count", "reference_event_count"):
        target[key] = int(target.get(key) or 0) + int(source.get(key) or 0)
    events = target.setdefault("event_types", {})
    for event, count in (source.get("event_types") or {}).items():
        events[str(event)] = int(events.get(str(event)) or 0) + int(count or 0)
    for key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
        if target.get(key) is None and source.get(key) is not None:
            target[key] = source.get(key)


def trace_cards(router_payload: Mapping[str, Any]) -> list[str]:
    cards: list[str] = []
    for row in router_payload.get("trace_plan_rows") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            card = str(row["card_name"])
            if card not in cards:
                cards.append(card)
    return cards


def structured_review_cards(router_payload: Mapping[str, Any]) -> list[str]:
    cards: list[str] = []
    for row in router_payload.get("structured_review_rows") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            card = str(row["card_name"])
            if card not in cards:
                cards.append(card)
    return cards


def replacement_cut_rows(router_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in router_payload.get("replacement_search_rows") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows.append(dict(row))
    return rows


def deck_scope(router_payload: Mapping[str, Any]) -> tuple[str, str]:
    for key in ("trace_plan_rows", "structured_review_rows", "replacement_search_rows", "cut_followup_rows"):
        for row in router_payload.get(key) or []:
            if isinstance(row, Mapping):
                deck_id = str(row.get("deck_id") or "")
                commander = str(row.get("commander") or "")
                if deck_id or commander:
                    return deck_id, commander
    return "", ""


def db_path_from_policy(ramp_policy_payload: Mapping[str, Any]) -> Path:
    return resolve_path(ramp_policy_payload.get("source_db"), default=SCRIPT_DIR / "knowledge.db")


def classify_trace(card: str, summary: Mapping[str, Any]) -> dict[str, Any]:
    usage = int(summary.get("usage_event_count") or 0)
    exposure = int(summary.get("exposure_event_count") or 0)
    decisions = int(summary.get("decision_trace_count") or 0)
    if usage > 0:
        status = "ramp_cut_natural_trace_usage_observed_blocks_cut"
        next_gate = "find_different_ramp_cut_or_same_lane_replacement_before_candidate_copy"
    elif exposure > 0 or decisions > 0:
        status = "ramp_cut_natural_trace_seen_without_usage_needs_manual_negative_review"
        next_gate = "manual_negative_trace_review_for_ramp_cut_before_candidate_copy"
    else:
        status = "ramp_cut_natural_trace_no_target_exposure_needs_force_access"
        next_gate = "run_forced_access_trace_for_unexposed_ramp_cut"
    return {
        "card_name": card,
        "status": status,
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "event_types": summary.get("event_types") or {},
        "first_usage_event": summary.get("first_usage_event"),
        "first_exposure_event": summary.get("first_exposure_event"),
        "first_decision_trace": summary.get("first_decision_trace"),
        "next_gate": next_gate,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def run_natural_traces(
    *,
    deck_id: str,
    commander: str,
    db_path: Path,
    battle_replay: Path,
    replay_dir: Path,
    cards: list[str],
    seed_start: int,
    seed_count: int,
    timeout: int,
    real_opponent_seed: str,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    if not cards:
        return [], []
    aggregate = empty_card_summary(cards)
    seed_rows = []
    for seed in range(seed_start, seed_start + max(1, seed_count)):
        run = run_replay_seed(
            seed=seed,
            deck_id=deck_id,
            db_path=db_path,
            replay_dir=replay_dir,
            battle_replay=battle_replay,
            timeout=timeout,
            real_opponent_seed=real_opponent_seed,
            runner=runner,
        )
        status = "ramp_cut_natural_replay_generated" if run["returncode"] == 0 else "ramp_cut_natural_replay_failed"
        trace_summary = (
            summarize_trace_files(
                events_path=run["events_path"],
                decisions_path=run["decisions_path"],
                card_names=cards,
                target_player=commander,
            )
            if run["returncode"] == 0
            else {"event_count": 0, "decision_count": 0, "cards": empty_card_summary(cards)}
        )
        for card in cards:
            merge_card_summary(aggregate[card], trace_summary["cards"][card])
        seed_rows.append(
            {
                "seed": seed,
                "status": status,
                "returncode": run["returncode"],
                "replay_txt": artifact_rel(run["replay_txt"]),
                "events_path": artifact_rel(run["events_path"]),
                "decisions_path": artifact_rel(run["decisions_path"]),
                "provenance_path": artifact_rel(run["provenance_path"]),
                "event_count": trace_summary["event_count"],
                "decision_count": trace_summary["decision_count"],
            }
        )
    return [classify_trace(card, aggregate[card]) for card in cards], seed_rows


def scout_rows_by_card(scout_payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = {}
    for row in scout_payload.get("cut_evidence_rows") or []:
        if isinstance(row, Mapping) and row.get("card_name"):
            rows[normalize_name(str(row["card_name"]))] = dict(row)
    return rows


def review_structured_trace_cards(
    *,
    cards: list[str],
    scout_payload: Mapping[str, Any],
) -> list[dict[str, Any]]:
    by_card = scout_rows_by_card(scout_payload)
    rows: list[dict[str, Any]] = []
    for card in cards:
        scout_row = by_card.get(normalize_name(card), {})
        structured_count = int(scout_row.get("structured_evidence_count") or 0)
        text_usage_count = int(scout_row.get("text_usage_candidate_count") or 0)
        status = "ramp_cut_text_trace_candidate_requires_manual_structured_review"
        next_gate = "manual_structured_trace_review_for_ramp_cut_before_candidate_copy"
        if structured_count == 0 and text_usage_count == 0:
            status = "ramp_cut_text_trace_candidate_not_found_needs_current_scope_trace"
            next_gate = "generate_current_scope_trace_for_ramp_cut"
        rows.append(
            {
                "card_name": card,
                "status": status,
                "structured_evidence_count": structured_count,
                "text_usage_candidate_count": text_usage_count,
                "next_gate": next_gate,
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "mutation_allowed": False,
            }
        )
    return rows


def parse_color_identity(value: object) -> set[str]:
    raw = str(value or "").strip()
    if not raw:
        return set()
    if raw.startswith("["):
        try:
            loaded = json.loads(raw)
            return {str(item).strip().upper() for item in loaded if str(item).strip()}
        except json.JSONDecodeError:
            return set()
    return {part.strip().upper() for part in raw.replace("/", ",").split(",") if part.strip()}


def color_identity_allowed(value: object, commander_identity: set[str] = COMMANDER_IDENTITY) -> bool:
    return parse_color_identity(value).issubset(commander_identity)


def ramp_signals(row: Mapping[str, Any]) -> list[str]:
    roles, _source = core_roles.card_roles(row)
    text = normalize_name(f"{row.get('type_line') or ''} {row.get('oracle_text') or ''}")
    signals = []
    if "ramp" in roles:
        signals.append("ramp_role_text")
    if "treasure" in text:
        signals.append("treasure_ramp")
    if "add" in text and "mana" in text:
        signals.append("mana_production")
    if "costs less to cast" in text or "cost less to cast" in text:
        signals.append("cost_reduction")
    if "search your library" in text and "land" in text:
        signals.append("land_search_ramp")
    return sorted(set(signals))


def replacement_candidate_status(signals: list[str]) -> str:
    if "ramp_role_text" in signals and (
        "mana_production" in signals
        or "treasure_ramp" in signals
        or "cost_reduction" in signals
        or "land_search_ramp" in signals
    ):
        return "same_lane_ramp_candidate_needs_source_trace_review"
    if signals:
        return "adjacent_ramp_candidate_needs_explicit_same_lane_proof"
    return "not_same_lane_ramp_candidate"


def query_replacement_candidates(*, db_path: Path, deck_id: str, limit: int) -> list[dict[str, Any]]:
    sql = """
    SELECT
      fs.card_name,
      fs.color_identity AS staple_color_identity,
      fs.edhrec_rank,
      fs.is_banned,
      coc.color_identity_json AS oracle_color_identity,
      coc.type_line,
      coc.oracle_text
    FROM format_staples fs
    JOIN card_oracle_cache coc ON lower(coc.name) = lower(fs.card_name)
    WHERE lower(fs.format) LIKE '%commander%'
      AND coalesce(fs.is_banned, 0) = 0
      AND NOT EXISTS (
        SELECT 1 FROM deck_cards dc
        WHERE dc.deck_id = ? AND lower(dc.card_name) = lower(fs.card_name)
      )
    ORDER BY coalesce(fs.edhrec_rank, 999999), fs.card_name
    """
    candidates: list[dict[str, Any]] = []
    seen: set[str] = set()
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        for db_row in conn.execute(sql, (deck_id,)):
            card_name = str(db_row["card_name"] or "")
            key = normalize_name(card_name)
            if not key or key in seen:
                continue
            color_value = db_row["oracle_color_identity"] or db_row["staple_color_identity"]
            if not color_identity_allowed(color_value):
                continue
            row = {
                "type_line": str(db_row["type_line"] or ""),
                "oracle_text": str(db_row["oracle_text"] or ""),
                "functional_tag": "",
            }
            signals = ramp_signals(row)
            status = replacement_candidate_status(signals)
            if status == "not_same_lane_ramp_candidate":
                continue
            seen.add(key)
            candidates.append(
                {
                    "card_name": card_name,
                    "status": status,
                    "role_signals": signals,
                    "edhrec_rank": db_row["edhrec_rank"],
                    "color_identity": sorted(parse_color_identity(color_value)),
                    "type_line": db_row["type_line"],
                    "oracle_excerpt": " ".join(str(db_row["oracle_text"] or "").split())[:260],
                    "candidate_copy_allowed": False,
                    "battle_gate_allowed": False,
                    "mutation_allowed": False,
                }
            )
            if len(candidates) >= limit:
                break
    return candidates


def build_replacement_reviews(
    *,
    replacement_rows: list[Mapping[str, Any]],
    candidates: list[Mapping[str, Any]],
) -> list[dict[str, Any]]:
    reviews = []
    strong = [row for row in candidates if row.get("status") == "same_lane_ramp_candidate_needs_source_trace_review"]
    adjacent = [row for row in candidates if row.get("status") == "adjacent_ramp_candidate_needs_explicit_same_lane_proof"]
    for row in replacement_rows:
        cut = str(row.get("card_name") or "")
        if strong:
            status = "ramp_replacement_candidates_found_needs_source_trace_review"
            next_gate = "review_ramp_replacement_candidates_before_candidate_copy"
        elif adjacent:
            status = "adjacent_ramp_candidates_found_needs_explicit_same_lane_proof"
            next_gate = "prove_adjacent_ramp_candidate_is_same_lane_before_candidate_copy"
        else:
            status = "no_local_ramp_replacement_candidate_found"
            next_gate = "expand_external_ramp_replacement_source_lanes"
        reviews.append(
            {
                "cut_card": cut,
                "required_replacement_roles": as_list(row.get("required_replacement_roles")),
                "status": status,
                "strong_candidate_count": len(strong),
                "adjacent_candidate_count": len(adjacent),
                "candidate_sample": list(strong[:5] or adjacent[:5]),
                "next_gate": next_gate,
                "candidate_copy_allowed": False,
                "battle_gate_allowed": False,
                "mutation_allowed": False,
            }
        )
    return reviews


def choose_status_and_gate(
    *,
    trace_reviews: list[Mapping[str, Any]],
    structured_reviews: list[Mapping[str, Any]],
    replacement_reviews: list[Mapping[str, Any]],
) -> tuple[str, str]:
    trace_no_exposure = [
        row["card_name"]
        for row in trace_reviews
        if row["status"] == "ramp_cut_natural_trace_no_target_exposure_needs_force_access"
    ]
    trace_usage = [
        row["card_name"]
        for row in trace_reviews
        if row["status"] == "ramp_cut_natural_trace_usage_observed_blocks_cut"
    ]
    trace_manual = [
        row["card_name"]
        for row in trace_reviews
        if row["status"] == "ramp_cut_natural_trace_seen_without_usage_needs_manual_negative_review"
    ]
    structured_manual = [
        row["card_name"]
        for row in structured_reviews
        if row["status"] == "ramp_cut_text_trace_candidate_requires_manual_structured_review"
    ]
    replacement_ready = [
        row["cut_card"]
        for row in replacement_reviews
        if row["status"] == "ramp_replacement_candidates_found_needs_source_trace_review"
    ]
    if trace_no_exposure:
        return ("ramp_cut_trace_replacement_gate_needs_forced_access", "run_forced_access_trace_for_unexposed_ramp_cut")
    if trace_usage or trace_manual or structured_manual:
        return ("ramp_cut_trace_replacement_gate_needs_trace_review", "review_ramp_cut_trace_results_before_candidate_copy")
    if replacement_ready:
        return (
            "ramp_cut_trace_replacement_gate_found_replacement_candidates",
            "review_ramp_replacement_candidates_before_candidate_copy",
        )
    return ("ramp_cut_trace_replacement_gate_needs_more_external_source", "expand_external_ramp_replacement_source_lanes")


def build_report(
    *,
    router_report: Path,
    ramp_policy_report: Path,
    scout_report: Path,
    battle_replay: Path = DEFAULT_BATTLE_REPLAY,
    replay_dir: Path = DEFAULT_REPLAY_DIR,
    seed_start: int = 90,
    seed_count: int = 3,
    timeout: int = 300,
    real_opponent_seed: str = "20260706",
    replacement_limit: int = 12,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, Any]:
    router_payload = load_json(router_report)
    ramp_payload = load_json(ramp_policy_report)
    scout_payload = load_json(scout_report)
    db_path = db_path_from_policy(ramp_payload)
    deck_id, commander = deck_scope(router_payload)
    cards = trace_cards(router_payload)
    trace_reviews, seed_rows = run_natural_traces(
        deck_id=deck_id,
        commander=commander,
        db_path=db_path,
        battle_replay=battle_replay,
        replay_dir=replay_dir,
        cards=cards,
        seed_start=seed_start,
        seed_count=seed_count,
        timeout=timeout,
        real_opponent_seed=real_opponent_seed,
        runner=runner,
    )
    structured_reviews = review_structured_trace_cards(
        cards=structured_review_cards(router_payload),
        scout_payload=scout_payload,
    )
    candidates = query_replacement_candidates(db_path=db_path, deck_id=deck_id, limit=max(1, replacement_limit))
    replacement_reviews = build_replacement_reviews(
        replacement_rows=replacement_cut_rows(router_payload),
        candidates=candidates,
    )
    generated_replays = sum(1 for row in seed_rows if row.get("status") == "ramp_cut_natural_replay_generated")
    trace_no_exposure = [row["card_name"] for row in trace_reviews if row["status"] == "ramp_cut_natural_trace_no_target_exposure_needs_force_access"]
    trace_usage = [row["card_name"] for row in trace_reviews if row["status"] == "ramp_cut_natural_trace_usage_observed_blocks_cut"]
    trace_manual = [row["card_name"] for row in trace_reviews if row["status"] == "ramp_cut_natural_trace_seen_without_usage_needs_manual_negative_review"]
    structured_manual = [row["card_name"] for row in structured_reviews if row["status"] == "ramp_cut_text_trace_candidate_requires_manual_structured_review"]
    replacement_ready = [row["cut_card"] for row in replacement_reviews if row["status"] == "ramp_replacement_candidates_found_needs_source_trace_review"]
    blockers = []
    if trace_no_exposure:
        blockers.append("natural_trace_no_target_exposure_needs_force_access:" + ",".join(trace_no_exposure))
    if trace_usage:
        blockers.append("natural_trace_usage_observed_blocks_cut:" + ",".join(trace_usage))
    if trace_manual:
        blockers.append("natural_trace_manual_negative_review_required:" + ",".join(trace_manual))
    if structured_manual:
        blockers.append("structured_trace_manual_review_required:" + ",".join(structured_manual))
    if replacement_reviews:
        blockers.append("replacement_candidates_require_source_trace_review")
    blockers.append("candidate_copy_closed_after_ramp_trace_replacement_gate")
    status, next_gate = choose_status_and_gate(
        trace_reviews=trace_reviews,
        structured_reviews=structured_reviews,
        replacement_reviews=replacement_reviews,
    )
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_cut_trace_replacement_gate",
        "deck_id": deck_id,
        "commander": commander,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_replay_performed": bool(seed_rows),
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "router_report": artifact_rel(router_report),
            "ramp_policy_report": artifact_rel(ramp_policy_report),
            "scout_report": artifact_rel(scout_report),
            "source_db": artifact_rel(db_path),
            "battle_replay": artifact_rel(battle_replay),
            "replay_dir": artifact_rel(replay_dir),
        },
        "summary": {
            "trace_card_count": len(cards),
            "structured_review_card_count": len(structured_reviews),
            "seed_count": max(1, seed_count) if cards else 0,
            "generated_replay_count": generated_replays,
            "trace_no_exposure_count": len(trace_no_exposure),
            "trace_usage_observed_count": len(trace_usage),
            "trace_manual_review_count": len(trace_manual),
            "structured_manual_review_count": len(structured_manual),
            "replacement_review_count": len(replacement_reviews),
            "replacement_candidate_count": len(candidates),
            "strong_replacement_candidate_count": sum(
                1 for row in candidates if row.get("status") == "same_lane_ramp_candidate_needs_source_trace_review"
            ),
            "adjacent_replacement_candidate_count": sum(
                1 for row in candidates if row.get("status") == "adjacent_ramp_candidate_needs_explicit_same_lane_proof"
            ),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "trace_review_rows": trace_reviews,
        "structured_review_rows": structured_reviews,
        "replacement_reviews": replacement_reviews,
        "replacement_candidate_rows": candidates,
        "seed_rows": seed_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "natural_trace_boundary": "Natural replay trace is evidence collection only, not a promotion battle gate.",
            "structured_trace_boundary": "Text trace candidates require manual structured review before negative clearance.",
            "replacement_boundary": "Local staple/oracle ramp candidates are review seeds, not explicit same-lane proof by themselves.",
            "same_lane_boundary": "A replacement for a used ramp cut still needs source and trace review before candidate copy.",
            "mutation_boundary": "This gate reads SQLite and writes report artifacts only.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Cut Trace Replacement Gate",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{payload['commander']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- trace_card_count: `{summary['trace_card_count']}`",
        f"- structured_review_card_count: `{summary['structured_review_card_count']}`",
        f"- seed_count: `{summary['seed_count']}`",
        f"- generated_replay_count: `{summary['generated_replay_count']}`",
        f"- trace_no_exposure_count: `{summary['trace_no_exposure_count']}`",
        f"- trace_usage_observed_count: `{summary['trace_usage_observed_count']}`",
        f"- trace_manual_review_count: `{summary['trace_manual_review_count']}`",
        f"- structured_manual_review_count: `{summary['structured_manual_review_count']}`",
        f"- replacement_candidate_count: `{summary['replacement_candidate_count']}`",
        f"- strong_replacement_candidate_count: `{summary['strong_replacement_candidate_count']}`",
        f"- adjacent_replacement_candidate_count: `{summary['adjacent_replacement_candidate_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_replay_performed: `{str(payload['battle_replay_performed']).lower()}`",
        f"- battle_gate_performed: `{str(payload['battle_gate_performed']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Trace Review",
        "",
        "| Card | Status | Usage | Exposure | Decisions | Next Gate |",
        "| --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in payload["trace_review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {usage} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                next=row.get("next_gate"),
            )
        )
    if not payload["trace_review_rows"]:
        lines.append("| none |  |  |  |  |  |")
    lines.extend(["", "## Structured Trace Review", ""])
    lines.extend(["| Card | Status | Structured Evidence | Text Usage Candidates | Next Gate |", "| --- | --- | ---: | ---: | --- |"])
    for row in payload["structured_review_rows"]:
        lines.append(
            "| `{card}` | `{status}` | {structured} | {text_usage} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                structured=row.get("structured_evidence_count"),
                text_usage=row.get("text_usage_candidate_count"),
                next=row.get("next_gate"),
            )
        )
    if not payload["structured_review_rows"]:
        lines.append("| none |  |  |  |  |")
    lines.extend(["", "## Replacement Reviews", ""])
    lines.extend(["| Cut | Status | Strong | Adjacent | Next Gate |", "| --- | --- | ---: | ---: | --- |"])
    for row in payload["replacement_reviews"]:
        lines.append(
            "| `{cut}` | `{status}` | {strong} | {adjacent} | `{next}` |".format(
                cut=row.get("cut_card"),
                status=row.get("status"),
                strong=row.get("strong_candidate_count"),
                adjacent=row.get("adjacent_candidate_count"),
                next=row.get("next_gate"),
            )
        )
    if not payload["replacement_reviews"]:
        lines.append("| none |  |  |  |  |")
    lines.extend(["", "## Replacement Candidate Sample", ""])
    lines.extend(["| Card | Status | Signals | Rank | Type |", "| --- | --- | --- | ---: | --- |"])
    for row in payload["replacement_candidate_rows"][:12]:
        lines.append(
            "| `{card}` | `{status}` | `{signals}` | {rank} | `{type_line}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                signals=",".join(row.get("role_signals") or []),
                rank=row.get("edhrec_rank") if row.get("edhrec_rank") is not None else "",
                type_line=str(row.get("type_line") or "").replace("|", "/"),
            )
        )
    if not payload["replacement_candidate_rows"]:
        lines.append("| none |  |  |  |  |")
    lines.extend(["", "## Seed Reports", ""])
    if payload["seed_rows"]:
        for row in payload["seed_rows"]:
            lines.append(
                f"- seed `{row['seed']}`: `{row['status']}`, events `{row['event_count']}`, decisions `{row['decision_count']}`"
            )
    else:
        lines.append("- none")
    lines.extend(["", "## Blockers", ""])
    for blocker in payload["candidate_copy_blockers"]:
        lines.append(f"- `{blocker}`")
    lines.extend(["", "## Policy", ""])
    for key, value in payload["policy"].items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--router-report", type=Path, default=DEFAULT_ROUTER_REPORT)
    parser.add_argument("--ramp-policy-report", type=Path, default=DEFAULT_RAMP_POLICY_REPORT)
    parser.add_argument("--scout-report", type=Path, default=DEFAULT_SCOUT_REPORT)
    parser.add_argument("--battle-replay", type=Path, default=DEFAULT_BATTLE_REPLAY)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--seed-start", type=int, default=90)
    parser.add_argument("--seed-count", type=int, default=3)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--real-opponent-seed", default="20260706")
    parser.add_argument("--replacement-limit", type=int, default=12)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        router_report=args.router_report,
        ramp_policy_report=args.ramp_policy_report,
        scout_report=args.scout_report,
        battle_replay=args.battle_replay,
        replay_dir=args.replay_dir,
        seed_start=args.seed_start,
        seed_count=args.seed_count,
        timeout=args.timeout,
        real_opponent_seed=args.real_opponent_seed,
        replacement_limit=args.replacement_limit,
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
