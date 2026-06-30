#!/usr/bin/env python3
"""Build a seed-safe cut model for Lorehold tutor packages.

This read-only helper turns the planner action ``build_tutor_seed_safe_cut_model``
into concrete evidence. It evaluates every protected deck-607 card as a possible
cut for Gamble and Enlightened Tutor, then separates direct gate candidates from
manual benchmarks and hard blocks. The script deliberately does not create a
package when the cut would repeat a known strong-seed regression.
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

from master_optimizer_common import resolve_default_knowledge_db


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_STRATEGY_AUDIT = REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json"
DEFAULT_MINER_REPORT = (
    REPORT_DIR / "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"
)
DEFAULT_EXPOSURE_PROFILES = [
    REPORT_DIR / "lorehold_card_exposure_profile_20260627_v2_role_fix.json",
    REPORT_DIR / "lorehold_tutor_cut_candidate_exposure_profile_20260627_v1.json",
]
DEFAULT_CANDIDATES = ["Enlightened Tutor", "Gamble"]
DEFAULT_BASELINE_DECK_ID = 607
ACTIVE_EXECUTION_STATUSES = {"active", "verified", "auto", "reviewed"}
ACTIVE_REVIEW_STATUSES = {"verified", "active", "needs_review", "reviewed"}
COMPATIBLE_TUTOR_CUT_LANES = {"selection", "tutor_access"}
SOFT_ACCESS_LANES = {"topdeck_miracle_setup", "hand_filter"}
HARD_BLOCK_STATUSES = {
    "blocked_core_cut",
    "blocked_locked_cut",
    "tested_negative_cut",
    "risky_same_lane_only",
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


def load_deck_cards(conn: sqlite3.Connection, deck_id: int) -> list[dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT card_name, quantity, functional_tag, cmc, type_line,
               functional_tags_json, is_commander
        FROM deck_cards
        WHERE deck_id = ?
        ORDER BY is_commander DESC, functional_tag, card_name
        """,
        (deck_id,),
    ).fetchall()
    out = []
    for row in rows:
        out.append(
            {
                "card_name": row["card_name"],
                "quantity": int(row["quantity"] or 1),
                "functional_tag": row["functional_tag"],
                "cmc": row["cmc"],
                "type_line": row["type_line"],
                "functional_tags": json_list(row["functional_tags_json"]),
                "is_commander": bool(row["is_commander"]),
            }
        )
    return out


