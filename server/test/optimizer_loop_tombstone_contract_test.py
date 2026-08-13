#!/usr/bin/env python3
"""Fail-closed contract for the retired mutating optimizer entrypoint."""

from __future__ import annotations

import subprocess
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "optimizer_loop.sh"


def test_optimizer_loop_is_a_non_executable_tombstone() -> None:
    text = SCRIPT.read_text(encoding="utf-8")

    assert "BLOCKED:" in text
    assert "historical mutating entrypoint" in text
    assert "server/bin/master_optimizer_preflight.sh" in text
    assert "exit 2" in text

    for forbidden in (
        "--apply",
        "MANALOOM_SECRETS",
        "/opt/data/secrets",
        "source ",
        '. "$',
        "python3",
        "rm -f",
    ):
        assert forbidden not in text

    result = subprocess.run(
        ["bash", str(SCRIPT)],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 2
    assert result.stdout == ""
    assert "BLOCKED:" in result.stderr
    assert "master_optimizer_preflight.sh" in result.stderr


if __name__ == "__main__":
    test_optimizer_loop_is_a_non_executable_tombstone()
    print("optimizer_loop_tombstone_contract_test.py: ok")
