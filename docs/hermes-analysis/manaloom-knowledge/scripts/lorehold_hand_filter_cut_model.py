#!/usr/bin/env python3
"""Build a cut model for Lorehold hand-filter/value candidates.

This helper is read-only. It resolves the planner action
``profile_hand_filter_cut_benchmarks`` by combining the variant gap miner with
fresh exposure evidence. The output separates a preflight benchmark from cuts
that are too exposed or strategically important to try blindly.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from collections import Counter
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
    REPORT_DIR / "lorehold_variant_gap_miner_20260628_v4_all_candidates_runtime_queue.json"
)
DEFAULT_EXPOSURE_PROFILES = [
    REPORT_DIR / "lorehold_hand_filter_cut_candidate_exposure_profile_20260627_v1.json",
]
DEFAULT_PRIOR_PACKAGE_REPORTS = [
    REPORT_DIR / "lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json",
    REPORT_DIR / "lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json",
]
HIGH_EXPOSURE_CUTOFF = 200
PROTECTED_EXPOSURE_CUTOFF = 80


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


def deck_card_lookup(conn: sqlite3.Connection, deck_id: int = 6) -> dict[str, dict[str, Any]]:
    rows = conn.execute(
        """
        SELECT card_name, functional_tag, functional_tags_json, type_line, cmc, is_commander
        FROM deck_cards
        WHERE deck_id=?
        """,
        (deck_id,),
    ).fetchall()
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        try:
            functional_tags = json.loads(row["functional_tags_json"] or "[]")
        except Exception:
            functional_tags = []
        out[normalize_key(row["card_name"])] = {
            "card_name": row["card_name"],
            "functional_tag": row["functional_tag"],
            "functional_tags": functional_tags if isinstance(functional_tags, list) else [],
            "type_line": row["type_line"],
            "cmc": float(row["cmc"] or 0),
            "is_commander": bool(row["is_commander"]),
        }
    return out


def hand_filter_pairings(miner_report: dict[str, Any]) -> list[dict[str, Any]]:
    rows = [
        row
        for row in miner_report.get("pairing_hypotheses") or []
        if row.get("lane") == "hand_filter"
    ]
    rows.sort(key=lambda row: (-int(row.get("candidate_score") or 0), row.get("candidate") or ""))
    return rows


def infer_package_decision(result: dict[str, Any]) -> str:
    if result.get("decision"):
        return str(result["decision"])
    gate = result.get("gate_summary") or {}
    baseline = gate.get("baseline") or {}
    candidate = gate.get("candidate") or {}
    baseline_wins = int(baseline.get("wins") or 0)
    candidate_wins = int(candidate.get("wins") or 0)
    delta = float(gate.get("delta_pp") or 0.0)
    if delta < 0 or candidate_wins < baseline_wins:
        return "reject_or_rework"
    if delta > 0 or candidate_wins > baseline_wins:
        return "promote_to_deeper_gate"
    return "tie_or_unknown"


def rejected_pair_lookup(
    prior_package_reports: list[tuple[Path, dict[str, Any]]],
) -> dict[tuple[str, str], dict[str, Any]]:
    rejected: dict[tuple[str, str], dict[str, Any]] = {}
    for path, payload in prior_package_reports:
        packages = payload.get("packages") or []
        if not isinstance(packages, list):
            continue
        for result in packages:
            if not isinstance(result, dict):
                continue
            adds = [normalize_key(card) for card in (result.get("adds") or []) if normalize_key(card)]
            cuts = [normalize_key(card) for card in (result.get("cuts") or []) if normalize_key(card)]
            if len(adds) != 1 or len(cuts) != 1:
                continue
            decision = infer_package_decision(result)
            if decision != "reject_or_rework":
                continue
            gate = result.get("gate_summary") or {}
            rejected[(adds[0], cuts[0])] = {
                "package_key": result.get("package_key"),
                "source_report": str(path),
                "adds": result.get("adds") or [],
                "cuts": result.get("cuts") or [],
                "decision": decision,
                "delta_pp": gate.get("delta_pp"),
                "baseline": gate.get("baseline") or {},
                "candidate": gate.get("candidate") or {},
            }
    return rejected


def profile_summary(card_name: str, exposures: dict[str, dict[str, Any]]) -> dict[str, Any]:
    row = exposures.get(normalize_key(card_name)) or {}
    rule = row.get("rule_summary") or {}
    decision = row.get("decision") or {}
    return {
        "profiled": bool(row),
        "unique_exposure_count": int(row.get("unique_exposure_count") or 0),
        "direct_event_count": int(row.get("direct_event_count") or 0),
        "inferred_role": row.get("inferred_role") or "unmeasured",
        "decision_status": decision.get("status") or "unmeasured",
        "role_signals": list(row.get("role_signals") or []),
        "active_rule_count": int(rule.get("active_rule_count") or 0),
        "rule_effects": sorted((rule.get("effects") or {}).keys()),
        "battle_model_scopes": sorted((rule.get("battle_model_scopes") or {}).keys()),
        "exposure_profile": row.get("exposure_profile") or "",
    }


def candidate_runtime_status(candidate: dict[str, Any]) -> tuple[str, list[str], int]:
    blockers: list[str] = []
    score = 0
    if not candidate["profiled"]:
        blockers.append("candidate_missing_exposure_profile")
    if int(candidate["active_rule_count"]) <= 0:
        blockers.append("candidate_missing_active_runtime_rule")
    else:
        score += 15
    if int(candidate["direct_event_count"]) >= 50:
        score += 15
    elif int(candidate["unique_exposure_count"]) == 0:
        blockers.append("candidate_zero_natural_exposure")
        score -= 12
    elif int(candidate["unique_exposure_count"]) < 5:
        blockers.append("candidate_low_natural_exposure")
        score -= 6
    if candidate.get("battle_model_scopes"):
        score += 8
    elif "exile_value" in set(candidate.get("rule_effects") or []):
        score -= 6
    return ("blocked" if any("missing" in blocker for blocker in blockers) else "review", blockers, score)


def cut_safety_status(cut: dict[str, Any], exposure: dict[str, Any]) -> tuple[str, list[str], int]:
    blockers: list[str] = []
    score = 0
    exposure_count = int(exposure["unique_exposure_count"])
    functional_tag = str(cut.get("functional_tag") or "")
    type_line = str(cut.get("type_line") or "")
    if cut.get("is_commander"):
        blockers.append("cut_is_commander")
    if "Land" in type_line:
        blockers.append("cut_is_land")
    if functional_tag == "wincon":
        blockers.append("cut_is_wincon")
    if exposure_count >= HIGH_EXPOSURE_CUTOFF:
        blockers.append(f"cut_high_exposure:{exposure_count}")
    elif exposure_count >= PROTECTED_EXPOSURE_CUTOFF:
        blockers.append(f"cut_protected_exposure:{exposure_count}")
        score -= 20
    else:
        score += 20
    if functional_tag == "ramp":
        blockers.append("cut_removes_ramp_or_treasure_role")
        score -= 8
    elif functional_tag == "draw":
        score -= 10
    return ("blocked" if any(blocker.startswith(("cut_is", "cut_high")) for blocker in blockers) else "review", blockers, score)


def classify_pair(
    *,
    pairing: dict[str, Any],
    cut_option: dict[str, Any],
    deck_cards: dict[str, dict[str, Any]],
    exposures: dict[str, dict[str, Any]],
    rejected_pairs: dict[tuple[str, str], dict[str, Any]] | None = None,
    rejected_cut_counts: dict[str, int] | None = None,
) -> dict[str, Any]:
    candidate_name = str(pairing.get("candidate") or "")
    cut_name = str(cut_option.get("card_name") or "")
    prior_rejection = (rejected_pairs or {}).get(
        (normalize_key(candidate_name), normalize_key(cut_name))
    )
    cut_reject_count = int((rejected_cut_counts or {}).get(normalize_key(cut_name), 0))
    candidate = profile_summary(candidate_name, exposures)
    cut_profile = profile_summary(cut_name, exposures)
    cut = deck_cards.get(normalize_key(cut_name), {"card_name": cut_name})
    _candidate_status, candidate_blockers, candidate_score = candidate_runtime_status(candidate)
    _cut_status, cut_blockers, cut_score = cut_safety_status(cut, cut_profile)
    base_score = int(pairing.get("candidate_score") or 0)
    score = base_score + candidate_score + cut_score
    blockers = sorted(set(candidate_blockers + cut_blockers))
    if prior_rejection:
        blockers.append("prior_exact_package_reject")
        status = "blocked_prior_reject"
    elif cut_reject_count >= 2:
        blockers.append(f"cut_repeated_prior_rejects:{cut_reject_count}")
        status = "blocked_cut_repeated_benchmark_reject"
    elif "candidate_missing_active_runtime_rule" in blockers or "candidate_missing_exposure_profile" in blockers:
        status = "blocked_candidate_runtime_or_profile"
    elif any(blocker.startswith("cut_is") or blocker.startswith("cut_high") for blocker in blockers):
        status = "blocked_cut_core_or_high_exposure"
    elif score >= 95 and int(cut_profile["unique_exposure_count"]) < PROTECTED_EXPOSURE_CUTOFF:
        status = "preflight_benchmark_ready"
    elif "candidate_zero_natural_exposure" in blockers:
        status = "runtime_smoke_required_before_gate"
    else:
        status = "protected_benchmark_required"
    return {
        "candidate": candidate_name,
        "cut": cut_name,
        "status": status,
        "score": score,
        "candidate_score": base_score,
        "blockers": blockers,
        "candidate_exposure": candidate,
        "cut_exposure": cut_profile,
        "cut_metadata": cut,
        "cut_inventory_status": cut_option.get("status"),
        "cut_gate_readiness": cut_option.get("gate_readiness"),
        "readiness_reason": cut_option.get("readiness_reason"),
        "prior_rejection": prior_rejection or {},
        "cut_prior_reject_count": cut_reject_count,
    }


def build_model(
    *,
    conn: sqlite3.Connection,
    miner_report: dict[str, Any],
    exposure_profiles: list[tuple[Path, dict[str, Any]]],
    prior_package_reports: list[tuple[Path, dict[str, Any]]] | None = None,
    db_path: Path = DEFAULT_DB,
    miner_path: Path = DEFAULT_MINER_REPORT,
) -> dict[str, Any]:
    exposures = exposure_lookup(exposure_profiles)
    rejected_pairs = rejected_pair_lookup(prior_package_reports or [])
    rejected_cut_counts = Counter(cut for _candidate, cut in rejected_pairs)
    deck_cards = deck_card_lookup(conn)
    pair_rows: list[dict[str, Any]] = []
    for pairing in hand_filter_pairings(miner_report):
        for cut_option in pairing.get("cut_options") or []:
            pair_rows.append(
                classify_pair(
                    pairing=pairing,
                    cut_option=cut_option,
                    deck_cards=deck_cards,
                    exposures=exposures,
                    rejected_pairs=rejected_pairs,
                    rejected_cut_counts=rejected_cut_counts,
                )
            )
    pair_rows.sort(key=lambda row: (-int(row["score"]), row["status"], row["candidate"], row["cut"]))
    status_counts = Counter(str(row["status"]) for row in pair_rows)
    preflight_rows = [row for row in pair_rows if row["status"] == "preflight_benchmark_ready"]
    return {
        "generated_at": utc_now(),
        "source_db": str(db_path),
        "miner_report": str(miner_path),
        "exposure_profiles": [str(path) for path, _payload in exposure_profiles],
        "prior_package_reports": [str(path) for path, _payload in (prior_package_reports or [])],
        "postgres_writes": False,
        "source_db_mutated": False,
        "summary": {
            "candidate_count": len({row["candidate"] for row in pair_rows}),
            "evaluated_pair_count": len(pair_rows),
            "preflight_benchmark_ready_count": len(preflight_rows),
            "prior_rejected_pair_count": len(rejected_pairs),
            "prior_rejected_cut_counts": dict(sorted(rejected_cut_counts.items())),
            "status_counts": dict(sorted(status_counts.items())),
            "recommended_next_action": (
                f"preflight_{preflight_rows[0]['candidate']}_over_{preflight_rows[0]['cut']}"
                if preflight_rows
                else "do_not_gate_hand_filter_without_new_cut_or_runtime_evidence"
            ),
        },
        "preflight_benchmark_candidates": preflight_rows[:5],
        "top_pair_evaluations": pair_rows[:25],
        "pair_evaluations": pair_rows,
        "guardrails": [
            {
                "guardrail_key": "do_not_cut_high_exposure_draw_or_wincon",
                "reason": "Esper Sentinel, Monument to Endurance, and Rise of the Eldrazi have high measured exposure or core wincon roles.",
            },
            {
                "guardrail_key": "big_score_is_benchmark_only",
                "reason": "Big Score is the least-exposed visible cut, but it still provides discard, draw, treasures, and miracle density.",
            },
        ],
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Hand Filter Cut Model - 2026-06-28",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Source DB: `{payload['source_db']}`",
        f"- Miner report: `{payload['miner_report']}`",
        f"- Exposure profiles: `{', '.join(payload['exposure_profiles'])}`",
        f"- Prior package reports: `{', '.join(payload.get('prior_package_reports') or []) or '-'}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
        "",
        "## Summary",
        "",
        f"- Candidate count: `{payload['summary']['candidate_count']}`",
        f"- Evaluated pairs: `{payload['summary']['evaluated_pair_count']}`",
        f"- Preflight benchmark-ready pairs: `{payload['summary']['preflight_benchmark_ready_count']}`",
        f"- Prior rejected exact pairs: `{payload['summary']['prior_rejected_pair_count']}`",
        f"- Prior rejected cut counts: `{json.dumps(payload['summary']['prior_rejected_cut_counts'], sort_keys=True)}`",
        f"- Status counts: `{json.dumps(payload['summary']['status_counts'], sort_keys=True)}`",
        f"- Recommended next action: `{payload['summary']['recommended_next_action']}`",
        "",
        "## Preflight Benchmark Candidates",
        "",
    ]
    if not payload["preflight_benchmark_candidates"]:
        lines.append("- None.")
    else:
        lines.extend(
            [
                "| Rank | Candidate | Cut | Score | Candidate Exposure | Cut Exposure | Blockers |",
                "| ---: | --- | --- | ---: | ---: | ---: | --- |",
            ]
        )
        for index, row in enumerate(payload["preflight_benchmark_candidates"], start=1):
            lines.append(
                "| {rank} | {candidate} | {cut} | {score} | {candidate_exposure} | {cut_exposure} | {blockers} |".format(
                    rank=index,
                    candidate=row["candidate"],
                    cut=row["cut"],
                    score=row["score"],
                    candidate_exposure=row["candidate_exposure"]["unique_exposure_count"],
                    cut_exposure=row["cut_exposure"]["unique_exposure_count"],
                    blockers="; ".join(row["blockers"]) or "none",
                )
            )
    lines.extend(
        [
            "",
            "## Top Pair Evaluations",
            "",
            "| Rank | Candidate | Cut | Status | Score | Candidate Role | Cut Role | Cut Exposure | Blockers |",
            "| ---: | --- | --- | --- | ---: | --- | --- | ---: | --- |",
        ]
    )
    for index, row in enumerate(payload["top_pair_evaluations"], start=1):
        cut_role = row["cut_metadata"].get("functional_tag") or row["cut_exposure"].get("inferred_role")
        lines.append(
            "| {rank} | {candidate} | {cut} | `{status}` | {score} | `{candidate_role}` | `{cut_role}` | {cut_exposure} | {blockers} |".format(
                rank=index,
                candidate=row["candidate"],
                cut=row["cut"],
                status=row["status"],
                score=row["score"],
                candidate_role=row["candidate_exposure"]["inferred_role"],
                cut_role=cut_role,
                cut_exposure=row["cut_exposure"]["unique_exposure_count"],
                blockers="; ".join(row["blockers"]) or "none",
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
    parser.add_argument("--miner-report", type=Path, default=DEFAULT_MINER_REPORT)
    parser.add_argument("--exposure-profile", type=Path, action="append")
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--stem", default="lorehold_hand_filter_cut_model_20260628_v4_current_miner")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    exposure_paths = args.exposure_profile or DEFAULT_EXPOSURE_PROFILES
    exposure_profiles = read_existing_json(exposure_paths)
    prior_package_reports = read_existing_json(
        args.prior_package_report or DEFAULT_PRIOR_PACKAGE_REPORTS
    )
    miner_report = read_json(args.miner_report)
    with connect(args.db) as conn:
        payload = build_model(
            conn=conn,
            miner_report=miner_report,
            exposure_profiles=exposure_profiles,
            prior_package_reports=prior_package_reports,
            db_path=args.db,
            miner_path=args.miner_report,
        )
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(payload["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
