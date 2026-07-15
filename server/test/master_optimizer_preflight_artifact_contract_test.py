#!/usr/bin/env python3
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "bin" / "master_optimizer_preflight.sh"
OPTIMIZER_LOOP = (
    Path(__file__).resolve().parents[2]
    / "docs"
    / "hermes-analysis"
    / "manaloom-knowledge"
    / "scripts"
    / "master_optimizer_loop.py"
)


def test_production_preflight_defaults_to_persistent_data_volume() -> None:
    text = SCRIPT.read_text(encoding="utf-8")

    assert 'if [[ -d /data/manaloom-ops ]]; then' in text
    assert 'DEFAULT_ARTIFACT_DIR="/data/manaloom-ops/artifacts/master-optimizer-preflight"' in text
    assert 'ARTIFACT_DIR="${MANALOOM_MASTER_OPTIMIZER_ARTIFACT_DIR:-$DEFAULT_ARTIFACT_DIR}"' in text
    assert 'export MANALOOM_MASTER_OPTIMIZER_REPORT_DIR="$REPORT_DIR"' in text

    optimizer_text = OPTIMIZER_LOOP.read_text(encoding="utf-8")
    assert 'os.environ.get(' in optimizer_text
    assert '"MANALOOM_MASTER_OPTIMIZER_REPORT_DIR"' in optimizer_text


if __name__ == "__main__":
    test_production_preflight_defaults_to_persistent_data_volume()
    print("master_optimizer_preflight_artifact_contract_test.py: ok")
