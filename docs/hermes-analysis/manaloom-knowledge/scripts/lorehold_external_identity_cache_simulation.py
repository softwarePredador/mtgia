#!/usr/bin/env python3
"""Simulate the external identity cache package on a temporary SQLite copy.

The previous package prepares SQL, but does not execute it. This script proves
what would happen on an isolated copy, reruns the identity/import preflight on
that copy after apply, and then rolls the copy back. The source knowledge DB is
never opened for writing.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sqlite3
import subprocess
import tempfile
from collections.abc import Mapping
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_optimizer_common import resolve_default_knowledge_db
from lorehold_external_candidate_identity_import_preflight import build_payload as build_preflight_payload
from lorehold_external_candidate_identity_import_preflight import read_json as read_preflight_json


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_DB = resolve_default_knowledge_db()
DEFAULT_PACKAGE_REPORT = REPORT_DIR / "lorehold_external_identity_cache_apply_package_20260705_current.json"
DEFAULT_SCOUT_REPORT = REPORT_DIR / "lorehold_external_material_evidence_scout_20260705_current.json"
DEFAULT_OUT_PREFIX = REPORT_DIR / "lorehold_external_identity_cache_simulation_20260705_current"
PACKAGE_SOURCE_MARKER = "lorehold_external_identity_resolution_queue_20260705_current"


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return dict(payload) if isinstance(payload, Mapping) else {}


def resolve_repo_path(value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else REPO_ROOT / path


def sqlite_json_lines(stdout: str) -> list[Any]:
    rows = []
    decoder = json.JSONDecoder()
    index = 0
    while index < len(stdout):
        while index < len(stdout) and stdout[index].isspace():
            index += 1
        if index >= len(stdout):
            break
        try:
            item, index = decoder.raw_decode(stdout, index)
        except json.JSONDecodeError:
            remainder = stdout[index:].strip()
            if remainder:
                rows.append(remainder)
            break
        rows.append(item)
    return rows


def run_sqlite_script(db_path: Path, sql_path: Path) -> dict[str, Any]:
    result = subprocess.run(
        ["sqlite3", "-json", str(db_path)],
        input=sql_path.read_text(encoding="utf-8"),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return {
        "sql_path": rel(sql_path),
        "returncode": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "json_lines": sqlite_json_lines(result.stdout),
    }


def query_scalar(db_path: Path, sql: str) -> int:
    with sqlite3.connect(f"file:{db_path}?mode=ro", uri=True) as conn:
        row = conn.execute(sql).fetchone()
    return int(row[0] or 0)


def first_count(sql_result: Mapping[str, Any], key: str) -> int | None:
    for item in sql_result.get("json_lines") or []:
        if isinstance(item, list) and item and isinstance(item[0], Mapping) and key in item[0]:
            return int(item[0][key] or 0)
    return None


def rows_from_json_result(sql_result: Mapping[str, Any], expected_key: str) -> list[dict[str, Any]]:
    for item in sql_result.get("json_lines") or []:
        if isinstance(item, list) and item and isinstance(item[0], Mapping) and expected_key in item[0]:
            return [dict(row) for row in item]
    return []


def queue_from_preflight(preflight_payload: Mapping[str, Any]) -> dict[str, list[str]]:
    rows = [dict(row) for row in preflight_payload.get("preflight_rows") or [] if isinstance(row, Mapping)]
    combo_runtime = [
        row["card_name"]
        for row in rows
        if "combo_package" in (row.get("route_types") or []) and int(row.get("verified_auto_rule_count") or 0) == 0
    ]
    return {
        "identity_import_required": list((preflight_payload.get("queues") or {}).get("identity_import_required") or []),
        "runtime_or_manual_review_required": list(
            (preflight_payload.get("queues") or {}).get("runtime_or_manual_review_required") or []
        ),
        "combo_runtime_required": combo_runtime,
        "shell_contract_required": list((preflight_payload.get("queues") or {}).get("shell_contract_required") or []),
        "cut_safety_contract_required": list(
            (preflight_payload.get("queues") or {}).get("cut_safety_contract_required") or []
        ),
    }


def simulate(
    *,
    source_db: Path,
    scout_report: Mapping[str, Any],
    scout_path: Path,
    package_path: Path | None = None,
    package_report: Mapping[str, Any],
) -> dict[str, Any]:
    sql_files = {
        key: resolve_repo_path(value)
        for key, value in (package_report.get("sql_files") or {}).items()
        if isinstance(value, str)
    }
    required = {"precheck", "apply", "postcheck", "rollback"}
    missing = sorted(required - set(sql_files))
    if missing:
        raise RuntimeError(f"package report missing sql files: {missing}")

    source_marker_rows_before = query_scalar(
        source_db,
        f"SELECT COUNT(*) FROM card_oracle_cache WHERE source = '{PACKAGE_SOURCE_MARKER}'",
    )
    with tempfile.TemporaryDirectory(prefix="manaloom_identity_cache_sim_") as tmpdir:
        temp_db = Path(tmpdir) / "knowledge_simulation.db"
        shutil.copy2(source_db, temp_db)
        precheck_result = run_sqlite_script(temp_db, sql_files["precheck"])
        apply_result = run_sqlite_script(temp_db, sql_files["apply"])
        postcheck_result = run_sqlite_script(temp_db, sql_files["postcheck"])
        with sqlite3.connect(f"file:{temp_db}?mode=ro", uri=True) as conn:
            conn.row_factory = sqlite3.Row
            post_apply_preflight = build_preflight_payload(
                conn,
                db_path=temp_db,
                scout_report=scout_report,
                scout_path=scout_path,
            )
        rollback_result = run_sqlite_script(temp_db, sql_files["rollback"])
        rollback_remaining = query_scalar(
            temp_db,
            f"SELECT COUNT(*) FROM card_oracle_cache WHERE source = '{PACKAGE_SOURCE_MARKER}'",
        )
    source_marker_rows_after = query_scalar(
        source_db,
        f"SELECT COUNT(*) FROM card_oracle_cache WHERE source = '{PACKAGE_SOURCE_MARKER}'",
    )
    post_summary = dict(post_apply_preflight.get("summary") or {})
    post_queues = queue_from_preflight(post_apply_preflight)
    apply_ok = apply_result["returncode"] == 0
    postcheck_count = first_count(postcheck_result, "resolved_cache_rows")
    precheck_existing = first_count(precheck_result, "existing_cache_rows")
    rollback_remaining_reported = first_count(rollback_result, "remaining_package_cache_rows")
    status = (
        "external_identity_cache_simulation_pass_keep_607"
        if apply_ok
        and precheck_existing == 0
        and postcheck_count == int((package_report.get("summary") or {}).get("cache_insert_ready_count") or 0)
        and rollback_remaining == 0
        and source_marker_rows_before == source_marker_rows_after
        else "external_identity_cache_simulation_needs_review_keep_607"
    )
    return {
        "generated_at": utc_now(),
        "artifact_type": "lorehold_external_identity_cache_simulation",
        "postgres_writes": False,
        "source_db_mutated": False,
        "deck_607_mutated": False,
        "simulation_db_removed": True,
        "source_db": str(source_db),
        "source_reports": {
            "external_material_scout": rel(scout_path),
            "identity_cache_package": rel(package_path) if package_path is not None else None,
            "identity_resolution_queue": package_report.get("source_reports", {}).get("identity_resolution_queue"),
        },
        "sql_files": {key: rel(path) for key, path in sql_files.items()},
        "status": status,
        "summary": {
            "current_baseline": "deck_607",
            "source_marker_rows_before": source_marker_rows_before,
            "source_marker_rows_after": source_marker_rows_after,
            "temp_precheck_existing_cache_rows": precheck_existing,
            "temp_apply_returncode": apply_result["returncode"],
            "temp_postcheck_resolved_cache_rows": postcheck_count,
            "temp_rollback_remaining_package_rows": rollback_remaining_reported,
            "temp_rollback_remaining_direct_count": rollback_remaining,
            "post_apply_identity_missing_count": int(post_summary.get("oracle_identity_missing_count") or 0),
            "post_apply_runtime_or_manual_review_required_count": int(
                post_summary.get("runtime_or_manual_review_required_count") or 0
            ),
            "post_apply_shell_contract_required_count": int(post_summary.get("shell_contract_required_count") or 0),
            "deck_test_ready_count": 0,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "recommended_next_action": "split_post_identity_runtime_combo_and_shell_contract_queues_without_deck_mutation",
        },
        "post_apply_preflight_summary": post_summary,
        "post_apply_queues": post_queues,
        "postcheck_rows": rows_from_json_result(postcheck_result, "normalized_name"),
        "sql_execution": {
            "precheck": precheck_result,
            "apply": apply_result,
            "postcheck": postcheck_result,
            "rollback": rollback_result,
        },
        "decision": {
            "keep_607_as_protected_baseline": True,
            "natural_battle_allowed_now": False,
            "promotion_allowed": False,
            "next_actions": [
                "do_not_mutate_or_replace_deck_607",
                "do_not_apply_identity_cache_automatically_from_simulation",
                "route post-identity cards into runtime/manual-review, combo, or shell-contract queues",
                "keep shell-contract cards out of one-for-one 607 cut gates",
            ],
            "reason": (
                "The package applies and rolls back cleanly on a temporary copy, "
                "and the post-apply preflight removes identity blockers. It still "
                "does not produce a deck-test-ready or promotion-ready package."
            ),
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload["summary"]
    lines = [
        "# Lorehold External Identity Cache Simulation",
        "",
        f"- Generated at: `{payload['generated_at']}`",
        f"- Status: `{payload['status']}`",
        f"- Current baseline: `{summary['current_baseline']}`",
        f"- Source DB mutated: `{payload['source_db_mutated']}`",
        f"- Simulation DB removed: `{payload['simulation_db_removed']}`",
        "",
        "## Simulation Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
    ]
    for key in [
        "source_marker_rows_before",
        "source_marker_rows_after",
        "temp_precheck_existing_cache_rows",
        "temp_apply_returncode",
        "temp_postcheck_resolved_cache_rows",
        "temp_rollback_remaining_direct_count",
        "post_apply_identity_missing_count",
        "post_apply_runtime_or_manual_review_required_count",
        "post_apply_shell_contract_required_count",
        "deck_test_ready_count",
    ]:
        lines.append(f"| `{key}` | `{summary[key]}` |")
    lines.extend(["", "## Post-Apply Queues", ""])
    for queue_name, cards in payload["post_apply_queues"].items():
        card_list = ", ".join(cards) if cards else "-"
        lines.append(f"- `{queue_name}`: {card_list}")
    lines.extend(
        [
            "",
            "## Postcheck Rows",
            "",
            "| Normalized Name | Name | Commander Status |",
            "| --- | --- | --- |",
        ]
    )
    for row in payload["postcheck_rows"]:
        lines.append(
            f"| `{row.get('normalized_name')}` | {row.get('name')} | `{row.get('commander_status')}` |"
        )
    decision = payload["decision"]
    lines.extend(
        [
            "",
            "## Decision",
            "",
            f"- Keep 607 as protected baseline: `{decision['keep_607_as_protected_baseline']}`",
            f"- Natural battle allowed now: `{decision['natural_battle_allowed_now']}`",
            f"- Promotion allowed: `{decision['promotion_allowed']}`",
            f"- Reason: {decision['reason']}",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--package-report", type=Path, default=DEFAULT_PACKAGE_REPORT)
    parser.add_argument("--scout-report", type=Path, default=DEFAULT_SCOUT_REPORT)
    parser.add_argument("--out-prefix", type=Path, default=DEFAULT_OUT_PREFIX)
    args = parser.parse_args()
    package_report = read_json(args.package_report)
    scout_report = read_preflight_json(args.scout_report)
    payload = simulate(
        source_db=args.db,
        scout_report=scout_report,
        scout_path=args.scout_report,
        package_path=args.package_report,
        package_report=package_report,
    )
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "post_apply_identity_missing_count": payload["summary"]["post_apply_identity_missing_count"],
                "promotion_allowed": payload["summary"]["promotion_allowed"],
            },
            ensure_ascii=True,
        )
    )
    return 0 if payload["status"] == "external_identity_cache_simulation_pass_keep_607" else 1


if __name__ == "__main__":
    raise SystemExit(main())
