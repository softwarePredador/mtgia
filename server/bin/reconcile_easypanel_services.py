#!/usr/bin/env python3
"""Reconcile optional ManaLoom services managed by the EasyPanel app API.

The required manaloom-ops runtime is a direct Docker Swarm service. Deploy it
with scripts/manaloom_deploy_ops_image.sh; this utility intentionally cannot
mutate that service through the unrelated EasyPanel app contract.
"""

from __future__ import annotations

import argparse
import json
import os
import secrets
import ssl
import subprocess
import time
import urllib.error
import urllib.request
from collections import OrderedDict
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urljoin


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ENV_CANDIDATES = [REPO_ROOT / ".env", REPO_ROOT / "server" / ".env"]
DEFAULT_PROJECT = "evolution"
SUPPORTED_SERVICES = ("hermes-lab",)
SECRET_KEYS = {
    "OPENAI_API_KEY",
    "API_SERVER_KEY",
    "EASYPANEL_API_TOKEN",
    "HERMES_GITHUB_TOKEN",
    "GITHUB_TOKEN",
    "GH_TOKEN",
}


@dataclass(frozen=True)
class ServiceState:
    project_name: str
    service_name: str
    env_text: str
    sha: str | None
    enabled: bool
    source_ref: str | None
    source_path: str | None
    zero_downtime: bool | None
    replicas: int | None


class EasyPanelError(RuntimeError):
    pass


def _ssl_context() -> ssl.SSLContext:
    try:
        import certifi  # type: ignore

        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


def _parse_dotenv(text: str) -> OrderedDict[str, str]:
    env: OrderedDict[str, str] = OrderedDict()
    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#") or "=" not in raw_line:
            continue
        key, value = raw_line.split("=", 1)
        env[key.strip()] = value
    return env


