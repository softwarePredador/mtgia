#!/usr/bin/env python3
"""Audit EasyPanel runtime alignment for ManaLoom server-owned ops.

Read-only audit:
- compares local HEAD with public backend SHA and EasyPanel service SHAs
- inspects service env for canonical knowledge DB wiring and OpenAI presence
- validates PostgreSQL side effects that should move under manaloom-ops
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import ssl
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import parse_qsl, urlsplit


REPO_ROOT = Path(__file__).resolve().parents[2]
SERVER_DIR = REPO_ROOT / "server"
DEFAULT_ARTIFACT_DIR = REPO_ROOT / "server" / "test" / "artifacts" / "easypanel_runtime_alignment"
DEFAULT_HEALTH_URL = "https://evolution-cartinhas.2ta7qx.easypanel.host/health"
DEFAULT_SERVICES = ("manaloom-ops",)
DEFAULT_PROJECT = "evolution"
EXPECTED_POSTGRES_HOST = "evolution_manaloom-postgres"
EXPECTED_POSTGRES_DB = "halder"
EXPECTED_POSTGRES_USER = "postgres"
APPROVED_SWARM_SERVICES = frozenset({"evolution_manaloom-ops"})
NEW_SERVER_PG_WRAPPER = SERVER_DIR / "bin" / "with_new_server_pg.sh"
EXPLICIT_APPROVAL_PHRASE = "I_HAVE_EXPLICIT_APPROVAL"
LIVE_MUTATION_APPROVAL_ENV = "MANALOOM_CONFIRM_LIVE_MUTATIONS"
POSTGRES_WRITE_APPROVAL_ENV = "MANALOOM_CONFIRM_POSTGRES_WRITES"

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reconcile_easypanel_services as reconcile  # noqa: E402


@dataclass(frozen=True)
class PendingEvent:
    id: str
    deck_id: str
    commander_name: str
    source: str
    card_count: int
    created_at: str


def _iso(dt: Any) -> str | None:
    if dt is None:
        return None
    if hasattr(dt, "isoformat"):
        return dt.isoformat()
    return str(dt)


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _load_psycopg2():
    import psycopg2  # type: ignore
    import psycopg2.extras  # type: ignore

    return psycopg2, psycopg2.extras


def _pg_connection_kwargs(runtime_env: dict[str, str]) -> dict[str, Any]:
    database_url = runtime_env.get("DATABASE_URL")
    if database_url:
        return {"dsn": database_url, "connect_timeout": 10}
    return {
        "host": runtime_env.get("DB_HOST", "127.0.0.1"),
        "port": runtime_env.get("DB_PORT", "5432"),
        "dbname": runtime_env.get("DB_NAME", ""),
        "user": runtime_env.get("DB_USER", ""),
        "password": runtime_env.get("DB_PASS", ""),
        "connect_timeout": 10,
    }


def _health_ssl_context() -> ssl.SSLContext:
    try:
        import certifi  # type: ignore

        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


def _fetch_public_health(url: str) -> dict[str, Any]:
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(
        request,
        timeout=15,
        context=_health_ssl_context(),
    ) as response:
        return json.loads(response.read().decode("utf-8", "replace"))


def _fetch_service_env_snapshot(
    client: reconcile.EasyPanelClient,
    *,
    project_name: str,
    service_names: tuple[str, ...],
    runtime_env: dict[str, str],
) -> dict[str, dict[str, Any]]:
    payload = client.list_projects_and_services()
    snapshots: dict[str, dict[str, Any]] = {}
    for service_name in service_names:
        try:
            state = reconcile._collect_service_state(payload, project_name, service_name)
            env_map = reconcile._parse_dotenv(state.env_text)
            snapshots[service_name] = {
                "enabled": state.enabled,
                "sha": state.sha,
                "image": None,
                "runtime_source": "easypanel_api",
                "source_ref": state.source_ref,
                "source_path": state.source_path,
                "replicas": state.replicas,
                "zero_downtime": state.zero_downtime,
                "knowledge_db": env_map.get("HERMES_KNOWLEDGE_DB"),
                "manaloom_knowledge_db": env_map.get("MANALOOM_KNOWLEDGE_DB"),
                "openai_api_key_present": bool(env_map.get("OPENAI_API_KEY")),
                "hermes_model": env_map.get("HERMES_MODEL"),
                "api_server_enabled": env_map.get("API_SERVER_ENABLED"),
            }
        except reconcile.EasyPanelError:
            snapshots[service_name] = _fetch_swarm_service_snapshot(
                runtime_env,
                swarm_service_name=f"{project_name}_{service_name}",
            )
    return snapshots


def _snapshot_from_swarm_inspect(service: dict[str, Any]) -> dict[str, Any]:
    spec = service.get("Spec") or {}
    task = spec.get("TaskTemplate") or {}
    container = task.get("ContainerSpec") or {}
    replicated = (spec.get("Mode") or {}).get("Replicated") or {}
    update = spec.get("UpdateConfig") or {}
    env_map = reconcile._parse_dotenv("\n".join(container.get("Env") or []))
    return {
        "enabled": True,
        "sha": env_map.get("GIT_SHA"),
        "image": container.get("Image"),
        "runtime_source": "docker_swarm",
        "source_ref": None,
        "source_path": None,
        "replicas": replicated.get("Replicas"),
        "zero_downtime": update.get("Order") != "stop-first",
        "knowledge_db": env_map.get("HERMES_KNOWLEDGE_DB"),
        "manaloom_knowledge_db": env_map.get("MANALOOM_KNOWLEDGE_DB"),
        "openai_api_key_present": bool(env_map.get("OPENAI_API_KEY")),
        "hermes_model": env_map.get("HERMES_MODEL"),
        "api_server_enabled": env_map.get("API_SERVER_ENABLED"),
    }


def _validated_easypanel_base_url(candidate: str) -> str:
    expected_hash = os.environ.get(
        "MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256",
        "",
    )
    if not re.fullmatch(r"[0-9a-f]{64}", expected_hash):
        raise RuntimeError(
            "MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256 must pin the approved EasyPanel origin"
        )
    parsed = urlsplit(candidate)
    if not (
        parsed.scheme == "https"
        and parsed.hostname
        and parsed.username is None
        and parsed.password is None
        and parsed.path in {"", "/"}
        and not parsed.query
        and not parsed.fragment
    ):
        raise RuntimeError(
            "EASYPANEL_BASE_URL must be an HTTPS origin without credentials, path, query, or fragment"
        )
    normalized = candidate.rstrip("/")
    actual_hash = hashlib.sha256(normalized.encode("utf-8")).hexdigest()
    if actual_hash != expected_hash:
        raise RuntimeError("EASYPANEL_BASE_URL differs from the caller-approved fingerprint")
    return normalized


def _validated_ssh_coordinate(
    runtime_env: dict[str, str],
) -> tuple[str, Path, str, str]:
    target = runtime_env.get("MANALOOM_EASYPANEL_SSH_HOST") or (
        f"{runtime_env.get('EASYPANEL_SSH_USER', 'root')}@"
        f"{runtime_env.get('EASYPANEL_SERVER_IP', '')}"
    )
    key_value = runtime_env.get("MANALOOM_EASYPANEL_SSH_KEY") or runtime_env.get(
        "EASYPANEL_SSH_KEY"
    )
    expected_target = os.environ.get("MANALOOM_EXPECTED_SSH_TARGET", "")
    expected_fingerprint = os.environ.get(
        "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256",
        "",
    )
    target_match = re.fullmatch(
        r"([A-Za-z_][A-Za-z0-9._-]{0,31})@([A-Za-z0-9][A-Za-z0-9.-]{0,252})",
        target,
    )
    if target != expected_target or target_match is None or ".." in target_match.group(2):
        raise RuntimeError("SSH target differs from the exact caller-approved destination")
    if not re.fullmatch(r"SHA256:[A-Za-z0-9+/]{43}", expected_fingerprint):
        raise RuntimeError(
            "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256 must pin the approved SSH host key"
        )
    if not key_value:
        raise RuntimeError("SSH key for the direct Swarm audit is not configured")
    key = Path(key_value).expanduser().resolve()
    if not key.is_file():
        raise RuntimeError(f"SSH key does not exist: {key}")
    return target, key, target_match.group(2), expected_fingerprint


def _write_verified_known_hosts(
    *,
    hostname: str,
    expected_fingerprint: str,
    destination: Path,
) -> None:
    scan = subprocess.run(
        ["ssh-keyscan", "-T", "10", hostname],
        check=False,
        capture_output=True,
        text=True,
        timeout=15,
    )
    matched_lines: list[str] = []
    for line in scan.stdout.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        fingerprint = subprocess.run(
            ["ssh-keygen", "-lf", "-", "-E", "sha256"],
            check=False,
            capture_output=True,
            input=f"{line}\n",
            text=True,
            timeout=10,
        )
        fields = fingerprint.stdout.split()
        if len(fields) >= 2 and fields[1] == expected_fingerprint:
            matched_lines.append(line)
    if not matched_lines:
        raise RuntimeError("SSH host key differs from the caller-approved fingerprint")
    destination.write_text("\n".join(matched_lines) + "\n", encoding="utf-8")
    destination.chmod(0o600)


def _fetch_swarm_service_snapshot(
    runtime_env: dict[str, str],
    *,
    swarm_service_name: str,
) -> dict[str, Any]:
    if swarm_service_name not in APPROVED_SWARM_SERVICES:
        raise reconcile.EasyPanelError(
            f"unapproved Swarm service destination: {swarm_service_name}"
        )
    try:
        host, key, hostname, expected_fingerprint = _validated_ssh_coordinate(
            runtime_env
        )
        with tempfile.TemporaryDirectory(prefix="manaloom-ssh-") as temp_dir:
            known_hosts = Path(temp_dir) / "known_hosts"
            _write_verified_known_hosts(
                hostname=hostname,
                expected_fingerprint=expected_fingerprint,
                destination=known_hosts,
            )
            output = subprocess.check_output(
                [
                    "ssh",
                    "-o",
                    "BatchMode=yes",
                    "-o",
                    "StrictHostKeyChecking=yes",
                    "-o",
                    f"UserKnownHostsFile={known_hosts}",
                    "-i",
                    str(key),
                    host,
                    f"docker service inspect {shlex.quote(swarm_service_name)}",
                ],
                text=True,
                timeout=30,
            )
    except RuntimeError as error:
        raise reconcile.EasyPanelError(str(error)) from error
    services = json.loads(output)
    if len(services) != 1:
        raise reconcile.EasyPanelError(f"unexpected Swarm inspect result for {swarm_service_name}")
    return _snapshot_from_swarm_inspect(services[0])


def _query_pg_metrics_direct(runtime_env: dict[str, str]) -> dict[str, Any]:
    psycopg2, extras = _load_psycopg2()
    connect_kwargs = _pg_connection_kwargs(runtime_env)
    conn = psycopg2.connect(cursor_factory=extras.RealDictCursor, **connect_kwargs)
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  COUNT(*) AS total,
                  COUNT(*) FILTER (WHERE synced_to_hermes) AS synced,
                  COUNT(*) FILTER (WHERE NOT synced_to_hermes) AS pending,
                  MAX(created_at) AS latest_created,
                  MAX(synced_at) AS latest_synced,
                  MAX(created_at) FILTER (WHERE NOT synced_to_hermes) AS latest_pending_created
                FROM deck_learning_events
                """
            )
            learning_row = cur.fetchone() or {}

            cur.execute(
                """
                SELECT
                  id,
                  deck_id,
                  COALESCE(commander_name, '') AS commander_name,
                  COALESCE(source, '') AS source,
                  COALESCE(card_count, 0) AS card_count,
                  created_at
                FROM deck_learning_events
                WHERE synced_to_hermes = FALSE
                ORDER BY created_at ASC
                LIMIT 5
                """
            )
            pending_rows = [
                PendingEvent(
                    id=str(row["id"]),
                    deck_id=str(row["deck_id"]),
                    commander_name=str(row["commander_name"]),
                    source=str(row["source"]),
                    card_count=int(row["card_count"] or 0),
                    created_at=_iso(row["created_at"]) or "",
                )
                for row in (cur.fetchall() or [])
            ]

            cur.execute(
                """
                SELECT COUNT(*) AS total, MAX(updated_at) AS latest_updated
                FROM commander_learned_decks
                """
            )
            learned_row = cur.fetchone() or {}

            cur.execute(
                """
                SELECT COUNT(*) AS total, MAX(imported_at) AS latest_imported
                FROM analysis_sources
                """
            )
            analysis_row = cur.fetchone() or {}
    finally:
        conn.close()

    latest_pending_created = learning_row.get("latest_pending_created")
    pending_age_hours = None
    if latest_pending_created is not None:
        delta = _utc_now() - latest_pending_created.astimezone(timezone.utc)
        pending_age_hours = round(delta.total_seconds() / 3600, 2)

    return {
        "deck_learning_events": {
            "total": int(learning_row.get("total") or 0),
            "synced": int(learning_row.get("synced") or 0),
            "pending": int(learning_row.get("pending") or 0),
            "latest_created": _iso(learning_row.get("latest_created")),
            "latest_synced": _iso(learning_row.get("latest_synced")),
            "latest_pending_created": _iso(latest_pending_created),
            "latest_pending_age_hours": pending_age_hours,
            "pending_samples": [asdict(row) for row in pending_rows],
        },
        "commander_learned_decks": {
            "total": int(learned_row.get("total") or 0),
            "latest_updated": _iso(learned_row.get("latest_updated")),
        },
        "analysis_sources": {
            "total": int(analysis_row.get("total") or 0),
            "latest_imported": _iso(analysis_row.get("latest_imported")),
        },
    }


