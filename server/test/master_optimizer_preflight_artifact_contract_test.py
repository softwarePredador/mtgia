#!/usr/bin/env python3
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "master_optimizer_preflight.sh"


def test_production_preflight_defaults_to_persistent_data_volume() -> None:
    text = SCRIPT.read_text(encoding="utf-8")

    assert 'if [[ -d /data/manaloom-ops ]]; then' in text
    assert 'DEFAULT_ARTIFACT_DIR="/data/manaloom-ops/artifacts/master-optimizer-preflight"' in text
    assert 'ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-$DEFAULT_ARTIFACT_DIR}"' in text


if __name__ == "__main__":
    test_production_preflight_defaults_to_persistent_data_volume()
    print("master_optimizer_preflight_artifact_contract_test.py: ok")