def load_rule_summaries(conn: sqlite3.Connection, names: Iterable[str]) -> dict[str, dict[str, Any]]:
    wanted = {normalize_key(name): str(name) for name in names if str(name).strip()}
    summaries: dict[str, dict[str, Any]] = {
        key: {
            "card_name": name,
            "active_rule_count": 0,
            "rule_count": 0,
            "effects": Counter(),
            "battle_model_scopes": Counter(),
            "execution_statuses": Counter(),
            "review_statuses": Counter(),
        }
        for key, name in wanted.items()
    }
    if not wanted:
        return {}
    rows = conn.execute(
        """
        SELECT card_name, normalized_name, execution_status, review_status, effect_json
        FROM battle_card_rules
        ORDER BY card_name
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
        for key in ("effects", "battle_model_scopes", "execution_statuses", "review_statuses"):
            summary[key] = dict(sorted((summary.get(key) or {}).items()))
    return summaries


def exposure_lookup(profiles: list[tuple[Path, dict[str, Any]]]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for path, payload in profiles:
        for row in payload.get("card_profiles") or []:
            if not row.get("card_name"):
                continue
            key = normalize_key(row["card_name"])
            candidate = {**row, "exposure_profile": str(path)}
            current = out.get(key)
            if current is None or int(candidate.get("unique_exposure_count") or 0) >= int(
                current.get("unique_exposure_count") or 0
            ):
                out[key] = candidate
    return out


def cut_inventory_lookup(miner_report: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        normalize_key(row.get("card_name")): row
        for row in miner_report.get("cut_inventory") or []
        if row.get("card_name")
    }


def prior_tutor_evidence(strategy_audit: dict[str, Any]) -> list[dict[str, Any]]:
    post_squee = (
        (strategy_audit.get("strategy_dependency_map") or {})
        .get("package_learning", {})
        .get("post_squee", {})
    )
    rows = []
    for section in ("hard_reject_sample", "probation_or_watch"):
        for row in post_squee.get(section) or []:
            if row.get("family") == "tutor_access":
                rows.append({**row, "source_section": section})
    rows.sort(
        key=lambda row: (
            row.get("adds") or [],
            row.get("cuts") or [],
            float(row.get("strong_seed_delta_pp") or 0),
        )
    )
    return rows


def guardrail_lookup(strategy_audit: dict[str, Any]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    guardrails = (strategy_audit.get("strategy_dependency_map") or {}).get("cut_guardrails") or {}
    for section, rows in guardrails.items():
        for row in rows or []:
            if row.get("card_name"):
                out[normalize_key(row["card_name"])] = {**row, "guardrail_section": section}
    return out


def exposure_summary(card_name: str, exposures: dict[str, dict[str, Any]]) -> dict[str, Any]:
    row = exposures.get(normalize_key(card_name)) or {}
    decision = row.get("decision") or {}
    return {
        "profiled": bool(row),
        "unique_exposure_count": int(row.get("unique_exposure_count") or 0),
        "inferred_role": row.get("inferred_role") or "unmeasured",
        "decision_status": decision.get("status") or "unmeasured",
        "role_signals": list(row.get("role_signals") or []),
        "exposure_profile": row.get("exposure_profile") or "",
    }


def candidate_summary(
    card_name: str,
    rules: dict[str, dict[str, Any]],
    exposures: dict[str, dict[str, Any]],
    prior_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    key = normalize_key(card_name)
    rule = rules.get(key, {})
    prior = [
        row
        for row in prior_rows
        if key in {normalize_key(card) for card in row.get("adds") or []}
    ]
    return {
        "card_name": card_name,
        "active_rule_count": int(rule.get("active_rule_count") or 0),
        "rule_count": int(rule.get("rule_count") or 0),
        "effects": sorted((rule.get("effects") or {}).keys()),
        "battle_model_scopes": sorted((rule.get("battle_model_scopes") or {}).keys()),
        "exposure": exposure_summary(card_name, exposures),
        "prior_tutor_evidence": prior,
    }


def prior_evidence_for_pair(
    candidate: str,
    cut: str,
    prior_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    candidate_key = normalize_key(candidate)
    cut_key = normalize_key(cut)
    return [
        row
        for row in prior_rows
        if candidate_key in {normalize_key(card) for card in row.get("adds") or []}
        and cut_key in {normalize_key(card) for card in row.get("cuts") or []}
    ]


def classify_pair(
    *,
    candidate: str,
    cut_card: dict[str, Any],
    cut_inventory: dict[str, dict[str, Any]],
    guardrails: dict[str, dict[str, Any]],
    prior_rows: list[dict[str, Any]],
) -> tuple[str, list[str], int]:
    cut_name = str(cut_card["card_name"])
    cut_key = normalize_key(cut_name)
    inventory = cut_inventory.get(cut_key, {})
    guardrail = guardrails.get(cut_key, {})
    prior_pair = prior_evidence_for_pair(candidate, cut_name, prior_rows)
    status = str(inventory.get("status") or "unknown")
    lane = str(inventory.get("lane") or cut_card.get("functional_tag") or "contextual")
    blockers: list[str] = []
    score = 0
    if cut_card.get("is_commander"):
        blockers.append("cut_is_commander")
    if "Land" in str(cut_card.get("type_line") or ""):
        blockers.append("cut_is_land_or_mana_base")
    if guardrail.get("guardrail_section") == "locked_or_protected":
        blockers.append(f"locked_cut:{cut_name}")
    if guardrail.get("guardrail_section") == "risky_same_lane_only":
        blockers.append(f"risky_prior_strong_seed_cut:{cut_name}")
    if prior_pair and any(float(row.get("strong_seed_delta_pp") or 0) < 0 for row in prior_pair):
        blockers.append(f"prior_strong_seed_regression:{cut_name}")
    if status in HARD_BLOCK_STATUSES:
        blockers.append(f"cut_status:{status}")
    if blockers:
        return "blocked", sorted(set(blockers)), -100
    if lane in COMPATIBLE_TUTOR_CUT_LANES:
        score += 40
    elif lane in SOFT_ACCESS_LANES:
        score += 20
    elif lane == "early_mana":
        return (
            "blocked_ramp_floor_mismatch",
            ["tutor add would remove early mana; prior ramp cuts already produced negative evidence"],
            -50,
        )
    else:
        score -= 10
    if status == "untested_flex_candidate" and lane in COMPATIBLE_TUTOR_CUT_LANES:
        return "gate_ready_after_preflight", [], score + 40
    if status == "manual_review_needed":
        return "manual_role_review_required", ["cut has local role/runtime uncertainty"], score + 5
    if status == "requires_same_lane_gate":
        return (
            "protected_benchmark_required",
            ["cut is protected support; needs explicit same-access benchmark before battle"],
            score + 10,
        )
    if status == "untested_flex_candidate":
        return (
            "blocked_cross_lane_flex",
            ["flex cut is not in tutor/access lane"],
            score - 20,
        )
    return "manual_cut_model_required", ["cut status is not automatically safe"], score


def build_model(
    *,
    conn: sqlite3.Connection,
    strategy_audit: dict[str, Any],
    miner_report: dict[str, Any],
    exposure_profiles: list[tuple[Path, dict[str, Any]]],
    candidates: list[str] = DEFAULT_CANDIDATES,
    deck_id: int = DEFAULT_BASELINE_DECK_ID,
    db_path: Path = DEFAULT_DB,
    strategy_path: Path = DEFAULT_STRATEGY_AUDIT,
    miner_path: Path = DEFAULT_MINER_REPORT,
) -> dict[str, Any]:
    deck_cards = load_deck_cards(conn, deck_id)
    all_names = sorted({*candidates, *(row["card_name"] for row in deck_cards)})
    rules = load_rule_summaries(conn, all_names)
    exposures = exposure_lookup(exposure_profiles)
    cut_inventory = cut_inventory_lookup(miner_report)
    guardrails = guardrail_lookup(strategy_audit)
    prior_rows = prior_tutor_evidence(strategy_audit)
    candidate_rows = [
        candidate_summary(candidate, rules, exposures, prior_rows)
        for candidate in candidates
    ]
    pair_rows: list[dict[str, Any]] = []
    for candidate in candidates:
        for cut_card in deck_cards:
            if normalize_key(candidate) == normalize_key(cut_card["card_name"]):
                continue
            status, blockers, score = classify_pair(
                candidate=candidate,
                cut_card=cut_card,
                cut_inventory=cut_inventory,
                guardrails=guardrails,
                prior_rows=prior_rows,
            )
            cut_name = str(cut_card["card_name"])
            inventory = cut_inventory.get(normalize_key(cut_name), {})
            cut_exposure = exposure_summary(cut_name, exposures)
            if not cut_exposure["profiled"] and status in {
                "protected_benchmark_required",
                "manual_role_review_required",
                "manual_cut_model_required",
            }:
                score -= 15
            pair_rows.append(
                {
                    "candidate": candidate,
                    "cut": cut_name,
                    "status": status,
                    "score": score,
                    "blockers": blockers,
                    "lane": inventory.get("lane") or cut_card.get("functional_tag") or "contextual",
                    "cut_status": inventory.get("status") or "unknown",
                    "effective_role": inventory.get("effective_role") or cut_card.get("functional_tag"),
                    "decision": inventory.get("decision"),
                    "decision_status": inventory.get("decision_status"),
                    "negative_cut_count": int(inventory.get("negative_cut_count") or 0),
                    "cut_exposure": cut_exposure,
                    "prior_pair_evidence": prior_evidence_for_pair(candidate, cut_name, prior_rows),
                }
            )
    pair_rows.sort(key=lambda row: (-int(row["score"]), row["status"], row["candidate"], row["cut"]))
    status_counts = Counter(row["status"] for row in pair_rows)
    gate_ready_rows = [row for row in pair_rows if row["status"] == "gate_ready_after_preflight"]
    benchmark_rows = [
        row
        for row in pair_rows
        if row["status"]
        in {
            "protected_benchmark_required",
            "manual_role_review_required",
            "manual_cut_model_required",
        }
    ]
    return {
        "generated_at": utc_now(),
        "source_db": str(db_path),
        "strategy_audit": str(strategy_path),
        "miner_report": str(miner_path),
        "exposure_profiles": [str(path) for path, _payload in exposure_profiles],
        "deck_id": deck_id,
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "candidate_count": len(candidate_rows),
            "deck_card_rows": len(deck_cards),
            "evaluated_pair_count": len(pair_rows),
            "direct_gate_ready_count": len(gate_ready_rows),
            "status_counts": dict(sorted(status_counts.items())),
            "recommended_next_action": (
                "preflight_gate_ready_tutor_package"
                if gate_ready_rows
                else "do_not_gate_direct_tutor_swap; benchmark same-access cuts or build additive package"
            ),
        },
        "candidates": candidate_rows,
        "prior_tutor_evidence": prior_rows,
        "top_direct_gate_candidates": gate_ready_rows[:10],
        "top_manual_benchmarks": benchmark_rows[:20],
        "cut_pair_evaluations": pair_rows,
        "guardrails": [
            {
                "guardrail_key": "do_not_repeat_thor_or_creative_tutor_cuts",
                "reason": "Thor and Creative Technique both have prior strong-seed regressions in tutor packages.",
            },
            {
                "guardrail_key": "do_not_trade_tutor_for_early_mana_without_benchmark",
                "reason": "The current shell is mana-hungry; direct tutor-over-ramp swaps are cross-lane and not seed-safe.",
            },
            {
                "guardrail_key": "same_access_benchmark_before_gate",
                "reason": "Land Tax/topdeck engines have high measured exposure and require explicit access-lane comparison before battle.",
            },
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Tutor Cut Model - 2026-06-28",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Source DB: `{payload['source_db']}`",
        f"- Deck id: `{payload['deck_id']}`",
        f"- Strategy audit: `{payload['strategy_audit']}`",
        f"- Miner report: `{payload['miner_report']}`",
        f"- Exposure profiles: `{', '.join(payload['exposure_profiles'])}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Candidate count: `{payload['summary']['candidate_count']}`",
        f"- Evaluated pairs: `{payload['summary']['evaluated_pair_count']}`",
        f"- Direct gate-ready pairs: `{payload['summary']['direct_gate_ready_count']}`",
        f"- Status counts: `{json.dumps(payload['summary']['status_counts'], sort_keys=True)}`",
        f"- Recommended next action: `{payload['summary']['recommended_next_action']}`",
        "",
        "## Tutor Candidates",
        "",
        "| Candidate | Active Rules | Exposure | Role | Prior Evidence |",
        "| --- | ---: | ---: | --- | --- |",
    ]
    for row in payload["candidates"]:
        prior = "; ".join(
            f"{item.get('package_key')} {float(item.get('delta_pp') or 0):+.2f}pp / seed {float(item.get('strong_seed_delta_pp') or 0):+.2f}pp"
            for item in row.get("prior_tutor_evidence") or []
        ) or "none"
        exposure = row["exposure"]
        lines.append(
            f"| {row['card_name']} | {row['active_rule_count']} | {exposure['unique_exposure_count']} | `{exposure['inferred_role']}` | {prior} |"
        )
    lines.extend(
        [
            "",
            "## Top Manual Benchmarks",
            "",
            "| Rank | Candidate | Cut | Status | Score | Lane | Cut Status | Exposure | Blockers |",
            "| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |",
        ]
    )
    for index, row in enumerate(payload["top_manual_benchmarks"], start=1):
        exposure = (
            str(row["cut_exposure"]["unique_exposure_count"])
            if row["cut_exposure"].get("profiled")
            else "unmeasured"
        )
        lines.append(
            "| {rank} | {candidate} | {cut} | `{status}` | {score} | `{lane}` | `{cut_status}` | {exposure} | {blockers} |".format(
                rank=index,
                candidate=row["candidate"],
                cut=row["cut"],
                status=row["status"],
                score=row["score"],
                lane=row["lane"],
                cut_status=row["cut_status"],
                exposure=exposure,
                blockers="; ".join(row["blockers"]) or "none",
            )
        )
    lines.extend(["", "## Direct Gate Candidates", ""])
    if not payload["top_direct_gate_candidates"]:
        lines.append("- None. No direct tutor swap is seed-safe from current evidence.")
    for row in payload["top_direct_gate_candidates"]:
        lines.append(f"- `{row['candidate']}` over `{row['cut']}`: score `{row['score']}`")
    lines.extend(["", "## Prior Tutor Evidence", ""])
    for row in payload["prior_tutor_evidence"]:
        lines.append(
            "- `{package}` adds {adds}, cuts {cuts}: delta `{delta:+.2f}pp`, strong seed `{seed:+.2f}pp`, decision `{decision}`".format(
                package=row.get("package_key"),
                adds=", ".join(row.get("adds") or []),
                cuts=", ".join(row.get("cuts") or []),
                delta=float(row.get("delta_pp") or 0),
                seed=float(row.get("strong_seed_delta_pp") or 0),
                decision=row.get("decision"),
            )
        )
    lines.extend(["", "## Guardrails", ""])
    for row in payload["guardrails"]:
        lines.append(f"- `{row['guardrail_key']}`: {row['reason']}")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--strategy-audit", type=Path, default=DEFAULT_STRATEGY_AUDIT)
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--exposure-profile", type=Path, action="append")
    parser.add_argument("--candidate", action="append")
    parser.add_argument("--deck-id", type=int, default=DEFAULT_BASELINE_DECK_ID)
    parser.add_argument("--stem", default="lorehold_tutor_cut_model_20260628_v2_current_miner")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    exposure_paths = args.exposure_profile or DEFAULT_EXPOSURE_PROFILES
    with connect(args.db) as conn:
        payload = build_model(
            conn=conn,
            strategy_audit=read_json(args.strategy_audit),
            miner_report=read_json(args.miner_report),
            exposure_profiles=read_existing_json(exposure_paths),
            candidates=args.candidate or DEFAULT_CANDIDATES,
            deck_id=args.deck_id,
            db_path=args.db,
            strategy_path=args.strategy_audit,
            miner_path=args.miner_report,
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