def _require_pg_runner_approvals() -> None:
    missing = [
        name
        for name in (LIVE_MUTATION_APPROVAL_ENV, POSTGRES_WRITE_APPROVAL_ENV)
        if os.environ.get(name) != EXPLICIT_APPROVAL_PHRASE
    ]
    if missing:
        raise RuntimeError(
            "PostgreSQL runner blocked before wrapper; missing explicit caller "
            f"approval: {', '.join(missing)}"
        )


def _validate_pg_metrics_only_runtime(runtime_env: dict[str, str]) -> None:
    database_url = runtime_env.get("DATABASE_URL", "")
    if database_url:
        parsed = urlsplit(database_url)
        if not (
            parsed.scheme in {"postgres", "postgresql"}
            and parsed.hostname in {"127.0.0.1", "localhost"}
            and parsed.path == f"/{EXPECTED_POSTGRES_DB}"
            and parsed.username == EXPECTED_POSTGRES_USER
            and parse_qsl(parsed.query, keep_blank_values=True)
            == [("sslmode", "disable")]
            and not parsed.fragment
        ):
            raise RuntimeError(
                "--pg-metrics-only is restricted to the approved loopback PostgreSQL tunnel"
            )
        return
    if not (
        runtime_env.get("DB_HOST") in {"127.0.0.1", "localhost"}
        and runtime_env.get("DB_NAME") == EXPECTED_POSTGRES_DB
        and runtime_env.get("DB_USER") == EXPECTED_POSTGRES_USER
        and str(runtime_env.get("DB_PORT", "")).isdigit()
    ):
        raise RuntimeError(
            "--pg-metrics-only is restricted to the approved loopback PostgreSQL tunnel"
        )


