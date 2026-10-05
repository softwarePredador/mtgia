#!/usr/bin/env python3
"""BT-DB-003: ensaio de upgrade e de rollback por restore do mesmo dump.

Num PostgreSQL 17 local e descartável (só loopback, sem socket e, no macOS,
dentro de sandbox-exec sem rede externa), a partir de um dump:

1. base: o banco novo deste código (server/database_setup.sql e migrate.dart),
   a referência da pós-checagem;
2. antes: o dump restaurado e nunca mexido, a referência do estado anterior;
3. ensaio: o dump restaurado de novo. Passa pelo preflight do runner (perfil
   misto para aqui, sem DDL, e o banco tem de continuar igual a antes) e pelo
   upgrade (migrate.dart);
4. pós-checagem: o catálogo do ensaio contra o da base. Cada diferença tem de
   estar na lista fechada da deriva aceita (server/config/schema_drift_allowlist.json);
5. payload: as linhas de cada tabela de antes, pelas colunas de antes, são as
   mesmas depois do upgrade, salvo mudança declarada na lista;
6. reaplicação: rodar o migrate de novo não muda nada;
7. rollback: o mesmo dump restaurado outra vez é idêntico a antes (catálogo,
   ledger e dados), e o upgrade dele chega ao mesmo estado do ensaio.

Grava rehearsal.json e rehearsal.md em --out-dir e apaga o cluster no fim. O
dump só é lido.

Uso:
  scripts/manaloom_migration_rehearsal.py --dump ARQUIVO.dump --out-dir DIR
      [--restore estrutura|completo] [--allowlist ARQUIVO] [--label NOME]

--restore estrutura (padrão) restaura só a estrutura e o ledger: nenhuma outra
tabela recebe linhas, e o script confere isso antes de seguir. --restore
completo restaura tudo e confere o payload com os dados; com um dump da
produção, é o ensaio do lote de deploy, com a palavra do dono.

Aprovação do PostgreSQL descartável: a mesma do gate tbls
(git config manaloom.localGates.disposablePostgres=true ou
MANALOOM_APPROVE_DISPOSABLE_POSTGRES=I_APPROVE_DISPOSABLE_LOCAL_POSTGRES).
As dependências de server/ precisam estar resolvidas: o Dart roda sem
`dart run`, para nunca disparar um pub get implícito.

Saída: 0 PASS; 1 FAIL (upgrade, pós-checagem, payload, reaplicação ou
rollback); 2 entrada ou ambiente recusado; 3 BLOCKED (perfil misto: o runner
recusou antes de DDL e o banco ficou igual a antes).
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import platform
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ALLOWLIST = REPO_ROOT / "server" / "config" / "schema_drift_allowlist.json"
APPROVAL_PHRASE = "I_APPROVE_DISPOSABLE_LOCAL_POSTGRES"
WRITE_PHRASE = "I_HAVE_EXPLICIT_APPROVAL"
DEFAULT_DART = (
    Path.home() / ".manaloom" / "toolchains" / "flutter-3.44.6" / "bin" / "cache"
    / "dart-sdk" / "bin" / "dart"
)
SANDBOX_PROFILE = """(version 1)
(allow default)
(deny network*)
(allow network-outbound (remote ip "localhost:*"))
(allow network-inbound (local ip "localhost:*"))"""
CATEGORIES = (
    "schemas",
    "extensoes",
    "tabelas",
    "colunas",
    "restricoes",
    "chaves_estrangeiras",
    "indices",
    "views",
    "funcoes",
    "gatilhos",
    "sequencias",
    "tipos_enum",
    "ledger",
)
LEDGER_TABLE = "public.schema_migrations"
USER_SCHEMA = (
    "n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname !~ '^pg_'"
)
# Cada consulta devolve uma linha com um jsonb (sem quebra de linha).
CATALOG_QUERIES = {
    "schemas": f"""
        SELECT COALESCE(jsonb_agg(n.nspname ORDER BY n.nspname), '[]')
        FROM pg_namespace n WHERE {USER_SCHEMA}""",
    "extensoes": """
        SELECT COALESCE(jsonb_object_agg(extname, extversion), '{}') FROM pg_extension""",
    "tabelas": f"""
        SELECT COALESCE(jsonb_agg(n.nspname || '.' || c.relname), '[]')
        FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r', 'p') AND {USER_SCHEMA}""",
    "colunas": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 n.nspname, c.relname, a.attname, format_type(a.atttypid, a.atttypmod),
                 a.attnotnull, pg_get_expr(d.adbin, d.adrelid), a.attidentity::text,
                 a.attgenerated::text, a.attnum) ORDER BY n.nspname, c.relname, a.attnum), '[]')
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
        WHERE c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped
          AND {USER_SCHEMA}""",
    "restricoes": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 n.nspname, c.relname, con.conname, pg_get_constraintdef(con.oid, true))), '[]')
        FROM pg_constraint con
        JOIN pg_class c ON c.oid = con.conrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE con.contype IN ('c', 'x') AND {USER_SCHEMA}""",
    "chaves_estrangeiras": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 n.nspname, c.relname, con.conname, pg_get_constraintdef(con.oid, true))), '[]')
        FROM pg_constraint con
        JOIN pg_class c ON c.oid = con.conrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE con.contype = 'f' AND {USER_SCHEMA}""",
    "indices": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 n.nspname, t.relname, i.relname, pg_get_indexdef(i.oid))), '[]')
        FROM pg_index x
        JOIN pg_class i ON i.oid = x.indexrelid
        JOIN pg_class t ON t.oid = x.indrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE {USER_SCHEMA}""",
    "views": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 n.nspname, c.relname, c.relkind::text, pg_get_viewdef(c.oid, true))), '[]')
        FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('v', 'm') AND {USER_SCHEMA}""",
    "funcoes": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 n.nspname, p.proname, pg_get_function_identity_arguments(p.oid),
                 pg_get_functiondef(p.oid))), '[]')
        FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.prokind IN ('f', 'p') AND {USER_SCHEMA}
          AND NOT EXISTS (SELECT 1 FROM pg_depend e
                          WHERE e.classid = 'pg_proc'::regclass AND e.objid = p.oid
                            AND e.deptype = 'e')""",
    "gatilhos": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 n.nspname, c.relname, g.tgname, pg_get_triggerdef(g.oid, true))), '[]')
        FROM pg_trigger g
        JOIN pg_class c ON c.oid = g.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE NOT g.tgisinternal AND {USER_SCHEMA}""",
    "sequencias": """
        SELECT COALESCE(jsonb_agg(jsonb_build_array(
                 schemaname, sequencename, data_type::text, start_value, min_value,
                 max_value, increment_by, cycle)), '[]')
        FROM pg_sequences
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')""",
    "tipos_enum": f"""
        SELECT COALESCE(jsonb_agg(jsonb_build_array(n.nspname, t.typname, (
                 SELECT jsonb_agg(e.enumlabel ORDER BY e.enumsortorder)
                 FROM pg_enum e WHERE e.enumtypid = t.oid))), '[]')
        FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typtype = 'e' AND {USER_SCHEMA}""",
    "tem_ledger": """
        SELECT to_jsonb(to_regclass('public.schema_migrations') IS NOT NULL)""",
}
# Os gatilhos de conta ativa levam o OID da chave no nome (migration 038), que
# muda de um banco para outro: o gatilho é identificado pela definição sem o nome.
TRIGGER_NAME = re.compile(r"^(CREATE (?:CONSTRAINT )?TRIGGER )(\"[^\"]+\"|\S+)")
INDEX_NAME = re.compile(r'INDEX\s+("[^"]+"|\S+)\s+ON\s+')
FOREIGN_KEY_CORE = re.compile(r"^FOREIGN KEY \([^)]*\) REFERENCES [^(]+\([^)]*\)")


