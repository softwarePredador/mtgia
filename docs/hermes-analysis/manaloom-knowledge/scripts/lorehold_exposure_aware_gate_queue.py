#!/usr/bin/env python3
"""Build an exposure-aware Lorehold gate queue.

This read-only selector prevents the slow failure mode where a package goes to
natural battle even though the added card is PG/runtime blocked, already failed
as the exact add/cut pair, or only needs a forced-exposure diagnostic. The
actual battle executor remains ``lorehold_synergy_package_gate.py``.
"""

from __future__ import annotations

import argparse
import json
import shlex
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import lorehold_synergy_package_gate as package_gate
from master_optimizer_common import normalize_name


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_READINESS = REPORT_DIR / "lorehold_runtime_candidate_readiness_20260628_v1.json"
DEFAULT_HYPOTHESIS_QUEUE = REPORT_DIR / "lorehold_next_hypothesis_queue_20260628_v10_runtime_pg245.json"
DEFAULT_PLANNER = REPORT_DIR / "lorehold_next_action_planner_20260630_goal_learning_queue_closed.json"
DEFAULT_REGISTRY = REPORT_DIR / "lorehold_candidate_hypothesis_registry_20260626.json"
DEFAULT_CUT_SAFETY_REPORT = REPORT_DIR / "lorehold_strategy_learning_audit_20260628_v3_runtime_readiness.json"