def _query_pg_metrics(runtime_env: dict[str, str]) -> dict[str, Any]:
    expected_internal_host = runtime_env.get(
        "MANALOOM_EXPECTED_DB_HOST",
        EXPECTED_POSTGRES_HOST,
    )
    if expected_internal_host != EXPECTED_POSTGRES_HOST:
        raise RuntimeError("expected PostgreSQL host differs from the approved service")
    if runtime_env.get("DB_HOST") != EXPECTED_POSTGRES_HOST:
        raise RuntimeError("runtime PostgreSQL host differs from the approved service")
    _require_pg_runner_approvals()
    output = subprocess.check_output(
        [
            str(NEW_SERVER_PG_WRAPPER),
            "--write-approved",
            sys.executable,
            str(Path(__file__).resolve()),
            "--pg-metrics-only",
        ],
        text=True,
        timeout=60,
    )
    payload = json.loads(output)
    if not isinstance(payload, dict):
        raise RuntimeError("PostgreSQL tunnel metrics did not return an object")
    return payload


def _build_findings(
    *,
    local_head: str,
    public_sha: str | None,
    services: dict[str, dict[str, Any]],
    pg_metrics: dict[str, Any],
) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []

    if public_sha and public_sha != local_head:
        findings.append(
            {
                "priority": "P1",
                "code": "public_sha_drift",
                "message": f"public backend health SHA {public_sha[:12]} differs from local HEAD {local_head[:12]}",
            }
        )

    for service_name, snapshot in services.items():
        if snapshot.get("sha") and snapshot["sha"] != local_head:
            findings.append(
                {
                    "priority": "P1",
                    "code": f"{service_name}_sha_drift",
                    "message": f"{service_name} runs {str(snapshot['sha'])[:12]} instead of {local_head[:12]}",
                }
            )

    hermes_lab = services.get("hermes-lab", {})
    if "hermes-lab" in services and not hermes_lab.get("openai_api_key_present"):
        findings.append(
            {
                "priority": "P0",
                "code": "hermes_lab_missing_openai",
                "message": "hermes-lab is missing OPENAI_API_KEY",
            }
        )

    ops_db = services.get("manaloom-ops", {}).get("knowledge_db")
    lab_db = hermes_lab.get("knowledge_db")
    if "hermes-lab" in services and ops_db != lab_db:
        findings.append(
            {
                "priority": "P2",
                "code": "split_operational_cache_paths",
                "message": "manaloom-ops and hermes-lab point to different knowledge.db paths; this is acceptable only while hermes-lab stays report-only",
            }
        )

    pending = pg_metrics["deck_learning_events"]["pending"]
    pending_age = pg_metrics["deck_learning_events"]["latest_pending_age_hours"]
    if pending > 0 and pending_age is not None and pending_age >= 2:
        findings.append(
            {
                "priority": "P1",
                "code": "learning_event_sync_lag",
                "message": f"{pending} deck_learning_events are pending sync for {pending_age}h",
            }
        )

    return findings


