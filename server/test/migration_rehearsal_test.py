#!/usr/bin/env python3
"""BT-DB-003: as partes do ensaio de upgrade que não precisam de PostgreSQL.

Normalização do catálogo (chaves estáveis entre bancos), comparação,
classificação contra a lista fechada da deriva, comparação do payload e a
própria lista: cada item vem da auditoria BT-DB-001, e o que a auditoria
achou está na lista, coberto por uma tabela ou um schema da lista, ou
reconciliado por uma migration.
"""

from __future__ import annotations

import copy
import importlib.util
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
ALLOWLIST = REPO_ROOT / "server" / "config" / "schema_drift_allowlist.json"
AUDIT = REPO_ROOT / "docs" / "qa" / "execution" / "2026-09-23" / "BT-DB-001-auditoria-de-schema.saida.json"
MIGRATE = REPO_ROOT / "server" / "bin" / "migrate.dart"


def _load():
    path = REPO_ROOT / "scripts" / "manaloom_migration_rehearsal.py"
    spec = importlib.util.spec_from_file_location("bt_db_003_rehearsal_unit", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


rehearsal = _load()


def _raw(**overrides):
    raw = {
        "schemas": ["public"],
        "extensoes": {"plpgsql": "1.0"},
        "tabelas": ["public.decks", "public.trade_items"],
        "colunas": [
            ["public", "decks", "id", "uuid", True, "gen_random_uuid()", "", "", 1],
            ["public", "decks", "name", "text", True, None, "", "", 2],
            ["public", "trade_items", "seq", "integer", True, None, "d", "", 1],
        ],
        "restricoes": [["public", "decks", "decks_name_check", "CHECK (name <> ''::text)"]],
        "chaves_estrangeiras": [
            ["public", "trade_items", "fk_a", "FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT"],
        ],
        "indices": [["public", "decks", "decks_pkey",
                     "CREATE UNIQUE INDEX decks_pkey ON public.decks USING btree (id)"]],
        "views": [["public", "v", "v", " SELECT 1"]],
        "funcoes": [["public", "f", "", "CREATE FUNCTION f() ...\n"]],
        "gatilhos": [["public", "trade_items", "manaloom_active_user_16423",
                      "CREATE TRIGGER manaloom_active_user_16423 BEFORE INSERT ON public.trade_items "
                      "FOR EACH ROW EXECUTE FUNCTION manaloom_require_active_user('owner_id')"]],
        "sequencias": [],
        "tipos_enum": [],
    }
    raw.update(overrides)
    return raw


class CatalogTest(unittest.TestCase):
    def test_keys_are_stable_across_databases(self) -> None:
        catalog = rehearsal.normalize_catalog(_raw(), {"001": "a"})
        self.assertEqual(catalog["colunas"]["public.trade_items.seq"]["default"],
                         "IDENTITY BY DEFAULT")
        self.assertEqual(catalog["indices"]["public.decks_pkey"]["definicao"],
                         "CREATE UNIQUE INDEX ON public.decks USING btree (id)")
        self.assertIn("public.trade_items: FOREIGN KEY (owner_id) REFERENCES users(id)",
                      catalog["chaves_estrangeiras"])
        # O gatilho de conta ativa leva o OID da chave no nome (038): some da chave.
        other = rehearsal.normalize_catalog(_raw(gatilhos=[[
            "public", "trade_items", "manaloom_active_user_99",
            "CREATE TRIGGER manaloom_active_user_99 BEFORE INSERT ON public.trade_items "
            "FOR EACH ROW EXECUTE FUNCTION manaloom_require_active_user('owner_id')"]]),
            {"001": "a"})
        self.assertEqual(catalog["gatilhos"], other["gatilhos"])
        self.assertEqual(catalog["_ordem_das_colunas"]["public.decks"], ["id", "name"])

    def test_diff_reports_missing_extra_and_divergent(self) -> None:
        base = rehearsal.normalize_catalog(_raw(), {"001": "a"})
        target = copy.deepcopy(base)
        target["tabelas"].append("public.posts")
        target["colunas"]["public.decks.name"]["not_null"] = False
        del target["indices"]["public.decks_pkey"]
        target["ledger"]["002"] = "b"
        diff = rehearsal.diff_catalogs(base, target)
        self.assertEqual([i["objeto"] for i in diff["tabelas"]["sobrando"]], ["public.posts"])
        self.assertEqual([i["objeto"] for i in diff["colunas"]["divergente"]], ["public.decks.name"])
        self.assertEqual([i["objeto"] for i in diff["indices"]["faltando"]], ["public.decks_pkey"])
        self.assertEqual([i["objeto"] for i in diff["ledger"]["sobrando"]], ["002"])
        self.assertEqual(rehearsal.count_differences(diff), 4)
        self.assertEqual(rehearsal.count_differences(rehearsal.diff_catalogs(base, base)), 0)


class ClassificationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.allowlist = {"schema_version": 1, "itens": [
            {"categoria": "schemas", "tipo": "sobrando", "objeto": "audit",
             "motivo": "m", "decisao": "D-49"},
            {"categoria": "tabelas", "tipo": "sobrando", "objeto": "public.posts",
             "motivo": "m", "decisao": "D-49"},
            {"categoria": "colunas", "tipo": "divergente", "objeto": "public.decks.name",
             "motivo": "m", "decisao": "D-67"},
            {"categoria": "indices", "tipo": "sobrando", "objeto": "public.nunca_visto",
             "motivo": "m", "decisao": "x"},
        ], "payload": []}

    def _diff(self, **items):
        diff = {category: {"faltando": [], "sobrando": [], "divergente": []}
                for category in rehearsal.CATEGORIES}
        for key, value in items.items():
            category, kind = key.split("__")
            diff[category][kind] = value
        return diff

    def test_exact_schema_and_table_entries_cover_what_is_inside(self) -> None:
        diff = self._diff(
            schemas__sobrando=[{"objeto": "audit"}],
            tabelas__sobrando=[{"objeto": "audit.x"}, {"objeto": "public.posts"}],
            colunas__sobrando=[{"objeto": "public.posts.body", "alvo": {}}],
            indices__sobrando=[{"objeto": "public.posts_pkey",
                                "alvo": {"tabela": "public.posts", "definicao": "d"}}],
            chaves_estrangeiras__sobrando=[{"objeto": "public.posts: FOREIGN KEY (a) REFERENCES b(id)",
                                            "alvo": ["x"]}],
            restricoes__sobrando=[{"objeto": "public.posts.posts_check", "alvo": "CHECK (x)"}],
            gatilhos__sobrando=[{"objeto": "public.posts: CREATE TRIGGER <gatilho> ...", "alvo": True}],
            sequencias__sobrando=[{"objeto": "public.posts_id_seq", "alvo": []}],
            colunas__divergente=[{"objeto": "public.decks.name", "base": 1, "alvo": 2}],
        )
        result = rehearsal.classify_differences(diff, self.allowlist)
        self.assertEqual(result["inesperadas"], [])
        self.assertEqual(len(result["aceitas"]), 10)
        self.assertEqual([e["objeto"] for e in result["entradas_sem_ocorrencia"]],
                         ["public.nunca_visto"])

    def test_anything_else_is_unexpected(self) -> None:
        diff = self._diff(
            tabelas__faltando=[{"objeto": "public.posts", "base": True}],
            colunas__divergente=[{"objeto": "public.decks.format", "base": 1, "alvo": 2}],
            indices__sobrando=[{"objeto": "public.idx_x",
                                "alvo": {"tabela": "public.decks", "definicao": "d"}}],
        )
        result = rehearsal.classify_differences(diff, self.allowlist)
        self.assertEqual(sorted(i["objeto"] for i in result["inesperadas"]),
                         ["public.decks.format", "public.idx_x", "public.posts"])

    def test_allowlist_entries_need_reason_and_decision(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "lista.json"
            broken = copy.deepcopy(self.allowlist)
            broken["itens"][0]["motivo"] = ""
            broken["itens"][1]["categoria"] = "gatilho"
            broken["payload"] = [{"tabela": "public.decks"}]
            path.write_text(json.dumps(broken), encoding="utf-8")
            with self.assertRaises(rehearsal.RehearsalError) as caught:
                rehearsal.load_allowlist(path)
        message = str(caught.exception)
        self.assertIn("itens[0] sem motivo", message)
        self.assertIn("categoria desconhecida gatilho", message)
        self.assertIn("payload[0] sem migration, motivo", message)


class PayloadTest(unittest.TestCase):
    def test_changed_rows_are_caught_unless_declared(self) -> None:
        before = {"public.a": {"linhas": 2, "hash": "x"}, "public.b": {"linhas": 1, "hash": "y"},
                  "public.c": {"linhas": 1, "hash": "z"}}
        after = {"public.a": {"linhas": 2, "hash": "x"}, "public.b": {"linhas": 1, "hash": "w"},
                 "public.c": {"ausente": True}}
        result = rehearsal.compare_payload(before, after, [])
        self.assertEqual(result["iguais"], 1)
        self.assertEqual([i["tabela"] for i in result["mudancas_inesperadas"]],
                         ["public.b", "public.c"])
        declared = rehearsal.compare_payload(
            before, after, [{"tabela": "public.b", "migration": "074", "motivo": "m"}])
        self.assertEqual([i["tabela"] for i in declared["mudancas_declaradas"]], ["public.b"])
        self.assertEqual([i["tabela"] for i in declared["mudancas_inesperadas"]], ["public.c"])

    def test_row_hash_does_not_depend_on_physical_order_and_quotes_names(self) -> None:
        tables, script = rehearsal.payload_script({'public.a"b': ["id", 'x"y']})
        self.assertEqual(tables, ['public.a"b'])
        self.assertIn("string_agg(h, '' ORDER BY h)", script)
        self.assertIn('ROW("id", "x""y")', script)
        self.assertIn('"public"."a""b"', script)
        self.assertTrue(script.startswith("BEGIN TRANSACTION READ ONLY;"))


class ClosedListTest(unittest.TestCase):
    """A lista fechada casa com a auditoria e com as migrations 064 e 065."""

    def setUp(self) -> None:
        self.allowlist = rehearsal.load_allowlist(ALLOWLIST)
        self.audit = json.loads(AUDIT.read_text(encoding="utf-8"))["diferencas"]
        self.entries = {(e["categoria"], e["tipo"], e["objeto"]): e
                        for e in self.allowlist["itens"]}

    def test_every_entry_comes_from_the_audit_or_says_it_is_inferred(self) -> None:
        audited = {(category, kind, item if isinstance(item, str) else item["objeto"])
                   for category, kinds in self.audit.items() for kind, items in kinds.items()
                   for item in items}
        for key, entry in self.entries.items():
            with self.subTest(entrada=key):
                self.assertTrue(key in audited or entry["motivo"].startswith("inferido"), key)
        self.assertEqual(self.allowlist["status"], "proposta_pendente_do_dono")

    def test_every_audited_difference_is_listed_covered_or_reconciled(self) -> None:
        migrate = MIGRATE.read_text(encoding="utf-8")

        def adopted(version: str) -> set[str]:
            # O bloco da migration vai até a próxima versão da lista (ou o fim dela).
            start = migrate.index(f"version: '{version}'")
            following = re.search(r"version: '\d{3}'|\n\];", migrate[start + 14:])
            block = migrate[start:start + 14 + following.start()]
            return set(re.findall(r"INDEX IF NOT EXISTS ([a-z0-9_]+)", block))

        reconciled = self.allowlist["reconciliado_pelas_migrations"]
        self.assertEqual(set(reconciled["064"]), adopted("064"))
        self.assertEqual(set(reconciled["065"]), adopted("065"))
        adopted_names = {"public." + name for name in reconciled["064"] + reconciled["065"]}
        extra_tables = {e["objeto"] for e in self.allowlist["itens"]
                        if e["categoria"] == "tabelas" and e["tipo"] == "sobrando"}
        since_058 = {"public.trade_items.item_snapshot", "public.trade_items.snapshot_captured_at",
                     "public.trade_items.snapshot_schema_version",
                     "public.trade_items.snapshot_status", "058"}
        by_migration = {"public.commander_learning_snapshot",
                        "public.trade_items: FOREIGN KEY (owner_id) REFERENCES users(id)"}
        for category, kinds in self.audit.items():
            mine = "ledger" if category == "ledger_schema_migrations" else category
            for kind, items in kinds.items():
                for item in items:
                    name = item if isinstance(item, str) else item["objeto"]
                    if name in since_058 or name in by_migration or name in adopted_names:
                        continue
                    owner = (item.get("alvo") or {}).get("tabela") if category == "indices" \
                        and isinstance(item, dict) else name.split(": ", 1)[0]
                    if kind == "sobrando" and owner in extra_tables:
                        continue
                    with self.subTest(diferenca=(mine, kind, name)):
                        self.assertIn((mine, kind, name), self.entries)


if __name__ == "__main__":
    unittest.main()
