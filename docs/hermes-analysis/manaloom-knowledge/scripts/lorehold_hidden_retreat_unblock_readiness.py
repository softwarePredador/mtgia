#!/usr/bin/env python3
"""Report whether the Lorehold Hidden Retreat route is ready to unblock.

This is intentionally read-only. It connects the current access/cut model,
focus-package queue, exposure-outcome audit, and PG271 runtime package manifest
so the optimizer does not keep running blind three-game swaps when the tested
card was not actually observed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs" / "hermes-analysis" / "master_optimizer_reports"

DEFAULT_MANIFEST = REPORT_DIR / "pg271_hidden_retreat_damage_prevention_20260630_manifest.json"
DEFAULT_ACCESS_MODEL = REPORT_DIR / "lorehold_access_cut_model_20260630_post_pg276_lane_core_blocked.json"
DEFAULT_FOCUS_QUEUE = REPORT_DIR / "lorehold_focus_access_package_generator_20260630_post_pg278_lantern.json"
DEFAULT_OUTCOME_AUDIT = REPORT_DIR / "lorehold_exposure_outcome_audit_20260628_v1.json"


CommandRunner = Callable[..., subprocess.CompletedProcess[str]]


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def integer(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except Exception:
        return default


def resolve_repo_path(path_value: str | None, repo_root: Path) -> Path | None:
    if not path_value:
        return None
    path = Path(path_value)
    return path if path.is_absolute() else repo_root / path


def sanitize_psql_error(text: str) -> str:
    sanitized = re.sub(r'server at "[^"]+"', 'server at "<redacted-host>"', text or "")
    sanitized = re.sub(r"port \d+", "port <redacted-port>", sanitized)
    sanitized = re.sub(r"postgres(?:ql)?://[^ \n]+", "postgres://<redacted>", sanitized)
    return sanitized.strip()


def classify_psql_error(exit_code: int, stderr: str) -> str:
    if exit_code == 0:
        return "success"
    lowered = (stderr or "").lower()
    if "does not support ssl" in lowered:
        return "failed_ssl_unsupported"
    if "server closed the connection unexpectedly" in lowered:
        return "failed_connection_closed"
    if "database system is in recovery mode" in lowered:
        return "failed_database_recovery_mode"
    if "password authentication failed" in lowered:
        return "failed_authentication"
    if "could not translate host name" in lowered:
        return "failed_dns"
    if "connection refused" in lowered:
        return "failed_connection_refused"
    return "failed_psql_error"


def source_env_probe(env_file: Path, runner: CommandRunner = subprocess.run) -> dict[str, Any]:
    if not env_file.exists():
        return {"attempted": False, "database_url_present": False, "error": "env_file_missing"}
    command = (
        "set -a && source {env_file} >/dev/null 2>&1 && "
        "if test -n \"$DATABASE_URL\"; then echo database_url_present; "
        "else echo database_url_missing; fi"
    ).format(env_file=shlex.quote(str(env_file)))
    completed = runner(
        ["/bin/zsh", "-lc", command],
        cwd=str(REPO_ROOT),
        text=True,
        capture_output=True,
        timeout=15,
        check=False,
    )
    stdout = (completed.stdout or "").strip()
    return {
        "attempted": True,
        "exit_code": completed.returncode,
        "database_url_present": stdout == "database_url_present",
        "stdout_classification": stdout,
        "stderr": sanitize_psql_error(completed.stderr or ""),
    }


def discover_env_status(
    *,
    repo_root: Path,
    env_path: Path | None = None,
    runner: CommandRunner = subprocess.run,
) -> dict[str, Any]:
    candidates = [env_path] if env_path else [
        repo_root / ".env",
        repo_root / "server" / ".env",
        repo_root / "backend" / ".env",
    ]
    checked = [str(path) for path in candidates if path is not None]
    existing = [path for path in candidates if path is not None and path.exists()]
    selected = existing[0] if existing else None
    probe = source_env_probe(selected, runner=runner) if selected else {
        "attempted": False,
        "database_url_present": False,
        "error": "no_env_file_found",
    }
    database_url_in_process = bool(os.environ.get("DATABASE_URL"))
    psql_path = shutil.which("psql")
    return {
        "psql_path": psql_path,
        "env_candidates_checked": checked,
        "existing_env_files": [str(path) for path in existing],
        "selected_env_file": str(selected) if selected else None,
        "database_url_available_in_process": database_url_in_process,
        "database_url_available_from_env_file": bool(probe.get("database_url_present")),
        "env_probe": probe,
        "precheck_environment_ready": bool(
            psql_path and (database_url_in_process or probe.get("database_url_present"))
        ),
    }


def run_precheck(
    *,
    sql_path: Path | None,
    env_file: Path | None,
    runner: CommandRunner = subprocess.run,
    sslmode: str | None = None,
) -> dict[str, Any]:
    if sql_path is None or not sql_path.exists():
        return {
            "attempted": False,
            "classification": "missing_precheck_sql",
            "sql_path": str(sql_path) if sql_path else None,
        }
    if not shutil.which("psql"):
        return {
            "attempted": False,
            "classification": "missing_psql_binary",
            "sql_path": str(sql_path),
        }
    prefix = ""
    if env_file:
        prefix = f"set -a && source {shlex.quote(str(env_file))} >/dev/null 2>&1 && "
    env_prefix = f"PGSSLMODE={shlex.quote(sslmode)} " if sslmode else ""
    command = (
        f"{prefix}{env_prefix}psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 "
        f"-P pager=off -f {shlex.quote(str(sql_path))}"
    )
    completed = runner(
        ["/bin/zsh", "-lc", command],
        cwd=str(REPO_ROOT),
        text=True,
        capture_output=True,
        timeout=45,
        check=False,
    )
    stderr = sanitize_psql_error(completed.stderr or "")
    return {
        "attempted": True,
        "sql_path": str(sql_path),
        "sslmode": sslmode or "default",
        "exit_code": completed.returncode,
        "classification": classify_psql_error(completed.returncode, completed.stderr or ""),
        "stdout_line_count": len((completed.stdout or "").splitlines()),
        "stderr_excerpt": "\n".join(stderr.splitlines()[:6]),
    }


def maybe_run_prechecks(
    *,
    run_enabled: bool,
    retry_ssl_require: bool,
    sql_path: Path | None,
    env_status: Mapping[str, Any],
    runner: CommandRunner = subprocess.run,
) -> list[dict[str, Any]]:
    if not run_enabled:
        return [
            {
                "attempted": False,
                "classification": "not_requested",
                "reason": "precheck execution is opt-in and read-only",
            }
        ]
    if not env_status.get("precheck_environment_ready"):
        return [
            {
                "attempted": False,
                "classification": "environment_not_ready",
                "reason": "psql or DATABASE_URL was not available",
            }
        ]
    env_file = Path(str(env_status["selected_env_file"])) if env_status.get("selected_env_file") else None
    attempts = [run_precheck(sql_path=sql_path, env_file=env_file, runner=runner)]
    if retry_ssl_require and attempts[-1]["classification"] != "success":
        attempts.append(run_precheck(sql_path=sql_path, env_file=env_file, runner=runner, sslmode="require"))
    return attempts


def readiness_status(
    *,
    gate_ready_count: int,
    preflight_access_count: int,
    deeper_gate_count: int,
    hidden_retreat_status: str,
    precheck_attempts: list[Mapping[str, Any]],
) -> str:
    if gate_ready_count > 0 and deeper_gate_count > 0:
        return "gate_ready_with_card_outcome_support"
    if gate_ready_count > 0:
        return "gate_ready_but_card_outcome_support_missing"
    if hidden_retreat_status == "applied_synced":
        return "hidden_retreat_synced_no_gate_ready_package"
    if hidden_retreat_status == "prepared_read_only_pending_apply_approval":
        last = precheck_attempts[-1] if precheck_attempts else {}
        if last.get("classification") == "success" and preflight_access_count == 0:
            return "pg_precheck_success_but_cut_model_still_blocks_battle"
        if last.get("attempted") and last.get("classification") != "success":
            return "blocked_db_precheck_and_no_safe_cut"
        return "blocked_pending_pg_precheck_apply_and_no_safe_cut"
    return "blocked_no_gate_ready_package"


def build_report(
    *,
    manifest_path: Path,
    access_model_path: Path,
    focus_queue_path: Path,
    outcome_audit_path: Path,
    env_path: Path | None = None,
    run_pg_precheck: bool = False,
    retry_ssl_require: bool = False,
    runner: CommandRunner = subprocess.run,
) -> dict[str, Any]:
    manifest = read_json(manifest_path)
    access_model = read_json(access_model_path)
    focus_queue = read_json(focus_queue_path)
    outcome_audit = read_json(outcome_audit_path)

    manifest_files = manifest.get("files") or {}
    precheck_sql = resolve_repo_path(manifest_files.get("precheck"), REPO_ROOT)
    env_status = discover_env_status(repo_root=REPO_ROOT, env_path=env_path, runner=runner)
    precheck_attempts = maybe_run_prechecks(
        run_enabled=run_pg_precheck,
        retry_ssl_require=retry_ssl_require,
        sql_path=precheck_sql,
        env_status=env_status,
        runner=runner,
    )

    access_summary = access_model.get("summary") or {}
    focus_summary = focus_queue.get("summary") or {}
    outcome_summary = outcome_audit.get("summary") or {}
    gate_ready_count = integer(focus_summary.get("gate_ready_package_count"))
    preflight_access_count = integer(access_summary.get("preflight_access_candidate_ready_count"))
    deeper_gate_count = integer(outcome_summary.get("deeper_gate_candidate_count"))
    rejected_pair_count = integer(outcome_summary.get("rejected_current_pair_count"))
    no_used_sample_count = integer(outcome_summary.get("inconclusive_no_used_sample_count"))
    missing_outcome_count = integer(
        (outcome_summary.get("decision_counts") or {}).get("missing_per_card_outcome_data")
    )
    hidden_retreat_status = str(access_summary.get("hidden_retreat_package_status") or manifest.get("status") or "")
    status = readiness_status(
        gate_ready_count=gate_ready_count,
        preflight_access_count=preflight_access_count,
        deeper_gate_count=deeper_gate_count,
        hidden_retreat_status=hidden_retreat_status,
        precheck_attempts=precheck_attempts,
    )
    safe_to_run_battle_gate_now = gate_ready_count > 0 and deeper_gate_count > 0

    return {
        "generated_at": utc_now(),
        "postgres_writes": False,
        "source_db_mutated": False,
        "inputs": {
            "manifest": str(manifest_path),
            "access_model": str(access_model_path),
            "focus_queue": str(focus_queue_path),
            "outcome_audit": str(outcome_audit_path),
        },
        "summary": {
            "readiness_status": status,
            "safe_to_run_battle_gate_now": safe_to_run_battle_gate_now,
            "hidden_retreat_package_status": hidden_retreat_status,
            "hidden_retreat_runtime_model_status": access_summary.get("hidden_retreat_runtime_model_status"),
            "pg271_apply_gate": manifest.get("apply_gate"),
            "gate_ready_package_count": gate_ready_count,
            "preflight_access_candidate_ready_count": preflight_access_count,
            "deeper_gate_candidate_count": deeper_gate_count,
            "rejected_current_pair_count": rejected_pair_count,
            "inconclusive_no_used_sample_count": no_used_sample_count,
            "missing_per_card_outcome_data_count": missing_outcome_count,
            "focus_recommended_next_action": focus_summary.get("recommended_next_action"),
            "access_model_recommended_next_action": access_summary.get("recommended_next_action"),
            "outcome_audit_recommended_next_action": outcome_summary.get("recommended_next_action"),
            "recommended_next_action": (
                "fix_or_retry_pg271_precheck_access_before_requesting_apply; do_not_run_blind_battle_gate"
                if status == "blocked_db_precheck_and_no_safe_cut"
                else "request_explicit_pg271_apply_approval_then_sync_and_rerun_cut_model"
                if status == "pg_precheck_success_but_cut_model_still_blocks_battle"
                else "continue_trace_targeted_cut_model_or_runtime_gap_work_before_more_battles"
            ),
        },
        "env_status": env_status,
        "postgres_precheck": {
            "run_requested": run_pg_precheck,
            "attempts": precheck_attempts,
        },
        "blocker_chain": [
            {
                "blocker": "no_gate_ready_package",
                "evidence": f"focus queue gate_ready_package_count={gate_ready_count}",
                "resolution": "rerun focus package generation only after runtime/safe-cut blockers change",
            },
            {
                "blocker": "no_safe_access_cut",
                "evidence": f"access model preflight_access_candidate_ready_count={preflight_access_count}",
                "resolution": "find a seed-safe cut for the access/topdeck lane before battle gating",
            },
            {
                "blocker": (
                    "hidden_retreat_product_truth_confirmed"
                    if hidden_retreat_status == "applied_synced"
                    else "hidden_retreat_not_product_truth"
                ),
                "evidence": f"PG271 status={hidden_retreat_status}",
                "resolution": (
                    "no PostgreSQL action; continue cut/gate work"
                    if hidden_retreat_status == "applied_synced"
                    else "run precheck, obtain explicit approval for apply SQL, apply, postcheck, then sync Hermes"
                ),
            },
            {
                "blocker": "card_level_evidence_required",
                "evidence": (
                    f"outcome audit deeper_gate_candidate_count={deeper_gate_count}, "
                    f"rejected_current_pair_count={rejected_pair_count}, "
                    f"inconclusive_no_used_sample_count={no_used_sample_count}"
                ),
                "resolution": "promote only packages where the added card has observed used-game support",
            },
        ],
        "guardrails": [
            "Do not run blind three-game swaps when the package queue has zero gate-ready candidates.",
            "Do not treat aggregate battle record as card-level proof.",
            "Do not repeat exact rejected pairs without a new failure target or cut rationale.",
            "Do not rerun PG271 SQL when Hidden Retreat is already applied/synced.",
            "Hermes/runtime overlay is laboratory evidence unless PostgreSQL apply and sync are complete.",
        ],
        "manifest_extract": {
            "deploy_id": manifest.get("deploy_id"),
            "status": manifest.get("status"),
            "selected_card_names": manifest.get("selected_card_names") or [],
            "files": manifest_files,
            "mutations_performed": manifest.get("mutations_performed") or [],
        },
    }


def render_markdown(payload: Mapping[str, Any]) -> str:
    summary = payload.get("summary") or {}
    precheck = payload.get("postgres_precheck") or {}
    env_status = payload.get("env_status") or {}
    attempts = precheck.get("attempts") or []
    lines = [
        "# Lorehold Hidden Retreat Unblock Readiness - 2026-06-28",
        "",
        f"- generated_at: `{payload.get('generated_at')}`",
        "- postgres_writes: `false`",
        "- source_db_mutated: `false`",
        f"- readiness_status: `{summary.get('readiness_status')}`",
        f"- safe_to_run_battle_gate_now: `{str(summary.get('safe_to_run_battle_gate_now')).lower()}`",
        f"- hidden_retreat_package_status: `{summary.get('hidden_retreat_package_status')}`",
        f"- gate_ready_package_count: `{summary.get('gate_ready_package_count')}`",
        f"- preflight_access_candidate_ready_count: `{summary.get('preflight_access_candidate_ready_count')}`",
        f"- deeper_gate_candidate_count: `{summary.get('deeper_gate_candidate_count')}`",
        f"- rejected_current_pair_count: `{summary.get('rejected_current_pair_count')}`",
        f"- inconclusive_no_used_sample_count: `{summary.get('inconclusive_no_used_sample_count')}`",
        f"- recommended_next_action: `{summary.get('recommended_next_action')}`",
        "",
        "## Precheck Status",
        "",
        f"- psql_path: `{env_status.get('psql_path')}`",
        f"- selected_env_file: `{env_status.get('selected_env_file')}`",
        f"- database_url_available_from_env_file: `{str(env_status.get('database_url_available_from_env_file')).lower()}`",
        f"- precheck_environment_ready: `{str(env_status.get('precheck_environment_ready')).lower()}`",
        f"- run_requested: `{str(precheck.get('run_requested')).lower()}`",
        "",
        "| Attempt | SSL mode | Classification | Exit | Stderr excerpt |",
        "| ---: | --- | --- | ---: | --- |",
    ]
    for idx, attempt in enumerate(attempts, start=1):
        stderr = str(attempt.get("stderr_excerpt") or attempt.get("reason") or "-").replace("\n", "<br>")
        lines.append(
            f"| {idx} | `{attempt.get('sslmode', '-')}` | `{attempt.get('classification')}` | "
            f"{attempt.get('exit_code', '-')} | {stderr} |"
        )
    lines.extend(
        [
            "",
            "## Blocker Chain",
            "",
            "| Blocker | Evidence | Resolution |",
            "| --- | --- | --- |",
        ]
    )
    for blocker in payload.get("blocker_chain") or []:
        lines.append(
            "| `{blocker}` | {evidence} | {resolution} |".format(
                blocker=blocker.get("blocker"),
                evidence=blocker.get("evidence"),
                resolution=blocker.get("resolution"),
            )
        )
    lines.extend(["", "## Guardrails", ""])
    lines.extend(f"- {item}" for item in payload.get("guardrails") or [])
    return "\n".join(lines).rstrip() + "\n"


def write_outputs(payload: Mapping[str, Any], stem: str) -> tuple[Path, Path]:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    json_path = REPORT_DIR / f"{stem}.json"
    md_path = REPORT_DIR / f"{stem}.md"
    json_path.write_text(json.dumps(payload, ensure_ascii=True, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    md_path.write_text(render_markdown(payload), encoding="utf-8")
    return json_path, md_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--access-model", type=Path, default=DEFAULT_ACCESS_MODEL)
    parser.add_argument("--focus-queue", type=Path, default=DEFAULT_FOCUS_QUEUE)
    parser.add_argument("--outcome-audit", type=Path, default=DEFAULT_OUTCOME_AUDIT)
    parser.add_argument("--env-file", type=Path)
    parser.add_argument("--run-pg-precheck", action="store_true")
    parser.add_argument("--retry-ssl-require", action="store_true")
    parser.add_argument("--stem", default="lorehold_hidden_retreat_unblock_readiness_20260628_v1")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = build_report(
        manifest_path=args.manifest.resolve(),
        access_model_path=args.access_model.resolve(),
        focus_queue_path=args.focus_queue.resolve(),
        outcome_audit_path=args.outcome_audit.resolve(),
        env_path=args.env_file.resolve() if args.env_file else None,
        run_pg_precheck=args.run_pg_precheck,
        retry_ssl_require=args.retry_ssl_require,
    )
    json_path, md_path = write_outputs(payload, args.stem)
    print(
        json.dumps(
            {
                "status": payload["summary"]["readiness_status"],
                "safe_to_run_battle_gate_now": payload["summary"]["safe_to_run_battle_gate_now"],
                "json": str(json_path),
                "markdown": str(md_path),
                "recommended_next_action": payload["summary"]["recommended_next_action"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
