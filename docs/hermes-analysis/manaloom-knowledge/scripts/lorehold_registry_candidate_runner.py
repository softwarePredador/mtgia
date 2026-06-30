#!/usr/bin/env python3
"""Run the Lorehold candidate queue from the hypothesis registry.

The runner is intentionally conservative: registry entries with TBD swaps are
reported as blocked until a matching same-function plan exists in
``lorehold_607_research_candidate.RESEARCH_PLANS``.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping

import lorehold_607_research_candidate as research
import seventeenlands_battle_prior_compare as battle_prior


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_REGISTRY = REPORT_DIR / "lorehold_candidate_hypothesis_registry_20260626.json"
DEFAULT_SOURCE_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_BATTLE_PRIOR_JSON = (
    REPORT_DIR / "seventeenlands_replay_profile_lci_premierdraft_sample_20260628.json"
)
PRIORITY_RANK = {"P0": 0, "P1": 1, "P2": 2, "P3": 3, "P4": 4}
BATTLE_PRIOR_EVIDENCE_GAP_STATUSES = {
    "inconclusive_candidate_not_used",
    "inconclusive_candidate_unobserved",
    "needs_more_evidence",
}
BATTLE_PRIOR_WARNING_STATUSES = {"battle_prior_warning"}


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


def added_cards_for_plan(plan: str) -> list[str]:
    payload = research.RESEARCH_PLANS.get(plan) or {}
    cards: list[str] = []
    for item in payload.get("added") or []:
        if isinstance(item, Mapping) and item.get("card_name"):
            cards.append(str(item["card_name"]))
    return cards


def focus_access_env(candidate_cards: list[str]) -> dict[str, str]:
    env = os.environ.copy()
    if candidate_cards:
        env["MANALOOM_FOCUS_ACCESS_CARDS"] = json.dumps(candidate_cards, ensure_ascii=False)
    return env


def extract_child_status(stdout: str) -> dict[str, Any]:
    decoder = json.JSONDecoder()
    text = str(stdout or "").strip()
    for index, char in enumerate(text):
        if char != "{":
            continue
        try:
            payload, end = decoder.raw_decode(text[index:])
        except json.JSONDecodeError:
            continue
        if text[index + end :].strip() == "" and isinstance(payload, dict):
            return payload
    return {}


def write_battle_prior_report(
    report: Mapping[str, Any],
    json_path: Path,
    md_path: Path,
) -> None:
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(battle_prior.stable_json(report) + "\n", encoding="utf-8")
    md_path.write_text(battle_prior.render_markdown(dict(report)), encoding="utf-8")


def battle_prior_summary(
    report: Mapping[str, Any],
    *,
    json_path: Path,
    md_path: Path,
) -> dict[str, Any]:
    comparison = report.get("comparison") or {}
    observed = report.get("observed_summary") or {}
    scoreability = report.get("candidate_scoreability") or {}
    candidate_observations = observed.get("candidate_observations") or {}
    if not isinstance(candidate_observations, Mapping):
        candidate_observations = {}
    return {
        "candidate_observations": candidate_observations,
        "candidate_scoreability": scoreability,
        "candidate_unused_cards": list(
            scoreability.get("candidate_accessed_not_used_cards") or []
        )
        + list(scoreability.get("candidate_near_access_only_cards") or []),
        "candidate_unobserved_cards": [
            card
            for card, payload in candidate_observations.items()
            if isinstance(payload, Mapping) and not payload.get("observed")
        ],
        "flags_count": len(comparison.get("flags") or []),
        "json": str(json_path),
        "markdown": str(md_path),
        "postgres_writes": False,
        "source_db_mutated": False,
        "status": report.get("status"),
    }


def classify_battle_prior_summary(prior_gate: Mapping[str, Any]) -> dict[str, str]:
    prior_status = str(prior_gate.get("status") or "")
    unobserved_cards = [str(card) for card in prior_gate.get("candidate_unobserved_cards") or []]
    unused_cards = [str(card) for card in prior_gate.get("candidate_unused_cards") or []]
    card_suffix = f": {', '.join(unobserved_cards[:3])}" if unobserved_cards else ""
    unused_suffix = f": {', '.join(unused_cards[:3])}" if unused_cards else ""
    if prior_status == "inconclusive_candidate_not_used":
        return {
            "next_action": "rerun_with_forced_focus_access_and_usage_or_inspect_play_heuristic",
            "reason": "candidate card was accessed or near-accessed but no direct use was observed; do not score or promote this swap"
            + unused_suffix,
            "status": "needs_more_evidence_candidate_not_used",
        }
    if prior_status in BATTLE_PRIOR_EVIDENCE_GAP_STATUSES or "inconclusive" in prior_status:
        return {
            "next_action": "rerun_with_forced_focus_access_or_larger_natural_sample_until_candidate_accessed",
            "reason": "candidate card was not accessed in the gate; do not score or promote this swap"
            + card_suffix,
            "status": "needs_more_evidence_candidate_unobserved",
        }
    if prior_status in BATTLE_PRIOR_WARNING_STATUSES or "warning" in prior_status:
        return {
            "next_action": "inspect_battle_prior_rhythm_flags_before_using_result",
            "reason": "candidate was observed, but the battle cadence is outside the 17Lands prior",
            "status": "battle_prior_warning",
        }
    if prior_status == "battle_prior_passed":
        return {
            "next_action": "eligible_for_strategy_review",
            "reason": "candidate was observed and battle-prior cadence passed",
            "status": "executed_battle_prior_passed",
        }
    if prior_status:
        return {
            "next_action": "inspect_unknown_battle_prior_status",
            "reason": f"unhandled battle-prior status: {prior_status}",
            "status": f"executed_{prior_status}",
        }
    return {
        "next_action": "rerun_battle_prior_gate",
        "reason": "battle-prior gate did not return a status",
        "status": "needs_more_evidence_missing_battle_prior_status",
    }


def aggregate_report_status(row_statuses: list[str]) -> str:
    status = "ready"
    if any("failed" in value for value in row_statuses):
        status = "failed"
    elif any(
        value.startswith("needs_more_evidence") or "inconclusive" in value
        for value in row_statuses
    ):
        status = "needs_more_evidence"
    elif any("warning" in value for value in row_statuses):
        status = "warning"
    elif any(value.startswith("blocked") for value in row_statuses):
        status = "blocked"
    return status


def command_payloads(
    *,
    plan: str,
    python: str,
    source_db: Path,
    battle_prior_json: Path,
    battle_prior_player_slots: int,
    candidate_cards: list[str],
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
    game_timeout_seconds: float,
    force_focus_access: str,
    stem: str,
) -> dict[str, Any]:
    plan_payload = research.RESEARCH_PLANS.get(plan) or {}
    candidate_deck_id = int(plan_payload.get("candidate_deck_id") or 607)
    candidate_out_dir = REPORT_DIR / f"lorehold_607_research_candidate_20260626_{plan}"
    candidate_db = candidate_out_dir / "knowledge_candidate.db"
    gate_stem = f"{stem}_{plan}_gate"
    gate_report_json = REPORT_DIR / f"{gate_stem}.json"
    battle_prior_stem = f"{gate_stem}_17lands_prior"
    battle_prior_json_path = REPORT_DIR / f"{battle_prior_stem}.json"
    battle_prior_md_path = REPORT_DIR / f"{battle_prior_stem}.md"
    candidate_key = f"candidate_607_{plan}"
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
        candidate_key,
        "--candidate-name",
        f"Lorehold 607 Research Candidate {plan}",
        "--candidate-archetype",
        "research-candidate",
        "--candidate-deck-id",
        str(candidate_deck_id),
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
        "--force-focus-access",
        force_focus_access,
        "--stem",
        gate_stem,
    ]
    battle_prior_cmd = [
        python,
        str(SCRIPT_DIR / "seventeenlands_battle_prior_compare.py"),
        "--prior-json",
        str(battle_prior_json),
        "--gate-report-json",
        str(gate_report_json),
        "--candidate-key",
        candidate_key,
        "--player-slots",
        str(max(1, battle_prior_player_slots)),
        "--output-json",
        str(battle_prior_json_path),
        "--output-md",
        str(battle_prior_md_path),
    ]
    for card in candidate_cards:
        battle_prior_cmd.extend(["--candidate-card", card])
    return {
        "battle_prior_command": battle_prior_cmd,
        "battle_prior_json": str(battle_prior_json_path),
        "battle_prior_markdown": str(battle_prior_md_path),
        "candidate_out_dir": str(candidate_out_dir),
        "candidate_db": str(candidate_db),
        "candidate_deck_id": candidate_deck_id,
        "candidate_key": candidate_key,
        "focus_access_cards": candidate_cards,
        "focus_access_env": json.dumps(candidate_cards, ensure_ascii=False),
        "gate_report_json": str(gate_report_json),
        "gate_stem": gate_stem,
        "candidate_command": candidate_cmd,
        "gate_command": gate_cmd,
    }


def run_command(cmd: list[str], *, env: Mapping[str, str] | None = None) -> dict[str, Any]:
    completed = subprocess.run(
        cmd,
        cwd=str(SCRIPT_DIR),
        check=False,
        capture_output=True,
        env=dict(env) if env is not None else None,
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
        "| Key | Priority | Status | Plan | Reason | Next Action |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for row in report.get("results") or []:
        lines.append(
            f"| `{row.get('key')}` | {row.get('priority')} | `{row.get('status')}` | "
            f"`{row.get('plan') or ''}` | {row.get('reason')} | "
            f"`{row.get('next_action') or ''}` |"
        )
    for row in report.get("results") or []:
        commands = row.get("commands") or {}
        if not commands:
            continue
        lines.extend(["", f"## Commands For `{row.get('key')}`", ""])
        lines.append("```bash")
        lines.append(" ".join(commands.get("candidate_command") or []))
        if commands.get("focus_access_env"):
            lines.append(
                "MANALOOM_FOCUS_ACCESS_CARDS="
                + json.dumps(commands.get("focus_access_cards") or [])
                + " "
                + " ".join(commands.get("gate_command") or [])
            )
        else:
            lines.append(" ".join(commands.get("gate_command") or []))
        if commands.get("battle_prior_command"):
            lines.append(" ".join(commands.get("battle_prior_command") or []))
        lines.append("```")
        prior_gate = row.get("battle_prior_gate") or {}
        if prior_gate:
            lines.extend(
                [
                    "",
                    f"- battle_prior_status: `{prior_gate.get('status')}`",
                    f"- battle_prior_json: `{prior_gate.get('json')}`",
                    f"- battle_prior_flags_count: `{prior_gate.get('flags_count')}`",
                ]
            )
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
    parser.add_argument(
        "--force-focus-access",
        choices=("none", "opening_hand", "library_top"),
        default="none",
    )
    parser.add_argument("--battle-prior-json", type=Path, default=DEFAULT_BATTLE_PRIOR_JSON)
    parser.add_argument("--battle-prior-player-slots", type=int, default=2)
    parser.add_argument("--skip-battle-prior-gate", action="store_true")
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
            candidate_cards = added_cards_for_plan(str(classification["plan"]))
            commands = command_payloads(
                plan=str(classification["plan"]),
                python=sys.executable,
                source_db=args.source_db,
                battle_prior_json=args.battle_prior_json,
                battle_prior_player_slots=args.battle_prior_player_slots,
                candidate_cards=candidate_cards,
                games=args.games,
                opponent_limit=args.opponent_limit,
                opponent_seed=args.opponent_seed,
                simulation_seed=args.simulation_seed,
                game_timeout_seconds=args.game_timeout_seconds,
                force_focus_access=args.force_focus_access,
                stem=args.stem,
            )
            row["commands"] = commands
            row["candidate_cards"] = candidate_cards
            if args.execute:
                candidate_run = run_command(commands["candidate_command"])
                row["candidate_run"] = candidate_run
                if candidate_run["returncode"] == 0:
                    row["gate_run"] = run_command(
                        commands["gate_command"],
                        env=focus_access_env(candidate_cards),
                    )
                    if row["gate_run"]["returncode"] != 0:
                        row["status"] = "gate_failed"
                    elif args.skip_battle_prior_gate:
                        row["status"] = "executed"
                        row["battle_prior_gate"] = {"status": "disabled"}
                    else:
                        child_status = extract_child_status(row["gate_run"].get("stdout_tail") or "")
                        gate_report_json = Path(
                            str(child_status.get("json") or commands["gate_report_json"])
                        )
                        battle_prior_json_path = Path(str(commands["battle_prior_json"]))
                        battle_prior_md_path = Path(str(commands["battle_prior_markdown"]))
                        if not gate_report_json.exists():
                            row["battle_prior_gate"] = {
                                "expected_gate_report_json": str(gate_report_json),
                                "status": "battle_prior_missing_gate_report",
                            }
                            row["status"] = "battle_prior_failed"
                        else:
                            prior_report = battle_prior.run_gate_report(
                                prior_path=args.battle_prior_json,
                                gate_report_path=gate_report_json,
                                candidate_key=str(commands["candidate_key"]),
                                candidate_cards=candidate_cards,
                                player_slots=max(1, args.battle_prior_player_slots),
                            )
                            write_battle_prior_report(
                                prior_report,
                                battle_prior_json_path,
                                battle_prior_md_path,
                            )
                            row["battle_prior_gate"] = battle_prior_summary(
                                prior_report,
                                json_path=battle_prior_json_path,
                                md_path=battle_prior_md_path,
                            )
                            prior_decision = classify_battle_prior_summary(row["battle_prior_gate"])
                            row["status"] = prior_decision["status"]
                            row["reason"] = prior_decision["reason"]
                            row["next_action"] = prior_decision["next_action"]
                else:
                    row["status"] = "candidate_generation_failed"
            else:
                row["battle_prior_gate"] = {
                    "candidate_cards": candidate_cards,
                    "prior_json": str(args.battle_prior_json),
                    "requires_execute": True,
                    "status": "pending_execute"
                    if not args.skip_battle_prior_gate
                    else "disabled",
                }
                row["status"] = "ready_dry_run"
        results.append(row)

    row_statuses = [str(row.get("status", "")) for row in results]
    status = aggregate_report_status(row_statuses)

    report = {
        "generated_at": utc_now(),
        "status": status,
        "registry": str(args.registry),
        "source_db": str(args.source_db),
        "battle_prior_gate_enabled": not args.skip_battle_prior_gate,
        "battle_prior_json": str(args.battle_prior_json),
        "battle_prior_player_slots": max(1, args.battle_prior_player_slots),
        "execute": bool(args.execute),
        "max_candidates": max(1, args.max_candidates),
        "games": max(1, args.games),
        "opponent_limit": max(1, args.opponent_limit),
        "opponent_seed": args.opponent_seed,
        "simulation_seed": args.simulation_seed,
        "game_timeout_seconds": float(args.game_timeout_seconds or 0),
        "force_focus_access": args.force_focus_access,
        "results": results,
    }
    json_path, md_path = write_report(report, args.stem)
    print(json.dumps({"status": status, "json": str(json_path), "markdown": str(md_path)}, indent=2))
    return 0 if status != "failed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