class RehearsalError(Exception):
    """Entrada ou ambiente recusado: código 2."""


# ---------------------------------------------------------------- catálogo


def normalize_catalog(raw: dict[str, Any], ledger: dict[str, str] | None) -> dict[str, Any]:
    """Transforma as linhas do catálogo em chaves estáveis entre bancos.

    As chaves seguem a auditoria da BT-DB-001 (server/bin/schema_audit.dart):
    tabela `schema.tabela`, coluna `schema.tabela.coluna`, índice
    `schema.nome` e chave estrangeira pela assinatura sem as ações.
    """
    catalog: dict[str, Any] = {
        "schemas": sorted(raw["schemas"]),
        "extensoes": dict(sorted(raw["extensoes"].items())),
        "tabelas": sorted(raw["tabelas"]),
    }
    columns: dict[str, Any] = {}
    order: dict[str, list[str]] = {}
    for schema, table, column, kind, not_null, default, identity, generated, _ in raw["colunas"]:
        if identity:
            default = "IDENTITY ALWAYS" if identity == "a" else "IDENTITY BY DEFAULT"
        elif generated:
            default = f"GENERATED ALWAYS AS ({default}) STORED"
        columns[f"{schema}.{table}.{column}"] = {
            "tipo": kind, "not_null": not_null, "default": default,
        }
        order.setdefault(f"{schema}.{table}", []).append(column)
    catalog["colunas"] = columns
    catalog["_ordem_das_colunas"] = order

    catalog["restricoes"] = {
        f"{schema}.{table}.{name}": definition
        for schema, table, name, definition in raw["restricoes"]
    }

    foreign_keys: dict[str, list[str]] = {}
    for schema, table, _name, definition in raw["chaves_estrangeiras"]:
        core = FOREIGN_KEY_CORE.match(definition)
        key = f"{schema}.{table}: {core.group(0) if core else definition}"
        foreign_keys.setdefault(key, []).append(definition)
    catalog["chaves_estrangeiras"] = {key: sorted(value) for key, value in foreign_keys.items()}

    catalog["indices"] = {
        f"{schema}.{name}": {
            "tabela": f"{schema}.{table}",
            "definicao": INDEX_NAME.sub("INDEX ON ", definition, count=1),
        }
        for schema, table, name, definition in raw["indices"]
    }
    catalog["views"] = {
        f"{schema}.{name}": f"{'MATERIALIZED VIEW' if kind == 'm' else 'VIEW'}: {definition}"
        for schema, name, kind, definition in raw["views"]
    }
    catalog["funcoes"] = {
        f"{schema}.{name}({arguments})": definition.strip()
        for schema, name, arguments, definition in raw["funcoes"]
    }
    triggers = set()
    for schema, table, _name, definition in raw["gatilhos"]:
        normalized = TRIGGER_NAME.sub(r"\1<gatilho>", definition)
        triggers.add(f"{schema}.{table}: {normalized}")
    catalog["gatilhos"] = sorted(triggers)
    catalog["sequencias"] = {
        f"{schema}.{name}": [kind, start, minimum, maximum, increment, cycle]
        for schema, name, kind, start, minimum, maximum, increment, cycle in raw["sequencias"]
    }
    catalog["tipos_enum"] = {f"{schema}.{name}": labels for schema, name, labels in raw["tipos_enum"]}
    catalog["ledger"] = dict(sorted((ledger or {}).items()))
    catalog["_tem_ledger"] = ledger is not None
    return catalog


