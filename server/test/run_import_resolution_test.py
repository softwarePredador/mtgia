#!/usr/bin/env python3
"""Tests for deterministic knowledge import path resolution."""

from __future__ import annotations

import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = (
        root
        / ".."
        / "docs"
        / "hermes-analysis"
        / "manaloom-knowledge"
        / "scripts"
        / "run_import.py"
    ).resolve()
    spec = importlib.util.spec_from_file_location("run_import", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class RunImportResolutionTest(unittest.TestCase):
    def test_repo_root_prefers_env_workspace(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / "repo"
            repo.mkdir()
            previous_repo = os.environ.get("MANALOOM_REPO")
            previous_workspace = os.environ.get("MANALOOM_WORKSPACE")
            previous_hermes_repo = os.environ.get("HERMES_REPO_DIR")
            try:
                os.environ.pop("MANALOOM_REPO", None)
                os.environ["MANALOOM_WORKSPACE"] = str(repo)
                os.environ["HERMES_REPO_DIR"] = str(repo)
                self.assertEqual(module._resolve_repo_root(), repo.resolve())
            finally:
                if previous_repo is None:
                    os.environ.pop("MANALOOM_REPO", None)
                else:
                    os.environ["MANALOOM_REPO"] = previous_repo
                if previous_workspace is None:
                    os.environ.pop("MANALOOM_WORKSPACE", None)
                else:
                    os.environ["MANALOOM_WORKSPACE"] = previous_workspace
                if previous_hermes_repo is None:
                    os.environ.pop("HERMES_REPO_DIR", None)
                else:
                    os.environ["HERMES_REPO_DIR"] = previous_hermes_repo

    def test_default_paths_point_inside_repo_knowledge_root(self) -> None:
        module = _load_module()
        self.assertTrue(str(module.THEMES_PATH).endswith("docs/hermes-analysis/manaloom-knowledge/THEMES.md"))
        self.assertTrue(str(module.DECKS_DIR).endswith("docs/hermes-analysis/manaloom-knowledge/decks"))


if __name__ == "__main__":
    unittest.main()
