#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "bin" / "reconcile_easypanel_services.py"
SPEC = importlib.util.spec_from_file_location("reconcile_easypanel_services", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC is not None and SPEC.loader is not None
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def test_merge_env_updates_only_target_keys() -> None:
    existing = "FOO=1\nSECRET_HINT=old\nBAR=2\n"
    merged, changes = MODULE._merge_env(
        existing,
        {
            "BAR": "2",
            "SECRET_HINT": "new-secret",
            "PULL_LEARNING_EVENTS_CRON": "0 * * * *",
        },
    )
    assert "FOO=1" in merged
    assert "BAR=2" in merged
    assert "SECRET_HINT=new-secret" in merged
    assert "PULL_LEARNING_EVENTS_CRON=0 * * * *" in merged
    assert changes["SECRET_HINT"] == {"from": "old", "to": "new-secret"}
    assert changes["PULL_LEARNING_EVENTS_CRON"] == {"from": None, "to": "0 * * * *"}


def test_redact_value_hides_secret_payloads() -> None:
    assert MODULE._redact_value("API_SERVER_KEY", "abc123") == "present"
    assert MODULE._redact_value("OPENAI_API_KEY", "") == "empty"
    assert MODULE._redact_value("HERMES_GITHUB_TOKEN", "ghp-example") == "present"


def test_reconciler_rejects_direct_swarm_ops_service() -> None:
    try:
        MODULE._desired_env(
            "manaloom-ops",
            {},
            MODULE._parse_dotenv(""),
        )
    except MODULE.EasyPanelError as exc:
        assert "unsupported service" in str(exc)
    else:
        raise AssertionError("manaloom-ops must not use EasyPanel app reconciliation")


def test_desired_env_for_hermes_lab_generates_missing_api_key() -> None:
    desired = MODULE._desired_env(
        "hermes-lab",
        {
            "OPENAI_API_KEY": "test-openai-key",
            "HERMES_GITHUB_TOKEN": "ghp-example",
        },
        MODULE._parse_dotenv(""),
    )
    assert desired["OPENAI_API_KEY"] == "test-openai-key"
    assert desired["HERMES_GITHUB_TOKEN"] == "ghp-example"
    assert desired["HERMES_DASHBOARD_HOST"] == "127.0.0.1"
    assert desired["HERMES_KNOWLEDGE_DB"].endswith("/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db")
    assert desired["MANALOOM_KNOWLEDGE_DB"] == desired["HERMES_KNOWLEDGE_DB"]
    assert desired["API_SERVER_ENABLED"] == "true"
    assert desired["HERMES_REPO_AUTO_SYNC"] == "1"
    assert len(desired["API_SERVER_KEY"]) >= 20


def main() -> None:
    test_merge_env_updates_only_target_keys()
    test_redact_value_hides_secret_payloads()
    test_reconciler_rejects_direct_swarm_ops_service()
    test_desired_env_for_hermes_lab_generates_missing_api_key()
    print("reconcile_easypanel_services_test.py: ok")


if __name__ == "__main__":
    main()
