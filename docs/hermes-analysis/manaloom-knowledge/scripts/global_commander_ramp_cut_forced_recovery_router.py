#!/usr/bin/env python3
"""Route ramp recovery after forced access blocks unexposed ramp cuts.

This read-only gate consumes the natural ramp trace/replacement report plus the
forced-access report. It decides whether current local replacement seeds are
exact same-lane replacements and whether another current-deck ramp cut source
needs trace. It does not authorize cuts, candidate copies, battles, mutations,
or promotions.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_contextual_usage_trace_generator import empty_card_summary, summarize_trace_files
from global_commander_deck_contract_audit import REPO_ROOT, rel
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_RAMP_TRACE_REPORT = REPORT_DIR / "global_commander_ramp_cut_trace_replacement_gate_20260706_current.json"
DEFAULT_FORCED_ACCESS_REPORT = REPORT_DIR / "global_commander_ramp_cut_forced_access_trace_generator_20260706_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_ramp_cut_forced_recovery_router_20260706_current"

NATURAL_USAGE_BLOCKED = "ramp_cut_natural_trace_usage_observed_blocks_cut"
FORCED_USAGE_BLOCKED = "ramp_cut_forced_access_usage_observed_blocks_cut"
STRUCTURED_REVIEW_REQUIRED = "ramp_cut_text_trace_candidate_requires_manual_structured_review"
STRONG_REPLACEMENT_STATUS = "same_lane_ramp_candidate_needs_source_trace_review"


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


def card_signatures(type_line: object, oracle_text: object) -> list[str]:
    type_text = normalize_name(str(type_line or ""))
    oracle = normalize_name(str(oracle_text or ""))
    signatures: set[str] = set()
    if "artifact" in type_text and ("add one mana" in oracle or "{t}: add" in oracle):
        signatures.add("permanent_mana_rock")
    if "artifact" in type_text and "commander's color identity" in oracle:
        signatures.add("commander_color_mana_rock")
    if "artifact" in type_text and "opponent controls could produce" in oracle:
        signatures.add("opponent_land_color_mana_rock")
    if "artifact" in type_text and ("add {c}{c}" in oracle or "add {c}{c}{c}" in oracle):
        signatures.add("colorless_big_mana_rock")
    if ("instant" in type_text or "sorcery" in type_text) and "add {" in oracle:
        signatures.add("burst_ritual")
    if "additional cost" in oracle and "sacrifice" in oracle and "add {" in oracle:
        signatures.add("sacrifice_ritual")
    if "whenever you cast a spell" in oracle and "add {" in oracle:
        signatures.add("spell_trigger_mana_engine")
    if "treasure token" in oracle:
        signatures.add("treasure_ramp")
    if "draw" in oracle or "exile the top" in oracle or "play that card" in oracle:
        if "treasure_ramp" in signatures:
            signatures.add("treasure_card_advantage_engine")
    if "search your library" in oracle and ("basic plains" in oracle or "land card" in oracle):
        signatures.add("land_access_ramp")
    if "costs less to cast" in oracle or "cost less to cast" in oracle:
        signatures.add("cost_reduction_ramp")
    return sorted(signatures)


def as_int(value: object) -> int:
    try:
        return int(value or 0)
    except Exception:
        return 0


def db_card_lookup(db_path: Path, names: list[str]) -> dict[str, dict[str, Any]]:
    if not names:
        return {}
    placeholders = ",".join("?" for _ in names)
    sql = f"""
    SELECT
      coc.name AS card_name,
      coc.type_line,
      coc.oracle_text,
      coc.cmc,
      fs.edhrec_rank
    FROM card_oracle_cache coc
    LEFT JOIN format_staples fs
      ON lower(fs.card_name) = lower(coc.name)
     AND lower(fs.format) LIKE '%commander%'
    WHERE lower(coc.name) IN ({placeholders})
    """
    lookup: dict[str, dict[str, Any]] = {}
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        for row in conn.execute(sql, [name.lower() for name in names]):
            card_name = str(row["card_name"] or "")
            lookup[normalize_name(card_name)] = {
                "card_name": card_name,
                "type_line": row["type_line"],
                "oracle_text": row["oracle_text"],
                "cmc": row["cmc"],
                "edhrec_rank": row["edhrec_rank"],
                "signatures": card_signatures(row["type_line"], row["oracle_text"]),
            }
    return lookup


def blocked_cut_rows(ramp_payload: Mapping[str, Any], forced_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in ramp_payload.get("trace_review_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") != NATURAL_USAGE_BLOCKED:
            continue
        card = str(row.get("card_name") or "")
        key = normalize_name(card)
        if key and key not in seen:
            seen.add(key)
            rows.append(
                {
                    "card_name": card,
                    "status": "blocked_natural_usage_observed",
                    "usage_event_count": as_int(row.get("usage_event_count")),
                    "block_reason": "natural_current_scope_usage_observed",
                }
            )
    for row in forced_payload.get("review_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") != FORCED_USAGE_BLOCKED:
            continue
        card = str(row.get("card_name") or "")
        key = normalize_name(card)
        if key and key not in seen:
            seen.add(key)
            rows.append(
                {
                    "card_name": card,
                    "status": "blocked_forced_usage_observed",
                    "usage_event_count": as_int(row.get("usage_event_count")),
                    "block_reason": "forced_access_usage_observed",
                }
            )
    for row in ramp_payload.get("structured_review_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") != STRUCTURED_REVIEW_REQUIRED:
            continue
        card = str(row.get("card_name") or "")
        key = normalize_name(card)
        if key and key not in seen:
            seen.add(key)
            rows.append(
                {
                    "card_name": card,
                    "status": "blocked_structured_review_required",
                    "usage_event_count": 0,
                    "block_reason": "structured_trace_review_required",
                }
            )
    for row in ramp_payload.get("replacement_reviews") or []:
        if not isinstance(row, Mapping) or not row.get("cut_card"):
            continue
        card = str(row.get("cut_card") or "")
        key = normalize_name(card)
        if key and key not in seen:
            seen.add(key)
            rows.append(
                {
                    "card_name": card,
                    "status": "blocked_prior_usage_requires_replacement",
                    "usage_event_count": 0,
                    "block_reason": "prior_usage_scout_requires_same_lane_replacement",
                }
            )
    rows.sort(key=lambda row: str(row.get("card_name") or ""))
    return rows


def replacement_candidates(ramp_payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    rows = []
    for row in ramp_payload.get("replacement_candidate_rows") or []:
        if not isinstance(row, Mapping) or row.get("status") != STRONG_REPLACEMENT_STATUS:
            continue
        rows.append(dict(row))
    rows.sort(key=lambda row: (as_int(row.get("edhrec_rank")) or 999999, str(row.get("card_name") or "")))
    return rows


def replacement_exactness_rows(
    *,
    blocked_rows: list[Mapping[str, Any]],
    candidate_rows: list[Mapping[str, Any]],
    db_path: Path,
) -> list[dict[str, Any]]:
    cut_lookup = db_card_lookup(db_path, [str(row.get("card_name") or "") for row in blocked_rows])
    candidate_lookup = db_card_lookup(db_path, [str(row.get("card_name") or "") for row in candidate_rows])
    reviews: list[dict[str, Any]] = []
    for cut in blocked_rows:
        cut_name = str(cut.get("card_name") or "")
        cut_info = cut_lookup.get(normalize_name(cut_name), {})
        cut_signatures = set(cut_info.get("signatures") or [])
        cut_rank = as_int(cut_info.get("edhrec_rank"))
        for candidate in candidate_rows:
            candidate_name = str(candidate.get("card_name") or "")
            candidate_info = candidate_lookup.get(normalize_name(candidate_name), {})
            candidate_signatures = set(candidate_info.get("signatures") or [])
            overlap = sorted(cut_signatures & candidate_signatures)
            candidate_rank = as_int(candidate_info.get("edhrec_rank") or candidate.get("edhrec_rank"))
            if not overlap:
                status = "replacement_blocked_not_exact_same_lane"
                reason = "replacement_signature_does_not_cover_cut_signature"
            elif cut_rank and candidate_rank and candidate_rank > cut_rank:
                status = "replacement_blocked_lower_staple_rank_than_used_cut"
                reason = "candidate_is_lower_rank_than_used_cut"
            elif "colorless_big_mana_rock" in cut_signatures and "colorless_big_mana_rock" not in candidate_signatures:
                status = "replacement_blocked_not_big_mana_rock"
                reason = "candidate_does_not_cover_colorless_big_mana_role"
            else:
                status = "replacement_needs_source_trace_before_candidate_copy"
                reason = "same_lane_signature_overlap_needs_source_trace"
            reviews.append(
                {
                    "cut_card": cut_name,
                    "replacement_card": candidate_name,
                    "status": status,
                    "reason": reason,
                    "cut_signatures": sorted(cut_signatures),
                    "replacement_signatures": sorted(candidate_signatures),
                    "overlap_signatures": overlap,
                    "cut_edhrec_rank": cut_rank or None,
                    "replacement_edhrec_rank": candidate_rank or None,
                    "candidate_copy_allowed": False,
                    "battle_gate_allowed": False,
                    "mutation_allowed": False,
                }
            )
    return reviews


def deck_ramp_rows(db_path: Path, deck_id: str) -> list[dict[str, Any]]:
    sql = """
    SELECT
      dc.card_name,
      max(dc.is_commander) AS is_commander,
      coalesce(coc.type_line, dc.type_line) AS type_line,
      coalesce(coc.oracle_text, dc.oracle_text) AS oracle_text,
      coc.cmc,
      fs.edhrec_rank
    FROM deck_cards dc
    LEFT JOIN card_oracle_cache coc ON lower(coc.name) = lower(dc.card_name)
    LEFT JOIN format_staples fs
      ON lower(fs.card_name) = lower(dc.card_name)
     AND lower(fs.format) LIKE '%commander%'
    WHERE dc.deck_id = ?
    GROUP BY lower(dc.card_name)
    ORDER BY dc.card_name
    """
    rows: list[dict[str, Any]] = []
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        for row in conn.execute(sql, (deck_id,)):
            signatures = card_signatures(row["type_line"], row["oracle_text"])
            if not signatures:
                continue
            rows.append(
                {
                    "card_name": row["card_name"],
                    "is_commander": bool(row["is_commander"]),
                    "type_line": row["type_line"],
                    "oracle_excerpt": " ".join(str(row["oracle_text"] or "").split())[:260],
                    "cmc": row["cmc"],
                    "edhrec_rank": row["edhrec_rank"],
                    "signatures": signatures,
                }
            )
    return rows


def summarize_existing_natural_trace(ramp_payload: Mapping[str, Any], card_names: list[str], commander: str) -> dict[str, dict[str, Any]]:
    aggregate = empty_card_summary(card_names)
    for seed in ramp_payload.get("seed_rows") or []:
        if not isinstance(seed, Mapping) or str(seed.get("status") or "") != "ramp_cut_natural_replay_generated":
            continue
        events_path = resolve_path(seed.get("events_path"), default=Path(""))
        decisions_path = resolve_path(seed.get("decisions_path"), default=Path(""))
        if not events_path.exists() or not decisions_path.exists():
            continue
        trace = summarize_trace_files(
            events_path=events_path,
            decisions_path=decisions_path,
            card_names=card_names,
            target_player=commander,
        )
        for card in card_names:
            for key in ("usage_event_count", "exposure_event_count", "decision_trace_count", "reference_event_count"):
                aggregate[card][key] = int(aggregate[card].get(key) or 0) + int(trace["cards"][card].get(key) or 0)
            events = aggregate[card].setdefault("event_types", {})
            for event, count in (trace["cards"][card].get("event_types") or {}).items():
                events[str(event)] = int(events.get(str(event)) or 0) + int(count or 0)
            for key in ("first_usage_event", "first_exposure_event", "first_decision_trace"):
                if aggregate[card].get(key) is None and trace["cards"][card].get(key) is not None:
                    aggregate[card][key] = trace["cards"][card].get(key)
    return aggregate


def classify_alternative_cut(row: Mapping[str, Any], trace: Mapping[str, Any], blocked_keys: set[str]) -> dict[str, Any]:
    name = str(row.get("card_name") or "")
    key = normalize_name(name)
    type_line = normalize_name(str(row.get("type_line") or ""))
    signatures = set(row.get("signatures") or [])
    usage = as_int(trace.get("usage_event_count"))
    exposure = as_int(trace.get("exposure_event_count"))
    decisions = as_int(trace.get("decision_trace_count"))
    rank = as_int(row.get("edhrec_rank"))
    if key in blocked_keys:
        status = "alternative_cut_blocked_already_current_ramp_blocker"
        reason = "already_blocked_by_natural_forced_or_structured_trace"
        next_gate = "find_different_ramp_cut"
    elif "land" in type_line:
        status = "alternative_cut_blocked_land_mana_base_gate_required"
        reason = "land_cut_requires_mana_base_profile_not_ramp_axis_shortcut"
        next_gate = "run_mana_base_profile_before_land_cut"
    elif bool(row.get("is_commander")):
        status = "alternative_cut_blocked_commander_card"
        reason = "commander_card_not_cut_candidate"
        next_gate = "find_different_ramp_cut"
    elif "legendary creature" in type_line and "treasure_ramp" in signatures:
        status = "alternative_cut_blocked_legendary_plan_engine"
        reason = "legendary_treasure_piece_carries_commander_plan_value"
        next_gate = "find_different_ramp_cut"
    elif "land_access_ramp" in signatures:
        status = "alternative_cut_blocked_land_access_engine_needs_profile_review"
        reason = "land_access_ramp_needs_mana_base_or_engine_profile_review"
        next_gate = "run_mana_base_or_engine_profile_review_before_cut"
    elif rank and rank <= 150:
        status = "alternative_cut_blocked_premium_ramp_staple"
        reason = "premium_commander_ramp_or_value_staple_rank"
        next_gate = "find_different_ramp_cut"
    elif "treasure_card_advantage_engine" in signatures:
        status = "alternative_cut_blocked_card_advantage_engine"
        reason = "treasure_source_also_carries_card_advantage_or_commander_plan_value"
        next_gate = "find_different_ramp_cut"
    elif usage > 0:
        status = "alternative_cut_current_trace_usage_observed_blocks_cut"
        reason = "existing_natural_trace_usage_observed"
        next_gate = "find_different_ramp_cut"
    elif exposure > 0 or decisions > 0:
        status = "alternative_cut_seen_without_usage_needs_manual_negative_review"
        reason = "existing_natural_trace_seen_without_usage"
        next_gate = "manual_negative_trace_review_for_alternative_ramp_cut"
    else:
        status = "alternative_cut_needs_current_scope_trace"
        reason = "no_current_scope_target_trace_for_alternative_ramp_cut"
        next_gate = "trace_alternative_ramp_cut_candidates_before_candidate_copy"
    return {
        "card_name": name,
        "status": status,
        "reason": reason,
        "signatures": sorted(signatures),
        "edhrec_rank": rank or None,
        "usage_event_count": usage,
        "exposure_event_count": exposure,
        "decision_trace_count": decisions,
        "next_gate": next_gate,
        "candidate_copy_allowed": False,
        "battle_gate_allowed": False,
        "mutation_allowed": False,
    }


def choose_status(
    *,
    exact_ready_count: int,
    alternative_trace_required_count: int,
    manual_review_count: int,
) -> tuple[str, str]:
    if exact_ready_count:
        return (
            "ramp_cut_forced_recovery_found_exact_replacement_trace_route",
            "source_trace_exact_ramp_replacement_before_candidate_copy",
        )
    if alternative_trace_required_count:
        return (
            "ramp_cut_forced_recovery_routes_alternative_cut_trace",
            "trace_alternative_ramp_cut_candidates_before_candidate_copy",
        )
    if manual_review_count:
        return (
            "ramp_cut_forced_recovery_needs_manual_negative_review",
            "manual_negative_trace_review_for_alternative_ramp_cut",
        )
    return (
        "ramp_cut_forced_recovery_exhausts_current_ramp_cut_lane",
        "expand_external_ramp_cut_or_pivot_role_axis",
    )


def build_report(
    *,
    ramp_trace_report: Path,
    forced_access_report: Path,
) -> dict[str, Any]:
    ramp_payload = load_json(ramp_trace_report)
    forced_payload = load_json(forced_access_report)
    artifacts = ramp_payload.get("input_artifacts") or {}
    db_path = resolve_path(artifacts.get("source_db"), default=SCRIPT_DIR / "knowledge.db")
    deck_id = str(ramp_payload.get("deck_id") or forced_payload.get("deck_id") or "")
    commander = str(ramp_payload.get("commander") or forced_payload.get("commander") or "")
    blocked_rows = blocked_cut_rows(ramp_payload, forced_payload)
    replacement_rows = replacement_candidates(ramp_payload)
    exactness_rows = replacement_exactness_rows(
        blocked_rows=blocked_rows,
        candidate_rows=replacement_rows,
        db_path=db_path,
    )
    blocked_keys = {normalize_name(str(row.get("card_name") or "")) for row in blocked_rows}
    deck_rows = deck_ramp_rows(db_path, deck_id)
    trace_summary = summarize_existing_natural_trace(
        ramp_payload,
        [str(row["card_name"]) for row in deck_rows],
        commander,
    )
    alternative_rows = [
        classify_alternative_cut(row, trace_summary.get(str(row["card_name"]), {}), blocked_keys)
        for row in deck_rows
    ]
    exact_ready = [row for row in exactness_rows if row["status"] == "replacement_needs_source_trace_before_candidate_copy"]
    alternative_trace_required = [row for row in alternative_rows if row["status"] == "alternative_cut_needs_current_scope_trace"]
    alternative_manual = [
        row
        for row in alternative_rows
        if row["status"] == "alternative_cut_seen_without_usage_needs_manual_negative_review"
    ]
    status, next_gate = choose_status(
        exact_ready_count=len(exact_ready),
        alternative_trace_required_count=len(alternative_trace_required),
        manual_review_count=len(alternative_manual),
    )
    blockers = []
    if not exact_ready:
        blockers.append("no_exact_same_lane_ramp_replacement_ready")
    if blocked_rows:
        blockers.append("current_ramp_cut_blocked_count:" + str(len(blocked_rows)))
    if alternative_trace_required:
        blockers.append("alternative_ramp_cut_requires_trace:" + ",".join(row["card_name"] for row in alternative_trace_required[:12]))
    blockers.append("candidate_copy_closed_after_ramp_forced_recovery_router")
    return {
        "generated_at": utc_now(),
        "status": status,
        "artifact_type": "global_commander_ramp_cut_forced_recovery_router",
        "deck_id": deck_id,
        "commander": commander,
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "battle_gate_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "candidate_copy_allowed_now": False,
        "battle_gate_allowed_now": False,
        "promotion_allowed": False,
        "input_artifacts": {
            "ramp_trace_report": artifact_rel(ramp_trace_report),
            "forced_access_report": artifact_rel(forced_access_report),
            "source_db": artifact_rel(db_path),
        },
        "summary": {
            "blocked_ramp_cut_count": len(blocked_rows),
            "replacement_candidate_count": len(replacement_rows),
            "replacement_exact_ready_count": len(exact_ready),
            "replacement_blocked_count": len(exactness_rows) - len(exact_ready),
            "alternative_ramp_card_count": len(alternative_rows),
            "alternative_trace_required_count": len(alternative_trace_required),
            "alternative_manual_review_count": len(alternative_manual),
            "candidate_copy_blocker_count": len(blockers),
            "next_gate": next_gate,
        },
        "blocked_cut_rows": blocked_rows,
        "replacement_exactness_rows": exactness_rows,
        "alternative_cut_rows": alternative_rows,
        "candidate_copy_blockers": blockers,
        "policy": {
            "forced_access_boundary": "Forced access usage blocks a ramp cut; it does not authorize a swap.",
            "exact_replacement_boundary": "A replacement must cover the cut's exact ramp signature and cannot downgrade a premium used staple without further source proof.",
            "alternative_cut_boundary": "Alternative ramp cuts are trace targets only until card-level usage and negative-review evidence exists.",
            "mutation_boundary": "This router reads reports and SQLite only; it does not mutate deck or database state.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Ramp Cut Forced Recovery Router",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{payload['commander']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- blocked_ramp_cut_count: `{summary['blocked_ramp_cut_count']}`",
        f"- replacement_candidate_count: `{summary['replacement_candidate_count']}`",
        f"- replacement_exact_ready_count: `{summary['replacement_exact_ready_count']}`",
        f"- replacement_blocked_count: `{summary['replacement_blocked_count']}`",
        f"- alternative_ramp_card_count: `{summary['alternative_ramp_card_count']}`",
        f"- alternative_trace_required_count: `{summary['alternative_trace_required_count']}`",
        f"- alternative_manual_review_count: `{summary['alternative_manual_review_count']}`",
        f"- candidate_copy_allowed_now: `{str(payload['candidate_copy_allowed_now']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Blocked Cuts",
        "",
        "| Card | Status | Usage | Reason |",
        "| --- | --- | ---: | --- |",
    ]
    for row in payload["blocked_cut_rows"]:
        lines.append(
            f"| `{row['card_name']}` | `{row['status']}` | {row['usage_event_count']} | `{row['block_reason']}` |"
        )
    lines.extend(["", "## Replacement Exactness", ""])
    lines.extend(["| Cut | Replacement | Status | Overlap | Reason |", "| --- | --- | --- | --- | --- |"])
    for row in payload["replacement_exactness_rows"]:
        lines.append(
            "| `{cut}` | `{replacement}` | `{status}` | `{overlap}` | `{reason}` |".format(
                cut=row.get("cut_card"),
                replacement=row.get("replacement_card"),
                status=row.get("status"),
                overlap=",".join(row.get("overlap_signatures") or []),
                reason=row.get("reason"),
            )
        )
    if not payload["replacement_exactness_rows"]:
        lines.append("| none |  |  |  |  |")
    lines.extend(["", "## Alternative Ramp Cuts", ""])
    lines.extend(["| Card | Status | Signatures | Usage | Exposure | Decisions | Next Gate |", "| --- | --- | --- | ---: | ---: | ---: | --- |"])
    for row in payload["alternative_cut_rows"]:
        lines.append(
            "| `{card}` | `{status}` | `{signatures}` | {usage} | {exposure} | {decisions} | `{next}` |".format(
                card=row.get("card_name"),
                status=row.get("status"),
                signatures=",".join(row.get("signatures") or []),
                usage=row.get("usage_event_count"),
                exposure=row.get("exposure_event_count"),
                decisions=row.get("decision_trace_count"),
                next=row.get("next_gate"),
            )
        )
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
    parser.add_argument("--ramp-trace-report", type=Path, default=DEFAULT_RAMP_TRACE_REPORT)
    parser.add_argument("--forced-access-report", type=Path, default=DEFAULT_FORCED_ACCESS_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    payload = build_report(
        ramp_trace_report=args.ramp_trace_report,
        forced_access_report=args.forced_access_report,
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
