#!/usr/bin/env python3
from __future__ import annotations

import copy
import unittest

import xmage_transition_activation_policy as policy


class XMageTransitionActivationPolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        cards = []
        results = []
        for index in range(169):
            if index < 45:
                scope_status = "future_deferred"
                release_scope = "future_only"
                release_date = "2026-10-02"
            elif index < 133:
                scope_status = "released_missing_from_postgresql"
                release_scope = "has_current_or_prior_registration"
                release_date = "2026-06-26"
            else:
                scope_status = "product_in_scope"
                release_scope = "has_current_or_prior_registration"
                release_date = "2025-01-01"
            name = f"Card {index:03d}"
            cards.append(
                {
                    "card_name": name,
                    "class": f"Card{index:03d}",
                    "source_path": f"Mage.Sets/src/mage/cards/c/Card{index:03d}.java",
                    "disposition": (
                        "catalog_supported_semantic_review_required"
                    ),
                    "runtime_catalog_status": "supported",
                    "release_scope_as_of_2026_07_28": release_scope,
                    "set_registrations": [{"release_date": release_date}],
                }
            )
            results.append(
                {
                    "card_name": name,
                    "product_scope_status": scope_status,
                }
            )
        self.evidence = {
            "transition_id": "transition",
            "from_pin": "d" * 40,
            "to_pin": "a" * 40,
            "cards": cards,
            "card_summary": {},
        }
        self.postgres = {
            "schema_version": policy.POSTGRES_SCHEMA_VERSION,
            "generated_at_utc": "2026-07-30T00:00:00+00:00",
            "status": "pass",
            "transaction_read_only": True,
            "writes_performed": False,
            "ambiguity_count": 0,
            "reconciled_card_count": 169,
            "rows_sha256": "b" * 64,
            "card_results": results,
        }

    def _build(self, *, evidence=None, postgres=None):
        return policy.build_policy(
            evidence or self.evidence,
            postgres or self.postgres,
            postgres_artifact_sha256="c" * 64,
        )

    def test_builds_exact_fail_closed_activation_scope(self) -> None:
        report = self._build()

        self.assertEqual(report["blocked_card_count"], 133)
        self.assertEqual(report["from_engine_commit"], "d" * 40)
        self.assertEqual(report["transition_card_count"], 169)
        self.assertEqual(len(report["transition_card_names"]), 169)
        self.assertEqual(report["future_deferred_count"], 45)
        self.assertEqual(report["released_missing_count"], 88)
        self.assertFalse(report["policy"]["catalog_absence_is_semantic_proof"])
        self.assertTrue(
            report["policy"]["activation_requires_new_versioned_review"]
        )
        self.assertEqual(
            {row["reason_code"] for row in report["cards"]},
            {"battle_card_activation_review_required"},
        )

    def test_product_in_scope_cards_are_not_deferred(self) -> None:
        report = self._build()

        blocked = {row["card_name"] for row in report["cards"]}
        self.assertNotIn("Card 168", blocked)

    def test_missing_identity_fails_closed(self) -> None:
        postgres = copy.deepcopy(self.postgres)
        postgres["card_results"].pop()
        postgres["reconciled_card_count"] = 168

        with self.assertRaisesRegex(ValueError, "identities"):
            self._build(postgres=postgres)

    def test_write_capable_postgres_claim_fails_closed(self) -> None:
        postgres = copy.deepcopy(self.postgres)
        postgres["writes_performed"] = True

        with self.assertRaisesRegex(ValueError, "read-only"):
            self._build(postgres=postgres)

    def test_scope_count_drift_fails_closed(self) -> None:
        postgres = copy.deepcopy(self.postgres)
        postgres["card_results"][0]["product_scope_status"] = "product_in_scope"

        with self.assertRaisesRegex(ValueError, "45 future"):
            self._build(postgres=postgres)

    def test_transition_pin_drift_fails_closed(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["from_pin"] = "not-a-git-pin"

        with self.assertRaisesRegex(ValueError, "exact engine pins"):
            self._build(evidence=evidence)

    def test_postgresql_digest_drift_fails_closed(self) -> None:
        postgres = copy.deepcopy(self.postgres)
        postgres["rows_sha256"] = "not-a-sha256"

        with self.assertRaisesRegex(ValueError, "read-only pass"):
            self._build(postgres=postgres)

    def test_applies_exact_activation_disposition_idempotently(
        self,
    ) -> None:
        report = self._build()
        transformed = policy.apply_activation_dispositions(
            self.evidence,
            self.postgres,
            report,
        )
        blocked = [
            row
            for row in transformed["cards"]
            if row["disposition"]
            == policy.ACTIVATION_BLOCKED_DISPOSITION
        ]

        self.assertEqual(len(blocked), 133)
        self.assertTrue(
            all(
                row["underlying_transition_disposition"]
                == "catalog_supported_semantic_review_required"
                for row in blocked
            )
        )
        self.assertTrue(
            all(
                row["catalog_status_before_activation"] == "supported"
                and row["runtime_catalog_status"] == "unsupported"
                for row in blocked
            )
        )
        self.assertEqual(
            transformed["card_summary"]["runtime_catalog_statuses"],
            {"supported": 36, "unsupported": 133},
        )
        self.assertEqual(
            policy.apply_activation_dispositions(
                transformed,
                self.postgres,
                report,
            ),
            transformed,
        )

    def test_activation_disposition_cannot_escape_policy_identity(
        self,
    ) -> None:
        report = self._build()
        evidence = copy.deepcopy(self.evidence)
        evidence["cards"][-1]["disposition"] = (
            policy.ACTIVATION_BLOCKED_DISPOSITION
        )
        evidence["cards"][-1]["underlying_transition_disposition"] = (
            "catalog_supported_semantic_review_required"
        )
        evidence["cards"][-1]["catalog_status_before_activation"] = (
            "supported"
        )

        with self.assertRaisesRegex(
            ValueError, "non-blocked card cannot use"
        ):
            policy.apply_activation_dispositions(
                evidence,
                self.postgres,
                report,
            )


if __name__ == "__main__":
    unittest.main()
