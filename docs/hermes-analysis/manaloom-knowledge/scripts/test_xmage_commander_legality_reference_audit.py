#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import xmage_commander_legality_reference_audit as audit


class XMageCommanderLegalityReferenceAuditTests(unittest.TestCase):
    def test_inspects_reference_files_without_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            partner = root / "Mage/src/main/java/mage/util/validation/PartnerValidator.java"
            commander = root / "Mage.Server.Plugins/Mage.Deck.Constructed/src/mage/deck/AbstractCommander.java"
            partner.parent.mkdir(parents=True)
            commander.parent.mkdir(parents=True)
            partner.write_text(
                "class PartnerValidator { public boolean canPartner() { return true; } }",
                encoding="utf-8",
            )
            commander.write_text(
                "class AbstractCommander { public boolean validatesColorIdentityAndSingleton() { return true; } }",
                encoding="utf-8",
            )

            report = audit.build_reference_audit(root)

        self.assertEqual(report["mutations_performed"], [])
        self.assertEqual(report["xmage_reference"]["found_count"], 2)
        self.assertGreater(report["xmage_reference"]["missing_count"], 0)

    def test_metadata_classifier_requires_identity_model(self) -> None:
        missing = audit.classify_metadata_row({"metadata": {}})
        present = audit.classify_metadata_row(
            {
                "metadata": {
                    "commander_identity_model": {
                        "identity_type": "partner",
                        "requires_first_class_persistence": True,
                    }
                }
            }
        )

        self.assertTrue(missing["requires_followup"])
        self.assertEqual(present["status"], "metadata_has_commander_identity_model")
        self.assertTrue(present["requires_first_class_persistence"])


if __name__ == "__main__":
    unittest.main()
