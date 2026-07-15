#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "bin" / "audit_easypanel_runtime_alignment.py"
SPEC = importlib.util.spec_from_file_location("audit_easypanel_runtime_alignment", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def test_snapshot_from_swarm_inspect_uses_running_env_sha_and_cache_path() -> None:
    snapshot = MODULE._snapshot_from_swarm_inspect(
        {
            "Spec": {
                "Mode": {"Replicated": {"Replicas": 1}},
                "UpdateConfig": {"Order": "stop-first"},
                "TaskTemplate": {
                    "ContainerSpec": {
                        "Image": "localhost:5000/manaloom/ops:abc123@sha256:test",
                        "Env": [
                            "GIT_SHA=abc123",
                            "HERMES_KNOWLEDGE_DB=/data/manaloom-ops/knowledge.db",
                            "MANALOOM_KNOWLEDGE_DB=/data/manaloom-ops/knowledge.db",
                        ],
                    }
                },
            }
        }
    )

    assert snapshot["runtime_source"] == "docker_swarm"
    assert snapshot["sha"] == "abc123"
    assert snapshot["replicas"] == 1
    assert snapshot["zero_downtime"] is False
    assert snapshot["knowledge_db"] == "/data/manaloom-ops/knowledge.db"


def test_build_findings_flags_pending_sync_lag_and_split_paths() -> None:
    findings = MODULE._build_findings(
        local_head="abc123",
        public_sha="abc123",
        services={
            "manaloom-ops": {
                "sha": "abc123",
                "knowledge_db": "/data/manaloom-ops/knowledge.db",
            },
            "hermes-lab": {
                "sha": "abc123",
                "knowledge_db": "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db",
                "openai_api_key_present": True,
            },
        },
        pg_metrics={
            "deck_learning_events": {
                "pending": 2,
                "latest_pending_age_hours": 5.5,
            },
        },
    )
    codes = {finding["code"] for finding in findings}
    assert "learning_event_sync_lag" in codes
    assert "split_operational_cache_paths" in codes


def test_build_findings_flags_missing_openai_and_sha_drift() -> None:
    findings = MODULE._build_findings(
        local_head="abc123",
        public_sha="zzz999",
        services={
            "manaloom-ops": {
                "sha": "abc123",
                "knowledge_db": "/data/manaloom-ops/knowledge.db",
            },
            "hermes-lab": {
                "sha": "old456",
                "knowledge_db": "/data/manaloom-ops/knowledge.db",
                "openai_api_key_present": False,
            },
        },
        pg_metrics={
            "deck_learning_events": {
                "pending": 0,
                "latest_pending_age_hours": None,
            },
        },
    )
    codes = {finding["code"] for finding in findings}
    assert "public_sha_drift" in codes
    assert "hermes-lab_sha_drift" in codes
    assert "hermes_lab_missing_openai" in codes


def test_internal_postgres_metrics_use_new_server_tunnel(monkeypatch) -> None:
    calls = []

    def fake_check_output(command, **kwargs):
        calls.append((command, kwargs))
        return json.dumps(
            {
                "deck_learning_events": {
                    "total": 1,
                    "synced": 1,
                    "pending": 0,
                    "latest_pending_age_hours": None,
                    "pending_samples": [],
                }
            }
        )

    monkeypatch.setattr(MODULE.subprocess, "check_output", fake_check_output)
    payload = MODULE._query_pg_metrics(
        {
            "DB_HOST": "evolution_manaloom-postgres",
            "MANALOOM_EXPECTED_DB_HOST": "evolution_manaloom-postgres",
        }
    )

    assert payload["deck_learning_events"]["pending"] == 0
    assert calls[0][0][0] == str(MODULE.NEW_SERVER_PG_WRAPPER)
    assert calls[0][0][-1] == "--pg-metrics-only"
    assert calls[0][1]["timeout"] == 60
