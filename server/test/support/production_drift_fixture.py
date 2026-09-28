"""BT-DB-003: a deriva conhecida da produção, como SQL, para o ensaio de upgrade.

Lê a saída da auditoria BT-DB-001 (produção às 00:51 UTC de 2026-09-23, ainda
na 057) e monta, item por item, o SQL que leva um banco canônico na 058 à
forma da produção: schema e tabelas só de lá, colunas, chaves, índices e a
view com o texto de lá. Nada de dado da produção: só a estrutura que a
auditoria publicou. O que a 058 trouxe (as 4 colunas de snapshot de
trade_items e o ledger) fica de fora, porque a produção já tem desde a
BT-REL-000.

Cada item vira um grupo de comandos aplicado na própria transação; o que não
dá para reproduzir sem a produção (tabela renomeada, coluna com view
dependente, índice por expressão em tabela só de lá) sai como "não modelado",
com o motivo.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

AUDIT = Path("docs/qa/execution/2026-09-23/BT-DB-001-auditoria-de-schema.saida.json")
ALLOWLIST = Path("server/config/schema_drift_allowlist.json")
SNAPSHOT_058 = {
    "public.trade_items.item_snapshot",
    "public.trade_items.snapshot_captured_at",
    "public.trade_items.snapshot_schema_version",
    "public.trade_items.snapshot_status",
}
SIMPLE_KEY = re.compile(
    r'^"?([a-z_][a-z0-9_]*)"?(?:\s+(?:ASC|DESC))?(?:\s+NULLS\s+(?:FIRST|LAST))?$'
)
INDEX_HEAD = re.compile(r"^CREATE (UNIQUE )?INDEX ON ")


def _q(name: str) -> str:
    return ".".join('"' + part.replace('"', '""') + '"' for part in name.split("."))


def _named_index(name: str, definition: str) -> str:
    return INDEX_HEAD.sub(lambda m: f"CREATE {m.group(1) or ''}INDEX {_q(name)} ON ", definition)


def _index_keys(definition: str) -> list[str] | None:
    """Colunas simples do índice; nulo quando há expressão, operador ou WHERE."""
    if " WHERE " in definition:
        return None
    match = re.search(r"USING \w+ \((.*)\)$", definition)
    if not match:
        return None
    keys = []
    for part in match.group(1).split(","):
        simple = SIMPLE_KEY.match(part.strip())
        if not simple:
            return None
        keys.append(simple.group(1))
    return keys


def _creation_order(views: list[dict]) -> list[dict]:
    """Ordena as views para recriar: a que é citada por outra vem antes."""
    pending = list(views)
    ordered: list[dict] = []
    while pending:
        for view in pending:
            cites = [
                other for other in pending
                if other is not view
                and re.search(rf"\b{other['objeto'].split('.', 1)[1]}\b", view["base"])
            ]
            if not cites:
                ordered.append(view)
                pending.remove(view)
                break
        else:
            raise ValueError("views com dependência circular")
    return ordered


def drift_groups(repo_root: Path) -> tuple[list[tuple[str, list[str]]], list[tuple[str, str]]]:
    """Grupos (rótulo, comandos) na ordem de aplicação e os itens não modelados."""
    audit = json.loads((repo_root / AUDIT).read_text(encoding="utf-8"))
    diffs = audit["diferencas"]
    groups: list[tuple[str, list[str]]] = []
    skipped: list[tuple[str, str]] = []
    # As tabelas só da produção que uma migration passou a criar (a 075) nascem
    # dela nos dois bancos: o fixture não as modela, e a forma real da produção é
    # conferida pelo ensaio na estrutura do dump.
    allowlist = json.loads((repo_root / ALLOWLIST).read_text(encoding="utf-8"))
    adopted = {name for names in allowlist["reconciliado_pelas_migrations"].values()
               if isinstance(names, list) for name in names}
    extra_tables = set(diffs["tabelas"]["sobrando"]) - adopted

    for schema in diffs["schemas"]["sobrando"]:
        groups.append((f"schemas sobrando {schema}", [
            f"CREATE SCHEMA {_q(schema)}",
            f"CREATE TABLE {_q(schema + '.amostra_do_ensaio')} (id integer PRIMARY KEY)",
        ]))

    extra_indexes = [item for item in diffs["indices"]["sobrando"]
                     if item["alvo"]["tabela"] in extra_tables]
    extra_foreign_keys = [item for item in diffs["chaves_estrangeiras"]["sobrando"]
                          if item["objeto"].split(": ", 1)[0] in extra_tables]
    for table in sorted(extra_tables):
        columns: dict[str, str] = {"id": "text"}
        statements = []
        for item in extra_foreign_keys:
            if item["objeto"].startswith(table + ": "):
                column = re.match(r"FOREIGN KEY \((\w+)\)", item["alvo"]["definicao"]).group(1)
                columns[column] = "uuid"
        indexes = []
        for item in extra_indexes:
            if item["alvo"]["tabela"] != table:
                continue
            keys = _index_keys(item["alvo"]["definicao"])
            if keys is None:
                skipped.append((f"indices sobrando {item['objeto']}",
                                "índice por expressão, operador ou WHERE em tabela só da produção"))
                continue
            # gin não tem classe de operador padrão para text: a coluna vira jsonb.
            kind = "jsonb" if " USING gin " in item["alvo"]["definicao"] else "text"
            for key in keys:
                columns.setdefault(key, kind)
            indexes.append(item)
        column_sql = ", ".join(f"{_q(name)} {kind}" for name, kind in columns.items())
        statements.append(f"CREATE TABLE {_q(table)} ({column_sql})")
        for item in indexes:
            statements.append(_named_index(item["objeto"].split(".", 1)[1],
                                           item["alvo"]["definicao"]))
        for item in extra_foreign_keys:
            if item["objeto"].startswith(table + ": "):
                statements.append(
                    f"ALTER TABLE {_q(table)} ADD CONSTRAINT {_q(item['alvo']['nome'])} "
                    f"{item['alvo']['definicao']}"
                )
        groups.append((f"tabelas sobrando {table}", statements))

    for item in diffs["colunas"]["sobrando"]:
        table, column = item["objeto"].rsplit(".", 1)
        shape = item["alvo"]
        sql = f"ALTER TABLE {_q(table)} ADD COLUMN {_q(column)} {shape['tipo']}"
        if shape["default"] is not None:
            sql += f" DEFAULT {shape['default']}"
        if shape["not_null"]:
            sql += " NOT NULL"
        groups.append((f"colunas sobrando {item['objeto']}", [sql]))

    # Views que a auditoria achou divergentes e que citam a tabela: uma troca de
    # tipo de coluna exige tirá-las e recriá-las (com o texto do banco novo).
    divergent_views = [item for item in diffs["views"]["divergente"]
                       if item["base"].startswith("VIEW: ")]
    for item in diffs["colunas"]["divergente"]:
        table, column = item["objeto"].rsplit(".", 1)
        target = f"ALTER TABLE {_q(table)} ALTER COLUMN {_q(column)}"
        statements = []
        dependents = []
        if "tipo" in item:
            kind = item["tipo"][1]
            short = table.split(".", 1)[1]
            dependents = [view for view in divergent_views
                          if re.search(rf"\b{short}\b", view["base"])
                          and re.search(rf"\b{column}\b", view["base"])]
            dependents = _creation_order(dependents)
            if dependents:
                statements.append("DROP VIEW " + ", ".join(_q(view["objeto"]) for view in dependents))
            statements.append(f"{target} TYPE {kind} USING {_q(column)}::{kind}")
        if "default" in item:
            default = item["default"][1]
            statements.append(f"{target} DROP DEFAULT" if default is None
                              else f"{target} SET DEFAULT {default}")
        if "not_null" in item:
            statements.append(f"{target} {'SET' if item['not_null'][1] else 'DROP'} NOT NULL")
        statements += [f"CREATE VIEW {_q(view['objeto'])} AS {view['base'][len('VIEW: '):]}"
                       for view in dependents]
        groups.append((f"colunas divergente {item['objeto']}", statements))

    for item in diffs["indices"]["divergente"]:
        name = item["objeto"]
        base_definition, target_definition = item["definicao"]
        base_table = re.search(r" ON (\S+) USING", base_definition).group(1)
        target_table = re.search(r" ON (\S+) USING", target_definition).group(1)
        if base_table != target_table:
            skipped.append((f"indices divergente {name}",
                            "na produção o nome está em outra tabela (renomeada)"))
            continue
        if name.endswith("_pkey"):
            keys = _index_keys(target_definition)
            groups.append((f"indices divergente {name}", [
                f"ALTER TABLE {_q(base_table)} DROP CONSTRAINT {_q(name.split('.', 1)[1])}",
                f"ALTER TABLE {_q(base_table)} ADD CONSTRAINT {_q(name.split('.', 1)[1])} "
                f"PRIMARY KEY ({', '.join(_q(key) for key in keys)})",
            ]))
        else:
            groups.append((f"indices divergente {name}", [
                f"DROP INDEX {_q(name)}",
                _named_index(name.split(".", 1)[1], target_definition),
            ]))

    for item in diffs["colunas"]["faltando"]:
        if item["objeto"] in SNAPSHOT_058:
            continue
        table, column = item["objeto"].rsplit(".", 1)
        groups.append((f"colunas faltando {item['objeto']}",
                       [f"ALTER TABLE {_q(table)} DROP COLUMN {_q(column)}"]))

    for item in diffs["indices"]["faltando"]:
        groups.append((f"indices faltando {item['objeto']}", [f"DROP INDEX {_q(item['objeto'])}"]))
    for item in diffs["indices"]["sobrando"]:
        if item["alvo"]["tabela"] in extra_tables | adopted:
            continue
        groups.append((f"indices sobrando {item['objeto']}",
                       [_named_index(item["objeto"].split(".", 1)[1], item["alvo"]["definicao"])]))

    for item in diffs["chaves_estrangeiras"]["faltando"]:
        table = item["objeto"].split(": ", 1)[0]
        groups.append((f"chaves_estrangeiras faltando {item['objeto']}",
                       [f"ALTER TABLE {_q(table)} DROP CONSTRAINT {_q(item['base']['nome'])}"]))
    for item in diffs["chaves_estrangeiras"]["divergente"]:
        table = item["objeto"].split(": ", 1)[0]
        base_name, target_name = item["nome"]
        groups.append((f"chaves_estrangeiras divergente {item['objeto']}", [
            f"ALTER TABLE {_q(table)} DROP CONSTRAINT {_q(base_name)}",
            f"ALTER TABLE {_q(table)} ADD CONSTRAINT {_q(target_name)} {item['definicao'][1]}",
        ]))

    for item in diffs["views"]["divergente"]:
        definition = item["alvo"]
        if not definition.startswith("VIEW: "):
            skipped.append((f"views divergente {item['objeto']}", "não é VIEW"))
            continue
        groups.append((f"views divergente {item['objeto']}", [
            f"CREATE OR REPLACE VIEW {_q(item['objeto'])} AS {definition[len('VIEW: '):]}"
        ]))
    return groups, skipped
