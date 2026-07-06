#!/usr/bin/env python3
"""Audit EasyPanel runtime alignment for ManaLoom server-owned ops.

Read-only audit:
- compares local HEAD with public backend SHA and EasyPanel service SHAs
- inspects service env for canonical knowledge DB wiring and OpenAI presence
- validates PostgreSQL side effects that should move under manaloom-ops
"""

from __future__ import annotations

import argparse
import json
import os
import ssl
import sys
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
SERVER_DIR = REPO_ROOT / "server"
DEFAULT_ARTIFACT_DIR = REPO_ROOT / "server" / "test" / "artifacts" / "easypanel_runtime_alignment"
DEFAULT_HEALTH_URL = "https://evolution-cartinhas.2ta7qx.easypanel.host/health"
DEFAULT_SERVICES = ("manaloom-ops", "hermes-lab")

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


def _health_ssl_context(*, insecure: bool) -> ssl.SSLContext:
    if insecure:
        return ssl._create_unverified_context()
    try:
        import certifi  # type: ignore

        return ssl.create_default_context(cafile=certifi.where())
    except Exception:
        return ssl.create_default_context()


def _fetch_public_health(url: str, *, insecure: bool) -> dict[str, Any]:
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(
        request,
        timeout=15,
        context=_health_ssl_context(insecure=insecure),
    ) as response:
        return json.loads(response.read().decode("utf-8", "replace"))


def _fetch_service_env_snapshot(
    client: reconcile.EasyPanelClient,
    *,
    project_name: str,
    service_names: tuple[str, ...],
) -> dict[str, dict[str, Any]]:
    payload = client.list_projects_and_services()
    snapshots: dict[str, dict[str, Any]] = {}
    for service_name in service_names:
        state = reconcile._collect_service_state(payload, project_name, service_name)
        env_map = reconcile._parse_dotenv(state.env_text)
        snapshots[service_name] = {
            "enabled": state.enabled,
            "sha": state.sha,
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
    return snapshots


def _query_pg_metrics(runtime_env: dict[str, str]) -> dict[str, Any]:
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
    if not hermes_lab.get("openai_api_key_present"):
        findings.append(
            {
                "priority": "P0",
                "code": "hermes_lab_missing_openai",
                "message": "hermes-lab is missing OPENAI_API_KEY",
            }
        )

    ops_db = services.get("manaloom-ops", {}).get("knowledge_db")
    lab_db = hermes_lab.get("knowledge_db")
    if ops_db != lab_db:
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
    parser.add_argument("--project", default=os.environ.get("EASYPANEL_PROJECT", "evolution"))
    parser.add_argument("--health-url", default=os.environ.get("MANALOOM_PUBLIC_HEALTH_URL", DEFAULT_HEALTH_URL))
    parser.add_argument("--artifact-dir", default=str(DEFAULT_ARTIFACT_DIR))
    parser.add_argument("--insecure-health", action="store_true")
    parser.add_argument("--stdout-only", action="store_true")
    args = parser.parse_args(argv)

    runtime_env = reconcile.load_runtime_env()
    client = reconcile.EasyPanelClient(
        runtime_env["EASYPANEL_BASE_URL"],
        runtime_env["EASYPANEL_API_TOKEN"],
    )

    local_head = reconcile._local_head_sha()
    public_health = _fetch_public_health(args.health_url, insecure=args.insecure_health)
    services = _fetch_service_env_snapshot(client, project_name=args.project, service_names=DEFAULT_SERVICES)
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
