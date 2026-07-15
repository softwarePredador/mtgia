#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import operational_surface_alignment_audit as audit


class OperationalSurfaceAlignmentAuditTests(unittest.TestCase):
    def test_current_repo_surface_passes(self) -> None:
        report = audit.build_report()

        self.assertEqual(report["status"], "pass", report["checks"])
        self.assertEqual(report["summary"]["status_counts"].get("fail", 0), 0)
        self.assertGreaterEqual(report["inventory"]["script_files"], 300)
        self.assertGreaterEqual(report["inventory"]["top_level_docs"], 100)
        check_names = {check["name"] for check in report["checks"]}
        self.assertIn(
            "docs.failure_mode_matrix_exists_and_covers_old_bug_classes",
            check_names,
        )
        self.assertIn("docs.app_ai_bridge_contract_exists", check_names)
        self.assertIn(
            "scripts.app_ai_bridge_audit_blocks_report_only_knowledge",
            check_names,
        )
        self.assertIn(
            "docs.new_server_workflow_quarantines_old_target",
            check_names,
        )
        self.assertIn(
            "scripts.old_server_reference_audit_blocks_old_operational_targets",
            check_names,
        )
        self.assertIn(
            "scripts.report_retention_audit_blocks_unused_report_data",
            check_names,
        )
        self.assertIn(
            "scripts.pg_hermes_sqlite_contract_wrapper_uses_new_server",
            check_names,
        )
        self.assertIn("docs.global_battle_closure_is_current", check_names)
        self.assertIn("scripts.global_card_coverage_closure_exists", check_names)
        self.assertIn("scripts.source_catalog_reconciliation_exists", check_names)
        self.assertIn(
            "scripts.external_battle_runner_is_resumable_and_non_promoting",
            check_names,
        )

    def test_forbidden_stale_snippet_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            path = Path(tmp_dir) / "README.md"
            path.write_text(
                "Decisao atual para acelerar XMage -> ManaLoom: usar\n"
                "    `hybrid_effective_queue_pattern_registry`",
                encoding="utf-8",
            )

            check = audit.check_absent(
                path,
                [
                    "Decisao atual para acelerar XMage -> ManaLoom: usar\n"
                    "    `hybrid_effective_queue_pattern_registry`"
                ],
                "forbidden_operational_stale_snippets.README.md",
            )

        self.assertEqual(check.status, "fail")


if __name__ == "__main__":
    unittest.main()
