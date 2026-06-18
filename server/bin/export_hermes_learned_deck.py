#!/usr/bin/env python3
"""Compatibility wrapper for the canonical Hermes learned deck exporter.

The canonical implementation lives under docs/hermes-analysis so the Hermes
runtime and the repo share the same logic. This server/bin entrypoint stays
stable for existing shell scripts and operational tooling.
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


def _implementation_path() -> Path:
    repo_root = Path(__file__).resolve().parents[2]
    return (
        repo_root
        / "docs"
        / "hermes-analysis"
        / "manaloom-knowledge"
        / "scripts"
        / "export_hermes_learned_deck.py"
    )


def _load_implementation():
    impl_path = _implementation_path()
    spec = importlib.util.spec_from_file_location(
        "hermes_export_hermes_learned_deck_impl",
        impl_path,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load exporter implementation from {impl_path}")

    module = importlib.util.module_from_spec(spec)
    scripts_dir = str(impl_path.parent)
    inserted = False
    if scripts_dir not in sys.path:
        sys.path.insert(0, scripts_dir)
        inserted = True
    try:
        spec.loader.exec_module(module)
    finally:
        if inserted:
            sys.path.remove(scripts_dir)
    return module


_IMPLEMENTATION = _load_implementation()

for _name in dir(_IMPLEMENTATION):
    if _name.startswith("_"):
        continue
    globals()[_name] = getattr(_IMPLEMENTATION, _name)

__all__ = [name for name in dir(_IMPLEMENTATION) if not name.startswith("_")]


def main(argv=None):
    return _IMPLEMENTATION.main(argv)


if __name__ == "__main__":
    raise SystemExit(main())
