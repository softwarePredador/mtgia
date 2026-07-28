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

CONSTANT_REFERENCE_TEST = """
package org.mage.test.cards.single.tst;

public class ConstantReferenceCardTest {
    private static final String CARD = "Constant Reference Card";

    @Test
    void testPackagePrivateMethodAndAssertHelpers() {
        addCard(Zone.HAND, playerA, CARD);
        castSpell(1, PhaseStep.PRECOMBAT_MAIN, playerA, CARD);
        addTarget(playerA, playerB);
        assertLife(playerB, 17);
        execute();
    }
}
"""

COMMENT_ONLY_REFERENCE_TEST = """
package org.mage.test.cards.single.tst;

public class UnrelatedTest {
    // Krark, the Thumbless is only mentioned in documentation here.
    @Test
    public void testOtherCard() {
        addCard(Zone.HAND, playerA, "Other Card");
        castSpell(1, PhaseStep.PRECOMBAT_MAIN, playerA, "Other Card");
        assertLife(playerB, 20);
        execute();
    }
}
"""

HELPER_ONLY_REFERENCE_TEST = """
package org.mage.test.cards.single.tst;

public class HelperOnlyReference {
    void buildFixture() {
        addCard(Zone.HAND, playerA, "Krark, the Thumbless");
        castSpell(1, PhaseStep.PRECOMBAT_MAIN, playerA, "Krark, the Thumbless");
        assertPermanentCount(playerA, "Krark, the Thumbless", 1);
        execute();
    }
}
"""


class XMageTestScenarioMinerTests(unittest.TestCase):
    def _root(self, *extra_sources: tuple[str, str]) -> Path:
        tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(tmpdir.cleanup)
        root = Path(tmpdir.name)
        test_root = (
            root
            / "Mage.Tests"
            / "src"
            / "test"
            / "java"
            / "org"
            / "mage"
            / "test"
            / "cards"
        )
        test_root.mkdir(parents=True)
        (test_root / "PromiseOfLoyaltyTest.java").write_text(
            PROMISE_TEST,
            encoding="utf-8",
        )
        for filename, source in extra_sources:
            (test_root / filename).write_text(source, encoding="utf-8")
        return root

    def test_mines_exact_card_reference_and_scenario_shape(self) -> None:
        report = miner.build_report(["Promise of Loyalty"], xmage_root=self._root())

        self.assertEqual(report["schema_version"], miner.SCHEMA_VERSION)
        self.assertEqual(report["mutations_performed"], [])
        self.assertEqual(report["summary"]["cards_with_test_reference"], 1)
        self.assertEqual(report["summary"]["usable_scenario_candidate_count"], 1)
        card = report["cards"][0]
        self.assertEqual(card["status"], "test_reference_found")
        shape = card["file_hits"][0]["method_hits"][0]["scenario_shape"]
        self.assertIn("addCard", shape["setup_commands"])
        self.assertIn("castSpell", shape["action_commands"])
        self.assertIn("checkPermanentCount", shape["assertion_commands"])
        self.assertEqual(shape["command_counts"]["checkPermanentCount"], 1)

    def test_reports_missing_reference_without_claiming_missing_implementation(self) -> None:
        report = miner.build_report(["Missing Card"], xmage_root=self._root())

        self.assertEqual(report["summary"]["cards_with_test_reference"], 0)
        self.assertEqual(report["cards"][0]["status"], "no_exact_test_reference_found")
        self.assertIn("does not mean XMage has no card implementation", report["notes"][1])

    def test_short_split_face_does_not_match_generic_java_fragments(self) -> None:
        report = miner.build_report(
            ["SP//dr, Piloted by Peni"],
            xmage_root=self._root(),
        )

        card = report["cards"][0]
        self.assertNotIn("SP", card["search_terms"])
        self.assertEqual(card["status"], "no_exact_test_reference_found")
        self.assertEqual(card["test_file_count"], 0)

    def test_follows_named_card_constants_and_package_private_test_methods(self) -> None:
        report = miner.build_report(
            ["Constant Reference Card"],
            xmage_root=self._root(
                ("ConstantReferenceCardTest.java", CONSTANT_REFERENCE_TEST),
            ),
        )

        card = report["cards"][0]
        self.assertEqual(card["test_file_count"], 1)
        method = card["file_hits"][0]["method_hits"][0]
        self.assertEqual(
            method["method_name"],
            "testPackagePrivateMethodAndAssertHelpers",
        )
        shape = method["scenario_shape"]
        self.assertIn("addTarget", shape["choice_commands"])
        self.assertIn("assertLife", shape["assertion_commands"])
        self.assertTrue(shape["usable_for_manaloom_candidate"])

    def test_comment_only_file_reference_is_not_nominal_scenario_evidence(self) -> None:
        report = miner.build_report(
            ["Krark, the Thumbless"],
            xmage_root=self._root(
                ("UnrelatedTest.java", COMMENT_ONLY_REFERENCE_TEST),
            ),
        )

        card = report["cards"][0]
        self.assertEqual(card["test_file_count"], 0)
        self.assertEqual(card["status"], "no_exact_test_reference_found")

    def test_helper_method_is_not_promoted_to_test_evidence(self) -> None:
        report = miner.build_report(
            ["Krark, the Thumbless"],
            xmage_root=self._root(
                ("HelperOnlyReference.java", HELPER_ONLY_REFERENCE_TEST),
            ),
        )

        card = report["cards"][0]
        self.assertEqual(card["test_file_count"], 0)
        self.assertEqual(card["status"], "no_exact_test_reference_found")

    def test_markdown_contains_boundary(self) -> None:
        report = miner.build_report(["Promise of Loyalty"], xmage_root=self._root())
        markdown = miner.render_markdown(report)

        self.assertIn("XMage Test Scenario Miner", markdown)
        self.assertIn("Boundary", markdown)
        self.assertIn("Promise of Loyalty", markdown)


if __name__ == "__main__":
    unittest.main()
