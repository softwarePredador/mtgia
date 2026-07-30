#!/usr/bin/env python3
from __future__ import annotations

import copy
import tempfile
import unittest
from pathlib import Path

import xmage_governed_patch_audit as audit


class XmageGovernedPatchAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.contract = audit.load_json(audit.DEFAULT_CONTRACT)
        evidence_path = audit.safe_repo_path(
            audit.REPO_ROOT,
            self.contract["active_patch"]["evidence_path"],
        )
        assert evidence_path is not None
        self.evidence = audit.load_json(evidence_path)
        self.digest = audit.file_sha256(evidence_path)

    def report(
        self,
        *,
        contract: dict | None = None,
        evidence: dict | None = None,
        digest: str | None = None,
        require_deployable: bool = False,
    ) -> dict:
        return audit.build_report(
            contract or self.contract,
            evidence or self.evidence,
            evidence_sha256=digest or self.digest,
            require_deployable=require_deployable,
        )

    def test_current_patch_is_deployable(self) -> None:
        report = self.report(require_deployable=True)

        self.assertEqual(report["status"], "pass", report["failures"])
        self.assertTrue(report["deployment_allowed"])
        self.assertEqual(report["patch"]["changed_path_count"], 14)
        self.assertEqual(report["patch"]["focused_test_count"], 6)
        self.assertIn(
            "runtime_identity_surfaces",
            {row["id"] for row in report["checks"]},
        )
        self.assertIn(
            "versioned_patch_delta",
            {row["id"] for row in report["checks"]},
        )

    def test_versioned_patch_reproduces_name_status_and_path_digests(
        self,
    ) -> None:
        patch_path = audit.safe_repo_path(
            audit.REPO_ROOT,
            self.evidence["versioned_patch"]["path"],
        )
        assert patch_path is not None
        entries = audit.versioned_patch_name_status(patch_path)

        self.assertEqual(len(entries), 14)
        self.assertEqual(
            audit.canonical_name_status_sha256(entries),
            self.evidence["exact_delta"]["name_status_sha256"],
        )
        self.assertEqual(
            audit.canonical_sorted_paths_sha256(entries),
            self.evidence["exact_delta"]["sorted_paths_sha256"],
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            tampered = Path(temp_dir) / "tampered.patch"
            tampered.write_text(
                patch_path.read_text(encoding="utf-8").replace(
                    "LoreholdTheHistorian.java",
                    "UnreviewedCard.java",
                ),
                encoding="utf-8",
            )
            tampered_entries = audit.versioned_patch_name_status(tampered)
            self.assertNotEqual(
                audit.canonical_name_status_sha256(tampered_entries),
                self.evidence["exact_delta"]["name_status_sha256"],
            )
            self.assertNotEqual(
                audit.canonical_sorted_paths_sha256(tampered_entries),
                self.evidence["exact_delta"]["sorted_paths_sha256"],
            )

    def test_evidence_digest_mismatch_fails_closed(self) -> None:
        report = self.report(digest="0" * 64, require_deployable=True)

        self.assertIn(
            "evidence_digest",
            {row["id"] for row in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_parent_mismatch_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["source"]["patch_parent"] = "0" * 40

        report = self.report(evidence=evidence, require_deployable=True)

        self.assertIn(
            "fetchable_governed_commit",
            {row["id"] for row in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_changed_path_substitution_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["exact_delta"]["changed_paths"][-1] = "Mage/Unreviewed.java"

        report = self.report(evidence=evidence, require_deployable=True)

        self.assertIn(
            "complete_git_delta",
            {row["id"] for row in report["failures"]},
        )

    def test_declared_name_status_digest_substitution_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["exact_delta"]["name_status_sha256"] = "0" * 64

        report = self.report(evidence=evidence, require_deployable=True)

        failure_ids = {row["id"] for row in report["failures"]}
        self.assertIn("complete_git_delta", failure_ids)
        self.assertIn("versioned_patch_delta", failure_ids)
        self.assertFalse(report["deployment_allowed"])

    def test_skipped_focused_test_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["focused_verification"]["skipped"] = 1

        report = self.report(evidence=evidence, require_deployable=True)

        self.assertIn(
            "focused_runtime_tests",
            {row["id"] for row in report["failures"]},
        )

    def test_postgresql_write_claim_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["postgresql_product_scope"]["writes_performed"] = True

        report = self.report(evidence=evidence, require_deployable=True)

        self.assertIn(
            "postgresql_read_only_scope",
            {row["id"] for row in report["failures"]},
        )

    def test_catalog_resolution_cannot_replace_focused_tests(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["runtime_policy"]["catalog_resolution_is_semantic_proof"] = True

        report = self.report(evidence=evidence, require_deployable=True)

        self.assertIn(
            "runtime_policy",
            {row["id"] for row in report["failures"]},
        )


if __name__ == "__main__":
    unittest.main()
