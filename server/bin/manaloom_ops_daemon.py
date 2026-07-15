#!/usr/bin/env python3
import os
import json
import re
import sqlite3
import subprocess
import sys
import threading
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
CANONICAL_SNAPSHOT = Path(
    os.environ.get(
        "MANALOOM_CANONICAL_KNOWN_CARDS_JSON",
        str(DATA_ROOT / "known_cards_canonical_snapshot.runtime.json"),
    )
).resolve()
ENV_FILE = Path(os.environ.get("MTGIA_ENV_FILE", str(REPO_ROOT / "server/.env"))).resolve()
PYTHON_BIN = os.environ.get("PYTHON_BIN", "python3")
MANALOOM_DART_BIN = os.environ.get("MANALOOM_DART_BIN", "dart")
RUN_PREFLIGHT_ON_BOOT = os.environ.get("MANALOOM_RUN_PREFLIGHT_ON_BOOT", "0") == "1"
BOOT_PULL_PENDING_EVENTS = os.environ.get("MANALOOM_BOOT_PULL_PENDING_EVENTS", "1") == "1"
NATIVE_BATTLE_HTTP_ENABLED = os.environ.get("MANALOOM_NATIVE_BATTLE_HTTP_ENABLED", "1") == "1"
NATIVE_BATTLE_SYNC_ON_BOOT = os.environ.get("MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT", "1") == "1"


@dataclass(frozen=True)
class Job:
    name: str
    schedule: str
    lockfile: Path
    command: str
    script_name: str
    background: bool = False


STATE_WRITE_LOCK = threading.Lock()


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
            "MANALOOM_CANONICAL_KNOWN_CARDS_JSON": str(CANONICAL_SNAPSHOT),
            "MANALOOM_NATIVE_BATTLE_HOST": os.environ.get(
                "MANALOOM_NATIVE_BATTLE_HOST", "0.0.0.0"
            ),
            "MANALOOM_NATIVE_BATTLE_PORT": os.environ.get(
                "MANALOOM_NATIVE_BATTLE_PORT", "8080"
            ),
            "HERMES_ARTIFACT_DIR": str(ARTIFACT_DIR / "hermes_auto_sync"),
            "HERMES_PROFILE_ARTIFACTS_DIR": str(REPO_ROOT / "server/test/artifacts"),
            "HERMES_MANA_BASE_REPORT": str(
                ARTIFACT_DIR / "hermes_mana_base_validator/latest_mana_base_validation_report.md"
            ),
            "MANALOOM_CARD_DATA_GAP_REVIEW_DIR": str(
                ARTIFACT_DIR / "card_data_gap_review"
            ),
            "MANALOOM_BATTLE_RULE_REVIEW_QUEUE_DIR": str(
                ARTIFACT_DIR / "battle_rule_review_queue"
            ),
            "MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE_DIR": str(
                ARTIFACT_DIR / "battle_rule_focused_evidence"
            ),
            "MANALOOM_BATTLE_RULE_PROMOTION_EVIDENCE_FILE": str(
                ARTIFACT_DIR / "battle_rule_focused_evidence/latest_evidence.json"
            ),
            "MANALOOM_BATTLE_STRATEGY_BASE_DIR": str(DATA_ROOT),
            "MANALOOM_BATTLE_STRATEGY_ARTIFACT_ROOT": str(
                ARTIFACT_DIR / "battle-strategy-audit"
            ),
            "MANALOOM_BATTLE_STRATEGY_LOG_DIR": str(DATA_ROOT / "logs"),
            "MANALOOM_BATTLE_STRATEGY_LOG_TO_STDOUT": "1",
            "MANALOOM_BATTLE_STRATEGY_DESKTOP_NOTIFICATIONS": "0",
            "MANALOOM_REPO_DIR": str(REPO_ROOT),
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
            "MANALOOM_NEW_CARD_CANDIDATE_REVIEW_DIR": str(
                ARTIFACT_DIR / "new_card_candidate_review"
            ),
            "MANALOOM_SYNC_CARD_LEGALITIES_OUTPUT_DIR": str(
                ARTIFACT_DIR / "sync_card_legalities_from_scryfall"
            ),
        }
    )
    return env


