#!/usr/bin/env python3
"""Repo/runtime path resolution shared by ManaLoom operational scripts."""

from __future__ import annotations

import os
from pathlib import Path


_ROOT_MARKERS = (
    "docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py",
    "server",
)


def _candidate_roots() -> list[Path]:
    script_path = Path(__file__).resolve()
    cwd = Path.cwd().resolve()
    candidates: list[Path] = []

    for base in [cwd, *cwd.parents, script_path.parent, *script_path.parents]:
        if base not in candidates:
            candidates.append(base)
    return candidates


def _looks_like_repo_root(path: Path) -> bool:
    return (
        (path / _ROOT_MARKERS[0]).is_file()
        and (path / _ROOT_MARKERS[1]).is_dir()
    )


def resolve_repo_root() -> Path:
    for key in ("MANALOOM_REPO", "MANALOOM_WORKSPACE", "HERMES_REPO_DIR", "MTGIA_REPO_ROOT"):
        raw = os.environ.get(key)
        if not raw:
            continue
        candidate = Path(raw).expanduser().resolve()
        if _looks_like_repo_root(candidate):
            return candidate

    for candidate in _candidate_roots():
        if _looks_like_repo_root(candidate):
            return candidate

    return Path(__file__).resolve().parents[2]


def resolve_battle_scripts_dir() -> Path:
    raw = os.environ.get("BATTLE_SCRIPTS_DIR")
    if raw:
        return Path(raw).expanduser().resolve()
    return resolve_repo_root() / "docs/hermes-analysis/manaloom-knowledge/scripts"


def resolve_battle_script_path() -> Path:
    raw = os.environ.get("MANALOOM_BATTLE_SCRIPT")
    if raw:
        return Path(raw).expanduser().resolve()
    return resolve_battle_scripts_dir() / "battle_analyst_v9.py"


def resolve_master_optimizer_replays_dir() -> Path:
    raw = os.environ.get("MANALOOM_MASTER_OPTIMIZER_REPLAYS_DIR")
    if raw:
        return Path(raw).expanduser().resolve()
    return resolve_repo_root() / "docs/hermes-analysis/master_optimizer_replays"


def resolve_forensic_replays_dir() -> Path:
    raw = os.environ.get("MANALOOM_FORENSIC_REPLAYS_DIR")
    if raw:
        return Path(raw).expanduser().resolve()
    return resolve_repo_root() / "docs/hermes-analysis/master_optimizer_reports/forensic_replays"
