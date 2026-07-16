#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import patch

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

    def test_complete_manifested_local_sql_quartet_is_governed(self) -> None:
        prefix = audit.REPORT_DIR / "pg999_example_20260716"
        paths = [
            Path(f"{prefix}_{role}.sql")
            for role in sorted(audit.SQL_PACKAGE_ROLES)
        ]

        classified = audit.classify_local_report_files(
            paths,
            manifest_paths={audit.rel(path) for path in paths},
        )

        self.assertEqual(classified["pending_manifest"], sorted(paths))
        self.assertEqual(classified["ignored"], [])

    def test_incomplete_manifested_local_sql_package_still_fails(self) -> None:
        paths = [
            audit.REPORT_DIR / "pg999_example_20260716_precheck.sql",
            audit.REPORT_DIR / "pg999_example_20260716_apply.sql",
        ]

        classified = audit.classify_local_report_files(
            paths,
            manifest_paths={audit.rel(path) for path in paths},
        )

        self.assertEqual(classified["pending_manifest"], [])
        self.assertEqual(classified["ignored"], sorted(paths))

    def test_unmanifested_sql_quartet_and_manifested_json_still_fail(self) -> None:
        prefix = audit.REPORT_DIR / "pg999_unmanifested_20260716"
        sql_paths = [
            Path(f"{prefix}_{role}.sql")
            for role in sorted(audit.SQL_PACKAGE_ROLES)
        ]
        generated_json = audit.REPORT_DIR / "generated_local.json"
        paths = [*sql_paths, generated_json]

        classified = audit.classify_local_report_files(
            paths,
            manifest_paths={audit.rel(generated_json)},
        )

        self.assertEqual(classified["pending_manifest"], [])
        self.assertEqual(classified["ignored"], sorted(paths))

    def test_manifested_json_requires_matching_sha256_seal(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            path = Path(temporary_directory) / "reviewed.json"
            path.write_text('{"status":"pass"}\n', encoding="utf-8")
            relative_path = audit.rel(path)
            digest = hashlib.sha256(path.read_bytes()).hexdigest()

            classified = audit.classify_local_report_files(
                [path],
                manifest_paths={relative_path},
                pending_hashes={relative_path: digest},
            )
            self.assertEqual(classified["pending_manifest"], [path])
            self.assertEqual(classified["ignored"], [])

            path.write_text('{"status":"changed"}\n', encoding="utf-8")
            tampered = audit.classify_local_report_files(
                [path],
                manifest_paths={relative_path},
                pending_hashes={relative_path: digest},
            )
            self.assertEqual(tampered["pending_manifest"], [])
            self.assertEqual(tampered["ignored"], [path])

    def test_manifested_markdown_without_seal_still_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            path = Path(temporary_directory) / "arbitrary.md"
            path.write_text("# Generated output\n", encoding="utf-8")

            classified = audit.classify_local_report_files(
                [path],
                manifest_paths={audit.rel(path)},
            )

        self.assertEqual(classified["pending_manifest"], [])
        self.assertEqual(classified["ignored"], [path])

    def test_manifest_pending_hash_parser_is_explicit(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            manifest = Path(temporary_directory) / "README.md"
            digest = "a" * 64
            path = "docs/hermes-analysis/master_optimizer_reports/reviewed.json"
            manifest.write_text(
                f"- `{path}` — pending-local-sha256: `{digest}`\n"
                f"- `docs/hermes-analysis/master_optimizer_reports/arbitrary.json`\n",
                encoding="utf-8",
            )
            with patch.object(audit, "RETENTION_MANIFEST_FILE", manifest):
                hashes = audit.retention_manifest_pending_hashes()

        self.assertEqual(hashes, {path: digest})

    def test_missing_tracked_report_file_is_not_counted_as_retained(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            existing = directory / "existing.sql"
            missing = directory / "missing.sql"
            existing.write_text("SELECT 1;\n", encoding="utf-8")

            with patch.object(audit, "git_ls_files", return_value=[existing, missing]):
                tracked = audit.tracked_report_raw_files()

        self.assertEqual(tracked, [existing])

    def test_current_project_revalidation_evidence_is_an_active_reference(self) -> None:
        evidence = audit.DOCS_DIR / "PROJECT_REVALIDATION_AND_GLOBAL_QUEUE_2026-07-14.md"

        self.assertIn(evidence, audit.CURRENT_CONTRACT_FILES)
        self.assertTrue(evidence.exists())


if __name__ == "__main__":
    unittest.main()
