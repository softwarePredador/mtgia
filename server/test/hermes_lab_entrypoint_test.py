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


def test_entrypoint_auto_syncs_persistent_repo_before_bootstrap() -> None:
    text = ENTRYPOINT.read_text(encoding="utf-8")
    auto_sync_index = text.index('REPO_AUTO_SYNC="${HERMES_REPO_AUTO_SYNC:-1}"')
    safe_directory_index = text.index('git config --global --add safe.directory "$REPO_DIR"')
    fetch_index = text.index('git -C "$REPO_DIR" fetch --all --prune')
    pull_index = text.index('git -C "$REPO_DIR" pull --ff-only origin "$REPO_REF"')
    bootstrap_index = text.index("python3 /opt/bootstrap/hermes_lab_cron_bootstrap.py")
    assert auto_sync_index < safe_directory_index < fetch_index < pull_index < bootstrap_index
