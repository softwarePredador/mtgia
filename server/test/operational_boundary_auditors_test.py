#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import importlib.util
import sys
from pathlib import Path

import pytest


BIN_DIR = Path(__file__).resolve().parents[1] / "bin"


def _load_module(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, BIN_DIR / filename)
    module = importlib.util.module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


ALIGNMENT = _load_module(
    "operational_boundary_runtime_alignment",
    "audit_easypanel_runtime_alignment.py",
)
CRON = _load_module(
    "operational_boundary_cron_runtime",
    "audit_easypanel_cron_runtime.py",
)


@pytest.mark.parametrize("module", [ALIGNMENT, CRON])
def test_easypanel_origin_requires_independent_caller_fingerprint(
    module,
    monkeypatch,
) -> None:
    origin = "https://panel.example.invalid"
    expected = hashlib.sha256(origin.encode("utf-8")).hexdigest()
    monkeypatch.setenv("MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256", expected)

    assert module._validated_easypanel_base_url(f"{origin}/") == origin
    with pytest.raises(RuntimeError, match="fingerprint"):
        module._validated_easypanel_base_url(
            "https://attacker.example.invalid",
        )
    with pytest.raises(RuntimeError, match="HTTPS origin"):
        module._validated_easypanel_base_url("http://panel.example.invalid")


@pytest.mark.parametrize("module", [ALIGNMENT, CRON])
def test_ssh_coordinate_requires_exact_target_and_host_key_anchor(
    module,
    monkeypatch,
    tmp_path,
) -> None:
    key = tmp_path / "id_ed25519"
    key.write_text("test-only", encoding="utf-8")
    target = "root@server.example.invalid"
    fingerprint = f"SHA256:{'A' * 43}"
    runtime_env = {
        "MANALOOM_EASYPANEL_SSH_HOST": target,
        "MANALOOM_EASYPANEL_SSH_KEY": str(key),
    }
    monkeypatch.setenv("MANALOOM_EXPECTED_SSH_TARGET", target)
    monkeypatch.setenv(
        "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256",
        fingerprint,
    )

    coordinate = module._validated_ssh_coordinate(runtime_env)
    assert coordinate[0] == target
    assert coordinate[1] == key.resolve()
    assert coordinate[3] == fingerprint

    monkeypatch.setenv(
        "MANALOOM_EXPECTED_SSH_TARGET",
        "root@different.example.invalid",
    )
    with pytest.raises(RuntimeError, match="exact caller-approved destination"):
        module._validated_ssh_coordinate(runtime_env)


def test_cron_auditor_rejects_insecure_websocket_tls() -> None:
    with pytest.raises(RuntimeError, match="insecure TLS is forbidden"):
        CRON._sslopt("wss://panel.example.invalid/ws", insecure=True)


def test_alignment_rejects_arbitrary_postgres_destinations() -> None:
    with pytest.raises(RuntimeError, match="runtime PostgreSQL host"):
        ALIGNMENT._query_pg_metrics(
            {
                "DB_HOST": "attacker.example.invalid",
                "MANALOOM_EXPECTED_DB_HOST": ALIGNMENT.EXPECTED_POSTGRES_HOST,
            }
        )
    with pytest.raises(RuntimeError, match="loopback PostgreSQL tunnel"):
        ALIGNMENT._validate_pg_metrics_only_runtime(
            {
                "DATABASE_URL": "postgresql://postgres:secret@attacker.example.invalid/halder",
            }
        )
    ALIGNMENT._validate_pg_metrics_only_runtime(
        {
            "DATABASE_URL": (
                "postgresql://postgres:secret@127.0.0.1:15432/halder"
                "?sslmode=disable"
            ),
        }
    )
    with pytest.raises(RuntimeError, match="loopback PostgreSQL tunnel"):
        ALIGNMENT._validate_pg_metrics_only_runtime(
            {
                "DATABASE_URL": (
                    "postgresql://postgres:secret@127.0.0.1:15432/halder"
                    "?sslmode=disable&host=attacker.example.invalid"
                ),
            }
        )