def _sync_native_battle_rules(env: dict[str, str]) -> None:
    if not NATIVE_BATTLE_SYNC_ON_BOOT:
        return
    script = (
        REPO_ROOT
        / "docs"
        / "hermes-analysis"
        / "manaloom-knowledge"
        / "scripts"
        / "sync_battle_card_rules_pg.py"
    )
    completed = subprocess.run(
        [
            PYTHON_BIN,
            str(script),
            "--sqlite-db",
            str(KNOWLEDGE_DB),
            "--apply-sqlite-from-pg",
            "--export-canonical-fallback-json",
            str(CANONICAL_SNAPSHOT),
        ],
        cwd=REPO_ROOT,
        env=env,
        check=False,
        text=True,
        capture_output=True,
    )
    if completed.returncode != 0:
        detail = (completed.stderr or completed.stdout or "unknown sync failure")[-2000:]
        raise RuntimeError(f"native battle rule sync failed: {detail}")
    print(
        f"[manaloom-ops] native battle rules synchronized db={KNOWLEDGE_DB}",
        flush=True,
    )


def _start_native_battle_http() -> object | None:
    if not NATIVE_BATTLE_HTTP_ENABLED:
        return None
    os.environ["MANALOOM_KNOWLEDGE_DB"] = str(KNOWLEDGE_DB)
    os.environ["MANALOOM_CANONICAL_KNOWN_CARDS_JSON"] = str(CANONICAL_SNAPSHOT)
    from native_battle_sidecar import create_server

    server = create_server()
    thread = threading.Thread(
        target=server.serve_forever,
        name="manaloom-native-battle-http",
        daemon=True,
    )
    thread.start()
    if not thread.is_alive():
        raise RuntimeError("native battle HTTP thread failed to start")
    print(
        f"[manaloom-ops] native battle HTTP started address={server.server_address}",
        flush=True,
    )
    return server


