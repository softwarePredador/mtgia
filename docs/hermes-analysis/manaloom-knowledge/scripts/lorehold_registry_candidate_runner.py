#!/usr/bin/env python3
"""Run the Lorehold candidate queue from the hypothesis registry.

The runner is intentionally conservative: registry entries with TBD swaps are
reported as blocked until a matching same-function plan exists in
``lorehold_607_research_candidate.RESEARCH_PLANS``.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

import lorehold_607_research_candidate as research


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REGISTRY = REPORT_DIR / "lorehold_candidate_hypothesis_registry_20260626.json"
DEFAULT_SOURCE_DB = SCRIPT_DIR / "knowledge.db"
PRIORITY_RANK = {"P0": 0, "P1": 1, "P2": 2, "P3": 3, "P4": 4}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_registry(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"registry not found: {path}")
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"registry must be a JSON object: {path}")
    return payload


def queue_entries(registry: Mapping[str, Any]) -> list[dict[str, Any]]:
    entries = registry.get("untested_queue") or []
    if not isinstance(entries, list):
        return []
    ranked: list[tuple[int, int, dict[str, Any]]] = []
    for idx, entry in enumerate(entries):
        if not isinstance(entry, dict):
            continue
        priority = str(entry.get("priority") or "P9").upper()
        ranked.append((PRIORITY_RANK.get(priority, 99), idx, dict(entry)))
    return [entry for _, _, entry in sorted(ranked, key=lambda item: (item[0], item[1]))]


def plan_name_for_candidate_key(key: str) -> str | None:
    prefixes = ("candidate_607_", "candidate_")
    for prefix in prefixes:
        if key.startswith(prefix):
            candidate = key[len(prefix) :]
            if candidate in research.RESEARCH_PLANS:
                return candidate
    return key if key in research.RESEARCH_PLANS else None


def classify_entry(entry: Mapping[str, Any]) -> dict[str, Any]:
    key = str(entry.get("key") or "")
    swap_or_scope = str(entry.get("swap_or_scope") or "")
    plan = plan_name_for_candidate_key(key)
    if "TBD" in swap_or_scope.upper():
        return {
            "key": key,
            "status": "blocked_tbd_swap",
            "plan": plan,
            "reason": "registry entry still has TBD same-function cut",
        }
    if not plan:
        return {
            "key": key,
            "status": "blocked_missing_plan",
            "plan": None,
            "reason": "no matching RESEARCH_PLANS entry",
        }
    return {
        "key": key,
        "status": "ready",
        "plan": plan,
        "reason": "matching executable research plan found",
    }


def command_payloads(
    *,
    plan: str,
    python: str,
    source_db: Path,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
    game_timeout_seconds: float,
    stem: str,
) -> dict[str, Any]:
    candidate_out_dir = REPORT_DIR / f"lorehold_607_research_candidate_20260626_{plan}"
    candidate_db = candidate_out_dir / "knowledge_candidate.db"
    gate_stem = f"{stem}_{plan}_gate"
    candidate_cmd = [
        python,
        str(SCRIPT_DIR / "lorehold_607_research_candidate.py"),
        "--source-db",
        str(source_db),
        "--plan",
        plan,
        "--out-dir",
        str(candidate_out_dir),
    ]
    gate_cmd = [
        python,
        str(SCRIPT_DIR / "lorehold_variant_battle_gate.py"),
        "--db",
        str(source_db),
        "--deck-ids",
        "607",
        "--candidate-db",
        str(candidate_db),
        "--candidate-key",
        f"candidate_607_{plan}",
        "--candidate-name",
        f"Lorehold 607 Research Candidate {plan}",
        "--candidate-archetype",
        "research-candidate",
        "--games",
        str(max(1, games)),
        "--opponent-limit",
        str(max(1, opponent_limit)),
        "--opponent-seed",
        str(opponent_seed),
        "--simulation-seed",
        str(simulation_seed),
        "--game-timeout-seconds",
        str(max(0.0, game_timeout_seconds)),
        "--stem",
        gate_stem,
    ]
    return {
        "candidate_out_dir": str(candidate_out_dir),
        "candidate_db": str(candidate_db),
        "gate_stem": gate_stem,
        "candidate_command": candidate_cmd,
        "gate_command": gate_cmd,
    }


def run_command(cmd: list[str]) -> dict[str, Any]:
    completed = subprocess.run(
        cmd,
        cwd=str(SCRIPT_DIR),
        check=False,
        capture_output=True,
        text=True,
    )
    return {
        "command": cmd,
        "returncode": completed.returncode,
        "stdout_tail": completed.stdout[-4000:],
        "stderr_tail": completed.stderr[-4000:],
    }


def render_markdown(report: Mapping[str, Any]) -> str:
    lines = [
        "# Lorehold Registry Candidate Runner",
        "",
        f"- generated_at: `{report['generated_at']}`",
        f"- registry: `{report['registry']}`",
        f"- execute: `{report['execute']}`",
        f"- max_candidates: `{report['max_candidates']}`",
        f"- status: `{report['status']}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        "",
        "## Queue Results",
        "",
        "| Key | Priority | Status | Plan | Reason |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in report.get("results") or []:
        lines.append(
            f"| `{row.get('key')}` | {row.get('priority')} | `{row.get('status')}` | "
            f"`{row.get('plan') or ''}` | {row.get('reason')} |"
        )
    for row in report.get("results") or []:
        commands = row.get("commands") or {}
        if not commands:
            continue
        lines.extend(["", f"## Commands For `{row.get('key')}`", ""])
        lines.append("```bash")
        lines.append(" ".join(commands.get("candidate_command") or []))
        lines.append(" ".join(commands.get("gate_command") or []))
        lines.append("```")
    return "\n".join(lines) + "\n"


def write_report(report: Mapping[str, Any], stem: str) -> tuple[Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    return json_path, md_path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--source-db", type=Path, default=DEFAULT_SOURCE_DB)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--max-candidates", type=int, default=1)
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--game-timeout-seconds", type=float, default=30.0)
    parser.add_argument("--stem", default="lorehold_registry_candidate_runner_20260626")
    args = parser.parse_args()

    registry = load_registry(args.registry)
    selected = queue_entries(registry)[: max(1, args.max_candidates)]
    results: list[dict[str, Any]] = []
    for entry in selected:
        classification = classify_entry(entry)
        row = {
            **entry,
            **classification,
        }
        if classification["status"] == "ready":
            commands = command_payloads(
                plan=str(classification["plan"]),
                python=sys.executable,
                source_db=args.source_db,
                games=args.games,
                opponent_limit=args.opponent_limit,
                opponent_seed=args.opponent_seed,
                simulation_seed=args.simulation_seed,
                game_timeout_seconds=args.game_timeout_seconds,
                stem=args.stem,
            )
            row["commands"] = commands
            if args.execute:
                candidate_run = run_command(commands["candidate_command"])
                row["candidate_run"] = candidate_run
                if candidate_run["returncode"] == 0:
                    row["gate_run"] = run_command(commands["gate_command"])
                    row["status"] = (
                        "executed"
                        if row["gate_run"]["returncode"] == 0
                        else "gate_failed"
                    )
                else:
                    row["status"] = "candidate_generation_failed"
            else:
                row["status"] = "ready_dry_run"
        results.append(row)

    status = "ready"
    if any(str(row.get("status", "")).startswith("blocked") for row in results):
        status = "blocked"
    if any(str(row.get("status", "")).endswith("failed") for row in results):
        status = "failed"

    report = {
        "generated_at": utc_now(),
        "status": status,
        "registry": str(args.registry),
        "source_db": str(args.source_db),
        "execute": bool(args.execute),
        "max_candidates": max(1, args.max_candidates),
        "games": max(1, args.games),
        "opponent_limit": max(1, args.opponent_limit),
        "opponent_seed": args.opponent_seed,
        "simulation_seed": args.simulation_seed,
        "game_timeout_seconds": float(args.game_timeout_seconds or 0),
        "results": results,
    }
    json_path, md_path = write_report(report, args.stem)
    print(json.dumps({"status": status, "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0 if status != "failed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
