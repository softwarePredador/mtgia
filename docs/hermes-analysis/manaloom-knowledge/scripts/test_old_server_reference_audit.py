#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import old_server_reference_audit as audit


class OldServerReferenceAuditTests(unittest.TestCase):
    def test_current_active_surface_passes(self) -> None:
        report = audit.build_report()

        self.assertEqual(report["status"], "pass", report["violations"])
        self.assertGreater(report["active_runtime_files_scanned"], 0)
        check_names = {check["name"] for check in report["checks"]}
        self.assertIn(
            "active_runtime_files_have_no_old_server_references",
            check_names,
        )
        self.assertIn(
            "docs.new_server_postgres_workflow_quarantines_old_target",
            check_names,
        )

    def test_old_public_host_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "active.md"
            path.write_text(
                "curl https://evolution-cartinhas.8ktevp.easypanel.host/health\n",
                encoding="utf-8",
            )

            violations = audit.scan_file(path)

        self.assertEqual(len(violations), 2)
        self.assertEqual(violations[0].kind, "old_server_token")

    def test_old_credentials_env_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "active.sh"
            path.write_text("source .credentials.env\n", encoding="utf-8")

            violations = audit.scan_file(path)

        self.assertEqual(len(violations), 1)
        self.assertEqual(violations[0].match, ".credentials.env")

    def test_old_postgres_port_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "active.py"
            path.write_text('env = {"DB_PORT": "5433"}\n', encoding="utf-8")

            violations = audit.scan_file(path)

        self.assertEqual(len(violations), 1)
        self.assertEqual(violations[0].kind, "old_postgres_port")


if __name__ == "__main__":
    unittest.main()
