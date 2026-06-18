#!/usr/bin/env python3
import os
import json
import sqlite3
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable


def _resolve_repo_root() -> Path:
    if os.environ.get("MANALOOM_REPO"):
        return Path(os.environ["MANALOOM_REPO"]).resolve()
    return Path(__file__).resolve().parents[2]


REPO_ROOT = _resolve_repo_root()
DATA_ROOT = Path(os.environ.get("MANALOOM_OPS_DATA_DIR", "/data/manaloom-ops")).resolve()
LOCK_DIR = Path(os.environ.get("MANALOOM_OPS_LOCK_DIR", str(DATA_ROOT / "locks"))).resolve()
ARTIFACT_DIR = Path(
    os.environ.get("MANALOOM_OPS_ARTIFACT_DIR", str(DATA_ROOT / "artifacts"))
).resolve()
CRON_DIR = Path(os.environ.get("MANALOOM_OPS_CRON_DIR", str(DATA_ROOT / "cron"))).resolve()
CRON_OUTPUT_DIR = Path(
    os.environ.get("MANALOOM_OPS_CRON_OUTPUT_DIR", str(CRON_DIR / "output"))
).resolve()
JOBS_JSON = Path(
    os.environ.get("MANALOOM_OPS_JOBS_JSON", str(CRON_DIR / "jobs.json"))
).resolve()
KNOWLEDGE_DB = Path(
    os.environ.get("HERMES_KNOWLEDGE_DB", str(DATA_ROOT / "knowledge.db"))
).resolve()
ENV_FILE = Path(os.environ.get("MTGIA_ENV_FILE", str(REPO_ROOT / "server/.env"))).resolve()
PYTHON_BIN = os.environ.get("PYTHON_BIN", "python3")
MANALOOM_DART_BIN = os.environ.get("MANALOOM_DART_BIN", "dart")
RUN_PREFLIGHT_ON_BOOT = os.environ.get("MANALOOM_RUN_PREFLIGHT_ON_BOOT", "0") == "1"
BOOT_PULL_PENDING_EVENTS = os.environ.get("MANALOOM_BOOT_PULL_PENDING_EVENTS", "1") == "1"


@dataclass(frozen=True)
class Job:
    name: str
    schedule: str
    lockfile: Path
    command: str
    script_name: str


def _base_env() -> dict[str, str]:
    env = dict(os.environ)
    if ENV_FILE.is_file():
        for raw_line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in raw_line:
                continue
            key, value = raw_line.split("=", 1)
            key = key.strip()
            value = value.strip().strip("\"'")
            if key and key not in env:
                env[key] = value
    env.update(
        {
            "MTGIA_HOME": str(REPO_ROOT),
            "MTGIA_SYNC_HOME": str(REPO_ROOT),
            "MTGIA_SYNC_SERVER_DIR": str(REPO_ROOT / "server"),
            "MTGIA_ENV_FILE": str(ENV_FILE),
            "MTGIA_SYNC_GIT_PULL": "0",
            "PYTHON_BIN": PYTHON_BIN,
            "MANALOOM_DART_BIN": MANALOOM_DART_BIN,
            "HERMES_KNOWLEDGE_DB": str(KNOWLEDGE_DB),
            "MANALOOM_KNOWLEDGE_DB": str(KNOWLEDGE_DB),
            "HERMES_ARTIFACT_DIR": str(ARTIFACT_DIR / "hermes_auto_sync"),
            "HERMES_PROFILE_ARTIFACTS_DIR": str(REPO_ROOT / "server/test/artifacts"),
            "HERMES_MANA_BASE_REPORT": str(
                ARTIFACT_DIR / "hermes_mana_base_validator/latest_mana_base_validation_report.md"
            ),
            "HERMES_CRON_JOBS_JSON": str(JOBS_JSON),
            "HERMES_CRON_OUTPUT_DIR": str(CRON_OUTPUT_DIR),
            "HERMES_SCRIPTS_DIR": str(REPO_ROOT / "server/bin"),
            "HERMES_CRON_GOVERNOR_REPORT": str(
                ARTIFACT_DIR / "hermes_cron_governor/latest_cron_governor_report.md"
            ),
            "MANALOOM_KNOWLEDGE_IMPORT_ARTIFACT_DIR": str(
                ARTIFACT_DIR / "knowledge_import"
            ),
            "MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR": str(
                ARTIFACT_DIR / "master_optimizer_preflight"
            ),
        }
    )
    return env