def _knowledge_db_has_validator_tables(path: Path) -> bool:
    if not path.exists():
        return False
    try:
        conn = sqlite3.connect(path)
        try:
            tables = {
                row[0]
                for row in conn.execute(
                    "SELECT name FROM sqlite_master WHERE type='table'"
                ).fetchall()
            }
        finally:
            conn.close()
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
        name="manaloom_sync_card_legalities_from_scryfall",
        schedule=os.environ.get(
            "MANALOOM_SYNC_CARD_LEGALITIES_CRON",
            "30 */6 * * *",
        ),
        lockfile=LOCK_DIR / "manaloom_sync_card_legalities_from_scryfall.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/sync_card_legalities_from_scryfall.sh',
        script_name="sync_card_legalities_from_scryfall.sh",
    ),
    Job(
        name="manaloom_new_card_candidate_review",
        schedule=os.environ.get(
            "MANALOOM_NEW_CARD_CANDIDATE_REVIEW_CRON",
            "35 */6 * * *",
        ),
        lockfile=LOCK_DIR / "manaloom_new_card_candidate_review.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/manaloom_new_card_candidate_review.sh',
        script_name="manaloom_new_card_candidate_review.sh",
    ),
    Job(
        name="manaloom_card_data_gap_review",
        schedule=os.environ.get("MANALOOM_CARD_DATA_GAP_REVIEW_CRON", "50 */6 * * *"),
        lockfile=LOCK_DIR / "manaloom_card_data_gap_review.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/manaloom_card_data_gap_review.sh',
        script_name="manaloom_card_data_gap_review.sh",
    ),
    Job(
        name="manaloom_battle_rule_review_queue",
        schedule=os.environ.get("MANALOOM_BATTLE_RULE_REVIEW_QUEUE_CRON", "55 */6 * * *"),
        lockfile=LOCK_DIR / "manaloom_battle_rule_review_queue.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/manaloom_battle_rule_review_queue.sh',
        script_name="manaloom_battle_rule_review_queue.sh",
    ),
    Job(
        name="manaloom_battle_rule_focused_evidence",
        schedule=os.environ.get("MANALOOM_BATTLE_RULE_FOCUSED_EVIDENCE_CRON", "56 */6 * * *"),
        lockfile=LOCK_DIR / "manaloom_battle_rule_focused_evidence.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/manaloom_battle_rule_focused_evidence.sh',
        script_name="manaloom_battle_rule_focused_evidence.sh",
    ),
    Job(
        name="manaloom_battle_rule_promotion_gate",
        schedule=os.environ.get("MANALOOM_BATTLE_RULE_PROMOTION_GATE_CRON", "58 */6 * * *"),
        lockfile=LOCK_DIR / "manaloom_battle_rule_promotion_gate.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/manaloom_battle_rule_promotion_gate.sh',
        script_name="manaloom_battle_rule_promotion_gate.sh",
    ),
    Job(
        name="auto_promote_learned_decks",
        schedule=os.environ.get("AUTO_PROMOTE_LEARNED_DECKS_CRON", "30 */6 * * *"),
        lockfile=LOCK_DIR / "auto_promote_learned_decks.lock",
        command='cd "$MTGIA_HOME" && ./server/bin/auto_promote_learned_decks.sh',
        script_name="auto_promote_learned_decks.sh",
    ),
    Job(
        name="manaloom_battle_strategy_audit",
        schedule=os.environ.get(
            "MANALOOM_BATTLE_STRATEGY_AUDIT_CRON",
            "5 0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23 * * *",
        ),
        lockfile=LOCK_DIR / "manaloom_battle_strategy_audit_scheduler.lock",
        command=(
            'cd "$MTGIA_HOME" && '
            'MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND=scheduled_hourly '
            './server/bin/manaloom_battle_strategy_audit.sh '
            '--seeds "${MANALOOM_BATTLE_STRATEGY_SEEDS:-16}"'
        ),
        script_name="manaloom_battle_strategy_audit.sh",
        background=True,
    ),
    Job(
        name="manaloom_battle_strategy_nightly",
        schedule=os.environ.get("MANALOOM_BATTLE_STRATEGY_NIGHTLY_CRON", "5 6 * * *"),
        lockfile=LOCK_DIR / "manaloom_battle_strategy_nightly_scheduler.lock",
        command=(
            'cd "$MTGIA_HOME" && '
            'MANALOOM_BATTLE_STRATEGY_INVOCATION_KIND=scheduled_nightly '
            './server/bin/manaloom_battle_strategy_audit.sh '
            '--seeds "${MANALOOM_BATTLE_STRATEGY_NIGHTLY_SEEDS:-64}"'
        ),
        script_name="manaloom_battle_strategy_audit.sh",
        background=True,
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
                "background": job.background,
                "last_status": job_state.get("last_status"),
                "last_started_at": job_state.get("last_started_at"),
                "last_finished_at": job_state.get("last_finished_at"),
                "last_exit_code": job_state.get("last_exit_code"),
                "last_error": job_state.get("last_error"),
                "latest_output": job_state.get("latest_output"),
            }
        )
    JOBS_JSON.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def _load_existing_state(jobs: list[Job]) -> dict[str, dict[str, object]]:
    if not JOBS_JSON.exists():
        return {}
    try:
        payload = json.loads(JOBS_JSON.read_text(encoding="utf-8"))
    except Exception:
        return {}
    if isinstance(payload, dict):
        payload = payload.get("jobs", payload)
    if not isinstance(payload, list):
        return {}

    allowed_names = {job.name for job in jobs}
    fields = (
        "last_status",
        "last_started_at",
        "last_finished_at",
        "last_exit_code",
        "last_error",
        "latest_output",
    )
    state: dict[str, dict[str, object]] = {}
    for row in payload:
        if not isinstance(row, dict):
            continue
        job_name = str(row.get("name") or row.get("id") or "").strip()
        if not job_name or job_name not in allowed_names:
            continue
        state[job_name] = {
            field: row[field]
            for field in fields
            if field in row and row[field] is not None
        }
        if state[job_name].get("last_status") == "running":
            state[job_name]["last_status"] = "error"
            state[job_name]["last_error"] = "interrupted_by_process_restart"
    for job in jobs:
        recovered = _recover_state_from_output_dir(job)
        if not recovered:
            continue
        current = state.get(job.name, {})
        if not any(current.get(field) is not None for field in fields):
            state[job.name] = recovered
            continue
        current_started = str(current.get("last_started_at") or "")
        recovered_started = str(recovered.get("last_started_at") or "")
        if recovered_started and (
            not current_started or recovered_started > current_started
        ):
            state[job.name] = {**current, **recovered}
    return state


_LOG_TIMESTAMP_RE = re.compile(r"(?P<stamp>\d{8}_\d{6})\.log$")


def _parse_log_timestamp(path: Path) -> str | None:
    match = _LOG_TIMESTAMP_RE.search(path.name)
    if not match:
        return None
    stamp = match.group("stamp")
    try:
        return datetime.strptime(stamp, "%Y%m%d_%H%M%S").isoformat(timespec="seconds")
    except ValueError:
        return None


