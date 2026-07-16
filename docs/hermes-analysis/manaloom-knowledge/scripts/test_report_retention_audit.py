#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

import report_retention_audit as audit


class ReportRetentionAuditTests(unittest.TestCase):
    def test_current_repo_report_retention_passes(self) -> None:
        report = audit.build_report(fail_on_ignored_local=True)

        self.assertEqual(report["status"], "pass", report["summary"])
        self.assertEqual(report["summary"]["ungoverned_tracked_raw_count"], 0)
        self.assertEqual(report["summary"]["ignored_local_count"], 0)
        self.assertGreater(report["summary"]["manifest_only_tracked_raw_count"], 0)
        self.assertTrue(report["retention_manifest"]["justification"])

    def test_manifest_is_not_counted_as_an_active_reference_surface(self) -> None:
        self.assertNotIn(audit.RETENTION_MANIFEST_FILE, audit.active_reference_files())

        report = audit.build_report(fail_on_ignored_local=False)

        self.assertLess(
            report["summary"]["active_consumer_tracked_raw_count"],
            report["summary"]["tracked_raw_count"],
        )

    def test_raw_without_consumer_or_manifest_is_ungoverned(self) -> None:
        active = audit.REPORT_DIR / "active.json"
        retained = audit.REPORT_DIR / "retained.sql"
        orphan = audit.REPORT_DIR / "orphan.log"

        classified = audit.classify_paths(
            [active, retained, orphan],
            active_tokens={active.name},
            manifest_paths={audit.rel(retained)},
            manifest_has_justification=True,
        )

        self.assertEqual(classified["active_consumer"], [active])
        self.assertEqual(classified["manifest_only"], [retained])
        self.assertEqual(classified["ungoverned"], [orphan])

    def test_artifact_metadata_exposes_size_and_age(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            path = Path(temporary_directory) / "artifact.json"
            path.write_text("{}\n", encoding="utf-8")

            metadata = audit.artifact_metadata(
                path,
                classification="manifest_only",
                justification="test evidence",
                now=datetime.now(timezone.utc),
            )

        self.assertEqual(metadata["size_bytes"], 3)
        self.assertIsNotNone(metadata["age_days"])
        self.assertEqual(metadata["classification"], "manifest_only")

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
