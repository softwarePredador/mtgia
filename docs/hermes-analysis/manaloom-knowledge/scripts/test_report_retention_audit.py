#!/usr/bin/env python3
from __future__ import annotations

import unittest

import report_retention_audit as audit


class ReportRetentionAuditTests(unittest.TestCase):
    def test_current_repo_report_retention_passes(self) -> None:
        report = audit.build_report(fail_on_ignored_local=True)

        self.assertEqual(report["status"], "pass", report["summary"])
        self.assertEqual(report["summary"]["unreferenced_tracked_raw_count"], 0)
        self.assertEqual(report["summary"]["ignored_local_count"], 0)

    def test_raw_report_suffixes_cover_heavy_artifact_types(self) -> None:
        self.assertIn(".json", audit.RAW_REPORT_SUFFIXES)
        self.assertIn(".jsonl", audit.RAW_REPORT_SUFFIXES)
        self.assertIn(".db", audit.RAW_REPORT_SUFFIXES)
        self.assertIn(".log", audit.RAW_REPORT_SUFFIXES)

    def test_current_project_revalidation_evidence_is_an_active_reference(self) -> None:
        evidence = audit.DOCS_DIR / "PROJECT_REVALIDATION_AND_GLOBAL_QUEUE_2026-07-14.md"

        self.assertIn(evidence, audit.CURRENT_CONTRACT_FILES)
        self.assertTrue(evidence.exists())


if __name__ == "__main__":
    unittest.main()
