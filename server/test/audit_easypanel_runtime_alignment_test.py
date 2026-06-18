#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "bin" / "audit_easypanel_runtime_alignment.py"
SPEC = importlib.util.spec_from_file_location("audit_easypanel_runtime_alignment", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


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
