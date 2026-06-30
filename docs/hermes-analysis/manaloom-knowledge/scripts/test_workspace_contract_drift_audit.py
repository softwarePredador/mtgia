#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import workspace_contract_drift_audit as audit


class WorkspaceContractDriftAuditTests(unittest.TestCase):
    def test_current_workspace_contract_passes(self) -> None:
        report = audit.build_report()
        failures = [check for check in report["checks"] if check["status"] == "fail"]
        self.assertEqual(failures, [])
        self.assertEqual(report["status"], "pass")

    def test_forbidden_stale_sqlite_path_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.py"
            path.write_text(
                'db = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db"\n',
                encoding="utf-8",
            )
            check = audit.check_forbidden_snippets([path])

        self.assertEqual(check.status, "fail")
        self.assertIn("hits=1", check.detail)

    def test_unsafe_direct_1n_join_fails_without_aggregate_boundary(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.dart"
            path.write_text(
                """
                SELECT c.name, cft.tag
                FROM cards c
                JOIN card_function_tags cft ON cft.card_id = c.id
                WHERE c.name = 'Sol Ring'
                """,
                encoding="utf-8",
            )
            issues = audit.direct_join_issues([path])

        self.assertEqual(len(issues), 1)
        self.assertEqual(issues[0]["table"], "card_function_tags")

    def test_grouped_aggregate_1n_join_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "good.dart"
            path.write_text(
                """
                SELECT c.name, ARRAY_AGG(DISTINCT cft.tag) AS tags
                FROM cards c
                LEFT JOIN card_function_tags cft ON cft.card_id = c.id
                GROUP BY c.name
                """,
                encoding="utf-8",
            )
            issues = audit.direct_join_issues([path])

        self.assertEqual(issues, [])

    def test_card_intelligence_snapshot_compat_id_alias_join_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "good.dart"
            path.write_text(
                """
                SELECT c.name
                FROM deck_cards dc
                JOIN card_intelligence_snapshot c ON c.id = dc.card_id
                """,
                encoding="utf-8",
            )
            findings = audit.card_intelligence_snapshot_join_findings([path])

        self.assertEqual(findings["issues"], [])
        self.assertEqual(findings["compatibility_alias_count"], 1)

    def test_card_intelligence_snapshot_name_join_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.dart"
            path.write_text(
                """
                SELECT c.name
                FROM cards raw
                JOIN card_intelligence_snapshot c ON c.name = raw.name
                """,
                encoding="utf-8",
            )
            findings = audit.card_intelligence_snapshot_join_findings([path])

        self.assertEqual(len(findings["issues"]), 1)
        self.assertEqual(
            findings["issues"][0]["reason"],
            "card_intelligence_snapshot join is not anchored on card identity fields",
        )


if __name__ == "__main__":
    unittest.main()