def diff_catalogs(base: dict[str, Any], target: dict[str, Any]) -> dict[str, dict[str, list]]:
    """Diferenças de cada categoria: faltando, sobrando e divergente."""
    result: dict[str, dict[str, list]] = {}
    for category in CATEGORIES:
        left, right = base[category], target[category]
        if isinstance(left, list):
            left = {item: True for item in left}
            right = {item: True for item in right}
        result[category] = {
            "faltando": [
                {"objeto": key, "base": left[key]} for key in sorted(left) if key not in right
            ],
            "sobrando": [
                {"objeto": key, "alvo": right[key]} for key in sorted(right) if key not in left
            ],
            "divergente": [
                {"objeto": key, "base": left[key], "alvo": right[key]}
                for key in sorted(left)
                if key in right and left[key] != right[key]
            ],
        }
    return result


def count_differences(diff: dict[str, dict[str, list]]) -> int:
    return sum(len(items) for kinds in diff.values() for items in kinds.values())


# ------------------------------------------------------- deriva aceita


def load_allowlist(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise RehearsalError(f"não li a lista da deriva aceita {path}: {error}") from error
    problems = []
    if data.get("schema_version") != 1:
        problems.append("schema_version deve ser 1")
    for index, item in enumerate(data.get("itens", [])):
        missing = [key for key in ("categoria", "tipo", "objeto", "motivo", "decisao")
                   if not isinstance(item.get(key), str) or not item[key].strip()]
        if missing:
            problems.append(f"itens[{index}] sem {', '.join(missing)}")
        elif item["categoria"] not in CATEGORIES:
            problems.append(f"itens[{index}]: categoria desconhecida {item['categoria']}")
        elif item["tipo"] not in ("faltando", "sobrando", "divergente"):
            problems.append(f"itens[{index}]: tipo desconhecido {item['tipo']}")
    for index, item in enumerate(data.get("payload", [])):
        missing = [key for key in ("tabela", "migration", "motivo")
                   if not isinstance(item.get(key), str) or not item[key].strip()]
        if missing:
            problems.append(f"payload[{index}] sem {', '.join(missing)}")
    if problems:
        raise RehearsalError("lista da deriva aceita inválida: " + "; ".join(problems))
    return data


def _owner(category: str, item: dict[str, Any]) -> tuple[str | None, str | None]:
    """Schema e tabela a que um objeto pertence, quando dá para saber."""
    name = item["objeto"]
    if category in ("chaves_estrangeiras", "gatilhos"):
        table = name.split(": ", 1)[0]
    elif category in ("colunas", "restricoes"):
        table = name.rsplit(".", 1)[0]
    elif category == "indices":
        table = (item.get("alvo") or item.get("base") or {}).get("tabela")
    elif category == "tabelas":
        table = name
    else:
        table = None
    schema = (table or name).split(".", 1)[0] if category != "schemas" else name
    return schema, table


def classify_differences(
    diff: dict[str, dict[str, list]], allowlist: dict[str, Any]
) -> dict[str, Any]:
    """Separa as diferenças em aceitas (na lista fechada) e inesperadas.

    Uma entrada de schema ou de tabela sobrando cobre também o que está dentro
    dela (tabelas, colunas, índices, chaves, restrições e gatilhos).
    """
    entries = allowlist.get("itens", [])
    exact = {(e["categoria"], e["tipo"], e["objeto"]): e for e in entries}
    extra_schemas = {e["objeto"]: e for e in entries
                     if e["categoria"] == "schemas" and e["tipo"] == "sobrando"}
    extra_tables = {e["objeto"]: e for e in entries
                    if e["categoria"] == "tabelas" and e["tipo"] == "sobrando"}
    used: set[int] = set()
    accepted, unexpected = [], []
    for category, kinds in diff.items():
        for kind, items in kinds.items():
            for item in items:
                entry = exact.get((category, kind, item["objeto"]))
                if entry is None and kind == "sobrando":
                    schema, table = _owner(category, item)
                    if category != "schemas" and schema in extra_schemas:
                        entry = extra_schemas[schema]
                    elif category != "tabelas" and table in extra_tables:
                        entry = extra_tables[table]
                    elif category == "sequencias":
                        entry = next((value for key, value in extra_tables.items()
                                      if item["objeto"].startswith(key + "_")), None)
                record = {"categoria": category, "tipo": kind, "objeto": item["objeto"]}
                if entry is None:
                    unexpected.append({**record, **{k: v for k, v in item.items() if k != "objeto"}})
                else:
                    used.add(id(entry))
                    accepted.append({**record, "decisao": entry["decisao"]})
    unused = [
        {"categoria": e["categoria"], "tipo": e["tipo"], "objeto": e["objeto"]}
        for e in entries if id(e) not in used
    ]
    return {"aceitas": accepted, "inesperadas": unexpected, "entradas_sem_ocorrencia": unused}


# ------------------------------------------------------------- payload


def payload_script(columns_by_table: dict[str, list[str]]) -> tuple[list[str], str]:
    """SQL que devolve, por tabela, linhas e um hash das linhas nas colunas dadas.

    O hash não depende da ordem física: cada linha vira um md5, e os md5 são
    ordenados antes de juntar.
    """
    tables = sorted(columns_by_table)
    lines = ["BEGIN TRANSACTION READ ONLY;", "SET LOCAL TimeZone = 'UTC';",
             "SET LOCAL extra_float_digits = 3;"]
    for table in tables:
        schema, name = table.split(".", 1)
        columns = ", ".join(_quote(column) for column in columns_by_table[table])
        lines.append(
            f"SELECT count(*) || '|' || COALESCE(md5(string_agg(h, '' ORDER BY h)), '') "
            f"FROM (SELECT md5(ROW({columns})::text) AS h "
            f"FROM {_quote(schema)}.{_quote(name)}) AS linhas;"
        )
    lines.append("COMMIT;")
    return tables, "\n".join(lines)


def compare_payload(
    before: dict[str, dict[str, Any]],
    after: dict[str, dict[str, Any]],
    declared: list[dict[str, str]],
) -> dict[str, Any]:
    allowed = {item["tabela"]: item for item in declared}
    changed, declared_changes = [], []
    for table, reading in sorted(before.items()):
        other = after.get(table)
        if other == reading:
            continue
        record = {"tabela": table, "antes": reading, "depois": other}
        if table in allowed:
            declared_changes.append({**record, "migration": allowed[table]["migration"]})
        else:
            changed.append(record)
    return {
        "tabelas": len(before),
        "linhas": sum(reading.get("linhas", 0) for reading in before.values()),
        "iguais": len(before) - len(changed) - len(declared_changes),
        "mudancas_declaradas": declared_changes,
        "mudancas_inesperadas": changed,
    }


def _quote(identifier: str) -> str:
    return '"' + identifier.replace('"', '""') + '"'


# ------------------------------------------------------------- cluster


class Cluster:
    """PostgreSQL 17 descartável, só em loopback, apagado no fim."""

    def __init__(self, pg_bin: Path, dart: Path, run_dir: Path) -> None:
        self.pg_bin = pg_bin
        self.dart = dart
        self.run_dir = run_dir
        self.data = run_dir / "pgdata"
        self.started = False
        self.port = 0
        self.sandbox = (
            ["sandbox-exec", "-p", SANDBOX_PROFILE] if platform.system() == "Darwin" else []
        )
        self.env = {**os.environ, "LC_ALL": "C", "LANG": "C", "PGTZ": "UTC"}
        self.env.pop("PGPASSWORD", None)

    def run(self, argv: list[str], *, env: dict[str, str] | None = None, cwd: Path | None = None,
            check: bool = True) -> subprocess.CompletedProcess:
        result = subprocess.run(
            [*self.sandbox, *argv], capture_output=True, text=True,
            env={**self.env, **(env or {})}, cwd=cwd, check=False,
        )
        if check and result.returncode != 0:
            raise RuntimeError(
                f"falhou ({result.returncode}): {' '.join(argv[:3])}\n"
                f"{result.stdout[-2000:]}\n{result.stderr[-2000:]}"
            )
        return result

    def start(self) -> None:
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            self.port = sock.getsockname()[1]
        self.run([str(self.pg_bin / "initdb"), "-D", str(self.data), "-U", "postgres",
                  "--auth=trust", "--no-locale", "--encoding=UTF8"])
        self.run([str(self.pg_bin / "pg_ctl"), "-D", str(self.data), "-l",
                  str(self.run_dir / "postgres.log"), "-w", "-o",
                  f"-F -p {self.port} -h 127.0.0.1 -c unix_socket_directories=''", "start"])
        self.started = True

    def stop(self) -> None:
        if self.started:
            subprocess.run([str(self.pg_bin / "pg_ctl"), "-D", str(self.data), "-m", "fast",
                            "stop"], capture_output=True, env=self.env, check=False)
            self.started = False

    def _connection(self, database: str) -> list[str]:
        return ["-h", "127.0.0.1", "-p", str(self.port), "-U", "postgres", "-d", database]

    def createdb(self, database: str) -> None:
        self.run([str(self.pg_bin / "createdb"), "-h", "127.0.0.1", "-p", str(self.port),
                  "-U", "postgres", database])

    def psql(self, database: str, sql: str) -> str:
        return self.run([str(self.pg_bin / "psql"), "-X", "-q", "-A", "-t", "-v",
                         "ON_ERROR_STOP=1", *self._connection(database), "-c", sql]).stdout

    def execute(self, database: str, script: str) -> None:
        """Roda um script numa transação só (fixtures e testes)."""
        result = subprocess.run(
            [*self.sandbox, str(self.pg_bin / "psql"), "-X", "-q", "-1", "-v", "ON_ERROR_STOP=1",
             *self._connection(database), "-f", "-"],
            input=script, capture_output=True, text=True, env=self.env, check=False,
        )
        if result.returncode != 0:
            raise RuntimeError(f"script em {database} falhou: {result.stderr[-2000:]}")

    def dump(self, database: str, path: Path) -> None:
        self.run([str(self.pg_bin / "pg_dump"), "-Fc", *self._connection(database),
                  "-f", str(path)])

    def psql_file(self, database: str, path: Path) -> None:
        self.run([str(self.pg_bin / "psql"), "-X", "-q", "-v", "ON_ERROR_STOP=1",
                  *self._connection(database), "-f", str(path)])

    def restore(self, database: str, dump: Path, mode: str) -> None:
        flags = ["--exit-on-error", "--no-owner", "--no-acl", "--no-tablespaces",
                 "--no-publications", "--no-subscriptions", "--no-security-labels"]
        base = [str(self.pg_bin / "pg_restore"), *flags, *self._connection(database)]
        if mode == "completo":
            self.run([*base, str(dump)])
            return
        self.run([*base, "--schema-only", str(dump)])
        if self.psql(database, "SELECT to_regclass('public.schema_migrations') IS NOT NULL"
                     ).strip() == "t":
            self.run([*base, "--data-only", "-n", "public", "-t", "schema_migrations",
                      str(dump)])

    def tables_with_rows(self, database: str) -> list[str]:
        output = self.psql(database, f"""
            SELECT COALESCE(string_agg(n.nspname || '.' || c.relname, ','), '')
            FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind IN ('r', 'p') AND {USER_SCHEMA}
              AND (xpath('/row/c/text()', query_to_xml(
                format('SELECT count(*) AS c FROM %I.%I', n.nspname, c.relname),
                false, true, '')))[1]::text::bigint > 0""").strip()
        return [item for item in output.split(",") if item]

    def catalog(self, database: str) -> dict[str, Any]:
        names = list(CATALOG_QUERIES)
        script = "BEGIN TRANSACTION READ ONLY;\n" + "\n".join(
            query.strip() + ";" for query in CATALOG_QUERIES.values()) + "\nCOMMIT;"
        lines = self._psql_stdin(database, script)
        if len(lines) != len(names):
            raise RuntimeError(f"catálogo de {database}: {len(lines)} linhas para {len(names)}")
        raw = {name: json.loads(line) for name, line in zip(names, lines)}
        ledger = None
        if raw.pop("tem_ledger"):
            ledger = json.loads(self.psql(
                database,
                "SELECT COALESCE(jsonb_object_agg(version, name), '{}') FROM public.schema_migrations",
            ).strip())
        return normalize_catalog(raw, ledger)

    def payload(self, database: str, columns_by_table: dict[str, list[str]]) -> dict[str, Any]:
        present = self.catalog(database)
        readings: dict[str, dict[str, Any]] = {}
        measurable: dict[str, list[str]] = {}
        order = present["_ordem_das_colunas"]
        for table, columns in columns_by_table.items():
            if table not in order:
                readings[table] = {"ausente": True}
            elif not set(columns) <= set(order[table]):
                readings[table] = {"colunas_ausentes": sorted(set(columns) - set(order[table]))}
            else:
                measurable[table] = columns
        tables, script = payload_script(measurable)
        if tables:
            lines = self._psql_stdin(database, script)
            if len(lines) != len(tables):
                raise RuntimeError(f"payload de {database}: {len(lines)} linhas para {len(tables)}")
            for table, line in zip(tables, lines):
                rows, digest = line.split("|", 1)
                readings[table] = {"linhas": int(rows), "hash": digest}
        return readings

    def _psql_stdin(self, database: str, script: str) -> list[str]:
        result = subprocess.run(
            [*self.sandbox, str(self.pg_bin / "psql"), "-X", "-q", "-A", "-t", "-v",
             "ON_ERROR_STOP=1", *self._connection(database), "-f", "-"],
            input=script, capture_output=True, text=True, env=self.env, check=False,
        )
        if result.returncode != 0:
            raise RuntimeError(f"consulta em {database} falhou: {result.stderr[-2000:]}")
        return [line for line in result.stdout.splitlines() if line.strip()]

    def migrate(self, database: str, *args: str) -> subprocess.CompletedProcess:
        env = {
            "DB_HOST": "127.0.0.1", "DB_PORT": str(self.port), "DB_USER": "postgres",
            "DB_PASS": "", "DB_NAME": database, "ENVIRONMENT": "development",
        }
        if "--preflight" not in args:
            env["MANALOOM_CONFIRM_POSTGRES_WRITES"] = WRITE_PHRASE
            env["MANALOOM_CONFIRM_LIVE_MUTATIONS"] = WRITE_PHRASE
        return self.run([str(self.dart), "bin/migrate.dart", *args], env=env,
                        cwd=REPO_ROOT / "server", check=False)

    def preflight(self, database: str) -> tuple[int, dict[str, Any]]:
        result = self.migrate(database, "--preflight")
        lines = [line for line in result.stdout.splitlines() if line.startswith("{")]
        if result.returncode not in (0, 3) or not lines:
            raise RuntimeError(f"preflight falhou ({result.returncode}): {result.stderr[-2000:]}")
        return result.returncode, json.loads(lines[-1])


# ------------------------------------------------------------- ensaio


def _approved() -> bool:
    if os.environ.get("MANALOOM_APPROVE_DISPOSABLE_POSTGRES") == APPROVAL_PHRASE:
        return True
    configured = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "config", "--local", "--bool", "--get",
         "manaloom.localGates.disposablePostgres"],
        capture_output=True, text=True, check=False,
    )
    return configured.stdout.strip() == "true"


