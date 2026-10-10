#!/usr/bin/env python3
"""S-05: o passo de migrations do lote de deploy, sem conexão.

O orquestrador `scripts/manaloom_lot_apply_migrations.sh` lê o ledger do banco
(`schema_migrations`) pelo `server/bin/with_new_server_pg.sh --read-only`, aplica as
migrations pelo `--write-approved` com o `server/bin/migrate.dart` e só segue com o que
este módulo aprovar.

O lote é declarado em `server/config/lot_migrations.json`: a migration em que o banco
tem de estar (`from`), as do lote em ordem numérica (`migrations`) e as que têm de ir
juntas (`same_lot`: a 074 com a 067 e a 069, pela BT-DB-007). Antes de qualquer
escrita, o plano confere o lote contra o código deste SHA:
- toda migration do lote existe no `migrate.dart` (lacuna: recusa);
- toda migration do código entre `from` e a última do lote está no lote, e o lote
  termina na última do código (nada fica pendente nem fora do lote);
- as regras de `same_lot` valem;
- o readiness do backend deste SHA (`server/lib/health_readiness_support.dart`) exige
  exatamente a última do lote e conhece cada migration que exige.
O ledger de antes tem de estar em `from`, sem lacuna e sem versão de outro código.
Depois, o ledger tem de ser o de antes mais o lote, nem mais nem menos.

Subcomandos:
  plan --policy P [--root R]
  check-before --plan PLANO --ledger-raw L
  check-after --plan PLANO --before-raw L0 --after-raw L1
  snapshot --raw L --out S                    o ledger para o --schema-snapshot da promoção
  receipt --out R --status S --sha SHA --started-at T --plan PLANO [--before B] [--after A]
          [--migrate-exit N] [--log NOME] [--reason TEXTO]

Saída JSON em stdout. Códigos: 0 PASS, 1 FAIL, 2 entrada inválida, 3 BLOCKED.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import importlib.util
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent
POLICY_KIND = "manaloom-lot-migrations"
RECEIPT_KIND = "manaloom-lot-migrations-receipt"
MIGRATE_SOURCE = "server/bin/migrate.dart"
LEDGER_SOURCE = "server/bin/with_new_server_pg.sh --read-only psql"
VERSION = re.compile(r"^[0-9]{3}$")
MIGRATION_ENTRY = re.compile(
    r"Migration\(\s*version:\s*'([0-9]{3})',\s*name:\s*'([a-z0-9_]+)'")
LEDGER_LINE = re.compile(r"^([0-9]{3})\|([a-z0-9_]+)$")
READINESS_MAP = re.compile(
    r"const\s+requiredReleaseSchemaMigrations\s*=\s*<String,\s*String>\{(.*?)\};", re.DOTALL)
READINESS_ENTRY = re.compile(r"'([0-9]{3})'\s*:\s*'([a-z0-9_]+)'")
STATUSES = {"applied", "failed", "blocked"}

# A exigência de schema de uma imagem e o formato do ledger são os da promoção (S-02):
# os dois passos leem o mesmo arquivo do mesmo jeito.
_spec = importlib.util.spec_from_file_location(
    "s02_promote_release", HERE / "manaloom_promote_release.py")
promote = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
sys.modules[_spec.name] = promote
_spec.loader.exec_module(promote)


class InvalidInput(Exception):
    pass


def _now() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise InvalidInput(f"não li {path}: {error}") from error


def _json(path: Path) -> Any:
    try:
        return json.loads(_read(path))
    except json.JSONDecodeError as error:
        raise InvalidInput(f"{path} não é JSON: {error}") from error


# ------------------------------------------------------------ política


def policy_problems(policy: Any) -> list[str]:
    if not isinstance(policy, dict):
        return ["a política do lote não é um objeto"]
    problems: list[str] = []
    if policy.get("schema_version") != 1 or policy.get("policy") != POLICY_KIND:
        problems.append(f"não é a política {POLICY_KIND} v1")
    if not isinstance(policy.get("version"), str) or not policy["version"]:
        problems.append("version ausente")
    start = policy.get("from")
    if not (isinstance(start, str) and VERSION.match(start)):
        problems.append("from deve ser uma versão de três dígitos")
    lot = policy.get("migrations")
    if not (isinstance(lot, list) and lot
            and all(isinstance(item, str) and VERSION.match(item) for item in lot)):
        problems.append("migrations deve listar versões de três dígitos")
    elif lot != sorted(set(lot)):
        problems.append("migrations deve vir em ordem numérica, sem repetição")
    elif isinstance(start, str) and lot[0] <= start:
        problems.append(f"o lote tem de começar depois da {start}")
    rules = policy.get("same_lot")
    if not isinstance(rules, list):
        problems.append("same_lot deve ser uma lista")
    else:
        for index, rule in enumerate(rules):
            if not (isinstance(rule, dict) and isinstance(rule.get("version"), str)
                    and VERSION.match(rule["version"])
                    and isinstance(rule.get("with"), list) and rule["with"]
                    and all(isinstance(item, str) and VERSION.match(item)
                            for item in rule["with"])
                    and isinstance(rule.get("rationale"), str) and rule["rationale"].strip()):
                problems.append(f"same_lot[{index}] inválido")
    for key in ("runner", "window", "rollback"):
        if not isinstance(policy.get(key), str) or not policy[key].strip():
            problems.append(f"{key} ausente")
    return problems


def load_policy(path: Path) -> dict[str, Any]:
    policy = _json(path)
    problems = policy_problems(policy)
    if problems:
        raise InvalidInput("política do lote inválida: " + "; ".join(problems))
    return policy


# ------------------------------------------------------------ código deste SHA


def code_migrations(text: str) -> list[tuple[str, str]]:
    """As migrations do migrate.dart, na ordem do arquivo (que tem de ser a numérica)."""
    entries = MIGRATION_ENTRY.findall(text)
    versions = [version for version, _ in entries]
    if not entries or versions != sorted(set(versions)):
        raise InvalidInput("o migrate.dart não lista as migrations em ordem, sem repetição")
    return entries


def readiness_required(text: str) -> dict[str, str]:
    """O mapa versão -> nome que o readiness do backend exige no ledger."""
    block = READINESS_MAP.search(text or "")
    if block is None:
        return {}
    return dict(READINESS_ENTRY.findall(block.group(1)))


def plan(policy: dict[str, Any], migrate_text: str, readiness_text: str) -> dict[str, Any]:
    """O lote contra o código: lacuna, migration fora do lote, regra de lote e readiness."""
    problems: list[str] = []
    code = code_migrations(migrate_text)
    names = dict(code)
    start = policy["from"]
    lot: list[str] = policy["migrations"]
    end = lot[-1]
    if start not in names:
        problems.append(f"a {start}, onde o banco tem de estar, não existe no migrate.dart")
    for version in lot:
        if version not in names:
            problems.append(f"lacuna: a {version} está no lote e não existe no migrate.dart "
                            "deste SHA")
    for version in names:
        if start < version <= end and version not in lot:
            problems.append(f"lacuna: o migrate.dart tem a {version} entre a {start} e a {end}, "
                            "e ela não está no lote")
        if version > end:
            problems.append(f"o migrate.dart tem a {version} depois da {end}: o lote tem de "
                            "terminar na última migration do código")
    for rule in policy["same_lot"]:
        present = [item for item in rule["with"] if item in lot]
        if present and rule["version"] not in lot:
            problems.append(f"a {rule['version']} tem de ir no mesmo lote da "
                            f"{' e da '.join(present)}: {rule['rationale']}")
        elif present and rule["version"] < max(present):
            problems.append(f"a {rule['version']} tem de rodar depois da {max(present)}")
    requires = promote.readiness_requirement(readiness_text)
    if requires is None:
        problems.append(f"não li qual migration o readiness deste SHA exige "
                        f"({promote.READINESS_SOURCE})")
    elif requires != end:
        problems.append(f"o readiness deste SHA exige a {requires} e o lote termina na {end}: "
                        "o backend novo daria 503")
    required = readiness_required(readiness_text)
    if not required:
        problems.append("não li a lista de migrations que o readiness exige")
    for version, name in sorted(required.items()):
        if names.get(version) != name:
            problems.append(f"o readiness exige a {version} ({name}), que o migrate.dart não tem "
                            "com esse nome")
    return {
        "status": "PASS" if not problems else "BLOCKED",
        "policy": policy["policy"],
        "policy_version": policy["version"],
        "from": start,
        "to": end,
        "migrations": [{"version": version, "name": names.get(version)} for version in lot],
        "same_lot": [{"version": rule["version"], "with": rule["with"]}
                     for rule in policy["same_lot"]],
        "readiness_requires": requires,
        "code_latest": code[-1][0],
        "code": [list(item) for item in code if item[0] <= end],
        "problems": problems,
    }


# ------------------------------------------------------------ ledger


def parse_ledger(raw: str) -> list[tuple[str, str]]:
    """O ledger lido pelo psql (-qAt, `versão|nome` por linha, em ordem)."""
    entries = []
    for number, line in enumerate((line.strip() for line in raw.splitlines()), start=1):
        if not line:
            continue
        match = LEDGER_LINE.match(line)
        if match is None:
            raise InvalidInput(f"linha {number} do ledger ilegível")
        entries.append((match.group(1), match.group(2)))
    versions = [version for version, _ in entries]
    if versions != sorted(set(versions)):
        raise InvalidInput("o ledger não veio em ordem, sem repetição")
    return entries


def ledger_view(entries: list[tuple[str, str]]) -> dict[str, Any]:
    text = "\n".join(f"{version}|{name}" for version, name in entries)
    return {
        "latest": entries[-1][0] if entries else None,
        "count": len(entries),
        "versions": [version for version, _ in entries],
        "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
    }


def check_before(planned: dict[str, Any], entries: list[tuple[str, str]]) -> dict[str, Any]:
    """O banco está onde o lote parte: em `from`, sem lacuna e só com este código."""
    problems: list[str] = []
    code = {version: name for version, name in planned["code"]}
    start = planned["from"]
    ledger = dict(entries)
    for version, name in entries:
        if version not in code:
            problems.append(f"o ledger tem a {version} ({name}), que este código não conhece")
        elif code[version] != name:
            problems.append(f"o ledger tem a {version} como {name}, e este código a chama "
                            f"de {code[version]}")
    latest = entries[-1][0] if entries else None
    if latest != start:
        problems.append(f"o banco está na {latest or 'nenhuma'} e o lote parte da {start}"
                        + (": este lote já foi aplicado" if latest == planned["to"] else ""))
    for version in code:
        if version <= start and version not in ledger:
            problems.append(f"lacuna no ledger: falta a {version}, antes da {start}")
    return {"status": "PASS" if not problems else "BLOCKED", "ledger": ledger_view(entries),
            "problems": problems}


def check_after(
    planned: dict[str, Any], before: list[tuple[str, str]], after: list[tuple[str, str]],
) -> dict[str, Any]:
    """O ledger depois é o de antes mais o lote, com os nomes do código."""
    expected = dict(before)
    expected.update({item["version"]: item["name"] for item in planned["migrations"]})
    now = dict(after)
    missing = [version for version in sorted(expected) if version not in now]
    unexpected = [version for version in sorted(now) if version not in expected]
    renamed = [version for version in sorted(now)
               if version in expected and now[version] != expected[version]]
    problems = [f"o ledger depois não tem a {version}" for version in missing]
    problems += [f"o ledger depois tem a {version}, fora do lote" for version in unexpected]
    problems += [f"o ledger depois tem a {version} com outro nome" for version in renamed]
    latest = after[-1][0] if after else None
    if latest != planned["to"]:
        problems.append(f"o banco ficou na {latest or 'nenhuma'}, não na {planned['to']}")
    applied = [version for version in sorted(now) if version not in dict(before)]
    return {"status": "PASS" if not problems else "FAIL", "ledger": ledger_view(after),
            "applied": applied, "missing": missing, "unexpected": unexpected,
            "problems": problems}


def snapshot(entries: list[tuple[str, str]]) -> dict[str, Any]:
    """O ledger no formato que a promoção aceita em --schema-snapshot (S-02)."""
    if not entries:
        raise InvalidInput("o ledger está vazio")
    view = ledger_view(entries)
    return {
        "kind": promote.SCHEMA_LEDGER_KIND,
        "schema_version": 1,
        "task": "S-05",
        "measured_at": _now(),
        "latest_migration": view["latest"],
        "versions": view["versions"],
        "count": view["count"],
        "sha256": view["sha256"],
        "source": LEDGER_SOURCE,
    }


def _write_private(path: Path, data: dict[str, Any]) -> None:
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        handle.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    path.chmod(0o600)


# ------------------------------------------------------------ CLI


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    commands = parser.add_subparsers(dest="command", required=True)
    planned = commands.add_parser("plan")
    planned.add_argument("--policy", type=Path, required=True)
    planned.add_argument("--root", type=Path, default=REPO_ROOT)
    before = commands.add_parser("check-before")
    before.add_argument("--plan", type=Path, required=True)
    before.add_argument("--ledger-raw", type=Path, required=True)
    after = commands.add_parser("check-after")
    after.add_argument("--plan", type=Path, required=True)
    after.add_argument("--before-raw", type=Path, required=True)
    after.add_argument("--after-raw", type=Path, required=True)
    snap = commands.add_parser("snapshot")
    snap.add_argument("--raw", type=Path, required=True)
    snap.add_argument("--out", type=Path, required=True)
    receipt = commands.add_parser("receipt")
    receipt.add_argument("--out", type=Path, required=True)
    receipt.add_argument("--status", required=True, choices=sorted(STATUSES))
    receipt.add_argument("--sha", required=True)
    receipt.add_argument("--started-at", required=True)
    receipt.add_argument("--plan", type=Path, required=True)
    receipt.add_argument("--before", type=Path)
    receipt.add_argument("--after", type=Path)
    receipt.add_argument("--migrate-exit", type=int)
    receipt.add_argument("--log")
    receipt.add_argument("--reason", default="")
    args = parser.parse_args(argv)

    try:
        if args.command == "plan":
            result = plan(load_policy(args.policy), _read(args.root / MIGRATE_SOURCE),
                          _read(args.root / promote.READINESS_SOURCE))
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "check-before":
            result = check_before(_json(args.plan), parse_ledger(_read(args.ledger_raw)))
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "check-after":
            result = check_after(_json(args.plan), parse_ledger(_read(args.before_raw)),
                                 parse_ledger(_read(args.after_raw)))
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 1
        if args.command == "snapshot":
            data = snapshot(parse_ledger(_read(args.raw)))
            _write_private(args.out, data)
            print(json.dumps({"status": "written", "out": str(args.out),
                              "latest_migration": data["latest_migration"]}))
            return 0
        planned_data = _json(args.plan)
        problems = list(planned_data.get("problems") or [])
        before_data = _json(args.before) if args.before else None
        after_data = _json(args.after) if args.after else None
        for part in (before_data, after_data):
            if isinstance(part, dict):
                problems += part.get("problems") or []
        if args.reason:
            problems.append(args.reason)
        data = {
            "kind": RECEIPT_KIND,
            "schema_version": 1,
            "task": "S-05",
            "tool": "scripts/manaloom_lot_apply_migrations.sh",
            "status": args.status,
            "sha": args.sha,
            "started_at": args.started_at,
            "finished_at": _now(),
            "policy_version": planned_data.get("policy_version"),
            "from": planned_data.get("from"),
            "to": planned_data.get("to"),
            "lot": [item["version"] for item in planned_data.get("migrations", [])],
            "same_lot": planned_data.get("same_lot"),
            "before": (before_data or {}).get("ledger"),
            "after": (after_data or {}).get("ledger"),
            "applied": (after_data or {}).get("applied", []),
            "migrate_exit": args.migrate_exit,
            "migrate_log": args.log,
            "problems": problems,
        }
        _write_private(args.out, data)
        print(json.dumps({"status": args.status, "receipt": str(args.out)}, ensure_ascii=False))
        return 0
    except (InvalidInput, promote.InvalidInput, KeyError, ValueError, TypeError) as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    sys.exit(main())