def _load_env_file(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    return dict(_parse_dotenv(path.read_text(encoding="utf-8")))


def load_runtime_env(extra_env_file: Path | None = None) -> dict[str, str]:
    combined: dict[str, str] = {}
    for candidate in DEFAULT_ENV_CANDIDATES:
        combined.update(_load_env_file(candidate))
    if extra_env_file is not None:
        combined.update(_load_env_file(extra_env_file))
    combined.update({key: value for key, value in os.environ.items() if value})
    return combined


def _local_head_sha() -> str:
    return (
        subprocess.check_output(
            ["git", "-C", str(REPO_ROOT), "rev-parse", "HEAD"],
            text=True,
        )
        .strip()
    )


def _redact_value(key: str, value: str | None) -> str | None:
    if value is None:
        return None
    if key in SECRET_KEYS:
        return "present" if value else "empty"
    return value


def _render_env(env_map: OrderedDict[str, str]) -> str:
    return "\n".join(f"{key}={value}" for key, value in env_map.items()).rstrip() + "\n"


def _merge_env(existing_text: str, updates: dict[str, str]) -> tuple[str, dict[str, dict[str, str | None]]]:
    merged = _parse_dotenv(existing_text)
    changes: dict[str, dict[str, str | None]] = {}
    for key, new_value in updates.items():
        old_value = merged.get(key)
        if old_value != new_value:
            merged[key] = new_value
            changes[key] = {
                "from": _redact_value(key, old_value),
                "to": _redact_value(key, new_value),
            }
    return _render_env(merged), changes


class EasyPanelClient:
    def __init__(self, base_url: str, token: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.token = token

    def _post(
        self,
        procedure: str,
        payload: dict[str, Any] | None = None,
        *,
        timeout: int = 30,
    ) -> Any:
        request = urllib.request.Request(
            urljoin(self.base_url, f"/api/trpc/{procedure}"),
            data=json.dumps({"json": payload}).encode("utf-8"),
            method="POST",
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(
                request,
                timeout=timeout,
                context=_ssl_context(),
            ) as response:
                payload = json.loads(response.read().decode("utf-8", "replace"))
                if "json" in payload:
                    return payload["json"]
                return payload
        except urllib.error.HTTPError as exc:
            body_text = exc.read().decode("utf-8", "replace")
            raise EasyPanelError(f"{procedure} failed: HTTP {exc.code} {body_text}") from exc

    def list_projects_and_services(self) -> dict[str, Any]:
        return self._post("projects.listProjectsAndServices")

    def list_actions(
        self,
        *,
        project_name: str,
        service_name: str,
        limit: int = 5,
        action_type: str = "deployment",
    ) -> list[dict[str, Any]]:
        return self._post(
            "actions.listActions",
            {
                "limit": limit,
                "projectName": project_name,
                "serviceName": service_name,
                "type": action_type,
            },
        )

    def update_env(self, *, project_name: str, service_name: str, env_text: str) -> Any:
        return self._post(
            "services.app.updateEnv",
            {
                "projectName": project_name,
                "serviceName": service_name,
                "env": env_text,
            },
        )

    def deploy_service(self, *, project_name: str, service_name: str) -> Any:
        return self._post(
            "services.app.deployService",
            {
                "projectName": project_name,
                "serviceName": service_name,
            },
            timeout=180,
        )


def _collect_service_state(payload: dict[str, Any], project_name: str, service_name: str) -> ServiceState:
    for service in payload["services"]:
        if service.get("projectName") != project_name or service.get("name") != service_name:
            continue
        if service.get("type") != "app":
            raise EasyPanelError(f"{project_name}/{service_name} is not an app service")
        deploy = service.get("deploy") or {}
        source = service.get("source") or {}
        commit = service.get("commit") or {}
        return ServiceState(
            project_name=project_name,
            service_name=service_name,
            env_text=service.get("env") or "",
            sha=commit.get("sha"),
            enabled=bool(service.get("enabled")),
            source_ref=source.get("ref"),
            source_path=source.get("path"),
            zero_downtime=deploy.get("zeroDowntime"),
            replicas=deploy.get("replicas"),
        )
    raise EasyPanelError(f"service not found: {project_name}/{service_name}")


def _desired_env(service_name: str, runtime_env: dict[str, str], existing_env: OrderedDict[str, str]) -> dict[str, str]:
    if service_name == "hermes-lab":
        api_server_key = (
            runtime_env.get("API_SERVER_KEY")
            or runtime_env.get("HERMES_API_SERVER_KEY")
            or existing_env.get("API_SERVER_KEY")
            or secrets.token_urlsafe(32)
        )
        desired = {
            "HERMES_HOME": "/opt/data",
            "HERMES_MODEL": runtime_env.get("HERMES_MODEL", existing_env.get("HERMES_MODEL", "gpt-4o-mini")),
            "HERMES_PROVIDER": runtime_env.get("HERMES_PROVIDER", existing_env.get("HERMES_PROVIDER", "openai-api")),
            "HERMES_REASONING_EFFORT": runtime_env.get(
                "HERMES_REASONING_EFFORT",
                existing_env.get("HERMES_REASONING_EFFORT", "none"),
            ),
            "HERMES_STATE_ROOT": "/opt/data",
            "HERMES_CRON_SCRIPTS_DIR": "/opt/data/scripts",
            "HERMES_CRON_JOBS_JSON": "/opt/data/cron/jobs.json",
            "HERMES_DASHBOARD": "1",
            "HERMES_DASHBOARD_HOST": "127.0.0.1",
            "HERMES_DASHBOARD_PORT": "9119",
            "HERMES_KNOWLEDGE_DB": "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
            "MANALOOM_KNOWLEDGE_DB": "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
            "API_SERVER_ENABLED": "true",
            "API_SERVER_HOST": "0.0.0.0",
            "API_SERVER_KEY": api_server_key,
            "HERMES_CRON_BOOTSTRAP": "1",
            "HERMES_CRON_BOOTSTRAP_REQUIRED": "1",
            "HERMES_DOCS_SYNC_ALLOW_ROOT": "1",
            "HERMES_REPO_REF": "master",
            "HERMES_REPO_AUTO_SYNC": "1",
        }
        openai_key = runtime_env.get("OPENAI_API_KEY") or existing_env.get("OPENAI_API_KEY")
        if openai_key:
            desired["OPENAI_API_KEY"] = openai_key
        github_token = (
            runtime_env.get("HERMES_GITHUB_TOKEN")
            or runtime_env.get("GITHUB_TOKEN")
            or runtime_env.get("GH_TOKEN")
            or existing_env.get("HERMES_GITHUB_TOKEN")
            or existing_env.get("GITHUB_TOKEN")
            or existing_env.get("GH_TOKEN")
        )
        if github_token:
            desired["HERMES_GITHUB_TOKEN"] = github_token
        return desired
    raise EasyPanelError(f"unsupported service: {service_name}")


def _latest_action_ids(client: EasyPanelClient, *, project_name: str, service_name: str) -> set[str]:
    return {
        str(action.get("id"))
        for action in client.list_actions(
            project_name=project_name,
            service_name=service_name,
            limit=5,
            action_type="deployment",
        )
        if action.get("id")
    }


def _wait_for_action(
    client: EasyPanelClient,
    *,
    project_name: str,
    service_name: str,
    previous_ids: set[str],
    timeout_seconds: int,
) -> dict[str, Any]:
    deadline = time.time() + timeout_seconds
    latest_seen: dict[str, Any] | None = None
    while time.time() < deadline:
        actions = client.list_actions(
            project_name=project_name,
            service_name=service_name,
            limit=5,
            action_type="deployment",
        )
        if actions:
            latest_seen = actions[0]
            if latest_seen.get("id") not in previous_ids and latest_seen.get("status") in {"done", "failed", "canceled"}:
                return latest_seen
        time.sleep(3)
    if latest_seen is not None:
        return latest_seen
    raise EasyPanelError(f"no deployment action observed for {project_name}/{service_name}")


def reconcile_service(
    client: EasyPanelClient,
    *,
    project_name: str,
    service_name: str,
    runtime_env: dict[str, str],
    apply: bool,
    deploy: bool,
    wait_timeout: int,
    expected_sha: str,
) -> dict[str, Any]:
    if service_name not in SUPPORTED_SERVICES:
        raise EasyPanelError(
            f"unsupported EasyPanel app service: {service_name}; "
            "deploy manaloom-ops with scripts/manaloom_deploy_ops_image.sh"
        )
    state = _collect_service_state(client.list_projects_and_services(), project_name, service_name)
    existing_env = _parse_dotenv(state.env_text)
    desired_updates = _desired_env(service_name, runtime_env, existing_env)
    merged_env_text, changes = _merge_env(state.env_text, desired_updates)

    result: dict[str, Any] = {
        "service": service_name,
        "sha_before": state.sha,
        "source_ref": state.source_ref,
        "source_path": state.source_path,
        "enabled": state.enabled,
        "replicas": state.replicas,
        "zero_downtime": state.zero_downtime,
        "changes": changes,
        "applied": False,
        "deployed": False,
        "deploy_action": None,
        "sha_after": state.sha,
    }

    if not apply:
        result["matches_expected_sha"] = state.sha == expected_sha
        return result

    if changes:
        client.update_env(
            project_name=project_name,
            service_name=service_name,
            env_text=merged_env_text,
        )
        result["applied"] = True

    if deploy:
        previous_ids = _latest_action_ids(
            client,
            project_name=project_name,
            service_name=service_name,
        )
        try:
            client.deploy_service(project_name=project_name, service_name=service_name)
        except TimeoutError:
            pass
        action = _wait_for_action(
            client,
            project_name=project_name,
            service_name=service_name,
            previous_ids=previous_ids,
            timeout_seconds=wait_timeout,
        )
        result["deployed"] = True
        result["deploy_action"] = {
            "id": action.get("id"),
            "status": action.get("status"),
            "createdAt": action.get("createdAt"),
            "completedAt": action.get("updatedAt") or action.get("completedAt"),
            "description": action.get("description"),
        }

    refreshed = _collect_service_state(client.list_projects_and_services(), project_name, service_name)
    result["sha_after"] = refreshed.sha
    result["matches_expected_sha"] = refreshed.sha == expected_sha
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--env-file", type=Path, help="Additional dotenv file to load")
    parser.add_argument("--project", default=DEFAULT_PROJECT)
    parser.add_argument(
        "--services",
        nargs="+",
        required=True,
        choices=list(SUPPORTED_SERVICES),
        help="Optional EasyPanel app services to reconcile",
    )
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--deploy", action="store_true")
    parser.add_argument("--wait-timeout", type=int, default=240)
    parser.add_argument("--expected-sha", default=_local_head_sha())
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    runtime_env = load_runtime_env(args.env_file)
    base_url = runtime_env.get("EASYPANEL_BASE_URL")
    token = runtime_env.get("EASYPANEL_API_TOKEN")
    if not base_url or not token:
        raise SystemExit("missing EASYPANEL_BASE_URL or EASYPANEL_API_TOKEN")
    client = EasyPanelClient(base_url=base_url, token=token)

    results = []
    for service_name in args.services:
        results.append(
            reconcile_service(
                client,
                project_name=args.project,
                service_name=service_name,
                runtime_env=runtime_env,
                apply=args.apply,
                deploy=args.deploy,
                wait_timeout=args.wait_timeout,
                expected_sha=args.expected_sha,
            )
        )

    print(
        json.dumps(
            {
                "project": args.project,
                "expected_sha": args.expected_sha,
                "apply": args.apply,
                "deploy": args.deploy,
                "results": results,
            },
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
