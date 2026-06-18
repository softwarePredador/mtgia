#!/usr/bin/env python3
"""Guards the server/bin exporter wrapper against drift."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


def _load_module(module_name: str, module_path: Path):
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to load {module_name} from {module_path}")
    module = importlib.util.module_from_spec(spec)
    scripts_dir = str(module_path.parent)
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


class ExportHermesLearnedDeckWrapperParityTests(unittest.TestCase):
    def test_server_wrapper_reexports_docs_implementation(self) -> None:
        repo_root = Path(__file__).resolve().parents[4]
        docs_path = (
            repo_root
            / "docs"
            / "hermes-analysis"
            / "manaloom-knowledge"
            / "scripts"
            / "export_hermes_learned_deck.py"
        )
        server_path = repo_root / "server" / "bin" / "export_hermes_learned_deck.py"

        docs_exporter = _load_module("docs_export_hermes_learned_deck", docs_path)
        server_exporter = _load_module("server_export_hermes_learned_deck", server_path)

        self.assertEqual(server_exporter.main.__code__.co_filename, str(server_path))
        self.assertEqual(
            server_exporter.export_learned_deck.__code__.co_filename,
            str(docs_path),
        )
        self.assertEqual(
            server_exporter.build_metadata.__code__.co_filename,
            str(docs_path),
        )
        self.assertEqual(
            server_exporter.export_learned_deck.__name__,
            docs_exporter.export_learned_deck.__name__,
        )
        self.assertEqual(
            server_exporter.build_metadata.__name__,
            docs_exporter.build_metadata.__name__,
        )


if __name__ == "__main__":
    unittest.main()
