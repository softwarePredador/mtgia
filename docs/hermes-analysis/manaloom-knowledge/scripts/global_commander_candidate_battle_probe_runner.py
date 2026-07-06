#!/usr/bin/env python3
"""Run and normalize a global Commander candidate battle probe.

This script is a bridge between the equal-sample battle gate and
`global_commander_candidate_battle_probe_audit.py`. It does not promote decks,
does not mutate PostgreSQL, and does not edit source SQLite databases. It runs
the existing small battle probe, writes the base/candidate metrics JSON files
expected by the audit, and prepares one structured replay directory with fixed
file names.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections.abc import Callable, Mapping, Sequence
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


SCRIPT_DIR = Path(__file__).resolve().parent
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_STRATEGY_REPORT = (
    REPORT_DIR / "global_commander_candidate_package_strategy_matrix_20260706_lorehold_profile_repair_package.json"
)
DEFAULT_OUT_PREFIX = (
    REPORT_DIR / "global_commander_candidate_battle_probe_runner_20260706_lorehold_profile_repair_package"
)
DEFAULT_REPLAY_DIR = (
    REPORT_DIR / "global_commander_candidate_battle_probe_runner_20260706_lorehold_profile_repair_package_replay"
)
DEFAULT_BATTLE_GATE = SCRIPT_DIR / "lorehold_variant_battle_gate.py"
DEFAULT_BATTLE_REPLAY = SCRIPT_DIR / "battle_replay_v10_3.py"
DEFAULT_BATTLE_STEM = "global_commander_candidate_battle_probe_gate_20260706_lorehold_profile_repair_package"
DEFAULT_CANDIDATE_KEY = "candidate_profile_repair_package"
REPLAY_EVENT_FILES = (
    "replay.events.jsonl",
    "replay.decision_trace.jsonl",
    "deck_provenance.json",
)


Runner = Callable[..., subprocess.CompletedProcess[str]]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def safe_rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def repo_path(value: Any) -> Path:
    path = Path(str(value))
    return path if path.is_absolute() else REPO_ROOT / path


def load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def write_json(path: Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def strategy_inputs(strategy_report: Path) -> dict[str, Any]:
    payload = load_json(strategy_report)
    summary = payload.get("summary") or {}
    artifacts = payload.get("input_artifacts") or {}
    deck_id = int(summary.get("deck_id") or payload.get("deck_id") or 0)
    if not deck_id:
        raise ValueError(f"strategy report has no deck_id: {strategy_report}")
    base_db = artifacts.get("base_db")
    candidate_db = artifacts.get("candidate_db")
    if not base_db or not candidate_db:
        raise ValueError(f"strategy report has no base_db/candidate_db: {strategy_report}")
    package_adds = [str(card) for card in summary.get("net_package_adds") or summary.get("package_adds") or []]
    package_cuts = [str(card) for card in summary.get("net_package_cuts") or summary.get("package_cuts") or []]
    commander = str(summary.get("commander") or payload.get("commander") or "")
    return {
        "strategy_report": strategy_report,
        "deck_id": deck_id,
        "commander": commander,
        "package_adds": package_adds,
        "package_cuts": package_cuts,
        "base_db": repo_path(base_db),
        "candidate_db": repo_path(candidate_db),
        "source_status": payload.get("status"),
        "next_gate": summary.get("next_gate"),
    }


def battle_gate_command(
    *,
    battle_gate: Path,
    base_db: Path,
    candidate_db: Path,
    deck_id: int,
    commander: str,
    candidate_key: str,
    battle_stem: str,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    fixed_opponent_deck_ids: str | None,
    simulation_seed: int,
    game_timeout_seconds: float,
    deck_process_timeout_seconds: float,
) -> list[str]:
    command = [
        sys.executable,
        str(battle_gate),
        "--db",
        str(base_db),
        "--deck-ids",
        str(deck_id),
        "--candidate-db",
        str(candidate_db),
        "--candidate-deck-id",
        str(deck_id),
        "--candidate-key",
        candidate_key,
        "--candidate-name",
        f"{commander or f'Deck {deck_id}'} profile repair package candidate",
        "--candidate-archetype",
        "profile-repair-package",
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
        "--deck-process-timeout-seconds",
        str(max(0.0, deck_process_timeout_seconds)),
        "--isolate-deck-process",
        "--stem",
        battle_stem,
        "--checkpoint-stem",
        f"{battle_stem}_checkpoint",
    ]
    if fixed_opponent_deck_ids:
        command.extend(["--fixed-opponent-deck-ids", fixed_opponent_deck_ids])
    return command


def replay_command(*, battle_replay: Path) -> list[str]:
    return [sys.executable, str(battle_replay)]


def focus_env(package_adds: Sequence[str], base_env: Mapping[str, str] | None = None) -> dict[str, str]:
    env = dict(base_env or os.environ)
    env["MANALOOM_FOCUS_ACCESS_CARDS"] = json.dumps(list(package_adds), sort_keys=True)
    return env


def replay_env(
    *,
    candidate_db: Path,
    deck_id: int,
    replay_dir: Path,
    package_adds: Sequence[str],
    real_opponent_seed: int,
    replay_seed: int,
    base_env: Mapping[str, str] | None = None,
) -> dict[str, str]:
    env = focus_env(package_adds, base_env=base_env)
    replay_dir.mkdir(parents=True, exist_ok=True)
    env.update(
        {
            "MANALOOM_KNOWLEDGE_DB": str(candidate_db),
            "MANALOOM_BATTLE_TARGET_DECK_ID": str(deck_id),
            "MANALOOM_BATTLE_REAL_OPPONENT_SEED": str(real_opponent_seed),
            "REPLAY_SEED": str(replay_seed),
            "REPLAY_OUT": str(replay_dir / "replay.txt"),
            "REPLAY_EVENTS_OUT": str(replay_dir / "replay.events.jsonl"),
            "DECISION_TRACE_OUT": str(replay_dir / "replay.decision_trace.jsonl"),
            "REPLAY_DECK_PROVENANCE_OUT": str(replay_dir / "deck_provenance.json"),
        }
    )
    return env


def run_command(
    command: Sequence[str],
    *,
    env: Mapping[str, str],
    timeout: float,
    runner: Runner = subprocess.run,
) -> subprocess.CompletedProcess[str]:
    return runner(
        list(command),
        cwd=str(REPO_ROOT),
        env=dict(env),
        text=True,
        capture_output=True,
        timeout=timeout if timeout > 0 else None,
    )


def result_by_key(gate_payload: Mapping[str, Any], key: str) -> dict[str, Any]:
    for result in gate_payload.get("results") or []:
        if isinstance(result, Mapping) and str(result.get("deck_key") or "") == key:
            return dict(result)
    return {}


def metric_payload(
    *,
    gate_payload: Mapping[str, Any],
    result: Mapping[str, Any],
    commander: str,
    source_gate_report: Path,
    role: str,
) -> dict[str, Any]:
    telemetry = result.get("telemetry") if isinstance(result.get("telemetry"), Mapping) else {}
    wins = int(result.get("wins") or 0)
    losses = int(result.get("losses") or 0)
    stalls = int(result.get("stalls") or 0)
    games = int(result.get("games") or wins + losses + stalls)
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_candidate_battle_probe_runner_metric",
        "metric_role": role,
        "metadata": {
            "win_rate": float(result.get("win_rate") or 0.0),
            "wins": wins,
            "losses": losses,
            "stalls": stalls,
            "total_games": games,
            "games_per_opponent": int(gate_payload.get("games_per_opponent") or 0),
            "opponents": len(gate_payload.get("opponents") or []),
            "opponent_kind": gate_payload.get("opponent_kind"),
            "evaluation_mode": "equal_seed_battle_probe",
            "evaluation_target_player": commander,
        },
        "event_counts": telemetry.get("event_counts") or {},
        "strategic_event_counts": telemetry.get("strategic_event_counts") or {},
        "card_event_counts": telemetry.get("card_event_counts") or {},
        "warnings": [],
        "source_result": dict(result),
        "source_gate_report": safe_rel(source_gate_report),
    }


def command_summary(result: subprocess.CompletedProcess[str], command: Sequence[str]) -> dict[str, Any]:
    return {
        "command": " ".join(str(part) for part in command),
        "returncode": int(result.returncode),
        "stdout_tail": (result.stdout or "")[-4000:],
        "stderr_tail": (result.stderr or "")[-4000:],
    }


def replay_files_ready(replay_dir: Path) -> bool:
    return all((replay_dir / name).exists() for name in REPLAY_EVENT_FILES)


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Candidate Battle Probe Runner",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- commander: `{summary['commander']}`",
        f"- battle_probe_audit_ready: `{str(payload['battle_probe_audit_ready']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- source_db_mutated: `{str(payload['source_db_mutated']).lower()}`",
        "",
        "## Metrics",
        "",
        f"- base_metrics: `{payload['output_artifacts'].get('base_metrics')}`",
        f"- candidate_metrics: `{payload['output_artifacts'].get('candidate_metrics')}`",
        f"- base_wr: `{summary.get('base_win_rate')}`",
        f"- candidate_wr: `{summary.get('candidate_win_rate')}`",
        f"- win_rate_delta: `{summary.get('win_rate_delta')}`",
        "",
        "## Replay",
        "",
        f"- replay_dir: `{payload['output_artifacts'].get('replay_dir')}`",
        f"- replay_files_ready: `{str(payload['replay_files_ready']).lower()}`",
        "",
        "## Blockers",
        "",
    ]
    blockers = payload.get("blocker_reasons") or []
    if blockers:
        lines.extend(f"- `{reason}`" for reason in blockers)
    else:
        lines.append("- none")
    lines.extend(["", "## Next Gate", "", f"- `{summary.get('next_gate')}`"])
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], out_prefix: Path) -> tuple[Path, Path]:
    out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = out_prefix.with_suffix(".json")
    md_path = out_prefix.with_suffix(".md")
    write_json(json_path, payload)
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def build_payload(
    *,
    strategy_report: Path,
    out_prefix: Path,
    replay_dir: Path,
    battle_gate: Path,
    battle_replay: Path,
    battle_stem: str,
    candidate_key: str,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    fixed_opponent_deck_ids: str | None,
    simulation_seed: int,
    real_opponent_seed: int,
    replay_seed: int,
    game_timeout_seconds: float,
    deck_process_timeout_seconds: float,
    timeout: float,
    report_dir: Path = REPORT_DIR,
    runner: Runner = subprocess.run,
) -> dict[str, Any]:
    inputs = strategy_inputs(strategy_report)
    base_metrics = out_prefix.with_name(f"{out_prefix.name}_base_metrics.json")
    candidate_metrics = out_prefix.with_name(f"{out_prefix.name}_candidate_metrics.json")
    gate_report = report_dir / f"{battle_stem}.json"
    gate_cmd = battle_gate_command(
        battle_gate=battle_gate,
        base_db=inputs["base_db"],
        candidate_db=inputs["candidate_db"],
        deck_id=inputs["deck_id"],
        commander=inputs["commander"],
        candidate_key=candidate_key,
        battle_stem=battle_stem,
        games=games,
        opponent_limit=opponent_limit,
        opponent_seed=opponent_seed,
        fixed_opponent_deck_ids=fixed_opponent_deck_ids,
        simulation_seed=simulation_seed,
        game_timeout_seconds=game_timeout_seconds,
        deck_process_timeout_seconds=deck_process_timeout_seconds,
    )
    gate_result = run_command(
        gate_cmd,
        env=focus_env(inputs["package_adds"]),
        timeout=timeout,
        runner=runner,
    )
    blockers: list[str] = []
    if gate_result.returncode != 0:
        blockers.append("battle_gate_command_failed")
    if not gate_report.exists():
        blockers.append("battle_gate_report_missing")
        gate_payload: dict[str, Any] = {}
    else:
        gate_payload = load_json(gate_report)

    base_result = result_by_key(gate_payload, f"deck_{inputs['deck_id']}")
    candidate_result = result_by_key(gate_payload, candidate_key)
    if not base_result:
        blockers.append("base_result_missing_from_battle_gate")
    if not candidate_result:
        blockers.append("candidate_result_missing_from_battle_gate")
    if base_result and candidate_result:
        write_json(
            base_metrics,
            metric_payload(
                gate_payload=gate_payload,
                result=base_result,
                commander=inputs["commander"],
                source_gate_report=gate_report,
                role="base",
            ),
        )
        write_json(
            candidate_metrics,
            metric_payload(
                gate_payload=gate_payload,
                result=candidate_result,
                commander=inputs["commander"],
                source_gate_report=gate_report,
                role="candidate",
            ),
        )

    replay_cmd = replay_command(battle_replay=battle_replay)
    replay_result = run_command(
        replay_cmd,
        env=replay_env(
            candidate_db=inputs["candidate_db"],
            deck_id=inputs["deck_id"],
            replay_dir=replay_dir,
            package_adds=inputs["package_adds"],
            real_opponent_seed=real_opponent_seed,
            replay_seed=replay_seed,
        ),
        timeout=timeout,
        runner=runner,
    )
    if replay_result.returncode != 0:
        blockers.append("battle_replay_command_failed")
    if not replay_files_ready(replay_dir):
        blockers.append("battle_replay_files_missing")

    ready = not blockers and base_metrics.exists() and candidate_metrics.exists()
    base_wr = float(base_result.get("win_rate") or 0.0) if base_result else None
    candidate_wr = float(candidate_result.get("win_rate") or 0.0) if candidate_result else None
    delta = candidate_wr - base_wr if base_wr is not None and candidate_wr is not None else None
    return {
        "generated_at": utc_now(),
        "artifact_type": "global_commander_candidate_battle_probe_runner",
        "status": "candidate_battle_probe_inputs_ready" if ready else "candidate_battle_probe_inputs_blocked",
        "battle_probe_audit_ready": bool(ready),
        "battle_or_optimization_performed": True,
        "battle_replay_performed": replay_result.returncode == 0,
        "promotion_allowed": False,
        "source_db_mutated": False,
        "postgres_writes": False,
        "summary": {
            "deck_id": inputs["deck_id"],
            "commander": inputs["commander"],
            "package_adds": inputs["package_adds"],
            "package_cuts": inputs["package_cuts"],
            "base_win_rate": base_wr,
            "candidate_win_rate": candidate_wr,
            "win_rate_delta": delta,
            "sample_games": int(candidate_result.get("games") or 0) if candidate_result else 0,
            "next_gate": "run_global_commander_candidate_battle_probe_audit" if ready else "repair_battle_probe_inputs",
        },
        "input_artifacts": {
            "strategy_report": safe_rel(strategy_report),
            "base_db": safe_rel(inputs["base_db"]),
            "candidate_db": safe_rel(inputs["candidate_db"]),
            "battle_gate": safe_rel(battle_gate),
            "battle_replay": safe_rel(battle_replay),
        },
        "output_artifacts": {
            "battle_gate_report": safe_rel(gate_report),
            "base_metrics": safe_rel(base_metrics),
            "candidate_metrics": safe_rel(candidate_metrics),
            "replay_dir": safe_rel(replay_dir),
        },
        "commands": {
            "battle_gate": command_summary(gate_result, gate_cmd),
            "battle_replay": command_summary(replay_result, replay_cmd),
        },
        "replay_files_ready": replay_files_ready(replay_dir),
        "blocker_reasons": blockers,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strategy-report", type=Path, default=DEFAULT_STRATEGY_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    parser.add_argument("--replay-dir", type=Path, default=DEFAULT_REPLAY_DIR)
    parser.add_argument("--battle-gate", type=Path, default=DEFAULT_BATTLE_GATE)
    parser.add_argument("--battle-replay", type=Path, default=DEFAULT_BATTLE_REPLAY)
    parser.add_argument("--battle-stem", default=DEFAULT_BATTLE_STEM)
    parser.add_argument("--candidate-key", default=DEFAULT_CANDIDATE_KEY)
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=1)
    parser.add_argument("--opponent-seed", type=int, default=20260706)
    parser.add_argument("--fixed-opponent-deck-ids", default=None)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--real-opponent-seed", type=int, default=20260706)
    parser.add_argument("--replay-seed", type=int, default=42)
    parser.add_argument("--game-timeout-seconds", type=float, default=30.0)
    parser.add_argument("--deck-process-timeout-seconds", type=float, default=120.0)
    parser.add_argument("--timeout", type=float, default=300.0)
    args = parser.parse_args()
    payload = build_payload(
        strategy_report=args.strategy_report,
        out_prefix=args.out_prefix,
        replay_dir=args.replay_dir,
        battle_gate=args.battle_gate,
        battle_replay=args.battle_replay,
        battle_stem=args.battle_stem,
        candidate_key=args.candidate_key,
        games=args.games,
        opponent_limit=args.opponent_limit,
        opponent_seed=args.opponent_seed,
        fixed_opponent_deck_ids=args.fixed_opponent_deck_ids,
        simulation_seed=args.simulation_seed,
        real_opponent_seed=args.real_opponent_seed,
        replay_seed=args.replay_seed,
        game_timeout_seconds=args.game_timeout_seconds,
        deck_process_timeout_seconds=args.deck_process_timeout_seconds,
        timeout=args.timeout,
    )
    json_path, md_path = write_outputs(payload, args.out_prefix)
    print(
        json.dumps(
            {
                "status": payload["status"],
                "battle_probe_audit_ready": payload["battle_probe_audit_ready"],
                "json": str(json_path),
                "markdown": str(md_path),
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
