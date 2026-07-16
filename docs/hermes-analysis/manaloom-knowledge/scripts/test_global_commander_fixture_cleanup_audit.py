#!/usr/bin/env python3

import tempfile
import unittest
from pathlib import Path

from global_commander_fixture_cleanup_audit import (
    ephemeral_provenance,
    source_class,
    write_sql_package,
)


class FixtureCleanupClassificationTest(unittest.TestCase):
    def test_incremental_requires_exact_owner_and_name_contract(self) -> None:
        accepted, witness = ephemeral_provenance(
            source="incremental_test_residue",
            email="test_deck_incremental@example.com",
            username="test_deck_incremental_user",
            name="Deck incremental",
        )
        self.assertTrue(accepted)
        self.assertIn("decks_incremental_add_test.dart", witness or "")

        rejected, _ = ephemeral_provenance(
            source="incremental_test_residue",
            email="test_deck_incremental@example.com",
            username="test_deck_incremental_user",
            name="Deck incremental retained baseline",
        )
        self.assertFalse(rejected)

    def test_retained_corpus_is_not_ephemeral(self) -> None:
        source = source_class(
            email="corpus.builder@example.com",
            username="corpus_builder",
            name="Corpus Seed - Atraxa, Praetors' Voice",
        )
        self.assertEqual(source, "corpus_seed_fixture")
        accepted, witness = ephemeral_provenance(
            source=source,
            email="corpus.builder@example.com",
            username="corpus_builder",
            name="Corpus Seed - Atraxa, Praetors' Voice",
        )
        self.assertFalse(accepted)
        self.assertIsNone(witness)

    def test_timestamped_device_pair_must_be_coherent(self) -> None:
        accepted, witness = ephemeral_provenance(
            source="device_qa_residue",
            email="iphone15_19df8c30206@example.com",
            username="iphone15_19df8c30206",
            name="iPhone15 Runtime Talrand 19df8c30206",
        )
        self.assertTrue(accepted)
        self.assertIn("deck_runtime_m2006_test.dart", witness or "")

        rejected, _ = ephemeral_provenance(
            source="device_qa_residue",
            email="iphone15_19df8c30206@example.com",
            username="iphone15_19df8c30206",
            name="iPhone15 Runtime Talrand different",
        )
        self.assertFalse(rejected)


class FixtureCleanupSqlPackageTest(unittest.TestCase):
    def _payload(self) -> dict:
        return {
            "generated_at": "2026-07-15T12:00:00+00:00",
            "safe_candidates": [
                {
                    "deck_id": "11111111-1111-4111-8111-111111111111",
                    "owner_user_id": "22222222-2222-4222-8222-222222222222",
                    "owner_email_md5": "0123456789abcdef0123456789abcdef",
                    "owner_username": "test_deck_incremental_user",
                    "name": "Deck incremental",
                    "created_at": "2026-01-01T00:00:00+00:00",
                    "deck_card_rows": 1,
                    "deck_quantity": 1,
                    "deck_row_md5": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "deck_cards_md5": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                    "source_class": "incremental_test_residue",
                    "ephemeral_provenance_witness": "server/test/decks_incremental_add_test.dart",
                }
            ],
            "incomplete_product_decks": [
                {"deck_id": "33333333-3333-4333-8333-333333333333"}
            ],
        }

    def test_package_is_exact_reversible_and_precheck_is_read_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            prefix = Path(tmp) / "fixture_cleanup_test"
            paths = write_sql_package(self._payload(), prefix)
            precheck = Path(paths["precheck"]).read_text(encoding="utf-8")
            apply_sql = Path(paths["apply"]).read_text(encoding="utf-8")
            rollback = Path(paths["rollback"]).read_text(encoding="utf-8")

        self.assertIn("SET TRANSACTION READ ONLY", precheck)
        self.assertNotIn("CREATE TEMP TABLE", precheck)
        self.assertNotIn("INSERT INTO public", precheck)
        self.assertIn("11111111-1111-4111-8111-111111111111", precheck)
        self.assertIn("product deck leaked", precheck)

        self.assertIn("manaloom_deploy_audit.fixture_cleanup_test_manifest", apply_sql)
        self.assertIn("fixture_cleanup_test_decks_backup", apply_sql)
        self.assertIn("fixture_cleanup_test_deck_cards_backup", apply_sql)
        self.assertIn("DELETE FROM public.decks d", apply_sql)
        self.assertIn("USING manaloom_deploy_audit.fixture_cleanup_test_manifest", apply_sql)
        self.assertIn("WHERE d.id = m.deck_id", apply_sql)
        self.assertNotIn("DELETE FROM public.decks WHERE", apply_sql)

        self.assertIn("INSERT INTO public.decks", rollback)
        self.assertIn("INSERT INTO public.deck_cards", rollback)
        self.assertIn("rollback identity hash mismatch", rollback)


if __name__ == "__main__":
    unittest.main()