def _tools() -> tuple[Path, Path]:
    pg_bin = Path(os.environ.get("MANALOOM_PG17_BIN", "/opt/homebrew/opt/postgresql@17/bin"))
    if not (pg_bin / "pg_ctl").exists() and shutil.which("pg_ctl"):
        pg_bin = Path(shutil.which("pg_ctl")).parent
    for tool in ("initdb", "pg_ctl", "createdb", "psql", "pg_restore", "pg_dump"):
        if not (pg_bin / tool).exists():
            raise RehearsalError(f"ferramenta ausente: {pg_bin / tool}")
    version = subprocess.run([str(pg_bin / "pg_restore"), "--version"], capture_output=True,
                             text=True, check=False).stdout
    if " 17." not in version:
        raise RehearsalError("pg_restore precisa ser da versão 17, a da produção")
    dart = Path(os.environ.get("MANALOOM_DART_BIN", str(DEFAULT_DART)))
    if not dart.exists():
        found = shutil.which("dart")
        if not found:
            raise RehearsalError("dart não encontrado (MANALOOM_DART_BIN)")
        dart = Path(found)
    if not (REPO_ROOT / "server" / ".dart_tool" / "package_config.json").exists():
        raise RehearsalError("server/ sem dependências resolvidas: rode dart pub get antes")
    if platform.system() == "Darwin" and not shutil.which("sandbox-exec"):
        raise RehearsalError("sandbox-exec é obrigatório no macOS")
    return pg_bin, dart


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _public(catalog: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in catalog.items() if not key.startswith("_")}


