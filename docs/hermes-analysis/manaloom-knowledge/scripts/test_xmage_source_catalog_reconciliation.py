#!/usr/bin/env python3

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import xmage_source_catalog_reconciliation as reconciliation


class XmageSourceCatalogReconciliationTest(unittest.TestCase):
    def test_catalog_truth_overrides_local_class_candidate(self):
        queue = {
            "queue": [
                {
                    "card_id": "1",
                    "card_name": "Exact",
                    "source_truth_status": "xmage_authoritative",
                    "source_resolution_status": "local_source_candidate",
                    "xmage_class": "Exact",
                },
                {
                    "card_id": "2",
                    "card_name": "Forge fallback",
                    "source_truth_status": "xmage_authoritative",
                    "source_resolution_status": "local_source_candidate",
                    "xmage_class": "ForgeFallback",
                },
                {
                    "card_id": "3",
                    "card_name": "False collision",
                    "source_truth_status": "xmage_authoritative",
                    "source_resolution_status": "local_source_candidate",
                    "xmage_class": "FalseCollision",
                },
                {
                    "card_id": "4",
                    "card_name": "No source",
                    "source_truth_status": "xmage_source_missing",
                    "source_resolution_status": "local_source_missing",
                },
            ]
        }
        coverage = {
            "schema_version": "external_card_coverage_closure_v1",
            "ledger": [
                {"card_id": "1", "lane": "xmage_exact"},
                {"card_id": "2", "lane": "forge_exact"},
                {"card_id": "3", "lane": "unresolved"},
            ],
        }
        payload = reconciliation.build_reconciliation(queue, coverage)
        self.assertEqual(payload["status"], "pass")
        self.assertEqual(payload["summary"]["operationally_covered"], 2)
        self.assertEqual(payload["summary"]["residual"], 1)
        self.assertEqual(
            payload["summary"]["status_counts"],
            {
                "forge_catalog_fallback": 1,
                "local_source_candidate_not_executable": 1,
                "xmage_catalog_confirmed": 1,
            },
        )

    def test_missing_coverage_row_fails_closed(self):
        queue = {
            "queue": [
                {
                    "card_id": "1",
                    "card_name": "Missing",
                    "source_truth_status": "xmage_authoritative",
                }
            ]
        }
        coverage = {
            "schema_version": "external_card_coverage_closure_v1",
            "ledger": [],
        }
        payload = reconciliation.build_reconciliation(queue, coverage)
        self.assertEqual(payload["status"], "fail")
        self.assertEqual(payload["summary"]["missing_from_coverage"], ["1"])

    def test_duplicate_source_card_id_fails_closed(self):
        queue = {
            "queue": [
                {
                    "card_id": "1",
                    "card_name": "First",
                    "source_resolution_status": "local_source_candidate",
                },
                {
                    "card_id": "1",
                    "card_name": "Second",
                    "source_resolution_status": "local_source_candidate",
                },
            ]
        }
        coverage = {
            "schema_version": "external_card_coverage_closure_v1",
            "ledger": [{"card_id": "1", "lane": "xmage_exact"}],
        }
        with self.assertRaisesRegex(ValueError, "must be unique"):
            reconciliation.build_reconciliation(queue, coverage)


if __name__ == "__main__":
    unittest.main()