def _knowledge_db_has_validator_tables(path: Path) -> bool:
    if not path.exists():
        return False
    try:
        with sqlite3.connect(path) as conn:
            tables = {
                row[0]
                for row in conn.execute(
                    "SELECT name FROM sqlite_master WHERE type='table'"
                ).fetchall()
            }
        return {"decks", "deck_cards"}.issubset(tables)
    except sqlite3.Error:
        return False


def _load_psycopg2():
    import psycopg2  # type: ignore
    import psycopg2.extras  # type: ignore

    return psycopg2, psycopg2.extras


def _pg_pending_learning_events_count(env: dict[str, str]) -> int | None:
    try:
        psycopg2, extras = _load_psycopg2()
        database_url = env.get("DATABASE_URL")
        connect_kwargs = {"connect_timeout": 10}
        if database_url:
            conn = psycopg2.connect(dsn=database_url, cursor_factory=extras.RealDictCursor, **connect_kwargs)
        else:
            conn = psycopg2.connect(
                host=env.get("DB_HOST", ""),
                port=env.get("DB_PORT", "5432"),
                dbname=env.get("DB_NAME", ""),
                user=env.get("DB_USER", ""),
                password=env.get("DB_PASS", ""),
                cursor_factory=extras.RealDictCursor,
                **connect_kwargs,
            )
    except Exception as exc:
        print(f"[manaloom-ops] pending learning-events probe failed at connect: {exc}", flush=True)
        return None

    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT COUNT(*) AS pending FROM deck_learning_events WHERE synced_to_hermes = FALSE"
                )
                row = cur.fetchone() or {}
                return int(row.get("pending") or 0)
    except Exception as exc:
        print(f"[manaloom-ops] pending learning-events probe failed at query: {exc}", flush=True)
        return None
    finally:
        conn.close()


def _collect_boot_jobs(
    env: dict[str, str],
    *,
    knowledge_db_path: Path,
    knowledge_db_has_validator_tables: Callable[[Path], bool] = _knowledge_db_has_validator_tables,
    pending_learning_events_count: Callable[[dict[str, str]], int | None] = _pg_pending_learning_events_count,
) -> list[tuple[str, str]]:
    planned: list[tuple[str, str]] = []
    if BOOT_PULL_PENDING_EVENTS:
        pending_events = pending_learning_events_count(env)
        if pending_events and pending_events > 0:
            planned.append(
                (
                    "pull_learning_events",
                    f"pending_learning_events={pending_events}",
                )
            )

    if RUN_PREFLIGHT_ON_BOOT or not knowledge_db_has_validator_tables(knowledge_db_path):
        reason = (
            "env_enabled"
            if RUN_PREFLIGHT_ON_BOOT
            else "knowledge_db_missing_validator_tables"
        )
        planned.append(("master_optimizer_preflight", reason))
    return planned


