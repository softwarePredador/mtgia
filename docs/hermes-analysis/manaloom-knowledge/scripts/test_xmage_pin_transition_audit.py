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

    def _review_artifact_shape_inputs(
        self,
    ) -> tuple[dict, dict, dict]:
        links = self.evidence["transition_review_derivatives"]
        matrix_path = audit._safe_repo_path(
            audit.REPO_ROOT,
            links["active_scope_semantic_matrix"]["artifact_path"],
        )
        index_path = audit._safe_repo_path(
            audit.REPO_ROOT,
            links["transition_compact_review_index"]["artifact_path"],
        )
        postgres_pointer = self.evidence["postgresql_scope_reconciliation"]
        postgres_path = audit._safe_repo_path(
            audit.REPO_ROOT,
            postgres_pointer["artifact_path"],
        )
        assert matrix_path is not None
        assert index_path is not None
        assert postgres_path is not None
        transition = self.contract["active_transition"]
        arguments = {
            "evidence_cards": self.evidence["cards"],
            "postgres": audit.load_json(postgres_path),
            "qualification": self.evidence["qualification"],
            "primary_evidence_path": transition["evidence_path"],
            "source_primary_snapshot_sha256": links[
                "source_primary_snapshot_sha256"
            ],
            "focused_artifact_path": self.evidence[
                "product_scope_focused_test_evidence"
            ]["artifact_path"],
            "focused_artifact_sha256": self.evidence[
                "product_scope_focused_test_evidence"
            ]["artifact_sha256"],
            "from_pin": transition["from_pin"],
            "to_pin": transition["to_pin"],
        }
        return (
            audit.load_json(matrix_path),
            audit.load_json(index_path),
            arguments,
        )

    def test_current_transition_classifies_every_changed_card(self) -> None:
        report = self._report()

        self.assertEqual(report["status"], "pass", report["failures"])
        self.assertEqual(report["card_summary"]["row_count"], 169)
        self.assertEqual(report["qualification_status"], "pass")
        self.assertTrue(report["deployment_allowed"])
        self.assertEqual(
            report["card_summary"]["dispositions"],
            {
                "activation_blocked_pending_product_semantic_review": 133,
                "exact_non_executable_tokens_passed": 5,
                "external_runtime_quarantine_semantic_defect": 1,
                "external_runtime_quarantine_known_upstream_gap": 1,
                "product_scope_focused_semantic_tests_passed": 29,
            },
        )
        self.assertEqual(report["card_summary"]["review_required_count"], 0)
        self.assertEqual(self.evidence["runtime_catalog"]["supported"], 34)
        self.assertEqual(
            self.evidence["runtime_catalog"]["unsupported"], 135
        )

    def test_mandate_is_quarantined_without_becoming_global_blocker(
        self,
    ) -> None:
        report = self._report()
        mandate = next(
            card
            for card in self.evidence["cards"]
            if card["card_name"] == "Mandate of Peace"
        )

        self.assertEqual(
            mandate["disposition"],
            "external_runtime_quarantine_known_upstream_gap",
        )
        self.assertEqual(
            mandate["external_residual"]["upstream_issue"],
            "magefree/mage#12911",
        )
        self.assertEqual(mandate["runtime_catalog_status"], "unsupported")
        self.assertNotIn(
            mandate["disposition"], audit.REVIEW_DISPOSITIONS
        )
        self.assertEqual(report["card_summary"]["review_required_count"], 0)

    def test_activation_blocked_rows_preserve_review_provenance(self) -> None:
        blocked = [
            card
            for card in self.evidence["cards"]
            if card["disposition"] == audit.ACTIVATION_BLOCKED_DISPOSITION
        ]

        self.assertEqual(len(blocked), 133)
        self.assertTrue(
            all(
                card["underlying_transition_disposition"]
                and card["catalog_status_before_activation"]
                in {"supported", "unsupported"}
                and card["runtime_catalog_status"] == "unsupported"
                for card in blocked
            )
        )

    def test_prudent_activation_block_preserves_external_residual(self) -> None:
        report = self._report()
        prudent = next(
            card
            for card in self.evidence["cards"]
            if card["card_name"] == "Prudent Fateseer"
        )

        self.assertEqual(
            prudent["disposition"], audit.ACTIVATION_BLOCKED_DISPOSITION
        )
        self.assertEqual(
            prudent["underlying_transition_disposition"],
            "external_residual_upstream_unfinished",
        )
        self.assertEqual(
            prudent["external_residual"]["reason"],
            "removed_from_xmage_catalog_as_unfinished",
        )
        self.assertNotIn(
            prudent["disposition"], audit.REVIEW_DISPOSITIONS
        )
        self.assertEqual(report["card_summary"]["review_required_count"], 0)

    def test_prudent_residual_cannot_be_silently_removed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        prudent = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Prudent Fateseer"
        )
        prudent.pop("external_residual")

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_disposition_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_mandate_quarantine_cannot_be_silently_removed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        mandate = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Mandate of Peace"
        )
        mandate["disposition"] = (
            "catalog_supported_regression_only_review_required"
        )
        mandate["runtime_catalog_status"] = "supported"
        mandate.pop("external_residual")

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_disposition_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_non_blocking_quarantines_cannot_be_swapped(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        planetarium = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Planetarium of Wan Shi Tong"
        )
        mandate = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Mandate of Peace"
        )
        (
            planetarium["disposition"],
            mandate["disposition"],
        ) = (
            mandate["disposition"],
            planetarium["disposition"],
        )

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_disposition_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_swordsman_is_executable_and_never_exactly_cleared(self) -> None:
        executable = set(
            self.evidence["modified_change_scope"][
                "executable_or_mixed_classes"
            ]
        )
        policy_path = audit._safe_repo_path(
            audit.REPO_ROOT,
            self.contract["active_transition"][
                "nominal_review_policy_path"
            ],
        )
        assert policy_path is not None
        policy = audit.load_json(policy_path)
        clearance_names = {
            row["card_name"]
            for row in policy["automatic_transition_clearance_rules"]
        }

        self.assertIn("SwordsmanSharpScoundrel", executable)
        self.assertNotIn("Swordsman, Sharp Scoundrel", clearance_names)
        self.assertEqual(len(clearance_names), 11)

    def test_swordsman_reclassification_cannot_be_reverted(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        scope = evidence["modified_change_scope"]
        scope["executable_or_mixed_classes"].remove(
            "SwordsmanSharpScoundrel"
        )
        scope["counts"] = {
            "comment_only": 2,
            "executable_or_mixed": 27,
            "presentation_or_metadata": 53,
            "total_modified": 82,
        }
        scope["presentation_or_metadata_count"] = 53

        report = self._report(evidence=evidence)

        self.assertIn(
            "modified_change_scope",
            {failure["id"] for failure in report["failures"]},
        )

    def test_strict_deployment_gate_passes_after_product_scope_clearance(
        self,
    ) -> None:
        report = self._report(require_deployable=True)

        self.assertEqual(report["status"], "pass", report["failures"])
        self.assertTrue(report["deployment_allowed"])
        self.assertNotIn(
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

    def test_nominal_review_artifact_digest_mismatch_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["input_artifact_digests"][
            "transition_nominal_review_v2_sha256"
        ] = "0" * 64

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("transition_nominal_review_evidence", failure_ids)
        self.assertIn("card_disposition_evidence", failure_ids)

    def test_nominal_policy_digest_mismatch_fails_closed(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["active_transition"][
            "nominal_review_policy_sha256"
        ] = "0" * 64

        report = self._report(contract=contract)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("transition_nominal_review_policy", failure_ids)
        self.assertIn("transition_nominal_review_evidence", failure_ids)
        self.assertIn("card_disposition_evidence", failure_ids)

    def test_clearance_rule_id_cannot_diverge_from_exact_artifact(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Metallic Mimic"
        )
        row["transition_review_rule_id"] = "unversioned_rule"

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_disposition_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_clearance_test_references_cannot_be_substituted(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Metallic Mimic"
        )
        row["direct_test_references"] = ["unversioned/SubstituteTest.java"]

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_disposition_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_catalog_resolution_cannot_claim_exact_clearance(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["disposition"]
            == audit.PRODUCT_FOCUSED_CLEARANCE_DISPOSITION
        )
        row["disposition"] = audit.CLEARANCE_DISPOSITION
        row["direct_test_references"] = ["unversioned/CatalogOnlyTest.java"]
        row["focused_test_case_count"] = 1
        row["source_warning_markers"] = []
        row["transition_review_rule_id"] = (
            "metallic_mimic_presentation_literal_v1"
        )

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_disposition_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_activation_blocked_card_cannot_claim_product_focused_clearance(
        self,
    ) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["disposition"]
            == audit.ACTIVATION_BLOCKED_DISPOSITION
        )
        row["disposition"] = audit.PRODUCT_FOCUSED_CLEARANCE_DISPOSITION
        row["runtime_catalog_status"] = "supported"

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("product_scope_focused_test_evidence", failure_ids)

    def test_empty_postgresql_pass_claim_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["postgresql_scope_reconciliation"] = {"status": "pass"}

        report = self._report(evidence=evidence)

        self.assertIn(
            "postgresql_reconciliation_evidence",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_postgresql_artifact_digest_mismatch_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["postgresql_scope_reconciliation"][
            "artifact_sha256"
        ] = "0" * 64

        report = self._report(evidence=evidence)

        self.assertIn(
            "postgresql_reconciliation_evidence",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_postgresql_artifact_path_escape_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["postgresql_scope_reconciliation"][
            "artifact_path"
        ] = "../outside.json"

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

    def test_activation_policy_digest_mismatch_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["future_release_activation_gate"][
            "resource_sha256"
        ] = "0" * 64

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("future_release_activation_gate", failure_ids)
        self.assertIn("runtime_catalog_proof", failure_ids)
        self.assertFalse(report["deployment_allowed"])

    def test_activation_policy_path_escape_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["future_release_activation_gate"][
            "resource_path"
        ] = "../activation-policy.json"

        report = self._report(evidence=evidence)

        self.assertIn(
            "future_release_activation_gate",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_activation_restricted_counts_are_exact(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["runtime_catalog"]["activation_restricted"] = 132
        evidence["runtime_catalog"]["unsupported"] = 133

        report = self._report(evidence=evidence)

        self.assertIn(
            "runtime_catalog_proof",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_activation_card_cannot_reenter_review_lane_without_release(
        self,
    ) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["disposition"] == audit.ACTIVATION_BLOCKED_DISPOSITION
            and card["underlying_transition_disposition"]
            == "catalog_supported_semantic_review_required"
        )
        row["disposition"] = row.pop("underlying_transition_disposition")
        row["runtime_catalog_status"] = row.pop(
            "catalog_status_before_activation"
        )

        report = self._report(evidence=evidence)
        failure_ids = {failure["id"] for failure in report["failures"]}

        self.assertIn("deployment_blocking_review_count", failure_ids)
        self.assertIn("future_release_activation_gate", failure_ids)
        self.assertFalse(report["deployment_allowed"])

    def test_non_policy_card_cannot_claim_activation_disposition(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["disposition"]
            == audit.PRODUCT_FOCUSED_CLEARANCE_DISPOSITION
        )
        row["underlying_transition_disposition"] = row["disposition"]
        row["catalog_status_before_activation"] = row[
            "runtime_catalog_status"
        ]
        row["disposition"] = audit.ACTIVATION_BLOCKED_DISPOSITION
        row["runtime_catalog_status"] = "unsupported"

        report = self._report(evidence=evidence)
        failure_ids = {failure["id"] for failure in report["failures"]}

        self.assertIn("future_release_activation_gate", failure_ids)
        self.assertFalse(report["deployment_allowed"])

    def test_product_scope_focused_artifact_digest_is_pinned(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["product_scope_focused_test_evidence"][
            "artifact_sha256"
        ] = "0" * 64

        report = self._report(evidence=evidence)

        self.assertIn(
            "product_scope_focused_test_evidence",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_transition_review_artifact_stale_hash_fails_closed(
        self,
    ) -> None:
        for pointer_name in (
            "active_scope_semantic_matrix",
            "transition_compact_review_index",
        ):
            with self.subTest(pointer_name=pointer_name):
                evidence = copy.deepcopy(self.evidence)
                evidence["transition_review_derivatives"][pointer_name][
                    "artifact_sha256"
                ] = "0" * 64

                report = self._report(evidence=evidence)

                self.assertIn(
                    "transition_review_artifacts",
                    {failure["id"] for failure in report["failures"]},
                )
                self.assertFalse(report["deployment_allowed"])

    def test_transition_review_status_and_identity_tamper_fail_closed(
        self,
    ) -> None:
        matrix, index, arguments = self._review_artifact_shape_inputs()
        self.assertTrue(
            audit._transition_review_artifacts_shape_valid(
                matrix,
                index,
                **arguments,
            )
        )

        status_tampered_matrix = copy.deepcopy(matrix)
        status_tampered_matrix["cards"][0]["status"] = "quarantined"
        self.assertFalse(
            audit._transition_review_artifacts_shape_valid(
                status_tampered_matrix,
                index,
                **arguments,
            )
        )

        identity_tampered_index = copy.deepcopy(index)
        identity_tampered_index["cards"][0]["card_name"] = (
            "Tampered transition identity"
        )
        self.assertFalse(
            audit._transition_review_artifacts_shape_valid(
                matrix,
                identity_tampered_index,
                **arguments,
            )
        )

    def test_focused_execution_count_is_distinct_from_patch_count(
        self,
    ) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["product_scope_focused_test_evidence"][
            "execution_report_count"
        ] = 3

        report = self._report(evidence=evidence)

        self.assertIn(
            "product_scope_focused_test_evidence",
            {failure["id"] for failure in report["failures"]},
        )
        self.assertFalse(report["deployment_allowed"])

    def test_product_focused_pass_cannot_hide_partial_obligation(
        self,
    ) -> None:
        focused_pointer = self.evidence[
            "product_scope_focused_test_evidence"
        ]
        focused_path = audit._safe_repo_path(
            audit.REPO_ROOT,
            focused_pointer["artifact_path"],
        )
        postgres_pointer = self.evidence["postgresql_scope_reconciliation"]
        postgres_path = audit._safe_repo_path(
            audit.REPO_ROOT,
            postgres_pointer["artifact_path"],
        )
        assert focused_path is not None
        assert postgres_path is not None
        focused = copy.deepcopy(audit.load_json(focused_path))
        postgres = audit.load_json(postgres_path)
        expected = self.contract["active_transition"]["expected"]
        transition = self.contract["active_transition"]
        shape_arguments = {
            "focused_artifact_path": focused_pointer["artifact_path"],
            "evidence_cards": self.evidence["cards"],
            "postgres": postgres,
            "postgres_artifact_path": postgres_pointer["artifact_path"],
            "postgres_artifact_sha256": audit.file_sha256(postgres_path),
            "repo_root": audit.REPO_ROOT,
            "from_pin": transition["from_pin"],
            "to_pin": transition["to_pin"],
            "expected_test_count": expected[
                "product_scope_focused_test_count"
            ],
            "expected_direct_card_count": expected[
                "product_scope_direct_focused_card_count"
            ],
            "expected_patch_count": expected[
                "product_scope_focused_patch_count"
            ],
            "expected_execution_report_count": expected[
                "product_scope_focused_execution_report_count"
            ],
        }
        self.assertTrue(
            audit._product_scope_focused_test_shape_valid(
                focused,
                **shape_arguments,
            )
        )
        focused_run = next(
            row
            for row in focused["focused_runs"]
            if any(
                obligation.get("coverage_status") == "focused_pass"
                for obligation in row["obligations"]
            )
        )
        passing_obligation = next(
            obligation
            for obligation in focused_run["obligations"]
            if obligation.get("coverage_status") == "focused_pass"
        )
        partial_obligation = copy.deepcopy(passing_obligation)
        partial_obligation["coverage_status"] = "partial_focused_pass"
        focused_run["obligations"].append(partial_obligation)

        valid = audit._product_scope_focused_test_shape_valid(
            focused,
            **shape_arguments,
        )

        self.assertFalse(valid)

    def test_cross_pin_maven_repositories_must_be_isolated(self) -> None:
        self.assertTrue(
            audit._presentation_maven_repositories_are_isolated(
                {"maven_repository": "/tmp/review/m2-from"},
                {"maven_repository": "/tmp/review/m2-to"},
            )
        )
        self.assertFalse(
            audit._presentation_maven_repositories_are_isolated(
                {"maven_repository": "/tmp/review/shared"},
                {"maven_repository": "/tmp/review/shared"},
            )
        )
        self.assertFalse(
            audit._presentation_maven_repositories_are_isolated(
                {"maven_repository": "/tmp/review/m2-to"},
                {"maven_repository": "/tmp/review/m2-from"},
            )
        )

    def test_focused_pass_cannot_become_exact_token_clearance(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Heroes' Hangout"
        )
        row["disposition"] = audit.CLEARANCE_DISPOSITION

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("card_disposition_evidence", failure_ids)

    def test_planetarium_focused_test_remains_quarantine_only(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Planetarium of Wan Shi Tong"
        )
        row["disposition"] = audit.CLEARANCE_DISPOSITION

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("card_disposition_evidence", failure_ids)
        self.assertIn("product_scope_focused_test_evidence", failure_ids)

    def test_mandate_focused_test_remains_quarantine_only(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["card_name"] == "Mandate of Peace"
        )
        row["disposition"] = audit.CLEARANCE_DISPOSITION

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("card_disposition_evidence", failure_ids)
        self.assertIn("product_scope_focused_test_evidence", failure_ids)

    def test_mandate_pointer_cannot_claim_promotion(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["product_scope_focused_test_evidence"][
            "mandate_of_peace_test_is_promotion_evidence"
        ] = True

        report = self._report(evidence=evidence)

        self.assertIn(
            "product_scope_focused_test_evidence",
            {failure["id"] for failure in report["failures"]},
        )

    def test_required_blocking_reasons_are_fail_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        row = next(
            card
            for card in evidence["cards"]
            if card["disposition"]
            == audit.PRODUCT_FOCUSED_CLEARANCE_DISPOSITION
        )
        row["disposition"] = (
            "catalog_supported_regression_only_review_required"
        )

        report = self._report(evidence=evidence)

        failure_ids = {failure["id"] for failure in report["failures"]}
        self.assertIn("qualification_consistency", failure_ids)
        self.assertIn("deployment_blocking_review_count", failure_ids)
        self.assertFalse(report["deployment_allowed"])

    def test_stale_extra_blocking_reason_is_rejected(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["qualification"]["blocking_reasons"].append(
            "stale_quarantine_global_blocker"
        )

        report = self._report(evidence=evidence)

        self.assertIn(
            "qualification_consistency",
            {failure["id"] for failure in report["failures"]},
        )

    def test_activation_blocked_diagnostic_must_match_activation_lane(
        self,
    ) -> None:
        evidence = copy.deepcopy(self.evidence)
        finding = next(
            row
            for row in evidence["card_data_diagnostics"][
                "actionable_findings"
            ]
            if row["status"] == "activation_blocked"
        )
        finding["status"] = "upstream_fix_required"

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_data_diagnostics",
            {failure["id"] for failure in report["failures"]},
        )

    def test_falcon_non_runtime_boundary_is_exact(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        falcon = next(
            row
            for row in evidence["card_data_diagnostics"][
                "actionable_findings"
            ]
            if row["card_name"] == "Falcon's Wing Harness"
        )
        falcon["runtime_boundary"]["upstream_fix_claimed"] = True

        report = self._report(evidence=evidence)

        self.assertIn(
            "card_data_diagnostics",
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
