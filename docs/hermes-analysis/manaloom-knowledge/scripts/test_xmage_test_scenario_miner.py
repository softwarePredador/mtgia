#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import xmage_test_scenario_miner as miner


PROMISE_TEST = """
package org.mage.test.cards.single.c16;

public class PromiseOfLoyaltyTest {
    @Test
    public void testPromiseOfLoyalty() {
        addCard(Zone.HAND, playerA, "Promise of Loyalty");
        addCard(Zone.BATTLEFIELD, playerA, "Plains", 5);
        addCard(Zone.BATTLEFIELD, playerA, "Silvercoat Lion");
        castSpell(1, PhaseStep.PRECOMBAT_MAIN, playerA, "Promise of Loyalty");
        setChoice(playerA, "Silvercoat Lion");
        waitStackResolved(1, PhaseStep.PRECOMBAT_MAIN);
        checkPermanentCount("lion survives", 1, PhaseStep.PRECOMBAT_MAIN, playerA, "Silvercoat Lion", 1);
        execute();
    }
}
"""


class XMageTestScenarioMinerTests(unittest.TestCase):
    def _root(self) -> Path:
        tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(tmpdir.cleanup)
        root = Path(tmpdir.name)
        test_path = root / "Mage.Tests" / "src" / "test" / "java" / "org" / "mage" / "test" / "cards" / "PromiseOfLoyaltyTest.java"
        test_path.parent.mkdir(parents=True)
        test_path.write_text(PROMISE_TEST, encoding="utf-8")
        return root

    def test_mines_exact_card_reference_and_scenario_shape(self) -> None:
        report = miner.build_report(["Promise of Loyalty"], xmage_root=self._root())

        self.assertEqual(report["mutations_performed"], [])
        self.assertEqual(report["summary"]["cards_with_test_reference"], 1)
        self.assertEqual(report["summary"]["usable_scenario_candidate_count"], 1)
        card = report["cards"][0]
        self.assertEqual(card["status"], "test_reference_found")
        shape = card["file_hits"][0]["method_hits"][0]["scenario_shape"]
        self.assertIn("addCard", shape["setup_commands"])
        self.assertIn("castSpell", shape["action_commands"])
        self.assertIn("checkPermanentCount", shape["assertion_commands"])

    def test_reports_missing_reference_without_claiming_missing_implementation(self) -> None:
        report = miner.build_report(["Missing Card"], xmage_root=self._root())

        self.assertEqual(report["summary"]["cards_with_test_reference"], 0)
        self.assertEqual(report["cards"][0]["status"], "no_exact_test_reference_found")
        self.assertIn("does not mean XMage has no card implementation", report["notes"][1])

    def test_markdown_contains_boundary(self) -> None:
        report = miner.build_report(["Promise of Loyalty"], xmage_root=self._root())
        markdown = miner.render_markdown(report)

        self.assertIn("XMage Test Scenario Miner", markdown)
        self.assertIn("Boundary", markdown)
        self.assertIn("Promise of Loyalty", markdown)


if __name__ == "__main__":
    unittest.main()
