#!/usr/bin/env python3
"""BT-DB-003: o ensaio de upgrade nos perfis canônico, deriva e misto.

Requer RUN_SCHEMA_DB_TESTS=1, a aprovação do PostgreSQL descartável
(MANALOOM_APPROVE_DISPOSABLE_POSTGRES=I_APPROVE_DISPOSABLE_LOCAL_POSTGRES ou
git config manaloom.localGates.disposablePostgres=true) e os binários do
PostgreSQL 17 e do Dart, os mesmos de scripts/manaloom_migration_rehearsal.py.
Não usa o banco das variáveis DB_*: monta os fixtures num cluster descartável
próprio, e cada ensaio sobe o seu.

Fixtures, sem dado da produção:
- canônico: server/test/fixtures/schema_profiles/database_setup_058.sql (o
  bootstrap da produção, em 41bab49c9) com as migrations até a 058 e linhas
  sintéticas;
- deriva: o canônico com a deriva que a auditoria BT-DB-001 publicou
  (server/test/support/production_drift_fixture.py);
- misto: o canônico com o ledger de outra linha de código (versão
  desconhecida, nome trocado, pendente antes da última executada) ou sem
  ledger e com contas.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
ENABLED = os.environ.get("RUN_SCHEMA_DB_TESTS") == "1"
SETUP_058 = REPO_ROOT / "server" / "test" / "fixtures" / "schema_profiles" / "database_setup_058.sql"
SETUP_058_SHA256 = "857c56423da0519ef12326f8686a37bd8e0c58746338efa5e6c8538f7ab057a9"
ALLOWLIST = REPO_ROOT / "server" / "config" / "schema_drift_allowlist.json"
SEED = """
INSERT INTO users (id, username, email, password_hash) VALUES
  ('00000000-0000-4000-8000-000000000001', 'ensaio_ana', 'ana@example.invalid', 'x'),
  ('00000000-0000-4000-8000-000000000002', 'ensaio_beto', 'beto@example.invalid', 'x');
INSERT INTO cards (id, scryfall_id, name) VALUES
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000201', 'Carta A'),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000202', 'Carta B');
INSERT INTO card_legalities (card_id, format, status) VALUES
  ('00000000-0000-4000-8000-000000000101', 'commander', 'legal');
INSERT INTO decks (id, user_id, name, format) VALUES
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000001',
   'Deck do ensaio', 'commander');
INSERT INTO deck_cards (deck_id, card_id) VALUES
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000101'),
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000102');
INSERT INTO user_binder_items (user_id, card_id) VALUES
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101');
INSERT INTO conversations (id, user_a_id, user_b_id) VALUES
  ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000001',
   '00000000-0000-4000-8000-000000000002');
INSERT INTO direct_messages (conversation_id, sender_id, message) VALUES
  ('00000000-0000-4000-8000-000000000401', '00000000-0000-4000-8000-000000000001', 'oi');
INSERT INTO notifications (user_id, type, title) VALUES
  ('00000000-0000-4000-8000-000000000002', 'direct_message', 'Mensagem nova');
INSERT INTO card_meta_insights (card_name) VALUES ('Carta A');
INSERT INTO commander_learned_decks (commander_name, commander_name_normalized, deck_name,
  source_system, source_ref, card_list, card_count)
  VALUES ('Talrand', 'talrand', 'Deck aprendido', 'ensaio', 'ref-1', 'Talrand', 100);
INSERT INTO trade_offers (id, sender_id, receiver_id) VALUES
  ('00000000-0000-4000-8000-000000000501', '00000000-0000-4000-8000-000000000001',
   '00000000-0000-4000-8000-000000000002');
