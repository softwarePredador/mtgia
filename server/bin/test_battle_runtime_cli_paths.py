#!/usr/bin/env python3
"""Smoke tests for local runtime path resolution of battle helper CLIs."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def _run(*parts: str) -> None:
    result = subprocess.run(
        [sys.executable, *parts],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise AssertionError(
            f"command failed: {' '.join(parts)}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )


def test_generate_card_replays_help_runs_locally() -> None:
    _run("server/bin/generate_card_replays.py", "--help")


def test_card_impact_analyzer_help_runs_locally() -> None:
    _run("server/bin/card_impact_analyzer.py", "--help")


def test_card_impact_analysis_help_runs_locally() -> None:
    _run("server/bin/card_impact_analysis.py", "--help")


def test_card_impact_scorer_help_runs_locally() -> None:
    _run("server/bin/card_impact_scorer.py", "--help")


def test_loss_mode_suggester_help_runs_locally() -> None:
    _run("server/bin/loss_mode_suggester.py", "--help")


def main() -> int:
    tests = [
        test_generate_card_replays_help_runs_locally,
        test_card_impact_analyzer_help_runs_locally,
        test_card_impact_analysis_help_runs_locally,
        test_card_impact_scorer_help_runs_locally,
        test_loss_mode_suggester_help_runs_locally,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
