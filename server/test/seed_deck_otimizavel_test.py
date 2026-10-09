#!/usr/bin/env python3
"""Seed do deck otimizavel: transacao unica e guarda de banco descartavel.

BT-UIEV-001. `scripts/lib/manaloom_seed_deck_otimizavel.sql` apaga as linhas
de `deck_cards` do deck informado, grava cartas sinteticas de id fixo e
legalidades, e tem duas conferencias (`DO` com `RAISE EXCEPTION`) que param a
corrida. Este teste le o arquivo, sem banco, e exige a forma que garante
"recusou ou falhou, nao sobrou nada":

- o unico metacomando do psql no arquivo e `\\set ON_ERROR_STOP on`, uma vez
  so, antes do `BEGIN` (lista fechada, `METACOMANDOS_PERMITIDOS`);
- o primeiro comando SQL e `BEGIN` e o ultimo e `COMMIT`;
- logo depois do `BEGIN`, antes de qualquer escrita, a guarda de banco
  descartavel: `SET manaloom.seed_descartavel = :'descartavel'` e o bloco
  `DO $guarda_descartavel$`, que recusa sem `-v descartavel=sim` e recusa
  conexao TCP fora de loopback;
- nenhum outro controle de transacao no meio;
- as duas conferencias ficam entre o `BEGIN` e o `COMMIT`.

Por que a lista de metacomandos e fechada. Medido em 2026-10-08 num
PostgreSQL 17 descartavel, com uma conferencia reprovada (legalidades
apagadas) e o deck ja populado com uma linha:

- `\\set ON_ERROR_STOP off` antes do `BEGIN`, com `psql -X` (configuracao
  padrao): o psql segue depois do erro, os comandos seguintes falham com
  "current transaction is aborted" e o `COMMIT` da transacao abortada vira
  `ROLLBACK`. Nada e gravado, mas a corrida termina com codigo 0: a falha
  passa em silencio;
- o mesmo arquivo sem `-X` e com `ON_ERROR_ROLLBACK on` no psqlrc: cada erro
  desfaz so o proprio comando, a transacao segue e o `COMMIT` confirma o
  resto -- codigo 0 com o deck reprovado gravado (100 linhas de `deck_cards`
  e 111 cartas sinteticas);
- com o `\\set ON_ERROR_STOP on` intacto, `ON_ERROR_ROLLBACK on` (no arquivo
  ou no psqlrc) nao mudou nada: codigo 3, nenhuma linha do seed e o deck
  intacto. A lista recusa
  `\\set ON_ERROR_ROLLBACK on` no arquivo mesmo assim: o seed nao precisa de
  outro metacomando, e cada um a mais e um jeito novo de mudar o que
  acontece no erro.

Para o psql, barra invertida fora de comentario, string, identificador entre
aspas e corpo `$tag$` e metacomando em QUALQUER ponto da linha, inclusive no
meio de um comando SQL -- medido: `SELECT 1; \\set ON_ERROR_STOP off` e um
`\\set ON_ERROR_STOP off` entre as linhas de um `SELECT` desligam a parada no
erro. Por isso o divisor abaixo conta todas, nao so as que abrem a linha.

A prova de comportamento (codigos e contagens no PostgreSQL 17 descartavel)
fica nos commits que trouxeram a transacao e a guarda; aqui fica a forma,
para ela nao regredir em silencio.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SEED_PATH = REPO_ROOT / "scripts" / "lib" / "manaloom_seed_deck_otimizavel.sql"

# Lista fechada. Acrescentar um metacomando aqui exige provar, num PostgreSQL
# descartavel, que ele nao muda o que acontece num erro (ver o topo).
METACOMANDOS_PERMITIDOS = ("\\set ON_ERROR_STOP on",)

_DOLAR = re.compile(r"\$([A-Za-z_][A-Za-z0-9_]*)?\$")
_CONTROLE_DE_TRANSACAO = {
    "ABORT", "BEGIN", "COMMIT", "END", "PREPARE", "RELEASE", "ROLLBACK",
    "SAVEPOINT", "START",
}
_ESCRITA = {
    "ALTER", "CALL", "CLUSTER", "COMMENT", "COPY", "CREATE", "DELETE",
    "DROP", "GRANT", "IMPORT", "INSERT", "LOCK", "MERGE", "REFRESH",
    "REINDEX", "REVOKE", "SECURITY", "TRUNCATE", "UPDATE", "VACUUM", "WITH",
}
_SET_DESCARTAVEL = "SET manaloom.seed_descartavel = :'descartavel'"


def comandos(sql: str) -> list[tuple[str, str]]:
    """Divide o arquivo em comandos de topo, na ordem em que o psql os ve.

    Devolve `("meta", texto)` para metacomando do psql -- barra invertida
    fora de comentario, string, identificador entre aspas e corpo
    `$tag$ ... $tag$`, em qualquer ponto da linha, ate o fim dela -- e
    `("sql", texto)` para comando terminado em `;`. Um metacomando no meio de
    um comando SQL sai antes dele, que e quando o psql o executa.
    """
    saida: list[tuple[str, str]] = []
    atual: list[str] = []
    i, n = 0, len(sql)
    while i < n:
        c = sql[i]
        if c == "\\":
            fim = sql.find("\n", i)
            fim = n if fim < 0 else fim
            saida.append(("meta", sql[i:fim].strip()))
            i = fim
            continue
        if sql.startswith("--", i):
            fim = sql.find("\n", i)
            i = n if fim < 0 else fim
            continue
        if sql.startswith("/*", i):
            fim = sql.find("*/", i + 2)
            if fim < 0:
                raise ValueError("comentario /* sem fim")
            i = fim + 2
            continue
        if (c in "eE" and sql.startswith("'", i + 1)
                and (i == 0 or not (sql[i - 1].isalnum()
                                    or sql[i - 1] in "_$"))):
            # Em E'...' a barra invertida escapa a aspa; este divisor nao
            # modela isso, entao recusa em vez de dividir errado.
            raise ValueError("string E'...' nao suportada pelo divisor")
        if c in "'\"":
            fim = sql.find(c, i + 1)
            if fim < 0:
                raise ValueError("string ou identificador sem fim")
            atual.append(sql[i:fim + 1])
            i = fim + 1
            continue
        if c == "$":
            m = _DOLAR.match(sql, i)
            if m:
                fim = sql.find(m.group(0), m.end())
                if fim < 0:
                    raise ValueError(f"corpo {m.group(0)} sem fim")
                atual.append(sql[i:fim + len(m.group(0))])
                i = fim + len(m.group(0))
                continue
        if c == ";":
            texto = "".join(atual).strip()
            if texto:
                saida.append(("sql", texto))
            atual = []
            i += 1
            continue
        atual.append(c)
        i += 1
    if "".join(atual).strip():
        raise ValueError("comando sem ';' no fim do arquivo")
    return saida


def _palavra(texto: str) -> str:
    return texto.split(None, 1)[0].upper()


def _tag(texto: str) -> str | None:
    m = _DOLAR.search(texto)
    return m.group(0) if m else None


class SeedDeckOtimizavelTransacaoTest(unittest.TestCase):
    def setUp(self) -> None:
        self.todos = comandos(SEED_PATH.read_text(encoding="utf-8"))
        self.sql = [t for tipo, t in self.todos if tipo == "sql"]
        self.assertTrue(self.sql, "o seed nao tem comando SQL")

    def test_unico_metacomando_e_on_error_stop_on_antes_do_begin(self) -> None:
        metas = [(i, t) for i, (tipo, t) in enumerate(self.todos)
                 if tipo == "meta"]
        self.assertEqual([t for _, t in metas], list(METACOMANDOS_PERMITIDOS))
        # Primeiro de tudo: antes do BEGIN e de qualquer SQL.
        self.assertEqual(metas[0][0], 0)

    def test_primeiro_comando_sql_e_begin(self) -> None:
        self.assertEqual(self.sql[0].upper(), "BEGIN")

    def test_ultimo_comando_e_commit(self) -> None:
        tipo, texto = self.todos[-1]
        self.assertEqual((tipo, texto.upper()), ("sql", "COMMIT"))

    def test_nenhum_outro_controle_de_transacao_no_meio(self) -> None:
        meio = [t for t in self.sql[1:-1]
                if _palavra(t) in _CONTROLE_DE_TRANSACAO]
        self.assertEqual(meio, [])

    def test_guarda_de_banco_descartavel_logo_depois_do_begin(self) -> None:
        self.assertGreaterEqual(len(self.sql), 3)
        self.assertEqual(self.sql[1], _SET_DESCARTAVEL)
        guarda = self.sql[2]
        self.assertEqual(_palavra(guarda), "DO")
        self.assertEqual(_tag(guarda), "$guarda_descartavel$")
        for trecho in (
            "current_setting('manaloom.seed_descartavel')",
            "IS DISTINCT FROM 'sim'",
            "inet_server_addr()",
            "'127.0.0.0/8'::inet",
            "'::1/128'::inet",
        ):
            self.assertIn(trecho, guarda)
        self.assertEqual(guarda.count("RAISE EXCEPTION"), 2)
        primeira_escrita = next(
            (i for i, t in enumerate(self.sql) if _palavra(t) in _ESCRITA),
            None)
        self.assertIsNotNone(primeira_escrita, "o seed nao escreve nada?")
        self.assertGreater(primeira_escrita, 2)

    def test_conferencias_e_guarda_param_dentro_da_transacao(self) -> None:
        blocos = [
            _tag(t) for t in self.sql[1:-1]
            if _palavra(t) == "DO" and "RAISE EXCEPTION" in t
        ]
        self.assertEqual(
            sorted(blocos),
            ["$conferencia_deck$", "$conferencia_pool$",
             "$guarda_descartavel$"],
        )

    def test_divisor_respeita_corpo_dolar_string_e_comentario(self) -> None:
        exemplo = (
            "\\set ON_ERROR_STOP on\n"
            "BEGIN;\n"
            "-- COMMIT; e \\set ON_ERROR_STOP off em comentario nao contam\n"
            "SELECT ';' || $x$ COMMIT; \\set x $x$ AS \"a;\\b\";\n"
            "DO $b$ BEGIN RAISE EXCEPTION 'x;\\'; END $b$;\n"
            "COMMIT;\n"
        )
        self.assertEqual(
            [(tipo, _palavra(t)) for tipo, t in comandos(exemplo)],
            [("meta", "\\SET"), ("sql", "BEGIN"), ("sql", "SELECT"),
             ("sql", "DO"), ("sql", "COMMIT")],
        )

    def test_divisor_conta_metacomando_no_meio_da_linha_e_do_comando(
            self) -> None:
        exemplo = (
            "BEGIN; \\set ON_ERROR_STOP off\n"
            "DELETE FROM t\n"
            "  \\set ON_ERROR_ROLLBACK on\n"
            "WHERE id = 1;\n"
        )
        self.assertEqual(
            comandos(exemplo),
            [("sql", "BEGIN"),
             ("meta", "\\set ON_ERROR_STOP off"),
             ("meta", "\\set ON_ERROR_ROLLBACK on"),
             ("sql", "DELETE FROM t\n  \nWHERE id = 1")],
        )

    def test_divisor_recusa_string_e(self) -> None:
        with self.assertRaises(ValueError):
            comandos("SELECT E'a\\'; \\set x';\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
