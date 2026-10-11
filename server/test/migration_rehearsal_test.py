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

    def test_a_row_rule_needs_its_fields(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "lista.json"
            broken = copy.deepcopy(self.allowlist)
            broken["payload"] = [
                {"tabela": "public.sets", "migration": "077", "motivo": "m",
                 "regra": "fusao_por_lower_code", "chave": "code", "campos_herdados": []},
                {"tabela": "public.x", "migration": "077", "motivo": "m", "regra": "outra"},
            ]
            path.write_text(json.dumps(broken), encoding="utf-8")
            with self.assertRaises(rehearsal.RehearsalError) as caught:
                rehearsal.load_allowlist(path)
        message = str(caught.exception)
        self.assertIn("payload[0]: regra fusao_por_lower_code sem carimbo", message)
        self.assertIn("payload[0]: regra fusao_por_lower_code sem campos_herdados", message)
        self.assertIn("payload[1]: regra desconhecida outra", message)


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

    def test_a_declared_change_with_a_rule_needs_the_row_check(self) -> None:
        before = {"public.sets": {"linhas": 3, "hash": "x"}}
        after = {"public.sets": {"linhas": 2, "hash": "y"}}
        declared = [{"tabela": "public.sets", "migration": "077", "motivo": "m",
                     "regra": "fusao_por_lower_code"}]
        unchecked = rehearsal.compare_payload(before, after, declared)
        self.assertEqual([i["tabela"] for i in unchecked["mudancas_inesperadas"]],
                         ["public.sets"])
        self.assertIn("não foi conferida", unchecked["mudancas_inesperadas"][0]["problemas"][0])
        failed = rehearsal.compare_payload(
            before, after, declared, {"public.sets": {"problemas": ["abc: mudou name"]}})
        self.assertEqual(failed["mudancas_inesperadas"][0]["problemas"], ["abc: mudou name"])
        self.assertEqual(failed["mudancas_declaradas"], [])
        passed = rehearsal.compare_payload(
            before, after, declared,
            {"public.sets": {"problemas": [], "linhas_apagadas": 1}})
        self.assertEqual(passed["mudancas_inesperadas"], [])
        self.assertEqual(passed["mudancas_declaradas"][0]["conferencia"],
                         {"linhas_apagadas": 1})

    def test_row_hash_does_not_depend_on_physical_order_and_quotes_names(self) -> None:
        tables, script = rehearsal.payload_script({'public.a"b': ["id", 'x"y']})
        self.assertEqual(tables, ['public.a"b'])
        self.assertIn("string_agg(h, '' ORDER BY h)", script)
        self.assertIn('ROW("id", "x""y")', script)
        self.assertIn('"public"."a""b"', script)
        self.assertTrue(script.startswith("BEGIN TRANSACTION READ ONLY;"))


def _set(code: str, **fields):
    row = {"code": code, "name": f"Set {code}", "release_date": None, "type": None,
           "block": None, "is_online_only": None, "is_foreign_only": None,
           "created_at": "2026-01-01T00:00:00+00:00", "updated_at": "2026-01-01T00:00:00+00:00",
           rehearsal.ROW_KEY_COLUMN: code.lower()}
    row.update(fields)
    return row


class MergeRuleTest(unittest.TestCase):
    """A regra `fusao_por_lower_code` da D-74, linha a linha, sem banco."""

    RULE = {"chave": "code", "carimbo": "updated_at",
            "campos_herdados": ["release_date", "type", "block", "is_online_only",
                                "is_foreign_only"]}

    def setUp(self) -> None:
        self.before = [_set("ABC", block="Bloco A"), _set("abc", type="expansion"),
                       _set("Abc", type="core", is_foreign_only=True), _set("LEA", type="core")]
        self.after = [_set("ABC", block="Bloco A", type="expansion",
                           updated_at="2026-10-10T00:00:00+00:00"),
                      _set("LEA", type="core")]

    def check(self, after):
        return rehearsal.check_merge_by_lower_code(self.before, after, self.RULE)

    def test_the_d74_merge_passes_with_its_counts(self) -> None:
        self.assertEqual(self.check(self.after), {
            "problemas": [], "linhas_antes": 4, "linhas_depois": 2, "linhas_apagadas": 2,
            "linhas_com_campo_herdado": 1})

    def test_nothing_to_merge_means_nothing_changes(self) -> None:
        only = [_set("LEA", type="core")]
        self.assertEqual(rehearsal.check_merge_by_lower_code(only, only, self.RULE)["problemas"], [])
        stamped = [_set("LEA", type="core", updated_at="2026-10-10T00:00:00+00:00")]
        self.assertEqual(rehearsal.check_merge_by_lower_code(only, stamped, self.RULE)["problemas"],
                         ["LEA: mudou updated_at sem fusão"])

    def test_everything_outside_the_rule_is_a_problem(self) -> None:
        cases = {
            "nome da que fica": ([_set("ABC", block="Bloco A", type="expansion", name="outro",
                                       updated_at="2026-10-10T00:00:00+00:00"),
                                  _set("LEA", type="core")],
                                 "ABC: mudou name, fora dos campos herdados"),
            "grupo sem linha": ([_set("LEA", type="core")], "grupo abc: 0 linha(s) depois"),
            "grupo com duas": (self.after + [_set("abc", type="expansion")],
                               "grupo abc: 2 linha(s) depois"),
            "linha sozinha apagada": (self.after[:1], "grupo lea: 0 linha(s) depois"),
            "linha nova": (self.after + [_set("XYZ")], "XYZ: linha nova depois do upgrade"),
            "valor sobrescrito": ([_set("ABC", block="Outro", type="expansion",
                                        updated_at="2026-10-10T00:00:00+00:00"),
                                   _set("LEA", type="core")], "ABC.block: tinha valor e mudou"),
            "valor inventado": ([_set("ABC", block="Bloco A", type="funny",
                                      updated_at="2026-10-10T00:00:00+00:00"),
                                 _set("LEA", type="core")],
                                "ABC.type: valor que nenhuma linha que saiu tinha"),
            "carimbo sem herança": ([_set("ABC", block="Bloco A",
                                          updated_at="2026-10-10T00:00:00+00:00"),
                                     _set("LEA", type="core")],
                                    "ABC.updated_at: mudou sem campo herdado"),
        }
        for label, (after, problem) in cases.items():
            with self.subTest(caso=label):
                problems = self.check(after)["problemas"]
                self.assertTrue(any(problem in item for item in problems), problems)

    def test_rows_compare_without_the_stamp(self) -> None:
        later = [dict(row, updated_at="2026-10-11T00:00:00+00:00") if row["code"] == "ABC" else row
                 for row in self.after]
        self.assertTrue(rehearsal.rows_equal_except(self.after, later, "code", "updated_at"))
        renamed = [dict(row, name="outro") if row["code"] == "ABC" else row for row in later]
        self.assertFalse(rehearsal.rows_equal_except(self.after, renamed, "code", "updated_at"))


class DedupeD74Test(unittest.TestCase):
    """O ensaio roda o dedupe do lote com as contagens que o script declara, e a
    lista fecha a regra com os mesmos campos que o script herda."""

    def test_the_rehearsal_uses_the_lot_script_and_its_declared_counts(self) -> None:
        self.assertEqual(rehearsal.DEDUPE_D74,
                         REPO_ROOT / "server" / "sql" / "lote" / "d74_dedupe_sets_lower_code.sql")
        self.assertEqual(rehearsal.lote_script_targets(rehearsal.DEDUPE_D74), [
            "referencias_levadas_para_a_linha_que_fica",
            "linhas_que_ficam_com_campo_herdado",
            "linhas_apagadas",
        ])

    def test_the_closed_list_rule_matches_the_script(self) -> None:
        allowlist = rehearsal.load_allowlist(ALLOWLIST)
        rule = {item["tabela"]: item for item in allowlist["payload"]}["public.sets"]
        self.assertEqual((rule["regra"], rule["migration"], rule["chave"], rule["carimbo"]),
                         ("fusao_por_lower_code", "077", "code", "updated_at"))
        script = rehearsal.DEDUPE_D74.read_text(encoding="utf-8")
        inherited = set(re.findall(r"(\w+) = COALESCE\(fica\.(\w+), herdado\.\2\)", script))
        self.assertEqual({column for column, _ in inherited}, set(rule["campos_herdados"]))
        self.assertIn("updated_at = CURRENT_TIMESTAMP", script)


class ClosedListTest(unittest.TestCase):
    """A lista fechada casa com a auditoria e com as migrations 064, 065, 066, 075 e 076."""

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
                if "origem" in entry:
                    # Achado de um ensaio (só nomes): o receipt tem de citar o objeto.
                    receipt = (REPO_ROOT / entry["origem"]).read_text(encoding="utf-8")
                    self.assertIn(entry["no_receipt"], receipt, key)
                    self.assertNotIn(key, audited, key)
                else:
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
        self.assertEqual(set(reconciled["066"]), adopted("066"))
        adopted_names = {"public." + name
                         for name in reconciled["064"] + reconciled["065"] + reconciled["066"]}
        # 075 e 076 (BT-DB-005) listam o objeto inteiro: a migration tem de citá-lo, e ele
        # sai da lista fechada.
        for version in ("075", "076"):
            block = migrate[migrate.index(f"version: '{version}'"):]
            for name in reconciled[version]:
                with self.subTest(reconciliado=(version, name)):
                    short = re.split(r"[.:]", name.split(": ", 1)[0].split(".", 1)[1])[-1] \
                        if ": " in name else name.rsplit(".", 1)[-1]
                    self.assertIn(short, block[:block.index("\n  ),\n")], name)
                    self.assertNotIn(name, {e["objeto"] for e in self.allowlist["itens"]})
            adopted_names |= set(reconciled[version])
        extra_tables = {e["objeto"] for e in self.allowlist["itens"]
                        if e["categoria"] == "tabelas" and e["tipo"] == "sobrando"}
        extra_tables |= set(reconciled["075"]) & set(self.audit["tabelas"]["sobrando"])
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

    def test_every_finding_of_the_structure_rehearsal_is_reconciled_or_listed(self) -> None:
        """Os achados do ensaio na estrutura do dump (receipt só com nomes) têm destino."""
        receipt = (REPO_ROOT / "docs/qa/execution/2026-09-28/"
                   "BT-DB-003-ensaio-na-estrutura-da-producao.md").read_text(encoding="utf-8")
        rows = [line for line in receipt.splitlines()
                if re.match(r"^\| (restrições|gatilhos|tipos) \|", line)]
        self.assertEqual(len(rows), 10)
        reconciled = set(self.allowlist["reconciliado_pelas_migrations"]["075"])
        listed = {e["objeto"] for e in self.allowlist["itens"]}
        for row in rows:
            name = re.findall(r"`([^`]+)`", row)[0]
            with self.subTest(achado=name):
                table = name.split(".", 1)[0].rstrip(":")
                if row.startswith("| gatilhos |"):
                    self.assertTrue(any(obj.startswith(f"public.{table}: CREATE TRIGGER")
                                        for obj in listed), name)
                else:
                    self.assertIn(f"public.{name}", reconciled | listed)


if __name__ == "__main__":
    unittest.main()