JOBS = [
    Job(
        name="pull_learning_events",
        schedule=os.environ.get("PULL_LEARNING_EVENTS_CRON", "0 * * * *"),
        lockfile=LOCK_DIR / "pull_learning_events.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/pull_learning_events.sh',
        script_name="pull_learning_events.sh",
    ),
    Job(
        name="auto_sync_learned_decks",
        schedule=os.environ.get("AUTO_SYNC_LEARNED_DECKS_CRON", "0 */2 * * *"),
        lockfile=LOCK_DIR / "auto_sync_learned_decks.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/auto_sync_learned_decks.sh',
        script_name="auto_sync_learned_decks.sh",
    ),
    Job(
        name="auto_promote_learned_decks",
        schedule=os.environ.get("AUTO_PROMOTE_LEARNED_DECKS_CRON", "30 */6 * * *"),
        lockfile=LOCK_DIR / "auto_promote_learned_decks.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/auto_promote_learned_decks.sh',
        script_name="auto_promote_learned_decks.sh",
    ),
    Job(
        name="master_optimizer_preflight",
        schedule=os.environ.get("MASTER_OPTIMIZER_PREFLIGHT_CRON", "15 * * * *"),
        lockfile=LOCK_DIR / "master_optimizer_preflight.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/master_optimizer_preflight.sh',
        script_name="master_optimizer_preflight.sh",
    ),
    Job(
        name="manaloom_knowledge_import",
        schedule=os.environ.get("MANALOOM_KNOWLEDGE_IMPORT_CRON", "20 */12 * * *"),
        lockfile=LOCK_DIR / "manaloom_knowledge_import.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/manaloom_knowledge_import.sh',
        script_name="manaloom_knowledge_import.sh",
    ),
    Job(
        name="hermes_mana_base_validator",
        schedule=os.environ.get("HERMES_MANA_BASE_VALIDATOR_CRON", "45 */6 * * *"),
        lockfile=LOCK_DIR / "hermes_mana_base_validator.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/hermes_mana_base_validator.sh',
        script_name="hermes_mana_base_validator.sh",
    ),
    Job(
        name="hermes_cron_governor_report",
        schedule=os.environ.get("HERMES_CRON_GOVERNOR_REPORT_CRON", "0 */12 * * *"),
        lockfile=LOCK_DIR / "hermes_cron_governor_report.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/hermes_cron_governor_report.sh',
        script_name="hermes_cron_governor_report.sh",
    ),
]


def _matches_part(value: int, expr: str) -> bool:
    expr = expr.strip()
    if expr == "*":
        return True
    if expr.startswith("*/"):
        try:
            step = int(expr[2:])
        except ValueError:
            return False
        return step > 0 and value % step == 0
    if "," in expr:
        return any(_matches_part(value, part) for part in expr.split(","))
    try:
        return value == int(expr)
    except ValueError:
        return False


def _matches_schedule(schedule: str, now: datetime) -> bool:
    parts = schedule.split()
    if len(parts) != 5:
        raise ValueError(f"unsupported cron expression: {schedule}")
    minute, hour, dom, month, dow = parts
    cron_dow = (now.weekday() + 1) % 7
    return all(
        [
            _matches_part(now.minute, minute),
            _matches_part(now.hour, hour),
            _matches_part(now.day, dom),
            _matches_part(now.month, month),
            _matches_part(cron_dow, dow),
        ]
    )


def _write_jobs_manifest(
    jobs: list[Job],
    state: dict[str, dict[str, object]],
) -> None:
    JOBS_JSON.parent.mkdir(parents=True, exist_ok=True)
    payload = []
    for job in jobs:
        job_state = state.get(job.name, {})
        payload.append(
            {
                "id": job.name,
                "name": job.name,
                "enabled": True,
                "script": job.script_name,
                "schedule": job.schedule,
                "schedule_display": job.schedule,
                "last_status": job_state.get("last_status"),
                "last_started_at": job_state.get("last_started_at"),
                "last_finished_at": job_state.get("last_finished_at"),
                "last_exit_code": job_state.get("last_exit_code"),
                "latest_output": job_state.get("latest_output"),
            }
        )
    JOBS_JSON.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def _job_log_path(job: Job) -> Path:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    job_dir = CRON_OUTPUT_DIR / job.name
    job_dir.mkdir(parents=True, exist_ok=True)
    return job_dir / f"{timestamp}.log"


