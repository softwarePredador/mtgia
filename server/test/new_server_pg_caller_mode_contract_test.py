#!/usr/bin/env python3
from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
WRAPPER_NAME = "with_new_server_pg.sh"
WRAPPER_PATH = REPO_ROOT / "server" / "bin" / WRAPPER_NAME

EXPECTED_SHELL_MODES = {
    "scripts/manaloom_battle_product_gate.sh": (
        "--read-only",
        "--read-only",
        "--write-approved",
        "--write-approved",
    ),
    "scripts/manaloom_deep_ai_alignment_tester.sh": (
        "--read-only",
        "--write-approved",
        "--write-approved",
    ),
    "scripts/manaloom_deploy_backend_image.sh": (
        "--read-only",
        "--read-only",
        "--read-only",
        "--read-only",
    ),
    "scripts/manaloom_e2e_suite.sh": ("--write-approved",),
    "scripts/manaloom_global_battle_closure.sh": (
        "--read-only",
        "--read-only",
        "--write-approved",
    ),
    "scripts/manaloom_pg_hermes_sqlite_contract_audit.sh": (
        "--write-approved",
    ),
    "scripts/quality_gate_resolution_corpus.sh": (
        "--write-approved",
        "--read-only",
        "--read-only",
        "--read-only",
        "--read-only",
        "--write-approved",
        "--write-approved",
        "--write-approved",
    ),
}
PYTHON_CALLER = "server/bin/audit_easypanel_runtime_alignment.py"


def _source(relative_path: str) -> str:
    return (REPO_ROOT / relative_path).read_text(encoding="utf-8")


def _shell_wrapper_modes(source: str) -> tuple[str, ...]:
    modes: list[str] = []
    for match in re.finditer(re.escape(WRAPPER_NAME), source):
        tail = source[match.end() : match.end() + 96]
        candidates = {
            mode: tail.find(mode)
            for mode in ("--read-only", "--write-approved")
            if tail.find(mode) >= 0
        }
        if not candidates:
            raise AssertionError(
                "real wrapper caller has no explicit mode near: "
                f"{source[match.start() : match.end() + 48]!r}"
            )
        mode, offset = min(candidates.items(), key=lambda item: item[1])
        if offset > 32:
            raise AssertionError(
                f"wrapper mode is not the next argument: {tail[:64]!r}"
            )
        modes.append(mode)
    return tuple(modes)


def _discover_real_callers() -> set[str]:
    callers: set[str] = set()
    for root in (REPO_ROOT / "scripts", REPO_ROOT / "server" / "bin"):
        for path in root.rglob("*"):
            if not path.is_file() or path == WRAPPER_PATH:
                continue
            if path.name == "manaloom_release_ops_contract_test.sh":
                continue
            if path.suffix not in {".sh", ".py", ".dart"}:
                continue
            try:
                source = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if WRAPPER_NAME in source:
                callers.add(str(path.relative_to(REPO_ROOT)))
    return callers


class NewServerPgCallerModeContractTest(unittest.TestCase):
    def test_inventory_and_modes_are_explicit_and_classified(self) -> None:
        expected_callers = set(EXPECTED_SHELL_MODES) | {PYTHON_CALLER}
        self.assertEqual(_discover_real_callers(), expected_callers)

        for relative_path, expected_modes in EXPECTED_SHELL_MODES.items():
            with self.subTest(caller=relative_path):
                self.assertEqual(
                    _shell_wrapper_modes(_source(relative_path)),
                    expected_modes,
                )

        python_source = _source(PYTHON_CALLER)
        self.assertIn(
            'str(NEW_SERVER_PG_WRAPPER),\n            "--write-approved",',
            python_source,
        )

    def test_write_capable_callers_require_both_canonical_approvals(self) -> None:
        for relative_path, modes in EXPECTED_SHELL_MODES.items():
            if "--write-approved" not in modes:
                continue
            source = _source(relative_path)
            with self.subTest(caller=relative_path):
                self.assertTrue(
                    "require_live_mutation_approval" in source
                    or "manaloom_has_live_mutation_approval" in source
                )
                self.assertTrue(
                    "require_postgres_write_approval" in source
                    or "manaloom_has_postgres_write_approval" in source
                )

        python_source = _source(PYTHON_CALLER)
        self.assertIn("_require_pg_runner_approvals()", python_source)
        self.assertIn("MANALOOM_CONFIRM_LIVE_MUTATIONS", python_source)
        self.assertIn("MANALOOM_CONFIRM_POSTGRES_WRITES", python_source)


if __name__ == "__main__":
    unittest.main()
