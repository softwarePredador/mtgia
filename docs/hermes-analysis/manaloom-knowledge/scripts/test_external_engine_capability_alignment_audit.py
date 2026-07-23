#!/usr/bin/env python3
from __future__ import annotations

import copy
import tempfile
import unittest
from pathlib import Path

import external_engine_capability_alignment_audit as audit


class ExternalEngineCapabilityAlignmentAuditTests(unittest.TestCase):
    def setUp(self) -> None:
        self.contract = audit.load_contract(audit.DEFAULT_CONTRACT)

    def test_current_contract_is_complete_and_evidenced(self) -> None:
        report = audit.build_report(self.contract)

        self.assertEqual(report["status"], "pass", report["failures"])
        self.assertEqual(report["summary"]["capability_count"], 20)
        self.assertEqual(report["summary"]["adopted_capability_count"], 13)
        self.assertEqual(report["source_inventory"]["xmage"]["status"], "not_requested")
        self.assertEqual(report["source_inventory"]["forge"]["status"], "not_requested")

    def test_missing_required_capability_fails_closed(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["capabilities"] = contract["capabilities"][:-1]

        report = audit.build_report(contract)

        self.assertEqual(report["status"], "fail")
        failure_ids = {row["id"] for row in report["failures"]}
        self.assertIn("required_capability_coverage", failure_ids)

    def test_adopted_capability_requires_existing_product_and_test_evidence(self) -> None:
        contract = copy.deepcopy(self.contract)
        contract["capabilities"][0]["test_evidence"] = ["missing/test.dart"]

        report = audit.build_report(contract)

        self.assertEqual(report["status"], "fail")
        self.assertTrue(
            any(
                row["id"] == "capability:rules_execution:test_paths"
                for row in report["failures"]
            )
        )

    def test_forge_import_outside_sidecar_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            rogue = root / "server" / "Rogue.java"
            rogue.parent.mkdir(parents=True)
            rogue.write_text("import forge.game.Game;\n", encoding="utf-8")
            checks: list[dict[str, object]] = []
            engine_map = {
                "xmage": {"allowed_java_root": "services/xmage-sidecar"},
                "forge": {"allowed_java_root": "services/forge-sidecar"},
            }

            audit._validate_import_boundaries(root, engine_map, checks)

            forge_check = next(
                row for row in checks if row["id"] == "forge_java_import_boundary"
            )
            self.assertEqual(forge_check["status"], "fail")
            self.assertEqual(forge_check["details"]["violations"], ["server/Rogue.java"])

    def test_source_inventory_counts_pinned_tree_paths(self) -> None:
        paths = [
            "Mage.Sets/src/mage/cards/a/Alpha.java",
            "Mage.Sets/src/mage/cards/b/Beta.java",
            "Mage.Tests/src/test/java/org/mage/test/AlphaTest.java",
            "Mage/src/main/java/mage/game/Game.java",
        ]
        xmage_metrics = {
            "card_implementations": sum(
                path.startswith("Mage.Sets/src/mage/cards/") and path.endswith(".java")
                for path in paths
            ),
            "java_tests": sum(
                path.startswith("Mage.Tests/src/test/") and path.endswith(".java")
                for path in paths
            ),
        }

        self.assertEqual(xmage_metrics["card_implementations"], 2)
        self.assertEqual(xmage_metrics["java_tests"], 1)

    def test_machine_specific_operational_default_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            resolver = (
                root
                / "docs/hermes-analysis/manaloom-knowledge/scripts/"
                "external_engine_source_contract.py"
            )
            resolver.parent.mkdir(parents=True)
            resolver.write_text("# resolver\n", encoding="utf-8")
            rogue = root / "scripts/rogue.py"
            rogue.parent.mkdir(parents=True)
            rogue.write_text(
                'ROOT = "/Users/example/Downloads/mage-master"\n',
                encoding="utf-8",
            )
            checks: list[dict[str, object]] = []

            audit._validate_local_source_policy(self.contract, root, checks)

            machine_check = next(
                row
                for row in checks
                if row["id"] == "no_machine_specific_operational_defaults"
            )
            self.assertEqual(machine_check["status"], "fail")
            self.assertEqual(machine_check["details"]["violations"], ["scripts/rogue.py"])


if __name__ == "__main__":
    unittest.main()
