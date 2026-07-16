#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import app_ai_knowledge_bridge_audit as audit


class AppAiKnowledgeBridgeAuditTests(unittest.TestCase):
    def test_current_bridge_contract_passes(self) -> None:
        report = audit.build_report()
        failures = [check for check in report["checks"] if check["status"] == "fail"]

        self.assertEqual(failures, [])
        self.assertEqual(report["status"], "pass")
        check_names = {check["name"] for check in report["checks"]}
        self.assertIn(
            "backend.generate_route_uses_promoted_knowledge_surfaces",
            check_names,
        )
        self.assertIn("quality.prompt_eval.quality_gate.sh", check_names)
        self.assertIn("runtime.no_report_md_as_product_truth", check_names)

    def test_missing_generate_contract_snippet_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "generate.dart"
            path.write_text("void main() {}\n", encoding="utf-8")
            check = audit.check_contains(
                path,
                ["buildCommanderDeckbuildingContractDiagnostics("],
                "test.generate_contract",
            )

        self.assertEqual(check.status, "fail")
        self.assertIn("buildCommanderDeckbuildingContractDiagnostics", check.detail)

    def test_contract_snippet_allows_formatter_whitespace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "generate.dart"
            path.write_text(
                """
                final cards = activeCommanderLearnedDeckCardNames(
                  activeLearnedDeck,
                );
                """,
                encoding="utf-8",
            )
            check = audit.check_contains(
                path,
                ["activeCommanderLearnedDeckCardNames(activeLearnedDeck)"],
                "test.formatted_contract",
            )

        self.assertEqual(check.status, "pass")

    def test_raw_app_metadata_string_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "screen.dart"
            path.write_text(
                "const label = 'Origem: HERMES learned_deck:82';\n",
                encoding="utf-8",
            )
            check = audit.check_absent_in_files(
                [path],
                audit.FORBIDDEN_APP_RAW_METADATA,
                "test.raw_metadata",
        )

        self.assertEqual(check.status, "fail")
        self.assertIn("hits=", check.detail)

    def test_report_artifact_runtime_consumption_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "consumer.dart"
            path.write_text(
                "final path = 'docs/hermes-analysis/master_optimizer_reports/latest.md';\n",
                encoding="utf-8",
            )
            check = audit.check_absent_in_files(
                [path],
                audit.FORBIDDEN_RUNTIME_REPORT_CONSUMPTION,
                "test.report_consumption",
            )

        self.assertEqual(check.status, "fail")


if __name__ == "__main__":
    unittest.main()