def _tail_excerpt(path: Path, max_lines: int = 6) -> str:
    if not path.exists():
        return ""
    lines = path.read_text(errors="replace").splitlines()
    if not lines:
        return ""
    return " | ".join(line.strip() for line in lines[-max_lines:] if line.strip())[:600]


def _run_job(job: Job, env: dict[str, str], state: dict[str, dict[str, object]]) -> None:
    started_at = datetime.now().isoformat(timespec="seconds")
    log_path = _job_log_path(job)
    state[job.name] = {
        **state.get(job.name, {}),
        "last_started_at": started_at,
        "latest_output": str(log_path),
    }
    _write_jobs_manifest(JOBS, state)
    print(
        f"[manaloom-ops] run name={job.name} schedule={job.schedule} "
        f"at={started_at} log={log_path}",
        flush=True,
    )
    with log_path.open("w", encoding="utf-8") as handle:
        result = subprocess.run(
            [
                "flock",
                "-n",
                str(job.lockfile),
                "bash",
                "-lc",
                job.command,
            ],
            cwd=REPO_ROOT,
            env=env,
            check=False,
            stdout=handle,
            stderr=subprocess.STDOUT,
        )
    finished_at = datetime.now().isoformat(timespec="seconds")
    state[job.name] = {
        "last_status": "ok" if result.returncode == 0 else "error",
        "last_started_at": started_at,
        "last_finished_at": finished_at,
        "last_exit_code": result.returncode,
        "latest_output": str(log_path),
    }
    _write_jobs_manifest(JOBS, state)
    excerpt = _tail_excerpt(log_path)
    print(
        f"[manaloom-ops] done name={job.name} exit_code={result.returncode}",
        flush=True,
    )
    if excerpt:
        print(f"[manaloom-ops] excerpt name={job.name} tail={excerpt}", flush=True)


def main() -> int:
    LOCK_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    CRON_DIR.mkdir(parents=True, exist_ok=True)
    CRON_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    KNOWLEDGE_DB.parent.mkdir(parents=True, exist_ok=True)

    env = _base_env()
    state: dict[str, dict[str, object]] = {}
    _write_jobs_manifest(JOBS, state)

    print("[manaloom-ops] scheduler started", flush=True)
    print(f"[manaloom-ops] repo_root={REPO_ROOT}", flush=True)
    print(f"[manaloom-ops] data_root={DATA_ROOT}", flush=True)
    print(f"[manaloom-ops] env_file={ENV_FILE}", flush=True)
    print(f"[manaloom-ops] knowledge_db={KNOWLEDGE_DB}", flush=True)
    print(f"[manaloom-ops] jobs_json={JOBS_JSON}", flush=True)
    print(f"[manaloom-ops] cron_output_dir={CRON_OUTPUT_DIR}", flush=True)
    for job in JOBS:
        print(
            f"[manaloom-ops] job name={job.name} schedule={job.schedule} script={job.script_name}",
            flush=True,
        )

    for job_name, reason in _collect_boot_jobs(env, knowledge_db_path=KNOWLEDGE_DB):
        job = next((candidate for candidate in JOBS if candidate.name == job_name), None)
        if job is None:
            continue
        print(
            f"[manaloom-ops] boot trigger name={job_name} reason={reason}",
            flush=True,
        )
        _run_job(job, env, state)

    last_minute: str | None = None
    while True:
        now = datetime.now()
        minute_key = now.strftime("%Y-%m-%d %H:%M")
        if minute_key != last_minute:
            for job in JOBS:
                try:
                    if _matches_schedule(job.schedule, now):
                        _run_job(job, env, state)
                except Exception as exc:  # keep scheduler alive even on bad schedule
                    print(
                        f"[manaloom-ops] error name={job.name} schedule={job.schedule} "
                        f"message={exc}",
                        file=sys.stderr,
                        flush=True,
                    )
            last_minute = minute_key
        time.sleep(5)


if __name__ == "__main__":
    raise SystemExit(main())