def rehearse(args: argparse.Namespace) -> tuple[int, dict[str, Any]]:
    dump = Path(args.dump).expanduser().resolve()
    if not dump.is_file() or dump.is_symlink():
        raise RehearsalError(f"dump ausente ou link simbólico: {dump}")
    if not _approved():
        raise RehearsalError(
            "o ensaio cria um PostgreSQL local descartável; aprove com "
            f"MANALOOM_APPROVE_DISPOSABLE_POSTGRES={APPROVAL_PHRASE}"
        )
    allowlist = load_allowlist(Path(args.allowlist))
    pg_bin, dart = _tools()
    dump_sha = _sha256(dump)
    report: dict[str, Any] = {
        "schema_version": 1,
        "kind": "brewtact-migration-rehearsal",
        "task": "BT-DB-003",
        "rotulo": args.label,
        "iniciado_em": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "dump": {"arquivo": dump.name, "bytes": dump.stat().st_size, "sha256": dump_sha},
        "restauracao": args.restore,
        "lista_da_deriva": {"arquivo": str(Path(args.allowlist)),
                            "versao": allowlist.get("version"),
                            "estado": allowlist.get("status")},
        "etapas": {},
    }
    steps = report["etapas"]
    failures: list[str] = []
    run_dir = Path(tempfile.mkdtemp(prefix="manaloom_migration_rehearsal."))
    cluster = Cluster(pg_bin, dart, run_dir)

    def timed(name: str, action):
        started = time.monotonic()
        value = action()
        steps.setdefault(name, {})["segundos"] = round(time.monotonic() - started, 2)
        return value

    try:
        return _rehearse_steps(args, dump, allowlist, cluster, report, steps, failures, timed)
    except RuntimeError as error:
        report["erro"] = str(error)[-4000:]
        report["resultado"] = "FAIL"
        return 1, report
    finally:
        cluster.stop()
        shutil.rmtree(run_dir, ignore_errors=True)
        report["cluster_descartado"] = not run_dir.exists()
        report["concluido_em"] = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _rehearse_steps(args, dump, allowlist, cluster, report, steps, failures, timed):
    """As etapas do ensaio; erro de etapa sobe como RuntimeError."""
    timed("cluster", cluster.start)
    report["postgres"] = cluster.psql("postgres", "SHOW server_version").strip()

    def build_base() -> dict[str, Any]:
        cluster.createdb("base")
        cluster.psql_file("base", REPO_ROOT / "server" / "database_setup.sql")
        result = cluster.migrate("base")
        if result.returncode != 0:
            raise RuntimeError("o banco novo não migrou: " + result.stdout[-2000:])
        return cluster.catalog("base")

    def restore(database: str) -> None:
        cluster.createdb(database)
        cluster.restore(database, dump, args.restore)

    timed("restauracao_antes", lambda: restore("antes"))
    if args.restore == "estrutura":
        with_rows = cluster.tables_with_rows("antes")
        steps["restauracao_antes"]["tabelas_com_linhas"] = with_rows
        if set(with_rows) - {LEDGER_TABLE}:
            raise RehearsalError(
                "no modo estrutura só public.schema_migrations pode ter linhas; "
                f"tem: {', '.join(with_rows)}"
            )
    before = cluster.catalog("antes")
    payload_columns = {
        table: columns for table, columns in before["_ordem_das_colunas"].items()
        if table != LEDGER_TABLE and not any(
            table.startswith(entry["objeto"] + ".")
            for entry in allowlist.get("itens", [])
            if entry["categoria"] == "schemas" and entry["tipo"] == "sobrando")
    }
    before_payload = timed("payload_antes", lambda: cluster.payload("antes", payload_columns))
    report["antes"] = {
        "migrations": len(before["ledger"]),
        "ultima": max(before["ledger"]) if before["ledger"] else None,
        "tabelas": len(before["tabelas"]),
        "linhas": sum(item.get("linhas", 0) for item in before_payload.values()),
    }

    timed("restauracao_ensaio", lambda: restore("ensaio"))
    code, preflight = timed("preflight", lambda: cluster.preflight("ensaio"))
    steps["preflight"].update(preflight)
    if code == 3:
        intact = _public(cluster.catalog("ensaio")) == _public(before)
        intact_payload = cluster.payload("ensaio", payload_columns) == before_payload
        steps["preflight"]["banco_intacto"] = intact and intact_payload
        migrate = cluster.migrate("ensaio")
        steps["preflight"]["migrate_recusou_com"] = migrate.returncode
        after_refusal = (
            _public(cluster.catalog("ensaio")) == _public(before)
            and cluster.payload("ensaio", payload_columns) == before_payload
        )
        steps["preflight"]["intacto_depois_do_migrate"] = after_refusal
        report["resultado"] = (
            "BLOCKED" if intact and intact_payload and after_refusal
            and migrate.returncode == 3 else "FAIL"
        )
        return (3 if report["resultado"] == "BLOCKED" else 1), report

    # Só com o perfil aceito: o banco novo deste código, referência da pós-checagem.
    base = timed("base", build_base)
    steps["base"]["migrations"] = len(base["ledger"])
    steps["base"]["catalogo"] = {category: len(base[category]) for category in CATEGORIES}

    upgrade = timed("upgrade", lambda: cluster.migrate("ensaio"))
    steps["upgrade"]["rc"] = upgrade.returncode
    if upgrade.returncode != 0:
        steps["upgrade"]["saida"] = (upgrade.stdout + upgrade.stderr)[-4000:]
        report["resultado"] = "FAIL"
        return 1, report
    after = cluster.catalog("ensaio")
    _, preflight_after = cluster.preflight("ensaio")
    steps["upgrade"]["ledger"] = {
        "migrations": len(after["ledger"]),
        "ultima": max(after["ledger"]) if after["ledger"] else None,
        "pendentes_depois": preflight_after["pendentes"],
        "igual_ao_da_base": after["ledger"] == base["ledger"],
    }
    if preflight_after["pendentes"] or after["ledger"] != base["ledger"]:
        failures.append("o ledger depois do upgrade não é o do código")

    postcheck_diff = diff_catalogs(_public(base), _public(after))
    classified = classify_differences(postcheck_diff, allowlist)
    steps["pos_checagem"] = {
        "diferencas": count_differences(postcheck_diff),
        "exata": count_differences(postcheck_diff) == 0,
        "aceitas": len(classified["aceitas"]),
        "inesperadas": classified["inesperadas"],
        "entradas_sem_ocorrencia": classified["entradas_sem_ocorrencia"],
        "aceitas_por_categoria": {
            category: sum(1 for item in classified["aceitas"] if item["categoria"] == category)
            for category in CATEGORIES
        },
    }
    if classified["inesperadas"]:
        failures.append("a pós-checagem achou diferença fora da lista fechada")

    after_payload = timed("payload_depois", lambda: cluster.payload("ensaio", payload_columns))
    payload = compare_payload(before_payload, after_payload, allowlist.get("payload", []))
    steps["payload"] = payload
    if payload["mudancas_inesperadas"]:
        failures.append("o upgrade mudou linhas que existiam antes")

    reapply = timed("reaplicacao", lambda: cluster.migrate("ensaio"))
    same_after_reapply = (
        reapply.returncode == 0
        and _public(cluster.catalog("ensaio")) == _public(after)
        and cluster.payload("ensaio", payload_columns) == after_payload
    )
    steps["reaplicacao"].update({"rc": reapply.returncode, "sem_mudanca": same_after_reapply})
    if not same_after_reapply:
        failures.append("reaplicar o migrate mudou o banco")

    timed("rollback_por_restore", lambda: restore("rollback"))
    rollback_catalog = cluster.catalog("rollback")
    rollback_payload = cluster.payload("rollback", payload_columns)
    rollback_diff = diff_catalogs(_public(before), _public(rollback_catalog))
    steps["rollback_por_restore"].update({
        "identico_a_antes": count_differences(rollback_diff) == 0
        and rollback_payload == before_payload,
        "diferencas_de_catalogo": count_differences(rollback_diff),
        "payload_igual": rollback_payload == before_payload,
    })
    if not steps["rollback_por_restore"]["identico_a_antes"]:
        failures.append("o restore do mesmo dump não voltou ao estado de antes")

    forward = timed("reforward", lambda: cluster.migrate("rollback"))
    forward_diff = diff_catalogs(_public(after), _public(cluster.catalog("rollback")))
    forward_payload = cluster.payload("rollback", payload_columns)
    steps["reforward"].update({
        "rc": forward.returncode,
        "igual_ao_upgrade": forward.returncode == 0 and count_differences(forward_diff) == 0
        and forward_payload == after_payload,
        "diferencas_de_catalogo": count_differences(forward_diff),
    })
    if not steps["reforward"]["igual_ao_upgrade"]:
        failures.append("o upgrade depois do rollback não chegou ao mesmo estado")

    report["falhas"] = failures
    report["resultado"] = "FAIL" if failures else "PASS"
    return (1 if failures else 0), report


