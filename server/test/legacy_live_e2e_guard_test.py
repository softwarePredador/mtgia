from __future__ import annotations

import ast
import importlib
import os
import unittest
from pathlib import Path
from unittest import mock

from server.test.legacy_live_e2e_guard import (
    APPROVAL_ENV,
    APPROVAL_TOKEN,
    BLOCKED_PRODUCTION_HOSTS,
    require_legacy_live_e2e_approval,
)


class LegacyLiveE2EGuardTest(unittest.TestCase):
    def test_rejects_missing_approval_before_any_request(self) -> None:
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(SystemExit, "writes test data"):
                require_legacy_live_e2e_approval("https://example.test")

    def test_rejects_missing_or_invalid_explicit_url(self) -> None:
        with mock.patch.dict(
            os.environ,
            {APPROVAL_ENV: APPROVAL_TOKEN},
            clear=True,
        ):
            for value in ("", "localhost:8080", "file:///tmp/api"):
                with self.subTest(value=value):
                    with self.assertRaisesRegex(SystemExit, "explicit http"):
                        require_legacy_live_e2e_approval(value)

    def test_accepts_explicit_url_with_exact_textual_approval(self) -> None:
        with mock.patch.dict(
            os.environ,
            {APPROVAL_ENV: APPROVAL_TOKEN},
            clear=True,
        ):
            self.assertEqual(
                require_legacy_live_e2e_approval("http://127.0.0.1:8080/"),
                "http://127.0.0.1:8080",
            )

    def test_rejects_known_production_even_with_textual_approval(self) -> None:
        with mock.patch.dict(
            os.environ,
            {APPROVAL_ENV: APPROVAL_TOKEN},
            clear=True,
        ):
            for production_host in sorted(BLOCKED_PRODUCTION_HOSTS):
                with self.subTest(production_host=production_host):
                    with self.assertRaisesRegex(
                        SystemExit,
                        "production API target is blocked",
                    ):
                        require_legacy_live_e2e_approval(
                            f"https://{production_host}"
                        )
            with self.assertRaisesRegex(SystemExit, "production API target is blocked"):
                require_legacy_live_e2e_approval(
                    "https://EVOLUTION-CARTINHAS.2TA7QX.EASYPANEL.HOST."
                )

    def test_uses_shared_live_mutation_approval_contract(self) -> None:
        self.assertEqual(APPROVAL_ENV, "MANALOOM_CONFIRM_LIVE_MUTATIONS")
        self.assertEqual(APPROVAL_TOKEN, "I_HAVE_EXPLICIT_APPROVAL")
        shared_guard = (
            Path(__file__).resolve().parents[2]
            / "scripts/lib/manaloom_mutation_guard.sh"
        ).read_text(encoding="utf-8")
        self.assertIn(
            'MANALOOM_EXPLICIT_APPROVAL_PHRASE="I_HAVE_EXPLICIT_APPROVAL"',
            shared_guard,
        )
        self.assertIn("MANALOOM_CONFIRM_LIVE_MUTATIONS", shared_guard)

    def test_retained_legacy_suites_guard_before_runner_construction(self) -> None:
        test_dir = Path(__file__).resolve().parent
        for filename, runner_name in (
            ("e2e_general_tests.py", "TestRunner"),
            ("e2e_trade_tests.py", "TestRunner"),
            ("e2e_ml_tests.py", "MLTestSuite"),
        ):
            with self.subTest(filename=filename):
                tree = ast.parse((test_dir / filename).read_text(encoding="utf-8"))
                main_function = next(
                    (
                        node
                        for node in tree.body
                        if isinstance(node, ast.FunctionDef) and node.name == "main"
                    ),
                    None,
                )
                if main_function is not None:
                    main_body = main_function.body
                else:
                    main_guard = next(
                        node
                        for node in tree.body
                        if isinstance(node, ast.If)
                        and "__main__" in ast.unparse(node.test)
                    )
                    main_body = main_guard.body
                calls = [
                    node.func.id
                    for statement in main_body
                    for node in ast.walk(statement)
                    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                ]
                self.assertLess(
                    calls.index("require_legacy_live_e2e_approval"),
                    calls.index(runner_name),
                )

    def test_retained_legacy_suites_import_as_package_modules(self) -> None:
        for module_name in (
            "server.test.e2e_general_tests",
            "server.test.e2e_trade_tests",
            "server.test.e2e_ml_tests",
        ):
            with self.subTest(module_name=module_name):
                self.assertIsNotNone(importlib.import_module(module_name))


if __name__ == "__main__":
    unittest.main()
