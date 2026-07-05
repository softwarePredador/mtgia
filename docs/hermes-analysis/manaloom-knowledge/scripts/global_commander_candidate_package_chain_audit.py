#!/usr/bin/env python3
"""Audit a chained isolated Commander candidate package.

This report does not run battles, mutate PostgreSQL, mutate the source DB, or
promote decks. It consolidates multiple one-swap materializer reports into a
single package-level readiness decision, then checks the final core-role and
strategy-readiness reports before allowing the next gate.
"""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from global_commander_deck_contract_audit import REPO_ROOT


REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"
DEFAULT_MATERIALIZER_REPORTS = [
    REPORT_DIR / "global_commander_candidate_copy_materializer_20260705_kaalia_path_archaeomancers_map_top_pair.json",
    REPORT_DIR / "global_commander_candidate_copy_materializer_20260705_kaalia_path_feed_package_step2.json",
    REPORT_DIR / "global_commander_candidate_copy_materializer_20260705_kaalia_path_feed_swords_package_step3.json",
    REPORT_DIR / "global_commander_candidate_copy_materializer_20260705_kaalia_path_feed_swords_rakdos_package_step4.json",
    REPORT_DIR / "global_commander_candidate_copy_materializer_20260705_kaalia_path_feed_swords_rakdos_terminate_package_step5.json",
]
DEFAULT_FINAL_CORE_REPORT = REPORT_DIR / "global_commander_core_role_audit_20260705_kaalia_removal_floor_package_step5_hermes_only.json"
DEFAULT_FINAL_STRATEGY_REPORT = REPORT_DIR / "global_commander_strategy_matrix_20260705_kaalia_removal_floor_package_step5_hermes_only.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "global_commander_candidate_package_chain_audit_20260705_kaalia_removal_floor_step5"


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


def materializer_steps(path: Path, payload: Mapping[str, Any]) -> list[dict[str, Any]]:
    summary = payload.get("summary") or {}
    source_pair_guard = payload.get("source_pair_guard") or {}
    source_matches_pair_report = bool(summary.get("source_matches_pair_report"))
    allow_chained_source = bool(source_pair_guard.get("allow_chained_source"))
    source_reference_accepted = source_matches_pair_report or allow_chained_source
    model_pairs = payload.get("model_pairs") or []
    if not isinstance(model_pairs, list) or not model_pairs:
        model_pairs = [
            {
                "add": summary.get("add"),
                "cut": summary.get("cut"),
                "role": summary.get("role"),
            }
        ]
    steps = []
    for index, pair in enumerate(model_pairs, start=1):
        if not isinstance(pair, Mapping):
            continue
        steps.append(
            {
                "path": rel(path),
                "materializer_pair_index": index,
                "status": payload.get("status"),
                "deck_id": summary.get("deck_id"),
                "commander": summary.get("commander"),
                "add": pair.get("add"),
                "cut": pair.get("cut"),
                "role": pair.get("role") or summary.get("role"),
                "candidate_db": payload.get("candidate_db"),
                "source_unchanged": bool(summary.get("source_unchanged")),
                "source_matches_pair_report": source_matches_pair_report,
                "allow_chained_source": allow_chained_source,
                "source_reference_accepted": source_reference_accepted,
                "source_candidate_hash_differs": bool(summary.get("source_candidate_hash_differs")),
                "allow_next_strategy_matrix": bool(summary.get("allow_next_strategy_matrix")),
                "allow_battle_gate_now": bool(summary.get("allow_battle_gate_now")),
                "promotion_allowed": bool(summary.get("promotion_allowed")),
            }
        )
    return steps


def deck_core_row(core_payload: Mapping[str, Any], deck_id: str) -> dict[str, Any]:
    for row in core_payload.get("decks", []):
        if str(row.get("deck_id")) == str(deck_id):
            return dict(row)
    return {}


def commander_strategy_row(strategy_payload: Mapping[str, Any], commander: str) -> dict[str, Any]:
    for row in strategy_payload.get("commanders", []):
        if str(row.get("commander")) == str(commander):
            return dict(row)
    return {}


def role_counts(core_row: Mapping[str, Any]) -> dict[str, int]:
    return {str(row.get("role")): int(row.get("count") or 0) for row in core_row.get("role_bands", [])}


def role_statuses(core_row: Mapping[str, Any]) -> dict[str, str]:
    return {str(row.get("role")): str(row.get("status") or "") for row in core_row.get("role_bands", [])}


