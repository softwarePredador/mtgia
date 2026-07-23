#!/usr/bin/env python3
"""Resolve local external-engine source checkouts without hidden machine paths."""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
XMAGE_SOURCE_ROOT_ENV = "MANALOOM_XMAGE_SOURCE_ROOT"
XMAGE_PIN_FILE = REPO_ROOT / "services/xmage-sidecar/XMAGE_COMMIT"
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")


def canonical_xmage_pin() -> str:
    try:
        pin = XMAGE_PIN_FILE.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise ValueError("cannot read the canonical XMage pin") from exc
    if not SHA_PATTERN.fullmatch(pin):
        raise ValueError("the canonical XMage pin is not a lowercase 40-character SHA")
    return pin


def inspect_xmage_source_root(root: Path) -> dict[str, Any]:
    """Return pin and cleanliness evidence for one local XMage checkout."""

    resolved = root.expanduser().resolve()
    if not resolved.is_dir():
        return {
            "status": "fail",
            "root": str(resolved),
            "error": "xmage_source_root_is_not_a_directory",
        }
    try:
        top_level = subprocess.run(
            ["git", "-C", str(resolved), "rev-parse", "--show-toplevel"],
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
        revision = subprocess.run(
            ["git", "-C", str(resolved), "rev-parse", "HEAD"],
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
        status = subprocess.run(
            ["git", "-C", str(resolved), "status", "--porcelain"],
            check=False,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return {
            "status": "fail",
            "root": str(resolved),
            "error": f"xmage_git_inspection_failed:{exc.__class__.__name__}",
        }

    expected_pin = canonical_xmage_pin()
    observed_pin = revision.stdout.strip() if revision.returncode == 0 else ""
    observed_top = Path(top_level.stdout.strip()).resolve() if top_level.returncode == 0 else None
    dirty_entries = [line for line in status.stdout.splitlines() if line.strip()]
    required_paths = (
        "Mage",
        "Mage.Sets",
        "Mage.Tests",
    )
    missing_paths = [name for name in required_paths if not (resolved / name).exists()]
    checks_pass = (
        top_level.returncode == 0
        and observed_top == resolved
        and revision.returncode == 0
        and observed_pin == expected_pin
        and status.returncode == 0
        and not dirty_entries
        and not missing_paths
    )
    error = None
    if top_level.returncode != 0 or observed_top != resolved:
        error = "xmage_source_root_is_not_a_git_toplevel"
    elif revision.returncode != 0 or observed_pin != expected_pin:
        error = "xmage_source_root_is_not_at_canonical_runtime_pin"
    elif status.returncode != 0 or dirty_entries:
        error = "xmage_source_root_has_uncommitted_or_untracked_changes"
    elif missing_paths:
        error = "xmage_source_root_is_incomplete"
    return {
        "status": "pass" if checks_pass else "fail",
        "root": str(resolved),
        "expected_pin": expected_pin,
        "observed_pin": observed_pin or None,
        "dirty_entry_count": len(dirty_entries),
        "missing_paths": missing_paths,
        "error": error,
    }


def resolve_xmage_source_root(
    value: str | Path | None = None,
    *,
    allow_unpinned: bool = False,
) -> Path:
    """Resolve an explicit/env source root and reject unsafe operational input."""

    raw = str(value).strip() if value is not None else ""
    if not raw:
        raw = os.environ.get(XMAGE_SOURCE_ROOT_ENV, "").strip()
    if not raw:
        raise ValueError(
            "XMage source root is required: pass --xmage-root or set "
            f"{XMAGE_SOURCE_ROOT_ENV}"
        )
    root = Path(raw).expanduser().resolve()
    if not root.is_dir():
        raise ValueError(f"XMage source root is not a directory: {root}")
    if allow_unpinned:
        return root
    evidence = inspect_xmage_source_root(root)
    if evidence["status"] != "pass":
        raise ValueError(
            "XMage source root must be a clean, complete checkout at canonical pin "
            f"{evidence.get('expected_pin')}: {evidence.get('error')}"
        )
    return root