def _infer_status_from_output(path: Path) -> str | None:
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8", errors="replace")
    lowered = text.lower()
    error_markers = (
        "traceback",
        "runtimeerror",
        "keyboardinterrupt",
        "fatal:",
        "exception",
        "error:",
    )
    if any(marker in lowered for marker in error_markers):
        return "error"
    success_markers = (
        "=ok",
        "houve mudanças nos dados.",
        "script gate returned `wakeagent=false`",
        "script gate returned `wakeagent=true`",
        "nenhum evento novo.",
        "nenhum deck promovido elegivel encontrado.",
        "totals promoted=",
        "manaloom_sync_card_legalities",
        "manaloom_new_card_candidate_review",
        "manaloom_card_data_gap_review",
        "manaloom_battle_rule_review_queue",
        "manaloom_battle_rule_focused_evidence",
        "manaloom_battle_rule_promotion_gate",
        "# mana base validation report",
        "## enabled jobs",
    )
    if any(marker in lowered for marker in success_markers):
        return "ok"
    if text.strip():
        return "ok"
    return None


def _recover_state_from_output_dir(job: Job) -> dict[str, object]:
    job_dir = CRON_OUTPUT_DIR / job.name
    if not job_dir.exists():
        return {}
    candidates = sorted(job_dir.glob("*.log"), key=lambda path: path.name, reverse=True)
    if not candidates:
        return {}
    latest = candidates[0]
    started_at = _parse_log_timestamp(latest)
    status = _infer_status_from_output(latest)
    recovered: dict[str, object] = {
        "latest_output": str(latest),
    }
    if started_at is not None:
        recovered["last_started_at"] = started_at
        recovered["last_finished_at"] = started_at
    if status is not None:
        recovered["last_status"] = status
        recovered["last_exit_code"] = 0 if status == "ok" else 1
    return recovered


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
    with STATE_WRITE_LOCK:
        state[job.name] = {
            **state.get(job.name, {}),
            "last_status": "running",
            "last_started_at": started_at,
            "last_finished_at": None,
            "last_exit_code": None,
            "last_error": None,
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
    with STATE_WRITE_LOCK:
        state[job.name] = {
            "last_status": "ok" if result.returncode == 0 else "error",
            "last_started_at": started_at,
            "last_finished_at": finished_at,
            "last_exit_code": result.returncode,
            "last_error": None,
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


def _start_background_job(
    job: Job,
    env: dict[str, str],
    state: dict[str, dict[str, object]],
    active_jobs: dict[str, threading.Thread],
    active_jobs_lock: threading.Lock,
) -> bool:
    with active_jobs_lock:
        current = active_jobs.get(job.name)
        if current is not None and current.is_alive():
            print(f"[manaloom-ops] skip active background job name={job.name}", flush=True)
            return False

        def run() -> None:
            try:
                _run_job(job, env, state)
            except Exception as exc:
                finished_at = datetime.now().isoformat(timespec="seconds")
                with STATE_WRITE_LOCK:
                    state[job.name] = {
                        **state.get(job.name, {}),
                        "last_status": "error",
                        "last_finished_at": finished_at,
                        "last_exit_code": 1,
                        "last_error": str(exc),
                    }
                    _write_jobs_manifest(JOBS, state)
                print(
                    f"[manaloom-ops] background error name={job.name} error={exc}",
                    flush=True,
                )
            finally:
                with active_jobs_lock:
                    active_jobs.pop(job.name, None)

        thread = threading.Thread(
            target=run,
            name=f"manaloom-ops-{job.name}",
            daemon=True,
        )
        active_jobs[job.name] = thread
        thread.start()
        return True


def main() -> int:
    LOCK_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    CRON_DIR.mkdir(parents=True, exist_ok=True)
    CRON_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    KNOWLEDGE_DB.parent.mkdir(parents=True, exist_ok=True)

    env = _base_env()
    _sync_native_battle_rules(env)
    native_battle_server = _start_native_battle_http()
    state = _load_existing_state(JOBS)
    _write_jobs_manifest(JOBS, state)
    active_jobs: dict[str, threading.Thread] = {}
    active_jobs_lock = threading.Lock()

    print("[manaloom-ops] scheduler started", flush=True)
    print(f"[manaloom-ops] repo_root={REPO_ROOT}", flush=True)
    print(f"[manaloom-ops] data_root={DATA_ROOT}", flush=True)
    print(f"[manaloom-ops] env_file={ENV_FILE}", flush=True)
    print(f"[manaloom-ops] knowledge_db={KNOWLEDGE_DB}", flush=True)
    print(f"[manaloom-ops] jobs_json={JOBS_JSON}", flush=True)
    print(f"[manaloom-ops] cron_output_dir={CRON_OUTPUT_DIR}", flush=True)
    print(
        f"[manaloom-ops] native_battle_http={'enabled' if native_battle_server else 'disabled'}",
        flush=True,
    )
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
                        if job.background:
                            _start_background_job(
                                job,
                                env,
                                state,
                                active_jobs,
                                active_jobs_lock,
                            )
                        else:
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