def build_report(
    *,
    materializer_reports: list[Path],
    final_core_report: Path,
    final_strategy_report: Path,
) -> dict[str, Any]:
    steps: list[dict[str, Any]] = []
    for path in materializer_reports:
        steps.extend(materializer_steps(path, load_json(path)))
    final_step = steps[-1] if steps else {}
    deck_id = str(final_step.get("deck_id") or "")
    commander = str(final_step.get("commander") or "")
    core_payload = load_json(final_core_report)
    strategy_payload = load_json(final_strategy_report)
    core_row = deck_core_row(core_payload, deck_id)
    strategy_row = commander_strategy_row(strategy_payload, commander)
    repair_plan = core_row.get("core_repair_plan") or {}
    chain_pass = all(
        str(step.get("status") or "").startswith("candidate_materialized_structure_ready")
        and step.get("source_unchanged")
        and step.get("source_reference_accepted")
        and not step.get("promotion_allowed")
        for step in steps
    )
    final_missing = list(repair_plan.get("missing_role_slots") or [])
    core_floor_repaired = core_row.get("core_status") == "core_review_ready" and not final_missing
    strategy_ready = strategy_row.get("status") == "ready_for_strategy_matrix"
    battle_gate_allowed_now = False
    blockers: list[str] = []
    if not chain_pass:
        blockers.append("materializer_chain_not_clean")
    if not core_floor_repaired:
        blockers.append("final_core_floor_not_repaired")
    if not strategy_ready:
        blockers.append("final_strategy_readiness_missing")
    blockers.append("commander_specific_strategy_matrix_not_run_for_package")
    blockers.append("package_battle_probe_not_run")
    return {
        "generated_at": utc_now(),
        "status": "pass" if chain_pass and core_floor_repaired and strategy_ready else "blocked",
        "artifact_type": "global_commander_candidate_package_chain_audit",
        "postgres_writes": False,
        "source_db_mutated": False,
        "battle_or_optimization_performed": False,
        "mutation_allowed": False,
        "deck_action_allowed": False,
        "promotion_allowed": False,
        "battle_gate_allowed_now": battle_gate_allowed_now,
        "input_artifacts": {
            "materializer_reports": [rel(path) for path in materializer_reports],
            "final_core_role_report": rel(final_core_report),
            "final_strategy_matrix_report": rel(final_strategy_report),
        },
        "summary": {
            "deck_id": deck_id,
            "commander": commander,
            "swap_count": len(steps),
            "package_adds": [step.get("add") for step in steps],
            "package_cuts": [step.get("cut") for step in steps],
            "final_candidate_db": final_step.get("candidate_db"),
            "materializer_chain_pass": chain_pass,
            "core_floor_repaired": core_floor_repaired,
            "strategy_ready": strategy_ready,
            "final_core_status": core_row.get("core_status"),
            "final_role_counts": role_counts(core_row),
            "final_role_statuses": role_statuses(core_row),
            "next_gate": "run_commander_specific_strategy_matrix_for_package_before_battle",
        },
        "blocker_reasons": blockers,
        "materializer_steps": steps,
        "final_core_deck_row": core_row,
        "final_strategy_commander_row": strategy_row,
        "policy": {
            "package_scope": "This is an isolated copied-DB package candidate, not a real deck change.",
            "battle_boundary": "Core floor repair and global readiness do not authorize battle until a commander-specific package strategy matrix exists.",
            "promotion_boundary": "Promotion remains closed until strategy matrix, equal battle gate, and replay trace pass.",
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Global Commander Candidate Package Chain Audit",
        "",
        f"- generated_at: `{payload['generated_at']}`",
        f"- status: `{payload['status']}`",
        f"- commander: `{summary['commander']}`",
        f"- deck_id: `{summary['deck_id']}`",
        f"- swap_count: `{summary['swap_count']}`",
        f"- materializer_chain_pass: `{str(summary['materializer_chain_pass']).lower()}`",
        f"- core_floor_repaired: `{str(summary['core_floor_repaired']).lower()}`",
        f"- strategy_ready: `{str(summary['strategy_ready']).lower()}`",
        f"- battle_gate_allowed_now: `{str(payload['battle_gate_allowed_now']).lower()}`",
        f"- promotion_allowed: `{str(payload['promotion_allowed']).lower()}`",
        f"- next_gate: `{summary['next_gate']}`",
        "",
        "## Package Swaps",
        "",
        "| Step | Add | Cut | Source Clean |",
        "| ---: | --- | --- | --- |",
    ]
    for index, step in enumerate(payload["materializer_steps"], start=1):
        lines.append(
            f"| {index} | `{step['add']}` | `{step['cut']}` | `{str(step['source_unchanged']).lower()}` |"
        )
    lines.extend(
        [
            "",
            "## Final Role Counts",
            "",
            f"- final_core_status: `{summary['final_core_status']}`",
            f"- final_role_counts: `{json.dumps(summary['final_role_counts'], sort_keys=True)}`",
            f"- final_role_statuses: `{json.dumps(summary['final_role_statuses'], sort_keys=True)}`",
            "",
            "## Blockers",
            "",
        ]
    )
    for blocker in payload["blocker_reasons"]:
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
    parser.add_argument("--materializer-report", type=Path, action="append", default=[])
    parser.add_argument("--final-core-role-report", type=Path, default=DEFAULT_FINAL_CORE_REPORT)
    parser.add_argument("--final-strategy-report", type=Path, default=DEFAULT_FINAL_STRATEGY_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    materializer_reports = args.materializer_report or DEFAULT_MATERIALIZER_REPORTS
    payload = build_report(
        materializer_reports=materializer_reports,
        final_core_report=args.final_core_role_report,
        final_strategy_report=args.final_strategy_report,
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
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
