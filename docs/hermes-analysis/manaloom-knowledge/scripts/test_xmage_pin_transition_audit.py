#!/usr/bin/env python3
from __future__ import annotations

import copy
import unittest

import xmage_pin_transition_audit as audit


class XMagePinTransitionAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.contract = audit.load_json(audit.DEFAULT_CONTRACT)
        evidence_path = audit._safe_repo_path(
            audit.REPO_ROOT,
            self.contract["active_transition"]["evidence_path"],
        )
        assert evidence_path is not None
        self.evidence = audit.load_json(evidence_path)
        self.digest = audit.file_sha256(evidence_path)

    def _report(
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

    def test_current_transition_classifies_every_changed_card(self) -> None:
        report = self._report()

        self.assertEqual(report["status"], "pass", report["failures"])
        self.assertEqual(report["card_summary"]["row_count"], 169)
        self.assertEqual(report["qualification_status"], "review_required")
        self.assertFalse(report["deployment_allowed"])
        self.assertEqual(
            report["card_summary"]["dispositions"],
            {
                "catalog_supported_nominal_test_passed_semantic_review_required": 3,
                "catalog_supported_regression_only_review_required": 78,
                "catalog_supported_semantic_review_required": 84,
                "external_runtime_quarantine_semantic_defect": 1,
                "external_residual_upstream_unfinished": 1,
                "focused_upstream_test_passed": 1,
                "focused_upstream_test_passed_card_data_warning_review_required": 1,
            },
        )
        self.assertEqual(report["card_summary"]["review_required_count"], 168)

    def test_strict_deployment_gate_fails_while_reviews_are_pending(self) -> None:
        report = self._report(require_deployable=True)

        self.assertEqual(report["status"], "fail")
        self.assertFalse(report["deployment_allowed"])
        self.assertIn(
            "deployment_qualification",
            {row["id"] for row in report["failures"]},
        )

    def test_missing_card_row_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["cards"].pop()

        report = self._report(evidence=evidence)

        failure_ids = {row["id"] for row in report["failures"]}
        self.assertIn("card_rows_complete", failure_ids)
        self.assertIn("card_summary_matches_rows", failure_ids)

    def test_missing_input_artifact_digest_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["input_artifact_digests"].pop(
            "all_169_test_scenario_miner_v2_sha256"
        )

        report = self._report(evidence=evidence)

        self.assertIn(
            "input_artifact_digests",
            {failure["id"] for failure in report["failures"]},
        )

    def test_catalog_supported_card_cannot_claim_focused_test_without_evidence(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["disposition"]
            == "catalog_supported_semantic_review_required"
        )
        row["disposition"] = "focused_upstream_test_passed"

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_disposition_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_empty_postgresql_pass_claim_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["postgresql_scope_reconciliation"] = {"status": "pass"}

        report = self._report(evidence=evidence)

        self.assertIn(
            "postgresql_reconciliation_evidence",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_planetarium_quarantine_cannot_be_removed_by_catalog_resolution(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Planetarium of Wan Shi Tong"
        )
        row["runtime_catalog_status"] = "supported"

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("card_disposition_evidence", failure_ids)
        self.assertIn("runtime_catalog_counts", failure_ids)

    def test_release_scope_must_match_declared_set_dates(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        future_card = next(
            card
            for card in evidence["cards"]
            if card["release_scope_as_of_2026_07_28"] == "future_only"
        )
        future_card["release_scope_as_of_2026_07_28"] = (
            "has_current_or_prior_registration"
        )

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_release_scope_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_future_gate_cannot_claim_pass_without_versioned_proof(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["future_release_activation_gate"] = {"status": "pass"}

        report = self._report(evidence=evidence)

        self.assertIn(
            "future_release_activation_gate",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_required_blocking_reasons_are_fail_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["qualification"]["blocking_reasons"] = []

        report = self._report(evidence=evidence)

        self.assertIn(
            "qualification_consistency",
            {failure["id"] for failure in report["failures"]},
        )

    def test_evidence_digest_mismatch_fails_closed(self) -> None:
        report = self._report(digest="0" * 64)

        self.assertIn(
            "evidence_digest",
            {row["id"] for row in report["failures"]},
        )


if __name__ == "__main__":
    unittest.main()
