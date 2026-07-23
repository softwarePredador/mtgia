from __future__ import annotations

import subprocess
from pathlib import Path
from unittest.mock import patch

import pytest

import external_engine_source_contract as contract


def test_requires_explicit_or_environment_source_root(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv(contract.XMAGE_SOURCE_ROOT_ENV, raising=False)
    with pytest.raises(ValueError, match="--xmage-root"):
        contract.resolve_xmage_source_root()


def test_allow_unpinned_is_diagnostic_only(tmp_path: Path) -> None:
    assert contract.resolve_xmage_source_root(tmp_path, allow_unpinned=True) == tmp_path.resolve()


def test_environment_fallback_is_supported(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv(contract.XMAGE_SOURCE_ROOT_ENV, str(tmp_path))
    assert contract.resolve_xmage_source_root(allow_unpinned=True) == tmp_path.resolve()


def test_unversioned_source_is_rejected(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="canonical pin"):
        contract.resolve_xmage_source_root(tmp_path)


def test_clean_exact_pin_source_is_accepted(tmp_path: Path) -> None:
    expected = contract.canonical_xmage_pin()
    for name in ("Mage", "Mage.Sets", "Mage.Tests"):
        (tmp_path / name).mkdir()

    def completed(stdout: str = "", returncode: int = 0) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess([], returncode, stdout=stdout, stderr="")

    with patch.object(
        contract.subprocess,
        "run",
        side_effect=[
            completed(f"{tmp_path.resolve()}\n"),
            completed(f"{expected}\n"),
            completed(),
        ],
    ):
        assert contract.resolve_xmage_source_root(tmp_path) == tmp_path.resolve()
