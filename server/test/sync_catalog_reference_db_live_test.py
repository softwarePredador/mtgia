#!/usr/bin/env python3
"""BT-CAT-01 em PostgreSQL descartável: duas execuções, delta zero, usuário intacto.

Exige RUN_CATALOG_REFERENCE_DB_TESTS=1 e os DB_* de um banco descartável já
montado com server/database_setup.sql e server/bin/migrate.dart. Nunca aponte
para banco compartilhado nem de produção: o teste semeia linhas e recusa um
banco em que `cards` já tenha dados.
"""
from __future__ import annotations

import importlib.util
import os
import sys
import tempfile
import unittest
from datetime import datetime, timezone
from decimal import Decimal
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "sync_catalog_reference_from_scryfall.py"
    spec = importlib.util.spec_from_file_location(
        "sync_catalog_reference_from_scryfall_live", path
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


ENABLED = os.environ.get("RUN_CATALOG_REFERENCE_DB_TESTS") == "1"
FIXTURES = Path(__file__).resolve().parent / "fixtures"
# Por padrão, o formato de produção desde 2026-09-23: JSON Lines com gzip. A
# lista JSON antiga roda com CATALOG_REFERENCE_DB_BULK=json. As asserções são
# as mesmas: os dois arquivos trazem os mesmos cards.
BULK_FIXTURES = {
    "jsonl": (FIXTURES / "scryfall_default_cards_sample.jsonl.gz", "jsonl"),
    "json": (FIXTURES / "scryfall_default_cards_sample.json", "json_array"),
}
FIXTURE, BULK_FORMAT = BULK_FIXTURES[os.environ.get("CATALOG_REFERENCE_DB_BULK", "jsonl")]
SOURCE_UPDATED_AT = "2026-09-22T09:00:00+00:00"
# Relógio fixo: o alerta de frescor (7 dias) não pode depender da data do teste.
NOW = datetime(2026, 9, 23, 10, 0, tzinfo=timezone.utc)

O_SOL = "5c8e7c9e-1111-4a1a-8a1a-000000000001"
O_BOLT = "5c8e7c9e-1111-4a1a-8a1a-000000000002"
O_DRAKE = "5c8e7c9e-1111-4a1a-8a1a-000000000003"
P_SOL_CMM = "5c8e7c9e-2222-4b2b-9b2b-000000000001"
P_SOL_BRT = "5c8e7c9e-2222-4b2b-9b2b-000000000002"
P_BOLT = "5c8e7c9e-2222-4b2b-9b2b-000000000003"
P_DRAKE = "5c8e7c9e-2222-4b2b-9b2b-000000000004"
P_ADEPT = "5c8e7c9e-2222-4b2b-9b2b-000000000006"
P_GLEEMAX = "5c8e7c9e-2222-4b2b-9b2b-000000000008"

USER_TABLES = ("users", "decks", "deck_cards", "user_binder_items")


@unittest.skipUnless(ENABLED, "Requer PostgreSQL descartável (RUN_CATALOG_REFERENCE_DB_TESTS=1).")
class CatalogReferenceRefreshDbTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        import psycopg2  # type: ignore

        cls.job = _load_module()
        cls.environment = {
            key: os.environ[key]
            for key in ("DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASS")
            if key in os.environ
        }
        cls.conn = psycopg2.connect(
            host=os.environ["DB_HOST"],
            port=os.environ.get("DB_PORT", "5432"),
            dbname=os.environ["DB_NAME"],
            user=os.environ["DB_USER"],
            password=os.environ.get("DB_PASS", ""),
        )
        cls.conn.autocommit = True
        cls._seed()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.conn.close()

    @classmethod
    def _seed(cls) -> None:
        with cls.conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM cards")
            if cur.fetchone()[0] != 0:
                raise RuntimeError("o banco não é descartável: cards já tem linhas")
            cur.execute(
                "INSERT INTO sets (code, name, release_date) VALUES "
                "('LEA', 'Limited Edition Alpha', '1993-08-05'), "
                "('2XM', 'Double Masters', '2020-08-07')"
            )
            cur.execute(
                """
                INSERT INTO cards (scryfall_id, oracle_id, name, mana_cost, type_line,
                  oracle_text, colors, color_identity, image_url, set_code, rarity,
                  is_reserved, price, price_usd, price_source, price_updated_at)
                VALUES (%s::uuid, %s::uuid, 'Sol Ring', '{1}', 'Artifact',
                  '{T}: Add {C}{C}.', '{}', '{}',
                  'https://api.scryfall.com/cards/named?exact=Sol%%20Ring&set=lea&format=image',
                  'lea', 'uncommon', FALSE, 1.00, 1.00, 'mtgjson', '2026-06-27T00:00:00Z')
                """,
                (O_SOL, O_SOL),
            )
            cur.execute(
                """
                INSERT INTO cards (scryfall_id, oracle_id, name, mana_cost, type_line,
                  oracle_text, colors, color_identity, image_url, set_code, rarity,
                  collector_number, is_reserved, price, price_usd, price_source,
                  price_updated_at)
                VALUES (%s::uuid, %s::uuid, 'Lightning Bolt', '{R}', 'Instant',
                  'Lightning Bolt deals 3 damage to target creature or player.',
                  '{R}', '{R}',
                  'https://api.scryfall.com/cards/named?exact=Lightning%%20Bolt&format=image',
                  '2XM', 'uncommon', '117', FALSE, 0.10, 0.10, 'legacy',
                  '2026-06-01T00:00:00Z')
                """,
                (P_BOLT, O_BOLT),
            )
            # Linha-alias do Drake: no bulk ele só tem preço foil e uma versão
            # digital, então o preço atual fica (D-62).
            cur.execute(
                """
                INSERT INTO cards (scryfall_id, oracle_id, name, mana_cost, type_line,
                  oracle_text, colors, color_identity, set_code, rarity,
                  is_reserved, price, price_usd, price_source, price_updated_at)
                VALUES (%s::uuid, %s::uuid, 'BrewTact Test Drake', '{2}{U}',
                  'Creature — Drake', 'Flying', '{U}', '{U}', 'brt', 'common',
                  FALSE, 0.30, 0.30, 'mtgjson', '2026-06-27T00:00:00Z')
                """,
                (O_DRAKE, O_DRAKE),
            )
            cur.execute(
                """
                INSERT INTO card_legalities (card_id, format, status)
                SELECT c.id, v.format, v.status
                FROM cards c
                JOIN (VALUES ('commander', 'legal'), ('legacy', 'legal'),
                             ('vintage', 'restricted')) AS v(format, status) ON TRUE
                WHERE c.scryfall_id = %s::uuid
                """,
                (O_SOL,),
            )
            cur.execute(
                """
                INSERT INTO card_legalities (card_id, format, status)
                SELECT c.id, 'modern', 'legal' FROM cards c WHERE c.scryfall_id = %s::uuid
                """,
                (P_BOLT,),
            )
            cur.execute(
                "INSERT INTO users (username, email, password_hash) "
                "VALUES ('catalog_refresh_user', 'catalog_refresh@example.invalid', 'x') "
                "RETURNING id"
            )
            user_id = cur.fetchone()[0]
            cur.execute(
                "INSERT INTO decks (user_id, name, format) VALUES (%s, 'Deck de teste', 'commander') "
                "RETURNING id",
                (user_id,),
            )
            deck_id = cur.fetchone()[0]
            cur.execute(
                """
                INSERT INTO deck_cards (deck_id, card_id, quantity)
                SELECT %s, c.id, 1 FROM cards c
                """,
                (deck_id,),
            )
            cur.execute(
                """
                INSERT INTO user_binder_items (user_id, card_id, quantity)
                SELECT %s, c.id, 2 FROM cards c WHERE c.scryfall_id = %s::uuid
                """,
                (user_id, P_BOLT),
            )
            cur.execute(
                "INSERT INTO sync_state (key, value) VALUES ('cards_last_sync_at', "
                "'2026-06-06T12:00:00') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value"
            )

    def user_tables_fingerprint(self) -> dict[str, str]:
        fingerprint = {}
        with self.conn.cursor() as cur:
            for table in USER_TABLES:
                cur.execute(
                    f"SELECT md5(COALESCE(string_agg(t::text, '|' ORDER BY t::text), '')) "
                    f"FROM {table} t"
                )
                fingerprint[table] = cur.fetchone()[0]
        return fingerprint

    def run_job(self, *argv: str, approval: bool = False):
        environment = dict(self.environment)
        if approval:
            environment[self.job.WRITE_APPROVAL_ENV] = self.job.WRITE_APPROVAL_VALUE
        with tempfile.TemporaryDirectory() as tmp:
            args = self.job.parse_args(
                ["--env-file", str(Path(tmp) / "none.env"), *argv]
            )
        ctx = self.job.RunContext(
            budget=self.job.budget_from_args(args), now=lambda: NOW
        )
        return self.job.run(args, environment=environment, ctx=ctx)

    def fetch_card(self, scryfall_id: str) -> dict:
        with self.conn.cursor() as cur:
            cur.execute(
                "SELECT name, oracle_text, image_url, set_code, collector_number, foil, "
                "is_reserved, cmc, price, price_usd, price_usd_foil, price_source, "
                "price_updated_at, oracle_id::text, card_faces_json "
                "FROM cards WHERE scryfall_id = %s::uuid",
                (scryfall_id,),
            )
            row = cur.fetchone()
            if row is None:
                return {}
            names = [column.name for column in cur.description]
            return dict(zip(names, row))

    def legalities(self, scryfall_id: str) -> dict[str, str]:
        with self.conn.cursor() as cur:
            cur.execute(
                "SELECT cl.format, cl.status FROM card_legalities cl "
                "JOIN cards c ON c.id = cl.card_id WHERE c.scryfall_id = %s::uuid",
                (scryfall_id,),
            )
            return dict(cur.fetchall())

    def test_activation_then_scheduled_runs_are_idempotent(self) -> None:
        bulk = ["--bulk-json", str(FIXTURE), "--source-updated-at", SOURCE_UPDATED_AT]
        before_user_tables = self.user_tables_fingerprint()

        code, receipt = self.run_job("--mode", "scheduled", *bulk)
        # Catálogo parado desde 2026-06-06 e contrato inativo: alerta (D-36).
        self.assertEqual(
            (code, receipt["status"], receipt["alerts"]),
            (self.job.FRESHNESS_ALERT_EXIT_CODE, "contract_inactive", ["catalog_stale"]),
            receipt,
        )

        code, receipt = self.run_job("--mode", "activate", *bulk, approval=True)
        self.assertEqual((code, receipt["status"]), (0, "activated"), receipt)
        self.assertEqual(receipt["source"]["format"], BULK_FORMAT)
        counts = receipt["counts"]
        self.assertEqual(counts["cards"]["inserted"], 4)
        self.assertEqual(counts["cards"]["updated"], 1)
        self.assertEqual(counts["sets"]["inserted"], 2)
        self.assertGreater(counts["card_legalities"]["inserted"], 0)
        self.assertEqual(counts["card_legalities"]["updated"], 1)
        self.assertEqual(
            counts["alias_prices"],
            {
                "found": 1,
                "updated": 1,
                "unchanged": 0,
                "kept_no_paper_usd": 1,
                "kept_not_in_bulk": 0,
            },
        )

        bolt = self.fetch_card(P_BOLT)
        self.assertEqual(bolt["price_usd"], Decimal("1.50"))
        self.assertEqual(bolt["price"], Decimal("1.50"))
        self.assertEqual(bolt["price_usd_foil"], Decimal("3.00"))
        self.assertEqual(bolt["price_source"], "scryfall")
        self.assertEqual(bolt["oracle_text"], "Lightning Bolt deals 3 damage to any target.")
        self.assertTrue(bolt["image_url"].startswith("https://cards.scryfall.io/normal/front/5/c/"))
        self.assertEqual(bolt["collector_number"], "117")
        self.assertEqual(bolt["set_code"], "2XM")
        self.assertTrue(bolt["foil"])
        # Linha existente sem impressão nova do mesmo Oracle: a legalidade
        # também é atualizada (status desconhecido da fonte fica de fora).
        self.assertEqual(
            self.legalities(P_BOLT),
            {
                "modern": "legal",
                "standard": "not_legal",
                "pauper": "legal",
                "commander": "legal",
            },
        )

        # D-62: a linha-alias leva o menor preço em papel, não foil, em USD, entre
        # todas as impressões do bulk: 1.99 (cmm, que nem está no catálogo)
        # contra 2.25 (brt).
        alias = self.fetch_card(O_SOL)
        self.assertEqual(alias["price_usd"], Decimal("1.99"))
        self.assertEqual(alias["price"], Decimal("1.99"))
        self.assertEqual(alias["price_source"], "scryfall")
        self.assertEqual(alias["price_updated_at"], datetime(2026, 9, 22, 9, 0, tzinfo=timezone.utc))
        self.assertIsNone(alias["price_usd_foil"])
        drake_alias = self.fetch_card(O_DRAKE)
        self.assertEqual(drake_alias["price_usd"], Decimal("0.30"))
        self.assertEqual(drake_alias["price_source"], "mtgjson")
        self.assertIn("api.scryfall.com/cards/named", alias["image_url"])
        self.assertEqual(
            self.legalities(O_SOL),
            {
                "commander": "legal",
                "legacy": "banned",
                "vintage": "restricted",
                "standard": "not_legal",
                "modern": "not_legal",
            },
        )

        self.assertEqual(self.fetch_card(P_SOL_CMM), {})
        recent = self.fetch_card(P_SOL_BRT)
        self.assertEqual(recent["oracle_id"], O_SOL)
        self.assertEqual(recent["set_code"], "BRT")
        self.assertEqual(recent["price_usd"], Decimal("2.25"))
        self.assertEqual(self.legalities(P_SOL_BRT)["legacy"], "banned")
        adept = self.fetch_card(P_ADEPT)
        self.assertIsNone(adept["oracle_text"])
        self.assertEqual(len(adept["card_faces_json"]), 2)
        gleemax = self.fetch_card(P_GLEEMAX)
        self.assertIsNone(gleemax["cmc"])
        self.assertTrue(gleemax["is_reserved"])
        drake = self.fetch_card(P_DRAKE)
        self.assertIsNone(drake["price_usd"])
        self.assertEqual(drake["price_usd_foil"], Decimal("0.75"))

        with self.conn.cursor() as cur:
            cur.execute("SELECT code FROM sets ORDER BY code")
            self.assertEqual([row[0] for row in cur.fetchall()], ["2XM", "BRT", "LEA", "UNF"])
            cur.execute(
                "SELECT key, value FROM sync_state WHERE key = ANY(%s)",
                ([self.job.STATE_ACTIVE_CONTRACT, self.job.STATE_SOURCE_UPDATED_AT],),
            )
            self.assertEqual(
                dict(cur.fetchall()),
                {
                    self.job.STATE_ACTIVE_CONTRACT: self.job.APPLY_CONTRACT,
                    self.job.STATE_SOURCE_UPDATED_AT: SOURCE_UPDATED_AT,
                },
            )
            cur.execute(
                "SELECT sync_type, status FROM sync_log WHERE sync_type LIKE 'catalog_reference%%' "
                "ORDER BY sync_type"
            )
            self.assertEqual(
                cur.fetchall(),
                [
                    ("catalog_reference:alias_prices", "success"),
                    ("catalog_reference:card_legalities", "success"),
                    ("catalog_reference:cards", "success"),
                    ("catalog_reference:sets", "success"),
                ],
            )
            cur.execute("SELECT count(*) FROM cards")
            cards_after_first = cur.fetchone()[0]
            cur.execute("SELECT count(*) FROM card_legalities")
            legalities_after_first = cur.fetchone()[0]

        code, receipt = self.run_job("--mode", "scheduled", *bulk)
        self.assertEqual((code, receipt["status"]), (0, "noop_same_source"), receipt)

        code, receipt = self.run_job("--mode", "scheduled", "--force", *bulk)
        self.assertEqual((code, receipt["status"]), (0, "applied"), receipt)
        counts = receipt["counts"]
        self.assertEqual(counts["cards"]["inserted"], 0)
        self.assertEqual(counts["cards"]["updated"], 0)
        self.assertEqual(counts["cards"]["refresh_candidates"], 5)
        self.assertEqual(counts["sets"]["inserted"], 0)
        self.assertEqual(counts["card_legalities"]["inserted"], 0)
        self.assertEqual(counts["card_legalities"]["updated"], 0)
        self.assertEqual(counts["alias_prices"]["updated"], 0)
        self.assertEqual(counts["alias_prices"]["unchanged"], 1)
        with self.conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM cards")
            self.assertEqual(cur.fetchone()[0], cards_after_first)
            cur.execute("SELECT count(*) FROM card_legalities")
            self.assertEqual(cur.fetchone()[0], legalities_after_first)

        code, receipt = self.run_job("--mode", "deactivate", approval=True)
        self.assertEqual((code, receipt["status"]), (0, "deactivated"), receipt)
        code, receipt = self.run_job("--mode", "scheduled", "--force", *bulk)
        self.assertEqual((code, receipt["status"]), (0, "contract_inactive"), receipt)

        self.assertEqual(self.user_tables_fingerprint(), before_user_tables)


if __name__ == "__main__":
    unittest.main()
