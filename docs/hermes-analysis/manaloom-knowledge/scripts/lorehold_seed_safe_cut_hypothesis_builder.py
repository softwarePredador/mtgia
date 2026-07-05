#!/usr/bin/env python3
"""Build seed-safe cut hypotheses for the protected Lorehold 607 shell.

This read-only helper starts after the normal cut models are exhausted. It does
not pick new cards and it does not run battles. Its job is narrower: prove
whether the current 607 list has any cut slot that is safe enough to receive a
new failure-targeted package without cutting the mana floor, protection shell,
miracle core, known structural anchors, or prior-negative cut slots.
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
from typing import Any, Iterable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = Path(os.environ.get("MANALOOM_KNOWLEDGE_DB", SCRIPT_DIR / "knowledge.db"))
DEFAULT_BASELINE_DECK_ID = 607
DEFAULT_MANUAL_REVIEW = (
    REPORT_DIR / "lorehold_manual_cut_review_20260704_role_tag_repair.json"
)
DEFAULT_SAFE_CUT_REPLANNER = (
    REPORT_DIR / "lorehold_safe_cut_replanner_20260704_role_tag_repair.json"
)
DEFAULT_STRATEGY_AUDIT = (
    REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
)
DEFAULT_EXPOSURE_PROFILE = (
    REPORT_DIR / "lorehold_card_exposure_profile_20260704_role_tag_repair_deck607.json"
)

SAFE_CUT_DECISIONS = {"engine_flex", "manual_review", "support_flex", "seed_safe_flex"}
READY_MANUAL_STATUSES = {
    "seed_safe_candidate",
    "low_exposure_flex",
    "candidate_seed_safe_cut",
}
SAME_LANE_ONLY_STATUSES = {
    "same_lane_only",
    "measured_cut_exposure_needs_same_lane_benchmark",
}
MANUAL_STATUS_BLOCKERS = {
    "blocked_by_cut_safety": "manual_review_cut_safety_block",
    "blocked_by_prior_rejection": "prior_rejected_cut_slot",
    "measured_high_cut_exposure": "measured_high_cut_exposure",
    "never_cut": "never_cut_or_mana_base",
    "structural_dependency": "structural_dependency",
}
HIGH_EXPOSURE_MIN = 100
MEASURED_EXPOSURE_MIN = 25
LANE_ALIASES = {
    "commander_engine": "commander",
    "early_mana": "early_mana",
    "finisher_or_big_spell": "big_spell_value",
    "graveyard_recursion": "graveyard_recursion",
    "hand_filter": "hand_filter",
    "interaction": "removal",
    "mana_base": "mana_base",
    "pressure_absorber_or_protection": "protection",
    "selection": "selection",
    "spell_density": "spell_velocity",
    "topdeck_miracle_setup": "topdeck_setup",
}
PROTECTED_LANES = {
    "commander",
    "mana_base",
    "early_mana",
    "protection",
    "big_spell_value",
    "topdeck_setup",
    "wincon",
}
GLOBAL_REPLANNER_BLOCKERS = {
    "cut_is_early_mana_floor_support",
    "cut_is_miracle_core_big_spell",
    "cut_is_protection_shell",
    "cut_not_flex_decision",
    "missing_cut_safety_row",
    "never_cut_lane",
    "prior_rejected_cut",
    "prior_rejected_signature",
    "protected_cut",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_key(value: object) -> str:
    return re.sub(r"[^a-z0-9]+", " ", str(value or "").lower()).strip()


def slug(value: object) -> str:
    return normalize_key(value).replace(" ", "_")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_optional_json(path: Path | None) -> dict[str, Any]:
    if not path or not path.exists():
        return {}
    return read_json(path)


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


def table_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {str(row["name"]) for row in conn.execute(f"PRAGMA table_info({table})").fetchall()}


def select_expr(columns: set[str], column: str, fallback: str) -> str:
    return column if column in columns else f"{fallback} AS {column}"


def deck_rows(source_db: Path, deck_id: int) -> list[dict[str, Any]]:
    conn = sqlite3.connect(source_db)
    conn.row_factory = sqlite3.Row
    try:
        columns = table_columns(conn, "deck_cards")
        rows = conn.execute(
            f"""
            SELECT card_name,
                   {select_expr(columns, "quantity", "1")},
                   {select_expr(columns, "functional_tag", "''")},
                   {select_expr(columns, "functional_tags_json", "'[]'")},
                   {select_expr(columns, "cmc", "0")},
                   {select_expr(columns, "type_line", "''")},
                   {select_expr(columns, "is_commander", "0")},
                   {select_expr(columns, "oracle_text", "''")}
            FROM deck_cards
            WHERE deck_id=?
            ORDER BY is_commander DESC, card_name
            """,
            (deck_id,),
        ).fetchall()
    finally:
        conn.close()
    out = []
    for row in rows:
        item = dict(row)
        item["normalized_name"] = normalize_key(item.get("card_name"))
        item["functional_tags"] = json_list(item.get("functional_tags_json"))
        out.append(item)
    return out


def manual_cut_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    expansion = payload.get("cut_evidence_expansion") or {}
    rows = {}
    for row in expansion.get("rows") or []:
        if isinstance(row, dict) and row.get("card_name"):
            rows[normalize_key(row["card_name"])] = dict(row)
    return rows


def cut_safety_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    manifest = payload.get("cut_safety_manifest") or {}
    rows: dict[str, dict[str, Any]] = {}
    for section in ("cuts", "untested_flex_pool"):
        for row in manifest.get(section) or []:
            if isinstance(row, dict) and row.get("card_name"):
                rows[normalize_key(row["card_name"])] = {**row, "source_section": section}
    return rows


def exposure_rows(payload: Mapping[str, Any]) -> dict[str, dict[str, Any]]:
    rows = {}
    for row in payload.get("card_profiles") or []:
        if isinstance(row, dict) and row.get("card_name"):
            rows[normalize_key(row["card_name"])] = dict(row)
    return rows


def safe_replanner_blockers(payload: Mapping[str, Any]) -> dict[str, list[str]]:
    blockers: dict[str, list[str]] = {}
    for row in payload.get("followups") or []:
        if not isinstance(row, dict):
            continue
        for cut in row.get("cuts") or []:
            key = normalize_key(cut)
            if key:
                blockers.setdefault(key, [])
                blockers[key].extend(
                    str(item)
                    for item in row.get("blockers") or []
                    if str(item) in GLOBAL_REPLANNER_BLOCKERS
                )
    return {key: sorted(set(values)) for key, values in blockers.items()}


def lane_from_sources(
    deck_row: Mapping[str, Any],
    manual_row: Mapping[str, Any],
    safety_row: Mapping[str, Any],
) -> str:
    for key in ("current_lane", "package_lane", "lane", "strategy_package_lane"):
        raw = safety_row.get(key) or manual_row.get(key)
        if raw:
            return LANE_ALIASES.get(str(raw), str(raw))
    type_line = str(deck_row.get("type_line") or "")
    tag = normalize_key(deck_row.get("functional_tag"))
    tags = {normalize_key(item) for item in deck_row.get("functional_tags") or []}
    if bool(deck_row.get("is_commander")):
        return "commander"
    if "land" in type_line.lower():
        return "mana_base"
    if "ramp" in tag or "ramp" in tags or "treasure" in tags:
        return "early_mana"
    if "protection" in tag or "protection" in tags:
        return "protection"
    if "removal" in tag or "removal" in tags:
        return "removal"
    if "draw" in tag or "draw" in tags:
        return "draw"
    if "wincon" in tag or "wincon" in tags:
        return "wincon"
    if "instant" in type_line.lower() or "sorcery" in type_line.lower():
        return "spell_velocity"
    return "misc"


def cut_safety_decision(row: Mapping[str, Any]) -> str:
    return str(row.get("decision") or row.get("current_decision") or "").strip()


def structurally_protected_by_text(deck_row: Mapping[str, Any], lane: str) -> list[str]:
    blockers = []
    type_line = str(deck_row.get("type_line") or "")
    tag = normalize_key(deck_row.get("functional_tag"))
    tags = {normalize_key(item) for item in deck_row.get("functional_tags") or []}
    cmc = float(deck_row.get("cmc") or 0.0)
    if bool(deck_row.get("is_commander")) or lane == "commander":
        blockers.append("commander_never_cut")
    if "land" in type_line.lower() or lane == "mana_base":
        blockers.append("mana_base_never_cut")
    if lane == "early_mana":
        blockers.append("early_mana_floor_support")
    if lane == "protection" or "protection" in tag or "protection" in tags:
        blockers.append("protection_shell")
    if lane in {"big_spell_value", "topdeck_setup", "wincon"}:
        blockers.append("miracle_or_finisher_core")
    if ("instant" in type_line.lower() or "sorcery" in type_line.lower()) and cmc >= 4:
        blockers.append("miracle_or_finisher_core")
    return blockers


def evaluate_cut_slot(
    deck_row: Mapping[str, Any],
    *,
    manual_row: Mapping[str, Any],
    safety_row: Mapping[str, Any],
    exposure_row: Mapping[str, Any],
    replanner_blockers: Iterable[str],
) -> dict[str, Any]:
    card_name = str(deck_row.get("card_name") or "")
    manual_status = str(manual_row.get("status") or "missing_manual_cut_evidence")
    lane = lane_from_sources(deck_row, manual_row, safety_row)
    exposure_count = int(
        exposure_row.get("unique_exposure_count")
        or (manual_row.get("cut_exposure") or {}).get("unique_exposure_count")
        or 0
    )
    direct_event_count = int(exposure_row.get("direct_event_count") or 0)
    safety_decision = cut_safety_decision(safety_row)
    safety_status = str(safety_row.get("status") or "")
    blockers: list[str] = []
    blockers.extend(structurally_protected_by_text(deck_row, lane))
    if manual_status in MANUAL_STATUS_BLOCKERS:
        blockers.append(MANUAL_STATUS_BLOCKERS[manual_status])
    if manual_status in SAME_LANE_ONLY_STATUSES:
        blockers.append("same_lane_only_requires_concrete_same_lane_add")
    if manual_status == "missing_manual_cut_evidence":
        blockers.append("missing_manual_cut_evidence")
    if not safety_row:
        blockers.append("missing_cut_safety_row")
    elif safety_decision not in SAFE_CUT_DECISIONS:
        blockers.append("cut_safety_not_seed_safe")
    if safety_status in {"locked_do_not_cut", "risky_cut_only_same_lane"}:
        blockers.append("cut_safety_not_seed_safe")
    if exposure_count >= HIGH_EXPOSURE_MIN:
        blockers.append("measured_high_cut_exposure")
    if manual_status not in READY_MANUAL_STATUSES:
        blockers.append("manual_status_not_seed_safe")
    blockers.extend(str(item) for item in replanner_blockers)
    blockers = sorted(set(blockers))
    if blockers:
        if "same_lane_only_requires_concrete_same_lane_add" in blockers:
            status = "same_lane_only_not_seed_safe"
        else:
            status = "blocked"
        recommended_action = "do_not_gate_from_this_cut"
    else:
        status = "seed_safe_cut_ready"
        recommended_action = "build_failure_targeted_package_from_cut"
    score = max(0, 100 - exposure_count)
    if exposure_count < MEASURED_EXPOSURE_MIN:
        score += 10
    return {
        "card_name": card_name,
        "normalized_name": normalize_key(card_name),
        "status": status,
        "recommended_action": recommended_action,
        "lane": lane,
        "score": score,
        "manual_status": manual_status,
        "cut_safety_status": safety_status,
        "cut_safety_decision": safety_decision,
        "cut_safety_source_section": safety_row.get("source_section"),
        "unique_exposure_count": exposure_count,
        "direct_event_count": direct_event_count,
        "inferred_role": exposure_row.get("inferred_role")
        or (manual_row.get("cut_exposure") or {}).get("inferred_role")
        or "",
        "blockers": blockers,
        "hypothesis_constraints": [
            "candidate package must target a named weak-seed failure mode",
            "candidate package must preserve seed-42 miracle/topdeck telemetry",
            "candidate card must be drawn/accessed/used in gate evidence",
            "candidate must tie or beat protected 607 without Winota regression",
        ],
    }


def build_report(
    *,
    source_db: Path,
    deck_id: int,
    manual_review_path: Path,
    strategy_audit_path: Path,
    exposure_profile_path: Path,
    safe_cut_replanner_path: Path | None,
) -> dict[str, Any]:
    manual_review = read_optional_json(manual_review_path)
    strategy_audit = read_optional_json(strategy_audit_path)
    exposure_profile = read_optional_json(exposure_profile_path)
    safe_cut_replanner = read_optional_json(safe_cut_replanner_path)
    missing_inputs = [
        name
        for name, payload in {
            "manual_review": manual_review,
            "strategy_audit": strategy_audit,
            "exposure_profile": exposure_profile,
        }.items()
        if not payload
    ]
    manual_by_card = manual_cut_rows(manual_review)
    safety_by_card = cut_safety_rows(strategy_audit)
    exposure_by_card = exposure_rows(exposure_profile)
    replanner_by_card = safe_replanner_blockers(safe_cut_replanner)
    rows = []
    for deck_row in deck_rows(source_db, deck_id):
        key = normalize_key(deck_row.get("card_name"))
        rows.append(
            evaluate_cut_slot(
                deck_row,
                manual_row=manual_by_card.get(key) or {},
                safety_row=safety_by_card.get(key) or {},
                exposure_row=exposure_by_card.get(key) or {},
                replanner_blockers=replanner_by_card.get(key) or [],
            )
        )
    rows.sort(
        key=lambda row: (
            0 if row["status"] == "seed_safe_cut_ready" else 1,
            0 if row["status"] == "same_lane_only_not_seed_safe" else 1,
            -int(row.get("score") or 0),
            row.get("card_name") or "",
        )
    )
    ready = [row for row in rows if row["status"] == "seed_safe_cut_ready"]
    same_lane = [row for row in rows if row["status"] == "same_lane_only_not_seed_safe"]
    blocker_counts = Counter(blocker for row in rows for blocker in row.get("blockers") or [])
    status_counts = Counter(row["status"] for row in rows)
    lane_counts = Counter(row["lane"] for row in rows)
    recommended = (
        "rerun_with_current_cut_evidence_inputs"
        if missing_inputs
        else
        "build_failure_targeted_packages_from_seed_safe_cuts"
        if ready
        else "expand_cut_safety_model_or_multi_card_shell_before_gate"
    )
    manifest = {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_id": deck_id,
        "purpose": "Seed-safe cut slots for future Lorehold package design.",
        "cut_slots": [
            {
                "cut_card": row["card_name"],
                "lane": row["lane"],
                "score": row["score"],
                "hypothesis_constraints": row["hypothesis_constraints"],
            }
            for row in ready
        ],
    }
    return {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "source_db": str(source_db),
        "deck_id": deck_id,
        "manual_review": str(manual_review_path),
        "strategy_audit": str(strategy_audit_path),
        "exposure_profile": str(exposure_profile_path),
        "safe_cut_replanner": str(safe_cut_replanner_path or ""),
        "summary": {
            "missing_inputs": missing_inputs,
            "deck_card_count": len(rows),
            "seed_safe_cut_ready_count": len(ready),
            "same_lane_only_count": len(same_lane),
            "blocked_count": len(rows) - len(ready),
            "status_counts": dict(sorted(status_counts.items())),
            "lane_counts": dict(sorted(lane_counts.items())),
            "blocker_counts": dict(sorted(blocker_counts.items())),
            "ready_cut_cards": [row["card_name"] for row in ready],
            "same_lane_only_cut_cards": [row["card_name"] for row in same_lane],
            "recommended_next_action": recommended,
        },
        "manifest": manifest,
        "seed_safe_cut_candidates": ready,
        "same_lane_only_cut_slots": same_lane,
        "cut_slots": rows,
        "method_notes": [
            "This report is a cut-slot synthesis, not a deck promotion.",
            "A same-lane-only cut is not seed-safe without a concrete same-lane add and gate.",
            "Early mana, protection, miracle core, lands, commander, high-exposure slots, and prior-negative slots are blocked.",
            "PostgreSQL and SQLite are not mutated by this script.",
        ],
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold Seed-Safe Cut Hypothesis Builder",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- postgres_writes: `{payload['postgres_writes']}`",
        f"- source_db_mutated: `{payload['source_db_mutated']}`",
        f"- deck_id: `{payload['deck_id']}`",
        f"- deck_card_count: `{summary['deck_card_count']}`",
        f"- missing_inputs: `{json.dumps(summary.get('missing_inputs') or [])}`",
        f"- seed_safe_cut_ready_count: `{summary['seed_safe_cut_ready_count']}`",
        f"- same_lane_only_count: `{summary['same_lane_only_count']}`",
        f"- blocked_count: `{summary['blocked_count']}`",
        f"- recommended_next_action: `{summary['recommended_next_action']}`",
        f"- status_counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
        f"- blocker_counts: `{json.dumps(summary['blocker_counts'], sort_keys=True)}`",
        "",
        "## Interpretation",
        "",
    ]
    if int(summary["seed_safe_cut_ready_count"] or 0) == 0:
        lines.extend(
            [
                "- No battle package should be generated from this report.",
                "- The current 607 shell has no generic seed-safe cut slot under the active evidence.",
                "- Next work is a new cut-safety model, a multi-card shell hypothesis, or a diagnostic-only forced-access probe.",
                "",
            ]
        )
    else:
        lines.extend(
            [
                "- The cut manifest contains slots that can receive a failure-targeted package design.",
                "- The package still needs exact add/cut preflight and natural battle evidence before any deck change.",
                "",
            ]
        )
    lines.extend(["## Seed-Safe Cut Candidates", ""])
    ready = payload.get("seed_safe_cut_candidates") or []
    if not ready:
        lines.append("- None.")
    else:
        lines.extend(["| Cut | Lane | Score | Exposure |", "| --- | --- | ---: | ---: |"])
        for row in ready:
            lines.append(
                f"| `{row['card_name']}` | `{row['lane']}` | `{row['score']}` | "
                f"`{row['unique_exposure_count']}` |"
            )
    lines.extend(["", "## Same-Lane Only Slots", ""])
    same_lane = payload.get("same_lane_only_cut_slots") or []
    if not same_lane:
        lines.append("- None.")
    else:
        for row in same_lane[:12]:
            lines.append(
                f"- `{row['card_name']}` lane `{row['lane']}` remains same-lane only; "
                f"blockers `{', '.join(row.get('blockers') or [])}`."
            )
    lines.extend(["", "## Top Blocked Slots", ""])
    blocked = [row for row in payload.get("cut_slots") or [] if row.get("status") == "blocked"]
    for row in blocked[:20]:
        lines.append(
            f"- `{row['card_name']}` lane `{row['lane']}` blockers "
            f"`{', '.join(row.get('blockers') or [])}`."
        )
    lines.extend(["", "## Method Notes", ""])
    for note in payload.get("method_notes") or []:
        lines.append(f"- {note}")
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], stem: str) -> tuple[Path, Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    manifest_path = REPORT_DIR / f"{stem}_cut_manifest.json"
    json_path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=True, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    manifest_path.write_text(
        json.dumps(payload["manifest"], indent=2, ensure_ascii=True, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return json_path, md_path, manifest_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--deck-id", type=int, default=DEFAULT_BASELINE_DECK_ID)
    parser.add_argument("--manual-review", type=Path, default=DEFAULT_MANUAL_REVIEW)
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--exposure-profile", type=Path, default=DEFAULT_EXPOSURE_PROFILE)
    parser.add_argument("--safe-cut-replanner", type=Path, default=DEFAULT_SAFE_CUT_REPLANNER)
    parser.add_argument("--stem", default="lorehold_seed_safe_cut_hypothesis_20260630_goal_learning")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        source_db=args.source_db.resolve(),
        deck_id=args.deck_id,
        manual_review_path=args.manual_review.resolve(),
        strategy_audit_path=args.strategy_audit.resolve(),
        exposure_profile_path=args.exposure_profile.resolve(),
        safe_cut_replanner_path=args.safe_cut_replanner.resolve()
        if args.safe_cut_replanner
        else None,
    )
    json_path, md_path, manifest_path = write_outputs(payload, args.stem)
    print(
        json.dumps(
            {
                "status": "ready",
                "json": str(json_path),
                "markdown": str(md_path),
                "manifest": str(manifest_path),
                "seed_safe_cut_ready_count": payload["summary"]["seed_safe_cut_ready_count"],
                "recommended_next_action": payload["summary"]["recommended_next_action"],
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
