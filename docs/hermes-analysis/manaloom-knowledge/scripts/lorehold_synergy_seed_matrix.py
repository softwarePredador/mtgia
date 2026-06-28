#!/usr/bin/env python3
"""Run Lorehold synergy packages across a deterministic seed matrix.

This script wraps ``lorehold_synergy_package_gate.py`` instead of duplicating
candidate DB mutation logic. It first filters package definitions through the
same cut-safety and prior-evidence checks, then executes each remaining package
for every requested simulation seed and writes one aggregate decision report.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import lorehold_synergy_package_gate as package_gate


DEFAULT_SEEDS = (7, 20260625, 42)
DEFAULT_STRONG_SEEDS = (42,)


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def parse_int_csv(value: str) -> list[int]:
    parsed: list[int] = []
    for item in str(value or "").split(","):
        item = item.strip()
        if not item:
            continue
        parsed.append(int(item))
    if not parsed:
        raise argparse.ArgumentTypeError("expected at least one integer")
    return parsed


def parse_package_keys(
    value: str,
    package_definitions: dict[str, dict[str, Any]] | None = None,
) -> list[str]:
    definitions = package_definitions or package_gate.PACKAGE_DEFINITIONS
    raw = [item.strip() for item in str(value or "").split(",") if item.strip()]
    if not raw or raw == ["all"]:
        return list(definitions)
    unknown = [key for key in raw if key not in definitions]
    if unknown:
        raise argparse.ArgumentTypeError(f"unknown package(s): {', '.join(unknown)}")
    return raw


def short_package_token(package_key: str, *, max_slug_length: int = 44) -> str:
    slug = "".join(ch if ch.isalnum() else "_" for ch in package_key.lower()).strip("_")
    slug = "_".join(part for part in slug.split("_") if part)
    digest = hashlib.sha1(package_key.encode("utf-8")).hexdigest()[:8]
    if len(slug) > max_slug_length:
        slug = slug[:max_slug_length].rstrip("_")
    return f"{slug}_{digest}"


def preflight_packages(
    package_keys: list[str],
    *,
    package_definitions: dict[str, dict[str, Any]],
    cut_safety: dict[str, Any],
    prior_results: dict[str, Any],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for package_key in package_keys:
        definition = package_definitions[package_key]
        cut_safety_result = package_gate.classify_package_cut_safety(definition, cut_safety)
        prior_result = package_gate.classify_package_prior_evidence(
            package_key,
            definition,
            prior_results,
        )
        status = "preflight_ready"
        if cut_safety_result["status"] == "blocked_cut_safety":
            status = "skipped_cut_safety"
        elif prior_result["status"] == "blocked_prior_reject":
            status = "skipped_prior_evidence"
        rows.append(
            {
                "package_key": package_key,
                "family": definition.get("family") or "misc",
                "hypothesis": definition["hypothesis"],
                "adds": list(definition.get("adds") or []),
                "cuts": list(definition.get("cuts") or []),
                "status": status,
                "cut_safety": compact_cut_safety(cut_safety_result),
                "prior_evidence": compact_prior_evidence(prior_result),
            }
        )
    return rows


def compact_cut_safety(value: dict[str, Any]) -> dict[str, Any]:
    return {
        "status": value.get("status"),
        "reason": value.get("reason"),
        "cuts": [
            {
                "card_name": row.get("card_name"),
                "status": row.get("status"),
                "current_lane": row.get("current_lane"),
                "effective_role": row.get("effective_role"),
                "worst_strong_seed_delta_pp": row.get("worst_strong_seed_delta_pp"),
                "best_delta_pp": row.get("best_delta_pp"),
            }
            for row in (value.get("cuts") or [])
            if isinstance(row, dict)
        ],
    }


def compact_prior_evidence(value: dict[str, Any]) -> dict[str, Any]:
    matches = [row for row in (value.get("matches") or []) if isinstance(row, dict)]
    latest = matches[-1] if matches else {}
    return {
        "status": value.get("status"),
        "reason": value.get("reason"),
        "match_count": len(matches),
        "latest_decision": latest.get("decision"),
        "latest_delta_pp": latest.get("delta_pp"),
        "latest_source_report": latest.get("source_report"),
    }


def compact_gate_side(value: dict[str, Any]) -> dict[str, Any]:
    telemetry = value.get("telemetry") or {}
    return {
        "status": value.get("status"),
        "error": value.get("error"),
        "games": value.get("games"),
        "wins": value.get("wins"),
        "losses": value.get("losses"),
        "stalls": value.get("stalls"),
        "win_rate": value.get("win_rate"),
        "avg_win_turn": value.get("avg_win_turn"),
        "telemetry": {
            "strategic_event_counts": telemetry.get("strategic_event_counts") or {},
            "top_cards": telemetry.get("top_cards") or [],
        },
    }


def compact_gate_summary(value: dict[str, Any]) -> dict[str, Any]:
    if not value:
        return {}
    return {
        "baseline": compact_gate_side(value.get("baseline") or {}),
        "candidate": compact_gate_side(value.get("candidate") or {}),
        "delta_pp": value.get("delta_pp"),
    }


def run_package_seed(
    *,
    package_key: str,
    seed: int,
    source_db: Path,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    game_timeout_seconds: float,
    deck_process_timeout_seconds: float,
    gate_timeout_seconds: float,
    stem: str,
    stamp: str,
    cut_safety_report: Path | None,
    prior_package_reports: list[Path],
    package_files: list[Path],
    ignore_prior_results: bool,
    no_game_checkpoint: bool,
) -> dict[str, Any]:
    run_stem = f"{stem}_seed{seed}_{short_package_token(package_key)}"
    report_json = package_gate.REPORT_DIR / f"{run_stem}_{stamp}.json"
    cmd = [
        sys.executable,
        str(package_gate.SCRIPT_DIR / "lorehold_synergy_package_gate.py"),
        "--source-db",
        str(source_db),
        "--packages",
        package_key,
        "--games",
        str(max(1, games)),
        "--opponent-limit",
        str(max(1, opponent_limit)),
        "--opponent-seed",
        str(opponent_seed),
        "--simulation-seed",
        str(seed),
        "--game-timeout-seconds",
        str(max(0.0, game_timeout_seconds)),
        "--deck-process-timeout-seconds",
        str(max(0.0, deck_process_timeout_seconds)),
        "--gate-timeout-seconds",
        str(max(0.0, gate_timeout_seconds)),
        "--stem",
        run_stem,
        "--stamp",
        stamp,
    ]
    if cut_safety_report is not None:
        cmd.extend(["--cut-safety-report", str(cut_safety_report)])
    for path in package_files:
        cmd.extend(["--package-file", str(path)])
    if ignore_prior_results:
        cmd.append("--ignore-prior-results")
    else:
        for path in prior_package_reports:
            cmd.extend(["--prior-package-report", str(path)])
    if no_game_checkpoint:
        cmd.append("--no-game-checkpoint")

    completed = subprocess.run(
        cmd,
        cwd=str(package_gate.REPO_ROOT),
        check=False,
        capture_output=True,
        text=True,
    )

    payload: dict[str, Any] = {}
    package_result: dict[str, Any] = {}
    if report_json.exists():
        payload = json.loads(report_json.read_text(encoding="utf-8"))
        packages = payload.get("packages") or []
        if packages:
            package_result = packages[0]

    gate_summary = compact_gate_summary(package_result.get("gate_summary") or {})
    return {
        "seed": seed,
        "status": package_result.get("status") or "missing_report",
        "gate_returncode": package_result.get("gate_returncode", completed.returncode),
        "gate_summary": gate_summary,
        "decision": package_gate.gate_decision(gate_summary) if gate_summary else "invalid_or_incomplete",
        "stdout_tail": completed.stdout[-1000:] if completed.returncode else "",
        "stderr_tail": completed.stderr[-1000:] if completed.returncode else "",
    }


def aggregate_seed_rows(
    package_key: str,
    seed_rows: list[dict[str, Any]],
    *,
    strong_seeds: set[int],
) -> dict[str, Any]:
    baseline_wins = 0
    baseline_losses = 0
    candidate_wins = 0
    candidate_losses = 0
    games = 0
    incomplete = []
    strong_regressions = []
    deltas: list[float] = []

    for row in seed_rows:
        gate_summary = row.get("gate_summary") or {}
        baseline = gate_summary.get("baseline") or {}
        candidate = gate_summary.get("candidate") or {}
        if not baseline or not candidate or row.get("gate_returncode") not in {0, None}:
            incomplete.append(row.get("seed"))
            continue
        baseline_wins += int(baseline.get("wins") or 0)
        baseline_losses += int(baseline.get("losses") or 0)
        candidate_wins += int(candidate.get("wins") or 0)
        candidate_losses += int(candidate.get("losses") or 0)
        games += int(candidate.get("games") or baseline.get("games") or 0)
        delta = float(gate_summary.get("delta_pp") or 0.0)
        deltas.append(delta)
        if int(row.get("seed") or -1) in strong_seeds:
            if int(candidate.get("wins") or 0) < int(baseline.get("wins") or 0) or delta < 0:
                strong_regressions.append(row.get("seed"))

    if incomplete:
        decision = "invalid_or_incomplete"
    elif strong_regressions:
        decision = "reject_regresses_strong_seed"
    elif candidate_wins > baseline_wins:
        decision = "promote_to_confirm_gate"
    elif candidate_wins == baseline_wins and all(delta >= 0 for delta in deltas):
        decision = "tie_hold_for_more_games"
    else:
        decision = "reject_or_rework"

    baseline_games = baseline_wins + baseline_losses
    candidate_games = candidate_wins + candidate_losses
    return {
        "package_key": package_key,
        "decision": decision,
        "baseline_record": f"{baseline_wins}-{baseline_losses}",
        "candidate_record": f"{candidate_wins}-{candidate_losses}",
        "baseline_win_rate": round((baseline_wins / baseline_games) * 100, 2) if baseline_games else 0.0,
        "candidate_win_rate": round((candidate_wins / candidate_games) * 100, 2) if candidate_games else 0.0,
        "delta_pp_total": round(
            ((candidate_wins / candidate_games) - (baseline_wins / baseline_games)) * 100,
            2,
        )
        if baseline_games and candidate_games
        else 0.0,
        "avg_seed_delta_pp": round(sum(deltas) / len(deltas), 2) if deltas else 0.0,
        "games": games,
        "incomplete_seeds": incomplete,
        "strong_seed_regressions": strong_regressions,
    }


def render_markdown(payload: dict[str, Any]) -> str:
    lines = [
        "# Lorehold Synergy Seed Matrix",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- source_db: `{payload['source_db']}`",
        f"- seeds: `{', '.join(str(seed) for seed in payload['seeds'])}`",
        f"- strong_seeds: `{', '.join(str(seed) for seed in payload['strong_seeds'])}`",
        f"- games_per_opponent: `{payload['games_per_opponent']}`",
        f"- opponent_limit: `{payload['opponent_limit']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        f"- package_status_counts: `{json.dumps(payload['package_status_counts'], sort_keys=True)}`",
        "",
        "## Aggregate Decisions",
        "",
        "| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |",
        "| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |",
    ]
    for row in payload["packages"]:
        aggregate = row.get("aggregate") or {}
        lines.append(
            "| {package} | {family} | {adds} | {cuts} | {base} | {candidate} | {delta:+.2f} | {avg:+.2f} | `{decision}` |".format(
                package=row["package_key"],
                family=row.get("family") or "-",
                adds=", ".join(row.get("adds") or []),
                cuts=", ".join(row.get("cuts") or []),
                base=aggregate.get("baseline_record") or "-",
                candidate=aggregate.get("candidate_record") or "-",
                delta=float(aggregate.get("delta_pp_total") or 0.0),
                avg=float(aggregate.get("avg_seed_delta_pp") or 0.0),
                decision=aggregate.get("decision") or row.get("status"),
            )
        )
    lines.extend(["", "## Seed Detail", ""])
    for row in payload["packages"]:
        lines.extend(["", f"### {row['package_key']}", ""])
        if row.get("status") != "matrix_run":
            lines.append(f"- status: `{row.get('status')}`")
            lines.append(f"- cut_safety: `{json.dumps(row.get('cut_safety') or {}, sort_keys=True)}`")
            lines.append(f"- prior_evidence: `{json.dumps(row.get('prior_evidence') or {}, sort_keys=True)}`")
            continue
        lines.append(f"- aggregate: `{json.dumps(row.get('aggregate') or {}, sort_keys=True)}`")
        lines.append("")
        lines.append("| Seed | Baseline | Candidate | Delta | Decision |")
        lines.append("| ---: | --- | --- | ---: | --- |")
        for seed_row in row.get("seed_results") or []:
            gate_summary = seed_row.get("gate_summary") or {}
            baseline = gate_summary.get("baseline") or {}
            candidate = gate_summary.get("candidate") or {}
            lines.append(
                "| {seed} | {bw}/{bl}/{bs} `{bwr:.2f}%` | {cw}/{cl}/{cs} `{cwr:.2f}%` | {delta:+.2f} | `{decision}` |".format(
                    seed=seed_row.get("seed"),
                    bw=baseline.get("wins", 0),
                    bl=baseline.get("losses", 0),
                    bs=baseline.get("stalls", 0),
                    bwr=float(baseline.get("win_rate") or 0.0),
                    cw=candidate.get("wins", 0),
                    cl=candidate.get("losses", 0),
                    cs=candidate.get("stalls", 0),
                    cwr=float(candidate.get("win_rate") or 0.0),
                    delta=float(gate_summary.get("delta_pp") or 0.0),
                    decision=seed_row.get("decision"),
                )
            )
    return "\n".join(lines).rstrip() + "\n"


def write_report(payload: dict[str, Any], stem: str, stamp: str) -> tuple[Path, Path]:
    package_gate.REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = package_gate.REPORT_DIR / f"{stem}_{stamp}.json"
    md_path = package_gate.REPORT_DIR / f"{stem}_{stamp}.md"
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-db", type=Path, default=package_gate.DEFAULT_SOURCE_DB)
    parser.add_argument("--packages", default="all")
    parser.add_argument("--max-packages", type=int, default=0)
    parser.add_argument("--seeds", default=",".join(str(seed) for seed in DEFAULT_SEEDS))
    parser.add_argument("--strong-seeds", default=",".join(str(seed) for seed in DEFAULT_STRONG_SEEDS))
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--game-timeout-seconds", type=float, default=20.0)
    parser.add_argument("--deck-process-timeout-seconds", type=float, default=180.0)
    parser.add_argument("--gate-timeout-seconds", type=float, default=600.0)
    parser.add_argument("--stem", default="lorehold_synergy_seed_matrix")
    parser.add_argument("--stamp", default=None)
    parser.add_argument("--cut-safety-report", type=Path, default=package_gate.DEFAULT_CUT_SAFETY_REPORT)
    parser.add_argument("--no-cut-safety", action="store_true")
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument(
        "--package-file",
        type=Path,
        action="append",
        default=[],
        help=(
            "External JSON package manifest with a packages list. "
            "Forwarded to lorehold_synergy_package_gate.py for each seed run."
        ),
    )
    parser.add_argument("--ignore-prior-results", action="store_true")
    parser.add_argument("--no-game-checkpoint", action="store_true")
    parser.add_argument("--preflight-only", action="store_true")
    args = parser.parse_args()

    package_files = [path.resolve() for path in args.package_file]
    package_definitions, loaded_package_files = package_gate.merge_package_definitions(package_files)
    package_keys = parse_package_keys(args.packages, package_definitions=package_definitions)
    seeds = parse_int_csv(args.seeds)
    strong_seeds = set(parse_int_csv(args.strong_seeds))
    if args.max_packages > 0:
        package_keys = package_keys[: args.max_packages]

    source_db = args.source_db.resolve()
    stamp = args.stamp or utc_stamp()
    cut_safety_report = None if args.no_cut_safety else args.cut_safety_report.resolve()
    cut_safety = package_gate.load_cut_safety_manifest(cut_safety_report)
    prior_package_reports = [] if args.ignore_prior_results else [
        path.resolve() for path in (args.prior_package_report or list(package_gate.DEFAULT_PRIOR_PACKAGE_REPORTS))
    ]
    prior_results = package_gate.load_prior_package_results(prior_package_reports)
    preflight_rows = preflight_packages(
        package_keys,
        package_definitions=package_definitions,
        cut_safety=cut_safety,
        prior_results=prior_results,
    )

    results: list[dict[str, Any]] = []
    for row in preflight_rows:
        if row["status"] != "preflight_ready" or args.preflight_only:
            results.append(row)
            continue
        seed_rows = [
            run_package_seed(
                package_key=row["package_key"],
                seed=seed,
                source_db=source_db,
                games=args.games,
                opponent_limit=args.opponent_limit,
                opponent_seed=args.opponent_seed,
                game_timeout_seconds=args.game_timeout_seconds,
                deck_process_timeout_seconds=args.deck_process_timeout_seconds,
                gate_timeout_seconds=args.gate_timeout_seconds,
                stem=args.stem,
                stamp=stamp,
                cut_safety_report=cut_safety_report,
                prior_package_reports=prior_package_reports,
                package_files=package_files,
                ignore_prior_results=args.ignore_prior_results,
                no_game_checkpoint=args.no_game_checkpoint,
            )
            for seed in seeds
        ]
        row = {
            **row,
            "status": "matrix_run",
            "seed_results": seed_rows,
            "aggregate": aggregate_seed_rows(
                row["package_key"],
                seed_rows,
                strong_seeds=strong_seeds,
            ),
        }
        results.append(row)

    status_counts: dict[str, int] = {}
    for row in results:
        status_counts[str(row.get("status") or "unknown")] = status_counts.get(str(row.get("status") or "unknown"), 0) + 1

    payload = {
        "generated_at": utc_now(),
        "source_db": str(source_db),
        "source_db_mutated": False,
        "postgres_writes": False,
        "seeds": seeds,
        "strong_seeds": sorted(strong_seeds),
        "games_per_opponent": max(1, args.games),
        "opponent_limit": max(1, args.opponent_limit),
        "opponent_seed": args.opponent_seed,
        "preflight_only": bool(args.preflight_only),
        "cut_safety_report": str(cut_safety_report) if cut_safety_report else None,
        "prior_package_reports": [str(path) for path in prior_package_reports],
        "loaded_package_files": loaded_package_files,
        "package_status_counts": dict(sorted(status_counts.items())),
        "packages": results,
    }
    json_path, md_path = write_report(payload, args.stem, stamp)
    print(json.dumps({"status": "ready", "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
