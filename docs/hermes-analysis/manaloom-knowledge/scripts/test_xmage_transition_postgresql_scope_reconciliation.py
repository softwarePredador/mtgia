#!/usr/bin/env python3
from __future__ import annotations

import copy
import unittest

import xmage_transition_postgresql_scope_reconciliation as reconciliation


class XMageTransitionPostgreSQLScopeReconciliationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.evidence = {
            "cards": [
                {
                    "card_name": "Released Supported",
                    "release_scope_as_of_2026_07_28": (
                        "has_current_or_prior_registration"
                    ),
                    "runtime_catalog_status": "supported",
                },
                {
                    "card_name": "Released Gap",
                    "release_scope_as_of_2026_07_28": (
                        "has_current_or_prior_registration"
                    ),
                    "runtime_catalog_status": "unsupported",
                },
                {
                    "card_name": "Released Missing",
                    "release_scope_as_of_2026_07_28": (
                        "has_current_or_prior_registration"
                    ),
                    "runtime_catalog_status": "supported",
                },
                {
                    "card_name": "Future Missing",
                    "release_scope_as_of_2026_07_28": "future_only",
                    "runtime_catalog_status": "supported",
                },
            ]
        }
        self.matches = {
            "released supported": [
                {
                    "canonical_name": "Released Supported",
                    "identity_count": 1,
                    "printing_count": 2,
                    "set_codes": ["AAA", "BBB"],
                    "release_dates": ["2025-01-01", "2026-01-01"],
                }
            ],
            "released gap": [
                {
                    "canonical_name": "Released Gap",
                    "identity_count": 1,
                    "printing_count": 1,
                    "set_codes": ["CCC"],
                    "release_dates": ["2024-01-01"],
                }
            ],
        }

    def _report(self, **overrides):
        return reconciliation.build_reconciliation(
            overrides.get("evidence", self.evidence),
            overrides.get("matches", self.matches),
            transaction_read_only=overrides.get("transaction_read_only", True),
            queries_executed=overrides.get("queries_executed", 2),
        )

    def test_classifies_all_product_scope_lanes(self) -> None:
        report = self._report()

        self.assertEqual(report["status"], "pass")
        self.assertEqual(
            report["scope_counts"],
            {
                "external_runtime_gap": 1,
                "future_deferred": 1,
                "product_in_scope": 1,
                "released_missing_from_postgresql": 1,
            },
        )
        self.assertTrue(report["transaction_read_only"])
        self.assertFalse(report["writes_performed"])
        self.assertEqual(len(report["rows_sha256"]), 64)

    def test_multiple_printings_of_one_oracle_identity_are_not_ambiguous(self) -> None:
        report = self._report()
        row = next(
            value
            for value in report["card_results"]
            if value["card_name"] == "Released Supported"
        )

        self.assertEqual(row["postgresql_match_count"], 1)
        self.assertEqual(row["postgresql_printing_count"], 2)
        self.assertFalse(row["ambiguous"])

    def test_multiple_oracle_identities_fail_closed(self) -> None:
        matches = copy.deepcopy(self.matches)
        matches["released supported"][0]["identity_count"] = 2

        report = self._report(matches=matches)

        self.assertEqual(report["status"], "fail")
        self.assertEqual(report["ambiguity_count"], 1)

    def test_non_read_only_transaction_fails_closed(self) -> None:
        report = self._report(transaction_read_only=False)

        self.assertEqual(report["status"], "fail")

    def test_duplicate_transition_name_is_rejected(self) -> None:
        evidence = copy.deepcopy(self.evidence)
        evidence["cards"].append(copy.deepcopy(evidence["cards"][0]))

        with self.assertRaisesRegex(ValueError, "unique"):
            self._report(evidence=evidence)


if __name__ == "__main__":
    unittest.main()
