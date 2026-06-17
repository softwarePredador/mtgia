#!/usr/bin/env python3
import os
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


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
KNOWLEDGE_DB = Path(
    os.environ.get("HERMES_KNOWLEDGE_DB", str(DATA_ROOT / "knowledge.db"))
).resolve()
ENV_FILE = Path(os.environ.get("MTGIA_ENV_FILE", str(REPO_ROOT / "server/.env"))).resolve()
PYTHON_BIN = os.environ.get("PYTHON_BIN", "python3")
MANALOOM_DART_BIN = os.environ.get("MANALOOM_DART_BIN", "dart")
RUN_PREFLIGHT_ON_BOOT = os.environ.get("MANALOOM_RUN_PREFLIGHT_ON_BOOT", "0") == "1"


@dataclass(frozen=True)
class Job:
    name: str
    schedule: str
    lockfile: Path
    command: str


def _base_env() -> dict[str, str]:
    env = dict(os.environ)
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
            "HERMES_ARTIFACT_DIR": str(ARTIFACT_DIR / "hermes_auto_sync"),
            "MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR": str(
                ARTIFACT_DIR / "master_optimizer_preflight"
            ),
        }
    )
    return env


JOBS = [
    Job(
        name="pull_learning_events",
        schedule=os.environ.get("PULL_LEARNING_EVENTS_CRON", "*/30 * * * *"),
        lockfile=LOCK_DIR / "pull_learning_events.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/pull_learning_events.sh',
    ),
    Job(
        name="auto_sync_learned_decks",
        schedule=os.environ.get("AUTO_SYNC_LEARNED_DECKS_CRON", "0 */2 * * *"),
        lockfile=LOCK_DIR / "auto_sync_learned_decks.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/auto_sync_learned_decks.sh',
    ),
    Job(
        name="master_optimizer_preflight",
        schedule=os.environ.get("MASTER_OPTIMIZER_PREFLIGHT_CRON", "15 * * * *"),
        lockfile=LOCK_DIR / "master_optimizer_preflight.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/master_optimizer_preflight.sh',
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


def _run_job(job: Job, env: dict[str, str]) -> None:
    print(
        f"[manaloom-ops] run name={job.name} schedule={job.schedule} "
        f"at={datetime.now().isoformat(timespec='seconds')}",
        flush=True,
    )
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
    )
    print(
        f"[manaloom-ops] done name={job.name} exit_code={result.returncode}",
        flush=True,
    )


def main() -> int:
    LOCK_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    KNOWLEDGE_DB.parent.mkdir(parents=True, exist_ok=True)

    env = _base_env()

    print("[manaloom-ops] scheduler started", flush=True)
    print(f"[manaloom-ops] repo_root={REPO_ROOT}", flush=True)
    print(f"[manaloom-ops] data_root={DATA_ROOT}", flush=True)
    print(f"[manaloom-ops] env_file={ENV_FILE}", flush=True)
    print(f"[manaloom-ops] knowledge_db={KNOWLEDGE_DB}", flush=True)
    for job in JOBS:
        print(
            f"[manaloom-ops] job name={job.name} schedule={job.schedule}",
            flush=True,
        )

    if RUN_PREFLIGHT_ON_BOOT:
        _run_job(JOBS[2], env)

    last_minute: str | None = None
    while True:
        now = datetime.now()
        minute_key = now.strftime("%Y-%m-%d %H:%M")
        if minute_key != last_minute:
            for job in JOBS:
                try:
                    if _matches_schedule(job.schedule, now):
                        _run_job(job, env)
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