INSERT INTO ml_prompt_feedback (archetype) VALUES ('control');
"""
MIXED = {
    "versao_desconhecida": (
        "INSERT INTO schema_migrations (version, name) VALUES ('999', 'de_outra_linha')",
        "a versão 999 (de_outra_linha) está no ledger e não existe neste código",
    ),
    "nome_trocado": (
        "UPDATE schema_migrations SET name = 'outra_058' WHERE version = '058'",
        'a versão 058 está no ledger como "outra_058"',
    ),
    "pendente_antes_da_ultima": (
        "DELETE FROM schema_migrations WHERE version = '057'",
        "a 057 (expand_battle_job_async_timeout) está pendente, mas a 058",
    ),
    "sem_ledger_com_contas": (
        "DROP TABLE schema_migrations",
        "schema_migrations não existe, mas users tem 2 conta(s)",
    ),
}


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


rehearsal = _load("bt_db_003_rehearsal", REPO_ROOT / "scripts" / "manaloom_migration_rehearsal.py")
drift = _load("bt_db_003_drift", REPO_ROOT / "server" / "test" / "support" / "production_drift_fixture.py")


@unittest.skipUnless(ENABLED, "Requer RUN_SCHEMA_DB_TESTS=1 e PostgreSQL descartavel isolado.")
class MigrationRehearsalOnDisposablePostgresTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not rehearsal._approved():
            raise AssertionError("aprove o PostgreSQL descartável (MANALOOM_APPROVE_DISPOSABLE_POSTGRES)")
        digest = hashlib.sha256(SETUP_058.read_bytes()).hexdigest()
        assert digest == SETUP_058_SHA256, "o bootstrap da 058 do fixture mudou"
        pg_bin, dart = rehearsal._tools()
        cls.work = Path(tempfile.mkdtemp(prefix="manaloom-rehearsal-fixtures."))
        cls.cluster = rehearsal.Cluster(pg_bin, dart, cls.work)
        cls.dumps: dict[str, Path] = {}
        cluster = cls.cluster
        try:
            cluster.start()
            cluster.createdb("canonico")
            cluster.psql_file("canonico", SETUP_058)
            result = cluster.migrate("canonico", "--target", "058")
            assert result.returncode == 0, result.stdout[-2000:] + result.stderr[-2000:]
            cluster.execute("canonico", SEED)
            cls.dumps["canonico"] = cls._dump("canonico")

            cluster.createdb("deriva")
            cluster.restore("deriva", cls.dumps["canonico"], "completo")
            groups, cls.not_modeled = drift.drift_groups(REPO_ROOT)
            for label, statements in groups:
                try:
                    cluster.execute("deriva", ";\n".join(statements) + ";")
                except RuntimeError as error:
                    raise AssertionError(f"deriva não aplicou: {label}: {error}") from error
            cls.drift_groups = [label for label, _ in groups]
            cls.dumps["deriva"] = cls._dump("deriva")

            for name, (statement, _reason) in MIXED.items():
                cluster.createdb(name)
                cluster.restore(name, cls.dumps["canonico"], "completo")
                cluster.execute(name, statement + ";")
                cls.dumps[name] = cls._dump(name)
        except BaseException:
            cls.tearDownClass()
            raise

    @classmethod
    def tearDownClass(cls) -> None:
        cls.cluster.stop()
        shutil.rmtree(cls.work, ignore_errors=True)

    @classmethod
    def _dump(cls, database: str) -> Path:
        path = cls.work / f"{database}.dump"
        cls.cluster.dump(database, path)
        return path

    def _rehearse(self, fixture: str, *, restore: str = "completo", allowlist: Path = ALLOWLIST):
        out = self.work / f"saida-{fixture}-{restore}-{allowlist.stem}"
        code, report = rehearsal.rehearse(argparse.Namespace(
            dump=str(self.dumps[fixture]), out_dir=str(out), restore=restore,
            allowlist=str(allowlist), label=fixture,
        ))
        self.assertTrue(report["cluster_descartado"], report)
        return code, report

    def test_canonical_upgrade_is_exact_and_the_same_dump_rolls_back(self) -> None:
        code, report = self._rehearse("canonico")
        steps = report["etapas"]
        self.assertEqual((code, report["resultado"]), (0, "PASS"), json.dumps(report)[:4000])
        self.assertEqual(steps["preflight"]["perfil"], "canonico")
        self.assertEqual(report["antes"]["ultima"], "058")
        self.assertTrue(steps["preflight"]["pendentes"])
        self.assertTrue(all(version > "058" for version in steps["preflight"]["pendentes"]))
        self.assertTrue(steps["upgrade"]["ledger"]["igual_ao_da_base"])
        # Pós-checagem exata: nenhuma diferença contra o banco novo deste código.
        self.assertTrue(steps["pos_checagem"]["exata"], steps["pos_checagem"])
        self.assertGreaterEqual(steps["base"]["catalogo"]["colunas"], 900)
        self.assertGreaterEqual(steps["base"]["catalogo"]["gatilhos"], 40)
        payload = steps["payload"]
        self.assertEqual(payload["iguais"], payload["tabelas"])
        self.assertGreaterEqual(payload["linhas"], 15)
        self.assertTrue(steps["reaplicacao"]["sem_mudanca"])
        self.assertTrue(steps["rollback_por_restore"]["identico_a_antes"])
        self.assertTrue(steps["reforward"]["igual_ao_upgrade"])

    def test_live_drift_upgrade_leaves_only_the_closed_list(self) -> None:
        self.assertGreaterEqual(len(self.drift_groups), 100)
        code, report = self._rehearse("deriva")
        check = report["etapas"]["pos_checagem"]
        self.assertEqual((code, report["resultado"]), (0, "PASS"), json.dumps(check)[:4000])
        self.assertEqual(check["inesperadas"], [])
        self.assertGreaterEqual(check["aceitas"], 150)
        allowlist = json.loads(ALLOWLIST.read_text(encoding="utf-8"))
        # O que as migrations reconciliam some depois do upgrade.
        reconciled = allowlist["reconciliado_pelas_migrations"]
        self.assertFalse({"public." + name for name in reconciled["064"] + reconciled["065"]}
                         & {entry["objeto"] for entry in allowlist["itens"]})
        # Só fica sem ocorrência o que o fixture não reproduz sem a produção.
        not_modeled = {label.split(" ", 2)[2] for label, _ in self.not_modeled}
        self.assertTrue(
            {entry["objeto"] for entry in check["entradas_sem_ocorrencia"]} <= not_modeled,
            check["entradas_sem_ocorrencia"],
        )
        steps = report["etapas"]
        self.assertEqual(steps["payload"]["iguais"], steps["payload"]["tabelas"])
        self.assertTrue(steps["rollback_por_restore"]["identico_a_antes"])
        self.assertTrue(steps["reforward"]["igual_ao_upgrade"])

    def test_structure_mode_restores_only_the_ledger(self) -> None:
        code, report = self._rehearse("deriva", restore="estrutura")
        self.assertEqual((code, report["resultado"]), (0, "PASS"))
        self.assertEqual(report["etapas"]["restauracao_antes"]["tabelas_com_linhas"],
                         ["public.schema_migrations"])
        self.assertEqual(report["antes"]["linhas"], 0)

    def test_mixed_profiles_stop_before_any_ddl_and_leave_the_database_as_it_was(self) -> None:
        for name, (_statement, reason) in MIXED.items():
            with self.subTest(perfil=name):
                code, report = self._rehearse(name)
                preflight = report["etapas"]["preflight"]
                self.assertEqual((code, report["resultado"]), (3, "BLOCKED"), preflight)
                self.assertEqual(preflight["perfil"], "misto")
                self.assertTrue(any(reason in item for item in preflight["motivos"]),
                                preflight["motivos"])
                self.assertTrue(preflight["banco_intacto"])
                # O migrate de verdade também para com 3, sem escrever nada.
                self.assertEqual(preflight["migrate_recusou_com"], 3)
                self.assertTrue(preflight["intacto_depois_do_migrate"])
                self.assertNotIn("upgrade", report["etapas"])

    def test_drift_outside_the_closed_list_fails(self) -> None:
        allowlist = json.loads(ALLOWLIST.read_text(encoding="utf-8"))
        allowlist["itens"] = [entry for entry in allowlist["itens"]
                              if entry["objeto"] != "public.uq_binder_user_card_cond_foil_list"]
        narrower = self.work / "lista_sem_uq_binder.json"
        narrower.write_text(json.dumps(allowlist), encoding="utf-8")
        code, report = self._rehearse("deriva", allowlist=narrower)
        self.assertEqual((code, report["resultado"]), (1, "FAIL"))
        unexpected = report["etapas"]["pos_checagem"]["inesperadas"]
        self.assertEqual([item["objeto"] for item in unexpected],
                         ["public.uq_binder_user_card_cond_foil_list"])


if __name__ == "__main__":
    unittest.main()
