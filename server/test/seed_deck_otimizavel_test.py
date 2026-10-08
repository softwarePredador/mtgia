#!/usr/bin/env python3
"""Seed do deck otimizavel roda numa transacao so (BT-UIEV-001).

`scripts/lib/manaloom_seed_deck_otimizavel.sql` grava cartas sinteticas,
legalidades e `deck_cards`, e tem duas conferencias (`DO` com
`RAISE EXCEPTION`) que param a corrida. Sem transacao, cada comando era
confirmado sozinho e uma conferencia reprovada deixava o deck reprovado
gravado no banco. Este teste le o arquivo, sem banco, e exige a forma que
garante "falhou, nao sobrou nada":

- `\\set ON_ERROR_STOP on` antes de qualquer SQL, e nenhum metacomando do
  psql depois do `BEGIN` (um `\\set ON_ERROR_STOP off` no meio deixaria o
  `COMMIT` confirmar o que veio antes do erro);
- o primeiro comando SQL e `BEGIN` e o ultimo e `COMMIT`;
- nenhum outro controle de transacao no meio;
- as duas conferencias ficam entre o `BEGIN` e o `COMMIT`.

A prova de comportamento (codigo 3 e zero linhas do seed num PostgreSQL 17
descartavel) fica no commit que trouxe a transacao; aqui fica a forma, para
ela nao regredir em silencio.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SEED_PATH = REPO_ROOT / "scripts" / "lib" / "manaloom_seed_deck_otimizavel.sql"

_DOLAR = re.compile(r"\$([A-Za-z_][A-Za-z0-9_]*)?\$")
_CONTROLE_DE_TRANSACAO = {
    "ABORT", "BEGIN", "COMMIT", "END", "PREPARE", "RELEASE", "ROLLBACK",
    "SAVEPOINT", "START",
}


def comandos(sql: str) -> list[tuple[str, str]]:
    """Divide o arquivo em comandos de topo, na ordem.

    Devolve `("meta", texto)` para metacomando do psql (linha que comeca com
    barra invertida) e `("sql", texto)` para comando terminado em `;` fora de
    comentario, string e corpo `$tag$ ... $tag$`.
    """
    saida: list[tuple[str, str]] = []
    atual: list[str] = []
    i, n = 0, len(sql)
    while i < n:
        c = sql[i]
        if c == "\\" and not "".join(atual).strip():
            fim = sql.find("\n", i)
            fim = n if fim < 0 else fim
            saida.append(("meta", sql[i:fim].strip()))
            atual = []
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
        if c == "'":
            fim = sql.find("'", i + 1)
            if fim < 0:
                raise ValueError("string sem fim")
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


class SeedDeckOtimizavelTransacaoTest(unittest.TestCase):
    def setUp(self) -> None:
        self.todos = comandos(SEED_PATH.read_text(encoding="utf-8"))
        self.sql = [t for tipo, t in self.todos if tipo == "sql"]
        self.assertTrue(self.sql, "o seed nao tem comando SQL")

    def test_on_error_stop_vem_antes_de_qualquer_sql(self) -> None:
        tipo, texto = self.todos[0]
        self.assertEqual(tipo, "meta")
        self.assertEqual(texto.split(), ["\\set", "ON_ERROR_STOP", "on"])

    def test_primeiro_comando_sql_e_begin(self) -> None:
        self.assertEqual(self.sql[0].upper(), "BEGIN")

    def test_ultimo_comando_e_commit(self) -> None:
        tipo, texto = self.todos[-1]
        self.assertEqual((tipo, texto.upper()), ("sql", "COMMIT"))

    def test_nenhum_outro_controle_de_transacao_no_meio(self) -> None:
        meio = [t for t in self.sql[1:-1]
                if _palavra(t) in _CONTROLE_DE_TRANSACAO]
        self.assertEqual(meio, [])

    def test_nenhum_metacomando_depois_do_begin(self) -> None:
        inicio = next((i for i, (tipo, t) in enumerate(self.todos)
                       if tipo == "sql" and t.upper() == "BEGIN"), None)
        self.assertIsNotNone(inicio, "o seed nao tem BEGIN")
        depois = [t for tipo, t in self.todos[inicio:] if tipo == "meta"]
        self.assertEqual(depois, [])

    def test_as_duas_conferencias_param_dentro_da_transacao(self) -> None:
        conferencias = [
            t for t in self.sql[1:-1]
            if _palavra(t) == "DO" and "RAISE EXCEPTION" in t
        ]
        tags = sorted(_DOLAR.search(t).group(0) for t in conferencias)
        self.assertEqual(tags, ["$conferencia_deck$", "$conferencia_pool$"])

    def test_divisor_respeita_corpo_dolar_e_string(self) -> None:
        exemplo = (
            "\\set ON_ERROR_STOP on\n"
            "BEGIN;\n"
            "-- COMMIT; em comentario nao conta\n"
            "SELECT ';' || $x$ COMMIT; $x$;\n"
            "DO $b$ BEGIN RAISE EXCEPTION 'x;'; END $b$;\n"
            "COMMIT;\n"
        )
        self.assertEqual(
            [(tipo, _palavra(t)) for tipo, t in comandos(exemplo)],
            [("meta", "\\SET"), ("sql", "BEGIN"), ("sql", "SELECT"),
             ("sql", "DO"), ("sql", "COMMIT")],
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
