#!/usr/bin/env python3
from __future__ import annotations

import unittest

import legacy_contamination_audit as audit


class LegacyContaminationAuditTests(unittest.TestCase):
    def test_wrapper_delegates_to_workspace_drift_audit(self) -> None:
        report = audit.build_report()

        self.assertEqual(report["audit_name"], "legacy_contamination_audit")
        self.assertEqual(report["delegates_to"], "workspace_contract_drift_audit.py")
        self.assertIn("unsafe one-to-many card table joins", report["guardrail_scope"])
        self.assertIn(report["status"], {"pass", "fail"})
        self.assertIn("checks", report)

    def test_markdown_reports_non_pass_checks_or_none(self) -> None:
        text = audit.markdown(
            {
                "status": "pass",
                "generated_at": "fixture",
                "delegates_to": "workspace_contract_drift_audit.py",
                "summary": {"pass": 1},
                "checks": [{"name": "ok", "status": "pass", "detail": "ok"}],
            }
        )

        self.assertIn("# Legacy Contamination Audit", text)
        self.assertIn("- none", text)


if __name__ == "__main__":
    unittest.main()