def _build_report(payload: dict[str, Any]) -> str:
    lines = [
        "# EasyPanel Runtime Alignment Audit",
        "",
        f"Generated: {payload['generated_at_utc']}",
        "",
        "## Git / Deploy",
        "",
        f"- local_head: `{payload['local_head']}`",
        f"- public_health_sha: `{payload['public_health'].get('git_sha')}`",
        "",
        "## Services",
        "",
    ]
    for service_name, snapshot in payload["services"].items():
        lines.extend(
            [
                f"### {service_name}",
                "",
                f"- enabled: `{snapshot.get('enabled')}`",
                f"- sha: `{snapshot.get('sha')}`",
                f"- image: `{snapshot.get('image')}`",
                f"- runtime_source: `{snapshot.get('runtime_source')}`",
                f"- source_ref: `{snapshot.get('source_ref')}`",
                f"- source_path: `{snapshot.get('source_path')}`",
                f"- knowledge_db: `{snapshot.get('knowledge_db')}`",
                f"- manaloom_knowledge_db: `{snapshot.get('manaloom_knowledge_db')}`",
                f"- openai_api_key_present: `{snapshot.get('openai_api_key_present')}`",
                "",
            ]
        )

    dle = payload["pg_metrics"]["deck_learning_events"]
    lines.extend(
        [
            "## PostgreSQL Side Effects",
            "",
            f"- deck_learning_events.total: `{dle['total']}`",
            f"- deck_learning_events.synced: `{dle['synced']}`",
            f"- deck_learning_events.pending: `{dle['pending']}`",
            f"- deck_learning_events.latest_created: `{dle['latest_created']}`",
            f"- deck_learning_events.latest_synced: `{dle['latest_synced']}`",
            f"- deck_learning_events.latest_pending_age_hours: `{dle['latest_pending_age_hours']}`",
            f"- commander_learned_decks.latest_updated: `{payload['pg_metrics']['commander_learned_decks']['latest_updated']}`",
            f"- analysis_sources.latest_imported: `{payload['pg_metrics']['analysis_sources']['latest_imported']}`",
            "",
            "### Pending Samples",
            "",
        ]
    )
    if dle["pending_samples"]:
        for row in dle["pending_samples"]:
            lines.append(
                f"- `{row['created_at']}` commander=`{row['commander_name']}` "
                f"source=`{row['source']}` cards=`{row['card_count']}` deck_id=`{row['deck_id']}`"
            )
    else:
        lines.append("- None.")

    lines.extend(["", "## Findings", ""])
    if payload["findings"]:
        for finding in payload["findings"]:
            lines.append(f"- {finding['priority']} `{finding['code']}`: {finding['message']}")
    else:
        lines.append("- None.")

    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default=os.environ.get("EASYPANEL_PROJECT", DEFAULT_PROJECT))
    parser.add_argument("--health-url", default=os.environ.get("MANALOOM_PUBLIC_HEALTH_URL", DEFAULT_HEALTH_URL))
    parser.add_argument("--artifact-dir", default=str(DEFAULT_ARTIFACT_DIR))
    parser.add_argument("--stdout-only", action="store_true")
    parser.add_argument("--pg-metrics-only", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args(argv)

    if args.pg_metrics_only:
        pg_runtime = dict(os.environ)
        _validate_pg_metrics_only_runtime(pg_runtime)
        print(json.dumps(_query_pg_metrics_direct(pg_runtime), sort_keys=True))
        return 0

    if args.project != DEFAULT_PROJECT:
        raise SystemExit("EasyPanel project differs from the approved production project")
    if args.health_url != DEFAULT_HEALTH_URL:
        raise SystemExit("public health URL differs from the approved production endpoint")

    runtime_env = reconcile.load_runtime_env()
    runtime_env["EASYPANEL_BASE_URL"] = _validated_easypanel_base_url(
        runtime_env["EASYPANEL_BASE_URL"]
    )
    client = reconcile.EasyPanelClient(
        runtime_env["EASYPANEL_BASE_URL"],
        runtime_env["EASYPANEL_API_TOKEN"],
    )

    local_head = reconcile._local_head_sha()
    public_health = _fetch_public_health(args.health_url)
    services = _fetch_service_env_snapshot(
        client,
        project_name=args.project,
        service_names=DEFAULT_SERVICES,
        runtime_env=runtime_env,
    )
    pg_metrics = _query_pg_metrics(runtime_env)
    findings = _build_findings(
        local_head=local_head,
        public_sha=public_health.get("git_sha"),
        services=services,
        pg_metrics=pg_metrics,
    )

    payload = {
        "generated_at_utc": _utc_now().isoformat(timespec="seconds"),
        "local_head": local_head,
        "public_health": public_health,
        "services": services,
        "pg_metrics": pg_metrics,
        "findings": findings,
    }
    report = _build_report(payload)

    if not args.stdout_only:
        artifact_dir = Path(args.artifact_dir)
        artifact_dir.mkdir(parents=True, exist_ok=True)
        (artifact_dir / "summary.json").write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        (artifact_dir / "report.md").write_text(report, encoding="utf-8")

    print(report, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
