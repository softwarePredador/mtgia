#!/usr/bin/env python3
"""Tests for global Commander deck contract audit."""

from __future__ import annotations

import unittest

from global_commander_deck_contract_audit import (
    DeckRow,
    classify_deck,
    summarize,
    validate_commander_shape,
)


class GlobalCommanderDeckContractAuditTests(unittest.TestCase):
    def test_product_deck_ready_when_shape_is_clean(self) -> None:
        row = DeckRow(
            source="postgres",
            deck_id="deck-1",
            user_email="real.player@gmail.com",
            name="Miirym Commander",
            format="commander",
            row_count=65,
            total_quantity=100,
            commander_count=1,
            commander_names=("Miirym, Sentinel Wyrm",),
        )

        self.assertEqual(classify_deck(row), "user_product")
        self.assertEqual(validate_commander_shape(row), ("structure_ready", []))

    def test_fixture_email_is_not_product_scope(self) -> None:
        row = DeckRow(
            source="postgres",
            deck_id="deck-2",
            user_email="qa_runtime@example.invalid",
            name="QA LotA krenko",
            format="commander",
            total_quantity=100,
            commander_count=1,
        )

        self.assertEqual(classify_deck(row), "test_or_fixture")

    def test_registered_pg_variant_has_own_scope(self) -> None:
        row = DeckRow(
            source="postgres",
            deck_id="deck-3",
            name="PG REGISTERED Kefka Variant 01",
            format="commander",
            total_quantity=100,
            commander_count=1,
        )

        self.assertEqual(classify_deck(row), "registered_pg_variant")

    def test_hermes_lorehold_variant_is_not_global_template(self) -> None:
        row = DeckRow(
            source="hermes",
            deck_id="607",
            name="VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23",
            format="commander",
            total_quantity=100,
            commander_count=1,
        )

        self.assertEqual(classify_deck(row), "hermes_lorehold_variant")

    def test_partner_or_multi_commander_requires_explicit_profile(self) -> None:
        row = DeckRow(
            source="postgres",
            deck_id="deck-4",
            user_email="real.player@gmail.com",
            name="Wilson Background",
            format="commander",
            total_quantity=100,
            commander_count=2,
        )

        status, issues = validate_commander_shape(row)

        self.assertEqual(status, "needs_repair")
        self.assertIn("partner_or_multi_commander_requires_profile", issues)

    def test_nonbasic_duplicate_rows_block_structure_ready(self) -> None:
        row = DeckRow(
            source="postgres",
            deck_id="deck-duplicate",
            user_email="real.player@gmail.com",
            name="Duplicate Nonbasic",
            format="commander",
            total_quantity=100,
            commander_count=1,
            nonbasic_duplicate_rows=1,
        )

        status, issues = validate_commander_shape(row)

        self.assertEqual(status, "needs_repair")
        self.assertIn("nonbasic_duplicate_quantity", issues)

    def test_summary_marks_action_required_when_product_scope_has_repairs(self) -> None:
        payload = summarize(
            [
                DeckRow(
                    source="postgres",
                    deck_id="ready",
                    user_email="real.player@gmail.com",
                    name="Ready",
                    format="commander",
                    total_quantity=100,
                    commander_count=1,
                ),
                DeckRow(
                    source="postgres",
                    deck_id="bad",
                    user_email="real.player@gmail.com",
                    name="Incomplete",
                    format="commander",
                    total_quantity=1,
                    commander_count=1,
                ),
            ]
        )

        self.assertEqual(payload["status"], "action_required")
        self.assertEqual(payload["scope_counts"]["user_product"], 2)
        self.assertIn(
            "repair_or_exclude_product_user_decks_before_global_promotion",
            payload["action_items"],
        )

    def test_example_domain_and_probe_names_are_not_product_scope(self) -> None:
        fixtures = [
            DeckRow(
                source="postgres",
                deck_id="flow",
                user_email="flow_19dcf0c78f8@example.com",
                name="Flow Talrand 19dcf0c78f8",
                format="commander",
                total_quantity=100,
                commander_count=1,
            ),
            DeckRow(
                source="postgres",
                deck_id="probe",
                user_email="probe_19dcf0c78f8@example.com",
                name="Probe Talrand 19dcf0c78f8",
                format="commander",
                total_quantity=100,
                commander_count=1,
            ),
            DeckRow(
                source="postgres",
                deck_id="ml-test",
                user_email="real.player@gmail.com",
                name="ML Test Deck",
                format="commander",
                total_quantity=2,
                commander_count=1,
            ),
            DeckRow(
                source="postgres",
                deck_id="example-domain",
                user_email="haalder@example.com",
                name="Meu Deck Commander",
                format="commander",
                total_quantity=91,
                commander_count=1,
            ),
        ]

        for row in fixtures:
            with self.subTest(row=row.deck_id):
                self.assertEqual(classify_deck(row), "test_or_fixture")


if __name__ == "__main__":
    unittest.main()
