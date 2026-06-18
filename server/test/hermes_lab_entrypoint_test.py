#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path


ENTRYPOINT = Path(__file__).resolve().parents[1] / "bin" / "hermes_lab_entrypoint.sh"


def test_entrypoint_normalizes_hermes_owned_runtime_paths_before_bootstrap() -> None:
    text = ENTRYPOINT.read_text(encoding="utf-8")
    chown_index = text.index("chown -R hermes:hermes")
    bootstrap_index = text.index("python3 /opt/bootstrap/hermes_lab_cron_bootstrap.py")
    gateway_index = text.index("exec hermes gateway run")
    assert chown_index < bootstrap_index < gateway_index
    assert '"$REPO_DIR"' in text
    assert '"$HERMES_CRON_SCRIPTS_DIR"' in text
    assert '"$(dirname "$HERMES_CRON_JOBS_JSON")"' in text
