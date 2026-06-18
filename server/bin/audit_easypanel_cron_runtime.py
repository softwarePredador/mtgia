#!/usr/bin/env python3
"""Read-only EasyPanel cron/runtime audit for ManaLoom services.

This audit proves the live state of the two runtime services:
- manaloom-ops: deterministic operational scheduler
- hermes-lab: provider-backed Hermes scheduler

It does not mutate EasyPanel, containers, PostgreSQL, or SQLite.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import shlex
import ssl
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import quote, urljoin, urlparse
import urllib.request

import websocket  # type: ignore


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ARTIFACT_DIR = (
    REPO_ROOT / "server" / "test" / "artifacts" / "easypanel_cron_runtime"
)
DEFAULT_PROJECT = "evolution"
DEFAULT_SERVICES = {
    "manaloom-ops": "evolution_manaloom-ops",
    "hermes-lab": "evolution_hermes-lab",
}
SERVICE_OUTPUT_ROOTS = {
    "manaloom-ops": "/data/manaloom-ops/cron/output",
    "hermes-lab": "/opt/data/cron/output",
}

sys.path.insert(0, str(Path(__file__).resolve().parent))
import reconcile_easypanel_services as reconcile  # noqa: E402


@dataclass(frozen=True)
class ContainerInfo:
    service_name: str
    container_id: str
    image: str | None
    status: str | None
    state: str | None
    health: str | None
    created_at: str | None


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _iso(value: Any) -> str | None:
    if value is None:
        return None
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value)


def _artifact_dir(explicit: str | None) -> Path:
    if explicit:
        path = Path(explicit).expanduser().resolve()
    else:
        stamp = _utc_now().strftime("%Y-%m-%d_%H%M%S")
        path = DEFAULT_ARTIFACT_DIR.parent / f"{DEFAULT_ARTIFACT_DIR.name}_{stamp}"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _health_ssl_context() -> ssl.SSLContext:
    try:
        import certifi  # type: ignore

        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


def _ws_base(base_url: str) -> str:
    parsed = urlparse(base_url)
    scheme = "wss" if parsed.scheme == "https" else "ws"
    netloc = parsed.netloc or parsed.path
    return f"{scheme}://{netloc}"


def _sslopt(ws_url: str, *, insecure: bool) -> dict[str, Any]:
    if not ws_url.startswith("wss://"):
        return {}
    if insecure:
        return {"cert_reqs": ssl.CERT_NONE}
    return {}


def _parse_container(payload: Any, service_name: str) -> ContainerInfo:
    if not isinstance(payload, list) or not payload:
        raise RuntimeError(f"no containers returned for {service_name}")
    row = payload[0]
    status = row.get("status") or row.get("Status")
    health = row.get("health")
    if health is None and isinstance(status, str):
        if "(healthy)" in status.lower():
            health = "healthy"
        elif "(unhealthy)" in status.lower():
            health = "unhealthy"
    return ContainerInfo(
        service_name=service_name,
        container_id=str(row.get("id") or row.get("Id") or ""),
        image=row.get("image") or row.get("Image"),
        status=status,
        state=row.get("state") or row.get("State"),
        health=health,
        created_at=_iso(row.get("createdAt") or row.get("Created")),
    )


def _collect_service_logs(
    ws_base: str,
    token: str,
    service: str,
    *,
    insecure: bool,
    max_messages: int = 120,
    idle_timeout_s: float = 1.2,
    connect_timeout_s: float = 10.0,
    hard_timeout_s: float = 8.0,
) -> list[str]:
    url = (
        f"{ws_base}/ws/serviceLogs?token={quote(token)}&service={quote(service)}"
        "&compose=false"
    )
    ws = websocket.create_connection(
        url,
        timeout=connect_timeout_s,
        sslopt=_sslopt(url, insecure=insecure),
    )
    raw_messages: list[str] = []
    start = time.time()
    try:
        ws.settimeout(idle_timeout_s)
        while len(raw_messages) < max_messages and (time.time() - start) < hard_timeout_s:
            try:
                message = ws.recv()
            except Exception:
                break
            if message is None:
                break
            text = str(message).strip()
            if not text:
                continue
            raw_messages.append(text)
    finally:
        try:
            ws.close()
        except Exception:
            pass
    return _join_ws_output(raw_messages).splitlines()


def _join_ws_output(messages: list[str]) -> str:
    chunks: list[str] = []
    for message in messages:
        try:
            parsed = json.loads(message)
        except json.JSONDecodeError:
            chunks.append(message)
            continue
        if isinstance(parsed, dict) and isinstance(parsed.get("output"), str):
            chunks.append(parsed["output"])
        else:
            chunks.append(message)
    return "".join(chunks)


def _container_shell(
    ws_base: str,
    token: str,
    container_id: str,
    command: str,
    *,
    insecure: bool,
    idle_timeout_s: float = 1.0,
    connect_timeout_s: float = 10.0,
    hard_timeout_s: float = 8.0,
    max_chunks: int = 120,
) -> str:
    encoded = base64.b64encode(command.encode("utf-8")).decode("ascii")
    url = (
        f"{ws_base}/ws/containerShell?token={quote(token)}"
        f"&container={quote(container_id)}&command={quote(encoded)}"
    )
    ws = websocket.create_connection(
        url,
        timeout=connect_timeout_s,
        sslopt=_sslopt(url, insecure=insecure),
    )
    chunks: list[str] = []
    start = time.time()
    try:
        ws.settimeout(idle_timeout_s)
        while len(chunks) < max_chunks and (time.time() - start) < hard_timeout_s:
            try:
                message = ws.recv()
            except Exception:
                break
            if message is None:
                break
            chunks.append(str(message))
    finally:
        try:
            ws.close()
        except Exception:
            pass
    return _join_ws_output(chunks)


def _sanitize_output(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text.strip()


def _parse_probe_lines(text: str) -> dict[str, str]:
    parsed: dict[str, str] = {}
    for line in _sanitize_output(text).splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if not key:
            continue
        parsed[key] = value.strip()
    return parsed


def _job_output_probe_targets(service_name: str, job: dict[str, Any]) -> list[dict[str, str]]:
    targets: list[dict[str, str]] = []
    latest_output = str(job.get("latest_output") or "").strip()
    if latest_output:
        targets.append({"mode": "file", "path": latest_output, "source": "latest_output"})

    output_root = SERVICE_OUTPUT_ROOTS.get(service_name)
    if output_root:
        if service_name == "manaloom-ops":
            job_name = str(job.get("name") or "").strip()
            if job_name:
                targets.append(
                    {
                        "mode": "dir",
                        "path": f"{output_root}/{job_name}",
                        "source": "derived_job_name_dir",
                    }
                )
        else:
            job_id = str(job.get("id") or "").strip()
            if job_id:
                targets.append(
                    {
                        "mode": "dir",
                        "path": f"{output_root}/{job_id}",
                        "source": "derived_job_id_dir",
                    }
                )

    deduped: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for target in targets:
        key = (target["mode"], target["path"])
        if key in seen:
            continue
        seen.add(key)
        deduped.append(target)
    return deduped


def _shell_probe_file(
    ws_base: str,
    token: str,
    container_id: str,
    path: str,
    *,
    insecure: bool,
    tail_lines: int = 20,
) -> tuple[bool, str]:
    quoted_path = shlex.quote(path)
    command = (
        "sh -lc '"
        f"if [ -f {quoted_path} ]; then "
        "echo __FOUND__; "
        f"tail -n {tail_lines} {quoted_path}; "
        "else echo __MISSING__; fi'"
    )
    output = _container_shell(
        ws_base,
        token,
        container_id,
        command,
        insecure=insecure,
    )
    clean = _sanitize_output(output)
    if clean.startswith("__FOUND__"):
        return True, clean.replace("__FOUND__", "", 1).strip()
    return False, clean


def _shell_latest_file_in_dir(
    ws_base: str,
    token: str,
    container_id: str,
    path: str,
    *,
    insecure: bool,
) -> str | None:
    quoted_path = shlex.quote(path)
    command = (
        "sh -lc '"
        f"if [ -d {quoted_path} ]; then "
        f"find {quoted_path} -maxdepth 1 -type f | sort | tail -n 1; "
        "else echo __MISSING__; fi'"
    )
    output = _container_shell(
        ws_base,
        token,
        container_id,
        command,
        insecure=insecure,
    )
    clean = _sanitize_output(output)
    if not clean or clean == "__MISSING__":
        return None
    return clean.splitlines()[-1].strip() or None


def _runtime_probe(
    ws_base: str,
    token: str,
    container_id: str,
    *,
    insecure: bool,
) -> dict[str, str]:
    output = _container_shell(
        ws_base,
        token,
        container_id,
        (
            "sh -lc '"
            "printf \"user=%s\\n\" \"$(id -un)\"; "
            "printf \"uid=%s\\n\" \"$(id -u)\"; "
            "printf \"hostname=%s\\n\" \"$(hostname)\"; "
            "printf \"pwd=%s\\n\" \"$PWD\"; "
            "printf \"repo_exists=%s\\n\" \"$(test -d /opt/data/workspace/mtgia && echo yes || echo no)\"'"
        ),
        insecure=insecure,
    )
    return _parse_probe_lines(output)


def _collect_job_output_evidence(
    ws_base: str,
    token: str,
    service_name: str,
    container_id: str,
    jobs: dict[str, Any],
    *,
    insecure: bool,
) -> None:
    for job in jobs.get("jobs", []):
        evidence: dict[str, Any] | None = None
        for target in _job_output_probe_targets(service_name, job):
            if target["mode"] == "file":
                found, preview = _shell_probe_file(
                    ws_base,
                    token,
                    container_id,
                    target["path"],
                    insecure=insecure,
                )
                if not found:
                    continue
                evidence = {
                    "path": target["path"],
                    "source": target["source"],
                    "preview": preview,
                }
                break
            latest_path = _shell_latest_file_in_dir(
                ws_base,
                token,
                container_id,
                target["path"],
                insecure=insecure,
            )
            if not latest_path:
                continue
            found, preview = _shell_probe_file(
                ws_base,
                token,
                container_id,
                latest_path,
                insecure=insecure,
            )
            if not found:
                continue
            evidence = {
                "path": latest_path,
                "source": target["source"],
                "preview": preview,
            }
            break
        if evidence is not None:
            job["output_evidence"] = evidence


def _shell_read_json(
    ws_base: str,
    token: str,
    container_id: str,
    path: str,
    *,
    insecure: bool,
) -> tuple[dict[str, Any] | list[Any] | None, str]:
    quoted_path = shlex.quote(path)
    output = _container_shell(
        ws_base,
        token,
        container_id,
        f"sh -lc 'if [ -f {quoted_path} ]; then cat {quoted_path}; else echo __MISSING__; fi'",
        insecure=insecure,
    )
    clean = _sanitize_output(output)
    if not clean or clean == "__MISSING__":
        return None, clean
    try:
        return json.loads(clean), clean
    except json.JSONDecodeError:
        return None, clean


def _jobs_summary(payload: dict[str, Any] | list[Any] | None) -> dict[str, Any]:
    if payload is None:
        return {"jobs_total": 0, "enabled_jobs": 0, "paused_jobs": 0, "jobs": []}
    jobs = payload.get("jobs", payload) if isinstance(payload, dict) else payload
    if not isinstance(jobs, list):
        return {"jobs_total": 0, "enabled_jobs": 0, "paused_jobs": 0, "jobs": []}
    normalized: list[dict[str, Any]] = []
    enabled = 0
    paused = 0
    for job in jobs:
        if not isinstance(job, dict):
            continue
        state = str(job.get("state") or ("active" if job.get("enabled", True) else "paused")).lower()
        if state == "paused":
            paused += 1
        else:
            enabled += 1
        normalized.append(
            {
                "id": job.get("id"),
                "name": job.get("name"),
                "state": state,
                "enabled": bool(job.get("enabled", True)),
                "schedule": (
                    job.get("schedule_display")
                    or job.get("schedule_expr")
                    or (job.get("schedule") or {}).get("display")
                    if isinstance(job.get("schedule"), dict)
                    else job.get("schedule")
                ),
                "last_run_at": job.get("last_run_at") or job.get("last_started_at"),
                "last_status": job.get("last_status"),
                "last_finished_at": job.get("last_finished_at"),
                "last_exit_code": job.get("last_exit_code"),
                "latest_output": job.get("latest_output"),
                "deliver": job.get("deliver"),
                "no_agent": job.get("no_agent"),
                "script": job.get("script"),
                "workdir": job.get("workdir"),
            }
        )
    return {
        "jobs_total": len(normalized),
        "enabled_jobs": enabled,
        "paused_jobs": paused,
        "jobs": normalized,
    }


def _extract_runtime_findings(
    *,
    service_envs: dict[str, dict[str, Any]],
    ops_jobs: dict[str, Any],
    lab_jobs: dict[str, Any],
    ops_logs: list[str],
    lab_logs: list[str],
) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []

    if not service_envs.get("hermes-lab", {}).get("openai_api_key_present"):
        findings.append(
            {
                "priority": "P0",
                "code": "hermes_lab_missing_openai_api_key",
                "message": "hermes-lab is provider-backed but OPENAI_API_KEY is absent in live env",
            }
        )

    if service_envs.get("manaloom-ops", {}).get("openai_api_key_present"):
        findings.append(
            {
                "priority": "P2",
                "code": "manaloom_ops_unexpected_openai_api_key",
                "message": "manaloom-ops should stay deterministic; OPENAI_API_KEY present in live env",
            }
        )

    if ops_jobs.get("jobs_total", 0) == 0:
        findings.append(
            {
                "priority": "P1",
                "code": "manaloom_ops_no_jobs",
                "message": "manaloom-ops live jobs.json returned no active jobs",
            }
        )

    if lab_jobs.get("jobs_total", 0) == 0:
        findings.append(
            {
                "priority": "P1",
                "code": "hermes_lab_no_jobs",
                "message": "hermes-lab live jobs.json returned no jobs",
            }
        )

    if not any("scheduler started" in line.lower() for line in ops_logs):
        findings.append(
            {
                "priority": "P1",
                "code": "manaloom_ops_scheduler_not_proven",
                "message": "service logs did not show scheduler startup for manaloom-ops",
            }
        )

    if not any("bootstrap" in line.lower() for line in lab_logs):
        findings.append(
            {
                "priority": "P2",
                "code": "hermes_lab_bootstrap_not_visible",
                "message": "service logs did not show hermes bootstrap activity in sampled window",
            }
        )

    for service_name, jobs in (
        ("manaloom-ops", ops_jobs),
        ("hermes-lab", lab_jobs),
    ):
        for job in jobs.get("jobs", []):
            state = str(job.get("state") or "").lower()
            enabled = bool(job.get("enabled", True))
            last_status = str(job.get("last_status") or "").lower()
            if enabled and state != "paused" and last_status in {"error", "failed"}:
                findings.append(
                    {
                        "priority": "P1",
                        "code": f"{service_name.replace('-', '_')}_job_error",
                        "message": (
                            f"{service_name} job `{job.get('name')}` reports "
                            f"last_status={job.get('last_status')}"
                        ),
                    }
                )
                continue
            if last_status != "ok":
                continue
            if job.get("output_evidence"):
                continue
            findings.append(
                {
                    "priority": "P2",
                    "code": f"{service_name.replace('-', '_')}_job_without_output_evidence",
                    "message": (
                        f"{service_name} job `{job.get('name')}` reports last_status=ok "
                        "but no output evidence file was resolved"
                    ),
                }
            )

    return findings


def _write_markdown(
    path: Path,
    *,
    generated_at: str,
    local_head: str,
    public_health: dict[str, Any] | None,
    service_envs: dict[str, dict[str, Any]],
    containers: dict[str, ContainerInfo],
    runtime_probes: dict[str, dict[str, str]],
    ops_jobs: dict[str, Any],
    lab_jobs: dict[str, Any],
    ops_logs: list[str],
    lab_logs: list[str],
    startup_status: dict[str, Any] | None,
    bootstrap_report: dict[str, Any] | None,
    findings: list[dict[str, Any]],
) -> None:
    lines = [
        "# EasyPanel Cron Runtime Audit",
        "",
        f"- generated_at_utc: `{generated_at}`",
        f"- local_head: `{local_head}`",
    ]
    if public_health:
        lines.extend(
            [
                f"- public_health_sha: `{public_health.get('git_sha')}`",
                f"- public_health_status: `{public_health.get('status')}`",
            ]
        )

    for service_name in ("manaloom-ops", "hermes-lab"):
        env = service_envs.get(service_name, {})
        container = containers.get(service_name)
        jobs = ops_jobs if service_name == "manaloom-ops" else lab_jobs
        lines.extend(
            [
                "",
                f"## {service_name}",
                "",
                f"- service_sha: `{env.get('sha')}`",
                f"- enabled: `{env.get('enabled')}`",
                f"- openai_api_key_present: `{env.get('openai_api_key_present')}`",
                f"- hermes_model: `{env.get('hermes_model')}`",
                f"- knowledge_db: `{env.get('knowledge_db')}`",
                f"- container_id: `{container.container_id if container else ''}`",
                f"- container_status: `{container.status if container else ''}`",
                f"- container_health: `{container.health if container else ''}`",
                f"- jobs_total: `{jobs.get('jobs_total')}`",
                f"- enabled_jobs: `{jobs.get('enabled_jobs')}`",
                f"- paused_jobs: `{jobs.get('paused_jobs')}`",
            ]
        )
        probe = runtime_probes.get(service_name, {})
        if probe:
            lines.extend(
                [
                    f"- runtime_probe.user: `{probe.get('user')}`",
                    f"- runtime_probe.uid: `{probe.get('uid')}`",
                    f"- runtime_probe.hostname: `{probe.get('hostname')}`",
                    f"- runtime_probe.pwd: `{probe.get('pwd')}`",
                    f"- runtime_probe.repo_exists: `{probe.get('repo_exists')}`",
                ]
            )
        lines.append("")
        lines.append("### Jobs")
        lines.append("")
        for job in jobs.get("jobs", []):
            lines.append(
                f"- `{job.get('name')}` | state=`{job.get('state')}` | schedule=`{job.get('schedule')}` | last_status=`{job.get('last_status')}` | last_run_at=`{job.get('last_run_at')}` | no_agent=`{job.get('no_agent')}` | script=`{job.get('script')}`"
            )
            evidence = job.get("output_evidence")
            if evidence:
                preview = str(evidence.get("preview") or "").splitlines()
                preview_line = preview[-1] if preview else ""
                lines.append(
                    f"  evidence=`{evidence.get('path')}` source=`{evidence.get('source')}` preview_tail=`{preview_line}`"
                )

    if startup_status:
        lines.extend(
            [
                "",
                "## Hermes Startup Status",
                "",
                "```json",
                json.dumps(startup_status, indent=2, sort_keys=True),
                "```",
            ]
        )

    if bootstrap_report:
        lines.extend(
            [
                "",
                "## Hermes Bootstrap Report",
                "",
                "```json",
                json.dumps(bootstrap_report, indent=2, sort_keys=True),
                "```",
            ]
        )

    lines.extend(
        [
            "",
            "## Sampled Logs",
            "",
            "### manaloom-ops",
            "",
            "```text",
            *(ops_logs[-40:] or ["<no logs captured>"]),
            "```",
            "",
            "### hermes-lab",
            "",
            "```text",
            *(lab_logs[-40:] or ["<no logs captured>"]),
            "```",
            "",
            "## Findings",
            "",
        ]
    )
    if findings:
        for finding in findings:
            lines.append(
                f"- {finding['priority']} `{finding['code']}`: {finding['message']}"
            )
    else:
        lines.append("- none")
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifact-dir", type=str, default=None)
    parser.add_argument("--project", type=str, default=DEFAULT_PROJECT)
    parser.add_argument("--insecure-health", action="store_true")
    args = parser.parse_args()

    artifact_dir = _artifact_dir(args.artifact_dir)
    runtime_env = reconcile.load_runtime_env()
    base_url = runtime_env.get("EASYPANEL_BASE_URL")
    token = runtime_env.get("EASYPANEL_API_TOKEN")
    if not base_url or not token:
        raise SystemExit("missing EASYPANEL_BASE_URL or EASYPANEL_API_TOKEN")

    client = reconcile.EasyPanelClient(base_url, token)
    ws_base = _ws_base(base_url)

    local_head = reconcile._local_head_sha()
    public_health = None
    public_url = (
        runtime_env.get("PUBLIC_API_BASE_URL")
        or runtime_env.get("API_BASE_URL")
        or ""
    ).rstrip("/")
    if public_url:
        try:
            public_health = json.loads(
                urllib.request.urlopen(
                    urllib.request.Request(
                        urljoin(public_url + "/", "health"),
                        method="GET",
                    ),
                    timeout=15,
                    context=_health_ssl_context(),
                )
                .read()
                .decode("utf-8", "replace")
            )
        except Exception:
            public_health = None

    services_payload = client.list_projects_and_services()
    service_envs: dict[str, dict[str, Any]] = {}
    containers: dict[str, ContainerInfo] = {}
    runtime_probes: dict[str, dict[str, str]] = {}
    for short_name, api_service in DEFAULT_SERVICES.items():
        state = reconcile._collect_service_state(
            services_payload,
            args.project,
            short_name,
        )
        env_map = reconcile._parse_dotenv(state.env_text)
        service_envs[short_name] = {
            "sha": state.sha,
            "enabled": state.enabled,
            "knowledge_db": env_map.get("HERMES_KNOWLEDGE_DB"),
            "manaloom_knowledge_db": env_map.get("MANALOOM_KNOWLEDGE_DB"),
            "openai_api_key_present": bool(env_map.get("OPENAI_API_KEY")),
            "hermes_model": env_map.get("HERMES_MODEL"),
            "hermes_provider": env_map.get("HERMES_PROVIDER"),
            "api_server_enabled": env_map.get("API_SERVER_ENABLED"),
        }
        containers_payload = client._post(
            "projects.getDockerContainers",
            {"service": api_service},
        )
        containers[short_name] = _parse_container(containers_payload, short_name)
        runtime_probes[short_name] = _runtime_probe(
            ws_base,
            token,
            containers[short_name].container_id,
            insecure=args.insecure_health,
        )

    ops_logs = _collect_service_logs(
        ws_base,
        token,
        DEFAULT_SERVICES["manaloom-ops"],
        insecure=args.insecure_health,
    )
    lab_logs = _collect_service_logs(
        ws_base,
        token,
        DEFAULT_SERVICES["hermes-lab"],
        insecure=args.insecure_health,
    )

    ops_jobs_json, ops_jobs_raw = _shell_read_json(
        ws_base,
        token,
        containers["manaloom-ops"].container_id,
        "/data/manaloom-ops/cron/jobs.json",
        insecure=args.insecure_health,
    )
    lab_jobs_json, lab_jobs_raw = _shell_read_json(
        ws_base,
        token,
        containers["hermes-lab"].container_id,
        "/opt/data/cron/jobs.json",
        insecure=args.insecure_health,
    )
    startup_status_json, startup_status_raw = _shell_read_json(
        ws_base,
        token,
        containers["hermes-lab"].container_id,
        "/opt/data/artifacts/hermes_lab_runtime/startup_status.json",
        insecure=args.insecure_health,
    )
    bootstrap_report_json, bootstrap_report_raw = _shell_read_json(
        ws_base,
        token,
        containers["hermes-lab"].container_id,
        "/opt/data/artifacts/hermes_cron_bootstrap/latest_bootstrap_report.json",
        insecure=args.insecure_health,
    )

    ops_jobs = _jobs_summary(ops_jobs_json)
    lab_jobs = _jobs_summary(lab_jobs_json)
    _collect_job_output_evidence(
        ws_base,
        token,
        "manaloom-ops",
        containers["manaloom-ops"].container_id,
        ops_jobs,
        insecure=args.insecure_health,
    )
    _collect_job_output_evidence(
        ws_base,
        token,
        "hermes-lab",
        containers["hermes-lab"].container_id,
        lab_jobs,
        insecure=args.insecure_health,
    )
    findings = _extract_runtime_findings(
        service_envs=service_envs,
        ops_jobs=ops_jobs,
        lab_jobs=lab_jobs,
        ops_logs=ops_logs,
        lab_logs=lab_logs,
    )

    generated_at = _utc_now().isoformat(timespec="seconds")
    summary = {
        "generated_at_utc": generated_at,
        "local_head": local_head,
        "public_health": public_health,
        "service_envs": service_envs,
        "runtime_probes": runtime_probes,
        "containers": {
            key: container.__dict__ for key, container in containers.items()
        },
        "manaloom_ops_jobs": ops_jobs,
        "hermes_lab_jobs": lab_jobs,
        "hermes_startup_status": startup_status_json,
        "hermes_bootstrap_report": bootstrap_report_json,
        "findings": findings,
    }

    (artifact_dir / "summary.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    (artifact_dir / "manaloom_ops_logs.txt").write_text(
        "\n".join(ops_logs).rstrip() + "\n",
        encoding="utf-8",
    )
    (artifact_dir / "hermes_lab_logs.txt").write_text(
        "\n".join(lab_logs).rstrip() + "\n",
        encoding="utf-8",
    )
    (artifact_dir / "manaloom_ops_jobs_raw.txt").write_text(
        (ops_jobs_raw or "").rstrip() + "\n",
        encoding="utf-8",
    )
    (artifact_dir / "hermes_lab_jobs_raw.txt").write_text(
        (lab_jobs_raw or "").rstrip() + "\n",
        encoding="utf-8",
    )
    (artifact_dir / "hermes_startup_status_raw.txt").write_text(
        (startup_status_raw or "").rstrip() + "\n",
        encoding="utf-8",
    )
    (artifact_dir / "hermes_bootstrap_report_raw.txt").write_text(
        (bootstrap_report_raw or "").rstrip() + "\n",
        encoding="utf-8",
    )
    _write_markdown(
        artifact_dir / "report.md",
        generated_at=generated_at,
        local_head=local_head,
        public_health=public_health,
        service_envs=service_envs,
        containers=containers,
        runtime_probes=runtime_probes,
        ops_jobs=ops_jobs,
        lab_jobs=lab_jobs,
        ops_logs=ops_logs,
        lab_logs=lab_logs,
        startup_status=startup_status_json if isinstance(startup_status_json, dict) else None,
        bootstrap_report=bootstrap_report_json if isinstance(bootstrap_report_json, dict) else None,
        findings=findings,
    )
    print(
        json.dumps(
            {
                "artifact_dir": str(artifact_dir),
                "findings": findings,
                "manaloom_ops_jobs": ops_jobs.get("jobs_total"),
                "hermes_lab_jobs": lab_jobs.get("jobs_total"),
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