def markdown(report: dict[str, Any]) -> str:
    steps = report.get("etapas", {})
    lines = [
        f"# Ensaio de upgrade — {report.get('rotulo')}",
        "",
        f"- Resultado: **{report.get('resultado')}**",
        f"- Dump: `{report['dump']['arquivo']}` ({report['dump']['bytes']} bytes), sha256 "
        f"`{report['dump']['sha256']}`; restauração `{report['restauracao']}`",
        f"- PostgreSQL: {report.get('postgres')}; cluster descartado: "
        f"{report.get('cluster_descartado')}",
    ]
    if "antes" in report:
        lines.append(f"- Antes: {report['antes']['migrations']} migrations (última "
                     f"{report['antes']['ultima']}), {report['antes']['tabelas']} tabelas, "
                     f"{report['antes']['linhas']} linhas")
    preflight = steps.get("preflight", {})
    lines.append(f"- Preflight: perfil `{preflight.get('perfil')}`, pendentes "
                 f"{len(preflight.get('pendentes', []))}")
    for reason in preflight.get("motivos", []):
        lines.append(f"  - {reason}")
    if "pos_checagem" in steps:
        check = steps["pos_checagem"]
        lines.append(f"- Pós-checagem contra a base: {check['diferencas']} diferenças, "
                     f"{check['aceitas']} aceitas e {len(check['inesperadas'])} inesperadas")
        for item in check["inesperadas"][:50]:
            lines.append(f"  - inesperada: {item['categoria']} {item['tipo']} `{item['objeto']}`")
    if "payload" in steps:
        payload = steps["payload"]
        lines.append(f"- Payload: {payload['iguais']} de {payload['tabelas']} tabelas iguais "
                     f"({payload['linhas']} linhas); {len(payload['mudancas_inesperadas'])} "
                     "mudanças inesperadas")
    for name in ("reaplicacao", "rollback_por_restore", "reforward"):
        if name in steps:
            lines.append(f"- {name}: {json.dumps({k: v for k, v in steps[name].items()}, ensure_ascii=False)}")
    for failure in report.get("falhas", []):
        lines.append(f"- FALHA: {failure}")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--dump", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--restore", choices=("estrutura", "completo"), default="estrutura")
    parser.add_argument("--allowlist", default=str(DEFAULT_ALLOWLIST))
    parser.add_argument("--label", default="ensaio")
    args = parser.parse_args(argv)
    out_dir = Path(args.out_dir).expanduser()
    try:
        code, report = rehearse(args)
    except RehearsalError as error:
        print(json.dumps({"resultado": "INVALID", "erro": str(error)}, ensure_ascii=False))
        return 2
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "rehearsal.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (out_dir / "rehearsal.md").write_text(markdown(report), encoding="utf-8")
    print(json.dumps({"resultado": report.get("resultado"), "saida": str(out_dir)},
                     ensure_ascii=False))
    return code


if __name__ == "__main__":
    sys.exit(main())
