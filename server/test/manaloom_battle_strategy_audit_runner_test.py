#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "server" / "bin" / "manaloom_battle_strategy_audit.sh"


def test_runner_is_server_portable_and_persistent() -> None:
    text = RUNNER.read_text(encoding="utf-8")

    assert "/Users/" not in text
    assert 'MANALOOM_OPS_DATA_DIR:-/data/manaloom-ops' in text
    assert "MANALOOM_BATTLE_STRATEGY_ARTIFACT_ROOT" in text
    assert "MANALOOM_KNOWLEDGE_DB" in text
    assert '[[ ! -d "$REPO_DIR/.git" ]]' not in text
    assert "flock -n 9" in text
    assert "MANALOOM_BATTLE_STRATEGY_DESKTOP_NOTIFICATIONS" in text


if __name__ == "__main__":
    test_runner_is_server_portable_and_persistent()
    print("manaloom_battle_strategy_audit_runner_test.py: ok")
