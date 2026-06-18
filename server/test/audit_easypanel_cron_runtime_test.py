#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "bin" / "audit_easypanel_cron_runtime.py"
SPEC = importlib.util.spec_from_file_location("audit_easypanel_cron_runtime", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def test_job_output_probe_targets_for_manaloom_ops_prefers_latest_output_and_name_dir() -> None:
    job = {
        "name": "pull_learning_events",
        "latest_output": "/data/manaloom-ops/cron/output/pull_learning_events/20260618_060004.log",
    }
    targets = MODULE._job_output_probe_targets("manaloom-ops", job)
    assert targets == [
        {
            "mode": "file",
            "path": "/data/manaloom-ops/cron/output/pull_learning_events/20260618_060004.log",
            "source": "latest_output",
        },
        {
            "mode": "dir",
            "path": "/data/manaloom-ops/cron/output/pull_learning_events",
            "source": "derived_job_name_dir",
        },
    ]


def test_job_output_probe_targets_for_hermes_lab_falls_back_to_job_id_dir() -> None:
    job = {
        "id": "46989818ac37",
        "name": "mtg-rules-auditor",
        "latest_output": None,
    }
    targets = MODULE._job_output_probe_targets("hermes-lab", job)
    assert targets == [
        {
            "mode": "dir",
            "path": "/opt/data/cron/output/46989818ac37",
            "source": "derived_job_id_dir",
        }
    ]


def test_parse_probe_lines_ignores_noise() -> None:
    parsed = MODULE._parse_probe_lines(
        "user=root\nuid=0\nhostname=node-1\nnoise-without-equals\npwd=/opt/data\n"
    )
    assert parsed == {
        "user": "root",
        "uid": "0",
        "hostname": "node-1",
        "pwd": "/opt/data",
    }


def test_extract_runtime_findings_flags_active_job_error() -> None:
    findings = MODULE._extract_runtime_findings(
        service_envs={
            "manaloom-ops": {"openai_api_key_present": False},
            "hermes-lab": {"openai_api_key_present": True},
        },
        ops_jobs={
            "jobs_total": 1,
            "jobs": [
                {
                    "name": "pull_learning_events",
                    "state": "active",
                    "enabled": True,
                    "last_status": "ok",
                    "output_evidence": {"path": "/tmp/out.log"},
                }
            ],
        },
        lab_jobs={
            "jobs_total": 1,
            "jobs": [
                {
                    "name": "manaloom-docs-branch-sync",
                    "state": "scheduled",
                    "enabled": True,
                    "last_status": "error",
                }
            ],
        },
        ops_logs=["scheduler started"],
        lab_logs=["bootstrap complete"],
    )
    assert any(finding["code"] == "hermes_lab_job_error" for finding in findings)