READINESS_BLOCKING_STATUSES = {
    "pg_precheck_blocked",
    "pg_package_prepared_pending_apply_approval",
    "runtime_model_blocked",
    "manual_mapper_required",
    "split_scope_review_required",
}
HYPOTHESIS_NEGATIVE_STATUSES = {
    "tested_negative_do_not_promote",
    "rejected",
    "rejected_probe",
    "rejected_probe_batch",
}
READY_STATUSES = {
    "natural_gate_preflight_ready",
    "forced_exposure_probe_ready",
}
READINESS_REWORK_BLOCKERS = {
    "cut_safety_blocked",
    "prior_exact_reject",
    "prior_natural_confirmation_reject",
    "hypothesis_queue_exact_negative",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def maybe_read_json(path: Path) -> dict[str, Any]:
    return read_json(path) if path.exists() else {}


def normalized_card_index(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    return {normalize_name(str(row.get("card_name") or "")): row for row in rows if row.get("card_name")}


def readiness_blockers_for_package(
    definition: dict[str, Any],
    readiness_by_card: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    blockers: list[dict[str, Any]] = []
    for card_name in definition.get("adds") or []:
        row = readiness_by_card.get(normalize_name(str(card_name)))
        if not row:
            continue
        status = str(row.get("status") or "")
        if status in READINESS_BLOCKING_STATUSES:
            blockers.append(
                {
                    "card_name": row.get("card_name") or card_name,
                    "status": status,
                    "next_action": row.get("next_action"),
                    "family_id": row.get("family_id"),
                }
            )
    return blockers


def hypothesis_rows(hypothesis_queue: dict[str, Any]) -> list[dict[str, Any]]:
    rows = hypothesis_queue.get("queue") or hypothesis_queue.get("hypotheses") or []
    return [row for row in rows if isinstance(row, dict)]


def current_package_keys(
    *,
    hypothesis_queue: dict[str, Any],
    planner_payload: dict[str, Any],
    registry_payload: dict[str, Any],
    include_static_packages: bool,
    package_definitions: dict[str, dict[str, Any]],
) -> list[str]:
    keys: list[str] = []
    for row in hypothesis_rows(hypothesis_queue):
        key = str(row.get("package_key") or "").strip()
        if key:
            keys.append(key)
    summary = planner_payload.get("summary") or {}
    keys.extend(str(key) for key in summary.get("prior_inconclusive_low_exposure_keys") or [] if str(key).strip())
    for row in registry_payload.get("untested_queue") or []:
        key = str(row.get("package_key") or row.get("key") or "").strip()
        if key:
            keys.append(key)
    if include_static_packages:
        keys.extend(package_definitions)
    seen: set[str] = set()
    ordered: list[str] = []
    for key in keys:
        if key in seen:
            continue
        seen.add(key)
        ordered.append(key)
    return ordered


def negative_hypothesis_index(hypothesis_queue: dict[str, Any]) -> dict[str, dict[str, Any]]:
    index: dict[str, dict[str, Any]] = {}
    for row in hypothesis_rows(hypothesis_queue):
        key = str(row.get("package_key") or "").strip()
        status = str(row.get("status") or "")
        if key and status in HYPOTHESIS_NEGATIVE_STATUSES:
            index[key] = {
                "status": status,
                "prior_gate": row.get("prior_gate") or {},
                "adds": row.get("adds") or [],
                "cuts": row.get("cuts") or [],
            }
    return index


def command_for_package(
    *,
    package_key: str,
    stem: str,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
    forced_access_mode: str = "none",
    package_files: list[Path] | None = None,
) -> list[str]:
    command = [
        "python3",
        str(SCRIPT_DIR / "lorehold_synergy_package_gate.py"),
        "--packages",
        package_key,
        "--games",
        str(max(1, games)),
        "--opponent-limit",
        str(max(1, opponent_limit)),
        "--opponent-seed",
        str(opponent_seed),
        "--simulation-seed",
        str(simulation_seed),
        "--stem",
        stem,
    ]
    for package_file in package_files or []:
        command.extend(["--package-file", str(package_file)])
    if forced_access_mode != "none":
        command.extend(["--forced-access-mode", forced_access_mode])
    return command


def extract_child_status(stdout: str) -> dict[str, Any]:
    marker = '{\n  "status": "ready"'
    start = stdout.rfind(marker)
    if start < 0:
        return {}
    try:
        return json.loads(stdout[start:].strip())
    except json.JSONDecodeError:
        return {}


def prior_evidence_has_natural_confirmation_reject(prior_evidence: dict[str, Any]) -> bool:
    for match in prior_evidence.get("matches") or []:
        if not isinstance(match, dict):
            continue
        source = Path(str(match.get("source_report") or "")).name
        mode = str(match.get("forced_access_mode") or "none")
        if (
            "natural_confirmation" in source
            and mode == "none"
            and match.get("decision") in package_gate.PRIOR_PACKAGE_BLOCKED_DECISIONS
        ):
            return True
    return False


def actionable_added_card_readiness_blocker(row: dict[str, Any]) -> bool:
    if row.get("status") != "blocked_added_card_readiness":
        return False
    blockers = set(row.get("blockers") or [])
    return not bool(blockers & READINESS_REWORK_BLOCKERS)


def classify_package(
    *,
    package_key: str,
    definition: dict[str, Any] | None,
    readiness_by_card: dict[str, dict[str, Any]],
    negative_by_key: dict[str, dict[str, Any]],
    inconclusive_low_exposure_keys: set[str],
    cut_safety: dict[str, Any],
    prior_results: dict[str, Any],
    command_stem: str,
    games: int,
    opponent_limit: int,
    opponent_seed: int,
    simulation_seed: int,
    package_files: list[Path] | None = None,
) -> dict[str, Any]:
    if definition is None:
        return {
            "package_key": package_key,
            "status": "blocked_unknown_package_definition",
            "decision": "not_run_unknown_package",
            "blockers": ["unknown_package_definition"],
        }

    readiness_blockers = readiness_blockers_for_package(definition, readiness_by_card)
    low_exposure_diagnostic = package_key in inconclusive_low_exposure_keys
    forced_access_mode = "opening_hand" if low_exposure_diagnostic else "none"
    cut_safety_status = package_gate.classify_package_cut_safety(definition, cut_safety)
    prior_evidence = package_gate.classify_package_prior_evidence(
        package_key,
        definition,
        prior_results,
        forced_access_mode=forced_access_mode,
    )
    natural_confirmation_prior_reject = (
        low_exposure_diagnostic
        and prior_evidence.get("status") == "forced_access_diagnostic_despite_prior_reject"
        and prior_evidence_has_natural_confirmation_reject(prior_evidence)
    )
    negative = negative_by_key.get(package_key)
    blockers: list[str] = []
    if readiness_blockers:
        blockers.append("added_card_readiness_blocked")
    if cut_safety_status.get("status") == "blocked_cut_safety":
        blockers.append("cut_safety_blocked")
    if prior_evidence.get("status") == "blocked_prior_reject":
        blockers.append("prior_exact_reject")
    if natural_confirmation_prior_reject:
        blockers.append("prior_natural_confirmation_reject")
    if negative:
        blockers.append("hypothesis_queue_exact_negative")

    if blockers:
        if readiness_blockers:
            status = "blocked_added_card_readiness"
            decision = "not_run_added_card_runtime_or_pg_blocked"
        elif "cut_safety_blocked" in blockers:
            status = "blocked_cut_safety"
            decision = "not_run_cut_safety_blocked"
        elif "prior_natural_confirmation_reject" in blockers:
            status = "blocked_prior_evidence"
            decision = "not_run_prior_natural_confirmation_reject"
        elif "prior_exact_reject" in blockers:
            status = "blocked_prior_evidence"
            decision = "not_run_prior_reject_blocked"
        else:
            status = "blocked_hypothesis_queue_prior_negative"
            decision = "not_run_exact_pair_already_negative"
        return {
            "package_key": package_key,
            "status": status,
            "decision": decision,
            "family": definition.get("family") or "misc",
            "adds": definition.get("adds") or [],
            "cuts": definition.get("cuts") or [],
            "readiness_blockers": readiness_blockers,
            "cut_safety": cut_safety_status,
            "prior_evidence": prior_evidence,
            "hypothesis_negative": negative or {},
            "blockers": blockers,
            "natural_promotion_allowed": False,
        }

    status = "natural_gate_preflight_ready"
    decision = "ready_for_natural_gate_preflight"
    promotion_allowed = True
    if low_exposure_diagnostic:
        status = "forced_exposure_probe_ready"
        decision = "diagnostic_only_low_exposure_requires_card_access"
        promotion_allowed = False

    command = command_for_package(
        package_key=package_key,
        stem=command_stem,
        games=games,
        opponent_limit=opponent_limit,
        opponent_seed=opponent_seed,
        simulation_seed=simulation_seed,
        forced_access_mode=forced_access_mode,
        package_files=package_files,
    )
    return {
        "package_key": package_key,
        "status": status,
        "decision": decision,
        "family": definition.get("family") or "misc",
        "adds": definition.get("adds") or [],
        "cuts": definition.get("cuts") or [],
        "readiness_blockers": [],
        "cut_safety": cut_safety_status,
        "prior_evidence": prior_evidence,
        "hypothesis_negative": {},
        "blockers": [],
        "forced_access_mode": forced_access_mode,
        "natural_promotion_allowed": promotion_allowed,
        "command": command,
        "command_text": shlex.join(command),
    }


def recommended_next_action(rows: list[dict[str, Any]]) -> str:
    if any(row["status"] == "natural_gate_preflight_ready" for row in rows):
        return "run_next_natural_gate_package"
    if any(row["status"] == "forced_exposure_probe_ready" for row in rows):
        return "run_forced_exposure_probe_before_natural_gate"
    if any(actionable_added_card_readiness_blocker(row) for row in rows):
        return "resolve_runtime_or_pg_readiness_before_more_battles"
    return "no_package_ready; build_new_failure_targeted_package_or_cut_model"


def build_report(
    *,
    readiness_report: dict[str, Any],
    hypothesis_queue: dict[str, Any],
    planner_payload: dict[str, Any],
    registry_payload: dict[str, Any],
    package_definitions: dict[str, dict[str, Any]],
    cut_safety: dict[str, Any],
    prior_results: dict[str, Any],
    include_static_packages: bool = False,
    command_stem: str = "lorehold_exposure_aware_gate_queue_run",
    games: int = 1,
    opponent_limit: int = 3,
    opponent_seed: int = 20260626,
    simulation_seed: int = 42,
    package_files: list[Path] | None = None,
) -> dict[str, Any]:
    readiness_by_card = normalized_card_index(readiness_report.get("cards") or [])
    negative_by_key = negative_hypothesis_index(hypothesis_queue)
    inconclusive_low_exposure_keys = {
        str(key)
        for key in (planner_payload.get("summary") or {}).get("prior_inconclusive_low_exposure_keys") or []
        if str(key).strip()
    }
    keys = current_package_keys(
        hypothesis_queue=hypothesis_queue,
        planner_payload=planner_payload,
        registry_payload=registry_payload,
        include_static_packages=include_static_packages,
        package_definitions=package_definitions,
    )
    rows = [
        classify_package(
            package_key=key,
            definition=package_definitions.get(key),
            readiness_by_card=readiness_by_card,
            negative_by_key=negative_by_key,
            inconclusive_low_exposure_keys=inconclusive_low_exposure_keys,
            cut_safety=cut_safety,
            prior_results=prior_results,
            command_stem=command_stem,
            games=games,
            opponent_limit=opponent_limit,
            opponent_seed=opponent_seed,
            simulation_seed=simulation_seed,
            package_files=package_files,
        )
        for key in keys
    ]
    priority = {
        "natural_gate_preflight_ready": 0,
        "forced_exposure_probe_ready": 1,
        "blocked_added_card_readiness": 2,
        "blocked_cut_safety": 3,
        "blocked_prior_evidence": 4,
        "blocked_hypothesis_queue_prior_negative": 5,
        "blocked_unknown_package_definition": 6,
    }
    rows.sort(key=lambda row: (priority.get(row["status"], 99), row["package_key"]))
    counts = Counter(row["status"] for row in rows)
    ready_rows = [row for row in rows if row["status"] in READY_STATUSES]
    actionable_readiness_rows = [
        row for row in rows if actionable_added_card_readiness_blocker(row)
    ]
    return {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "readiness_report": readiness_report.get("runtime_queue") or "",
        "package_count": len(rows),
        "summary": {
            "package_count": len(rows),
            "status_counts": dict(sorted(counts.items())),
            "ready_count": len(ready_rows),
            "natural_gate_ready_count": counts.get("natural_gate_preflight_ready", 0),
            "forced_exposure_probe_ready_count": counts.get("forced_exposure_probe_ready", 0),
            "blocked_added_card_readiness_count": counts.get("blocked_added_card_readiness", 0),
            "actionable_added_card_readiness_count": len(actionable_readiness_rows),
            "nonactionable_added_card_readiness_count": (
                counts.get("blocked_added_card_readiness", 0) - len(actionable_readiness_rows)
            ),
            "prior_inconclusive_low_exposure_keys": sorted(inconclusive_low_exposure_keys),
            "recommended_next_action": recommended_next_action(rows),
        },
        "ready_queue": ready_rows,
        "packages": rows,
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report["summary"]
    sources = report.get("sources") or {}
    generated_date = str(report.get("generated_at") or "")[:10] or "unknown-date"
    lines = [
        f"# Lorehold Exposure-Aware Gate Queue - {generated_date}",
        "",
        f"- Generated at: `{report['generated_at']}`",
        "- PostgreSQL writes: `false`",
        "- Source DB mutated: `false`",
    ]
    if sources:
        lines.extend(
            [
                f"- Readiness report: `{sources.get('readiness_report')}`",
                f"- Hypothesis queue: `{sources.get('hypothesis_queue')}`",
                f"- Planner: `{sources.get('planner')}`",
                f"- Cut safety report: `{sources.get('cut_safety_report')}`",
            ]
        )
    lines.extend(
        [
            "",
            "## Summary",
            "",
            f"- Packages reviewed: `{summary['package_count']}`",
            f"- Status counts: `{json.dumps(summary['status_counts'], sort_keys=True)}`",
            f"- Ready packages: `{summary['ready_count']}`",
            f"- Natural gate ready: `{summary['natural_gate_ready_count']}`",
            f"- Forced-exposure diagnostic ready: `{summary['forced_exposure_probe_ready_count']}`",
            f"- Recommended next action: `{summary['recommended_next_action']}`",
            "",
            "## Ready Queue",
            "",
        ]
    )
    if not report["ready_queue"]:
        lines.append("- No package is ready for execution.")
    else:
        lines.extend(
            [
                "| Rank | Package | Status | Adds | Cuts | Promotion allowed | Command |",
                "| ---: | --- | --- | --- | --- | --- | --- |",
            ]
        )
        for index, row in enumerate(report["ready_queue"], start=1):
            lines.append(
                "| {rank} | `{package}` | `{status}` | {adds} | {cuts} | `{promotion}` | `{command}` |".format(
                    rank=index,
                    package=row["package_key"],
                    status=row["status"],
                    adds=", ".join(f"`{card}`" for card in row.get("adds") or []),
                    cuts=", ".join(f"`{card}`" for card in row.get("cuts") or []),
                    promotion=str(bool(row.get("natural_promotion_allowed"))).lower(),
                    command=row.get("command_text") or "",
                )
            )
    executed = report.get("executed") or []
    if executed:
        lines.extend(["", "## Executed", ""])
        lines.extend(
            [
                "| Package | Return code | Child JSON | Child Markdown |",
                "| --- | ---: | --- | --- |",
            ]
        )
        for row in executed:
            lines.append(
                "| `{package}` | {returncode} | `{json_path}` | `{md_path}` |".format(
                    package=row.get("package_key") or "",
                    returncode=int(row.get("returncode") or 0),
                    json_path=row.get("child_json") or "",
                    md_path=row.get("child_markdown") or "",
                )
            )
    lines.extend(["", "## Blocked Queue", ""])
    lines.extend(
        [
            "| Package | Status | Adds | Cuts | Blockers |",
            "| --- | --- | --- | --- | --- |",
        ]
    )
    for row in report["packages"]:
        if row["status"] in READY_STATUSES:
            continue
        lines.append(
            "| `{package}` | `{status}` | {adds} | {cuts} | {blockers} |".format(
                package=row["package_key"],
                status=row["status"],
                adds=", ".join(f"`{card}`" for card in row.get("adds") or []),
                cuts=", ".join(f"`{card}`" for card in row.get("cuts") or []),
                blockers=", ".join(f"`{item}`" for item in row.get("blockers") or []),
            )
        )
    return "\n".join(lines).rstrip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--readiness-report", type=Path, default=DEFAULT_READINESS)
    parser.add_argument("--hypothesis-queue", type=Path, default=DEFAULT_HYPOTHESIS_QUEUE)
    parser.add_argument("--planner", type=Path, default=DEFAULT_PLANNER)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--cut-safety-report", type=Path, default=DEFAULT_CUT_SAFETY_REPORT)
    parser.add_argument("--package-file", type=Path, action="append", default=[])
    parser.add_argument("--prior-package-report", type=Path, action="append")
    parser.add_argument("--include-static-packages", action="store_true")
    parser.add_argument("--games", type=int, default=1)
    parser.add_argument("--opponent-limit", type=int, default=3)
    parser.add_argument("--opponent-seed", type=int, default=20260626)
    parser.add_argument("--simulation-seed", type=int, default=42)
    parser.add_argument("--stem", default="lorehold_exposure_aware_gate_queue_20260628_v1")
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--max-execute", type=int, default=1)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    package_files = [path.resolve() for path in args.package_file]
    package_definitions, loaded_package_files, _loaded_package_keys = package_gate.merge_package_definitions(package_files)
    cut_safety = package_gate.merge_registry_cut_guard(
        package_gate.load_cut_safety_manifest(args.cut_safety_report.resolve()),
        package_gate.load_registry_cut_guard(args.registry.resolve()),
    )
    prior_package_reports = [
        path.resolve()
        for path in (args.prior_package_report or list(package_gate.DEFAULT_PRIOR_PACKAGE_REPORTS))
    ]
    prior_results = package_gate.merge_registry_prior_results(
        package_gate.load_prior_package_results(prior_package_reports),
        package_gate.load_registry_prior_results(args.registry.resolve()),
    )
    command_stem = f"{args.stem}_run"
    report = build_report(
        readiness_report=read_json(args.readiness_report),
        hypothesis_queue=read_json(args.hypothesis_queue),
        planner_payload=read_json(args.planner),
        registry_payload=maybe_read_json(args.registry),
        package_definitions=package_definitions,
        cut_safety=cut_safety,
        prior_results=prior_results,
        include_static_packages=bool(args.include_static_packages),
        command_stem=command_stem,
        games=max(1, args.games),
        opponent_limit=max(1, args.opponent_limit),
        opponent_seed=args.opponent_seed,
        simulation_seed=args.simulation_seed,
        package_files=package_files,
    )
    report["sources"] = {
        "readiness_report": str(args.readiness_report),
        "hypothesis_queue": str(args.hypothesis_queue),
        "planner": str(args.planner),
        "registry": str(args.registry),
        "cut_safety_report": str(args.cut_safety_report),
        "prior_package_reports": [str(path) for path in prior_package_reports],
    }
    report["package_definition_files"] = loaded_package_files
    if args.execute:
        executed: list[dict[str, Any]] = []
        for row in report["ready_queue"][: max(1, args.max_execute)]:
            completed = subprocess.run(
                row["command"],
                cwd=str(REPO_ROOT),
                text=True,
                capture_output=True,
                check=False,
            )
            child_status = extract_child_status(completed.stdout)
            executed.append(
                {
                    "package_key": row["package_key"],
                    "returncode": completed.returncode,
                    "child_status": child_status,
                    "child_json": child_status.get("json"),
                    "child_markdown": child_status.get("markdown"),
                    "stdout_tail": completed.stdout[-2000:],
                    "stderr_tail": completed.stderr[-2000:],
                }
            )
        report["executed"] = executed

    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{args.stem}.json"
    md_path = REPORT_DIR / f"{args.stem}.md"
    json_path.write_text(json.dumps(report, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(report), encoding="utf-8")
    print(f"wrote {json_path}")
    print(f"wrote {md_path}")
    print(json.dumps(report["summary"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
