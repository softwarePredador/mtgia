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
  exatamente a última do lote e conhece cada migration que exige;
- todo script de `server/sql/lote/` que uma migration do lote pede no código (a 077
  pede o dedupe da D-74, `server/sql/lote/d74_dedupe_sets_lower_code.sql`) está em
  `before_first_migration`, existe neste SHA e segue o contrato do lote: prévia por
  padrão e, com `-v aplicar=1`, a gravação só com as contagens `-v esperado_<objeto>=<n>`
  que a prévia mostrou.
As provas do L-01 (backup com ensaio de restauração) e do L-02 (ensaio do upgrade com o
dump desse backup) têm de existir, ter passado e ter no máximo 24 h (o RPO da D-12).
O ledger de antes tem de estar em `from`, sem lacuna e sem versão de outro código.
Os passos de `before_first_migration` rodam depois dessa conferência e antes da primeira
migration, com o banco ainda em `from` e o backend antigo no ar (fora da janela de 503),
e o resultado de cada um vai para o mesmo receipt. Depois, o ledger tem de ser o de
antes mais o lote, nem mais nem menos, e do mesmo banco (nome e system_identifier do
cluster) que o de antes.

Cada leitura do banco começa pela identidade (`database|<current_database()>|
<system_identifier>`) e segue com o ledger (`versão|nome`, em ordem).

Nenhum arquivo de evidência é sobrescrito: receipt, log e ledger são criados com
O_EXCL (`chmod 600`), e um nome que já existe é recusado.

Subcomandos:
  plan --policy P [--root R]
  expected --plan PLANO [--esperado PASSO:OBJETO=N ...]   as contagens da gravação
  step-result --plan PLANO --id PASSO --mode previa|gravacao --exit N --stdout O --stderr E
          [--expected X]                      o que um passo antes da primeira migration fez
  proofs --backup-receipt B --upgrade-rehearsal E   as provas do L-01 e do L-02
  check-before --plan PLANO --ledger-raw L
  check-after --plan PLANO --before-raw L0 --after-raw L1
  snapshot --raw L --out S                    o ledger para o --schema-snapshot da promoção
  create --out F                              cria F vazio, só do dono, se não existe
  receipt --out R --status S --sha SHA --started-at T --plan PLANO [--before B] [--after A]
          [--proofs P] [--steps S] [--migrate-exit N] [--log NOME] [--reason TEXTO]

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
DATABASE_LINE = re.compile(r"^database\|([^|]*)\|([^|]*)$")
READINESS_MAP = re.compile(
    r"const\s+requiredReleaseSchemaMigrations\s*=\s*<String,\s*String>\{(.*?)\};", re.DOTALL)
READINESS_ENTRY = re.compile(r"'([0-9]{3})'\s*:\s*'([a-z0-9_]+)'")
STATUSES = {"applied", "failed", "blocked"}
# As provas do lote (L-01 e L-02): os receipts das ferramentas versionadas.
BACKUP_KIND = "brewtact-backup-cycle"
BACKUP_TOOL = "scripts/manaloom_backup_cycle.sh --execute --drill"
REHEARSAL_KIND = "brewtact-migration-rehearsal"
REHEARSAL_TOOL = "scripts/manaloom_migration_rehearsal.py --restore completo"
PROOF_MAX_AGE = dt.timedelta(hours=24)
PROOF_MAX_SKEW = dt.timedelta(minutes=5)
SHA256 = re.compile(r"^[0-9a-f]{64}$")
# Os passos antes da primeira migration: scripts de server/sql/lote/ no contrato do lote
# (prévia por padrão; -v aplicar=1 com -v esperado_<objeto>=<n>), pedidos no código por
# uma migration do lote.
STEP_ID = re.compile(r"^[a-z][a-z0-9_]*$")
LOT_SCRIPT = re.compile(r"^server/sql/lote/[a-z0-9_]+\.sql$")
LOT_SCRIPT_MENTION = re.compile(r"server/sql/lote/[a-z0-9_]+\.sql")
SCRIPT_APPLY_FLAG = re.compile(r"^\\if :\{\?aplicar\}$", re.MULTILINE)
SCRIPT_TARGET = re.compile(r"^\\if :\{\?esperado_([a-z0-9_]+)\}$", re.MULTILINE)
EXPECTED_ARG = re.compile(r"^([a-z][a-z0-9_]*):([a-z0-9_]+)=([0-9]{1,12})$")
STEP_MODES = {"previa": "rollback", "gravacao": "commit"}

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
    steps = policy.get("before_first_migration")
    if not isinstance(steps, list):
        problems.append("before_first_migration deve ser uma lista")
    else:
        seen: set[str] = set()
        for index, step in enumerate(steps):
            if not (isinstance(step, dict)
                    and isinstance(step.get("id"), str) and STEP_ID.match(step["id"])
                    and step["id"] not in seen
                    and isinstance(step.get("script"), str) and LOT_SCRIPT.match(step["script"])
                    and isinstance(step.get("required_by"), str)
                    and VERSION.match(step["required_by"])
                    and all(isinstance(step.get(key), str) and step[key].strip()
                            for key in ("decision", "rationale"))):
                problems.append(f"before_first_migration[{index}] inválido")
            else:
                seen.add(step["id"])
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


def migration_script_mentions(text: str) -> dict[str, list[str]]:
    """Os scripts de server/sql/lote/ que cada migration cita no seu bloco do migrate.dart
    (a 077 manda rodar antes o dedupe da D-74)."""
    entries = list(MIGRATION_ENTRY.finditer(text))
    mentions: dict[str, list[str]] = {}
    for index, entry in enumerate(entries):
        end = entries[index + 1].start() if index + 1 < len(entries) else len(text)
        found = sorted(set(LOT_SCRIPT_MENTION.findall(text[entry.start():end])))
        if found:
            mentions[entry.group(1)] = found
    return mentions


def script_contract(text: str) -> tuple[bool, list[str]]:
    """Se um script do lote tem a prévia por padrão (`-v aplicar`) e as contagens que a
    gravação exige (`-v esperado_<objeto>`), na ordem do arquivo."""
    return bool(SCRIPT_APPLY_FLAG.search(text)), SCRIPT_TARGET.findall(text)


def _steps_plan(policy: dict[str, Any], lot: list[str], mentions: dict[str, list[str]],
                root: Path, problems: list[str]) -> list[dict[str, Any]]:
    """Os passos antes da primeira migration: os que o código pede e o contrato de cada um."""
    steps = policy["before_first_migration"]
    declared = {step["script"]: step for step in steps}
    for version in lot:
        for script in mentions.get(version, []):
            if script not in declared:
                problems.append(f"a {version} pede {script} antes dela (no migrate.dart), e o "
                                "lote não o roda antes da primeira migration "
                                "(before_first_migration)")
            elif declared[script]["required_by"] != version:
                problems.append(f"{script} é pedido pela {version}, e o lote o declara para a "
                                f"{declared[script]['required_by']}")
    planned = []
    for step in steps:
        entry: dict[str, Any] = {
            "id": step["id"], "script": step["script"], "required_by": step["required_by"],
            "decision": step["decision"], "sha256": None, "targets": [],
        }
        if step["required_by"] not in lot:
            problems.append(f"o passo {step['id']} é da {step['required_by']}, que não está "
                            "no lote")
        path = root / step["script"]
        if path.is_symlink() or not path.is_file():
            problems.append(f"o passo {step['id']}: {step['script']} não existe neste SHA")
        else:
            raw = path.read_bytes()
            entry["sha256"] = hashlib.sha256(raw).hexdigest()
            has_apply, targets = script_contract(raw.decode("utf-8", errors="replace"))
            entry["targets"] = targets
            if not has_apply or not targets or len(set(targets)) != len(targets):
                problems.append(f"o passo {step['id']}: {step['script']} não segue o contrato "
                                "do lote (prévia por padrão, -v aplicar=1 e -v esperado_<objeto> "
                                "para cada contagem da gravação)")
        planned.append(entry)
    return planned


def plan(policy: dict[str, Any], migrate_text: str, readiness_text: str,
         root: Path = REPO_ROOT) -> dict[str, Any]:
    """O lote contra o código: lacuna, migration fora do lote, regra de lote, readiness e
    os passos que o código pede antes da primeira migration."""
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
    steps = _steps_plan(policy, lot, migration_script_mentions(migrate_text), root, problems)
    return {
        "status": "PASS" if not problems else "BLOCKED",
        "policy": policy["policy"],
        "policy_version": policy["version"],
        "from": start,
        "to": end,
        "migrations": [{"version": version, "name": names.get(version)} for version in lot],
        "same_lot": [{"version": rule["version"], "with": rule["with"]}
                     for rule in policy["same_lot"]],
        "before_first_migration": steps,
        "readiness_requires": requires,
        "code_latest": code[-1][0],
        "code": [list(item) for item in code if item[0] <= end],
        "problems": problems,
    }


# ------------------------------------------------------------ passos antes da 1ª migration


def expected_counts(planned: dict[str, Any], arguments: list[str]) -> dict[str, Any]:
    """As contagens que a gravação de cada passo exige, de `--esperado PASSO:OBJETO=N`.

    Cada contagem que o script declara (`-v esperado_<objeto>`) tem de vir uma vez, e só
    elas: o número é o que a prévia mostrou e o dono aprovou. O script recusa (RAISE, nada
    gravado) se a ação não bater.
    """
    steps = {step["id"]: step for step in planned.get("before_first_migration") or []}
    given: dict[str, dict[str, str]] = {step_id: {} for step_id in steps}
    problems: list[str] = []
    for argument in arguments:
        match = EXPECTED_ARG.match(argument)
        if match is None:
            problems.append(f"--esperado {argument}: use PASSO:OBJETO=N, com N inteiro")
            continue
        step_id, target, count = match.groups()
        if step_id not in steps:
            problems.append(f"--esperado {argument}: o lote não tem o passo {step_id}")
        elif target not in steps[step_id]["targets"]:
            problems.append(f"--esperado {argument}: o passo {step_id} não conta {target} "
                            f"(conta {', '.join(steps[step_id]['targets'])})")
        elif target in given[step_id]:
            problems.append(f"--esperado {argument}: {step_id}:{target} veio duas vezes")
        else:
            given[step_id][target] = str(int(count))
    for step_id, step in steps.items():
        missing = [target for target in step["targets"] if target not in given[step_id]]
        if missing:
            problems.append(f"falta --esperado para {', '.join(f'{step_id}:{target}' for target in missing)}"
                            " (rode antes --execute --preview e passe os números que o dono aprovou)")
    if problems:
        raise InvalidInput("; ".join(problems))
    return {
        "status": "PASS",
        "steps": [{"id": step_id, "expected": given[step_id],
                   "psql_variables": ["aplicar=1"] + [f"esperado_{target}={given[step_id][target]}"
                                                      for target in steps[step_id]["targets"]]}
                  for step_id in steps],
    }


def _rows(output: str) -> list[tuple[str, str, str]]:
    """As linhas `fase<TAB>objeto<TAB>quantidade` de um script do lote."""
    rows = []
    for line in output.splitlines():
        parts = line.split("\t")
        if len(parts) == 3:
            rows.append((parts[0], parts[1], parts[2]))
    return rows


def step_result(planned: dict[str, Any], step_id: str, mode: str, exit_code: int,
                stdout: str, stderr: str, expected: dict[str, str] | None) -> dict[str, Any]:
    """O que um passo antes da primeira migration fez, pela saída do psql.

    - `previa`: saiu 0 e terminou em ROLLBACK, com cada contagem da gravação na ação;
    - `gravacao`: `applied` só com saída 0, o COMMIT impresso e a ação igual ao esperado;
      `refused` (nada gravado) quando o script terminou em ROLLBACK, ou quando o COMMIT não
      saiu e o psql parou num erro do servidor dentro da transação (código 3 com
      ON_ERROR_STOP), ou quando nada foi impresso; `failed` no resto, quando não dá para
      afirmar que nada foi gravado.
    """
    steps = {step["id"]: step for step in planned.get("before_first_migration") or []}
    if step_id not in steps:
        raise InvalidInput(f"o plano não tem o passo {step_id}")
    if mode not in STEP_MODES:
        raise InvalidInput(f"modo do passo inválido: {mode}")
    step = steps[step_id]
    rows = _rows(stdout)
    phases: dict[str, dict[str, str]] = {}
    merges: list[str] = []
    for phase, target, value in rows:
        if phase == "fusao":
            merges.append(f"{target} {value}")
        else:
            phases.setdefault(phase, {})[target] = value
    action = phases.get("acao", {})
    outcome = phases.get("modo", {}).get("desfecho")
    problems: list[str] = []
    if mode == "previa":
        missing = [target for target in step["targets"] if target not in action]
        status = "preview"
        if exit_code != 0 or outcome != "rollback" or missing:
            status = "failed"
            problems.append(f"a prévia do passo {step_id} saiu com {exit_code}, desfecho "
                            f"{outcome or 'ausente'}"
                            + (f", sem {', '.join(missing)}" if missing else ""))
    else:
        expected = expected or {}
        diverged = [target for target in step["targets"]
                    if action.get(target) != expected.get(target)]
        if exit_code == 0 and outcome == "commit" and not diverged:
            status = "applied"
        elif outcome == "rollback" or (outcome != "commit" and (exit_code == 3 or not rows)):
            status = "refused"
            problems.append(f"o passo {step_id} não gravou (saiu com {exit_code}, desfecho "
                            f"{outcome or 'sem COMMIT'}): nada foi gravado")
        else:
            status = "failed"
            problems.append(f"o passo {step_id} saiu com {exit_code} e desfecho "
                            f"{outcome or 'ausente'}"
                            + (f"; a ação diverge do esperado em {', '.join(diverged)}"
                               if outcome == "commit" and diverged else "")
                            + ": confira à mão o que foi gravado")
    errors = [line.strip() for line in stderr.splitlines() if "ERROR" in line or "FATAL" in line]
    return {
        "id": step_id,
        "script": step["script"],
        "sha256": step["sha256"],
        "required_by": step["required_by"],
        "mode": mode,
        "exit": exit_code,
        "status": status,
        "expected": expected if mode == "gravacao" else None,
        # Na prévia, o que o --apply pede: cada contagem da ação como --esperado.
        "esperado": ([f"{step_id}:{target}={action[target]}" for target in step["targets"]]
                     if status == "preview" else []),
        "phases": phases,
        "fusao": merges,
        "errors": errors[-5:],
        "problems": problems,
    }


# ------------------------------------------------------------ provas do L-01 e do L-02


def _age_problem(label: str, stamp: Any, now: dt.datetime) -> str | None:
    when = promote._parse_utc(stamp)
    if when is None:
        return f"{label} não tem a data em UTC"
    if when - now > PROOF_MAX_SKEW:
        return f"{label} diz ter sido feito no futuro: {stamp}"
    if now - when > PROOF_MAX_AGE:
        return (f"{label} é de {stamp}, há mais de "
                f"{int(PROOF_MAX_AGE.total_seconds() // 3600)} h (o RPO da D-12)")
    return None


def proofs(backup: Any, rehearsal: Any, now: dt.datetime) -> dict[str, Any]:
    """O L-01 e o L-02 antes de escrever: existem, passaram, são recentes e casam.

    L-01: o receipt do ciclo de backup com o ensaio de restauração (`--drill`) aprovado e
    a cadência PASS (RPO, RTO e ensaio). L-02: o rehearsal.json do ensaio do upgrade no
    modo `completo`, com resultado PASS, sobre o dump desse backup (o mesmo SHA-256).
    Os dois com no máximo 24 h (o RPO da D-12): depois disso, um backup novo.
    """
    problems: list[str] = []
    dump: dict[str, Any] = {}
    if not (isinstance(backup, dict) and backup.get("kind") == BACKUP_KIND
            and backup.get("schema_version") == 1):
        problems.append(f"o L-01 não é um receipt {BACKUP_KIND} v1 ({BACKUP_TOOL})")
        backup = {}
    else:
        age = _age_problem("o L-01 (backup)", backup.get("recorded_at"), now)
        if age:
            problems.append(age)
        drill = backup.get("drill")
        if not (isinstance(drill, dict) and drill.get("status") == "passed"):
            problems.append("o L-01 não tem o ensaio de restauração aprovado (--drill)")
        cadence = backup.get("cadence")
        if not (isinstance(cadence, dict) and cadence.get("status") == "PASS"):
            problems.append("a cadência do L-01 não fechou (RPO, RTO e ensaio)")
        if isinstance(backup.get("backup"), dict):
            dump = backup["backup"]
    dump_sha = dump.get("sha256") if isinstance(dump.get("sha256"), str) \
        and SHA256.match(dump["sha256"]) else None
    if backup and dump_sha is None:
        problems.append("o L-01 não traz o SHA-256 do dump")
    rehearsed: dict[str, Any] = {}
    if not (isinstance(rehearsal, dict) and rehearsal.get("kind") == REHEARSAL_KIND
            and rehearsal.get("schema_version") == 1):
        problems.append(f"o L-02 não é um {REHEARSAL_KIND} v1 ({REHEARSAL_TOOL})")
        rehearsal = {}
    else:
        if rehearsal.get("resultado") != "PASS":
            problems.append(f"o L-02 (ensaio do upgrade) não passou: "
                            f"{rehearsal.get('resultado') or 'sem resultado'}")
        if rehearsal.get("restauracao") != "completo":
            problems.append("o L-02 tem de ser o ensaio completo (--restore completo)")
        age = _age_problem("o L-02 (ensaio do upgrade)", rehearsal.get("concluido_em"), now)
        if age:
            problems.append(age)
        if isinstance(rehearsal.get("dump"), dict):
            rehearsed = rehearsal["dump"]
        if dump_sha is not None and rehearsed.get("sha256") != dump_sha:
            problems.append("o L-02 não ensaiou o dump do L-01 (o SHA-256 do dump é outro)")
    return {
        "status": "PASS" if not problems else "BLOCKED",
        "max_age_hours": int(PROOF_MAX_AGE.total_seconds() // 3600),
        "backup": {
            "recorded_at": backup.get("recorded_at"),
            "dump_file": dump.get("file"),
            "dump_sha256": dump_sha,
            "drill": (backup.get("drill") or {}).get("status")
            if isinstance(backup.get("drill"), dict) else None,
            "cadence": (backup.get("cadence") or {}).get("status")
            if isinstance(backup.get("cadence"), dict) else None,
        },
        "rehearsal": {
            "completed_at": rehearsal.get("concluido_em"),
            "result": rehearsal.get("resultado"),
            "restore": rehearsal.get("restauracao"),
            "dump_sha256": rehearsed.get("sha256"),
        },
        "problems": problems,
    }


def _proof_file(path: Path) -> tuple[Any, str]:
    """Um receipt de prova: arquivo regular (não link), JSON, e o SHA-256 dele."""
    if path.is_symlink() or not path.is_file():
        raise InvalidInput(f"a prova não é um arquivo regular: {path}")
    raw = _read(path)
    try:
        return json.loads(raw), hashlib.sha256(raw.encode("utf-8")).hexdigest()
    except json.JSONDecodeError as error:
        raise InvalidInput(f"{path} não é JSON: {error}") from error


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


def parse_read(raw: str) -> tuple[dict[str, str], list[tuple[str, str]]]:
    """Uma leitura do banco: a identidade na primeira linha e o ledger depois."""
    lines = [line.strip() for line in raw.splitlines() if line.strip()]
    match = DATABASE_LINE.match(lines[0]) if lines else None
    database = promote.database_identity(
        {"name": match.group(1), "system_identifier": match.group(2)} if match else None)
    if database is None:
        raise InvalidInput("a leitura do banco não começa pela identidade "
                           "(current_database e system_identifier)")
    return database, parse_ledger("\n".join(lines[1:]))


def ledger_view(entries: list[tuple[str, str]], database: dict[str, str]) -> dict[str, Any]:
    text = "\n".join(f"{version}|{name}" for version, name in entries)
    return {
        "database": database,
        "latest": entries[-1][0] if entries else None,
        "count": len(entries),
        "versions": [version for version, _ in entries],
        "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
    }


def check_before(
    planned: dict[str, Any], entries: list[tuple[str, str]], database: dict[str, str],
) -> dict[str, Any]:
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
    return {"status": "PASS" if not problems else "BLOCKED",
            "ledger": ledger_view(entries, database), "problems": problems}


def check_after(
    planned: dict[str, Any], before: list[tuple[str, str]], after: list[tuple[str, str]],
    before_database: dict[str, str], after_database: dict[str, str],
) -> dict[str, Any]:
    """O ledger depois é o de antes mais o lote, com os nomes do código, no mesmo banco."""
    expected = dict(before)
    expected.update({item["version"]: item["name"] for item in planned["migrations"]})
    now = dict(after)
    missing = [version for version in sorted(expected) if version not in now]
    unexpected = [version for version in sorted(now) if version not in expected]
    renamed = [version for version in sorted(now)
               if version in expected and now[version] != expected[version]]
    problems = []
    if after_database != before_database:
        problems.append(f"o ledger de depois é do {promote.database_label(after_database)}, "
                        f"e o de antes, do {promote.database_label(before_database)}")
    problems += [f"o ledger depois não tem a {version}" for version in missing]
    problems += [f"o ledger depois tem a {version}, fora do lote" for version in unexpected]
    problems += [f"o ledger depois tem a {version} com outro nome" for version in renamed]
    latest = after[-1][0] if after else None
    if latest != planned["to"]:
        problems.append(f"o banco ficou na {latest or 'nenhuma'}, não na {planned['to']}")
    applied = [version for version in sorted(now) if version not in dict(before)]
    return {"status": "PASS" if not problems else "FAIL",
            "ledger": ledger_view(after, after_database),
            "applied": applied, "missing": missing, "unexpected": unexpected,
            "problems": problems}


def snapshot(entries: list[tuple[str, str]], database: dict[str, str]) -> dict[str, Any]:
    """O ledger no formato que a promoção aceita em --schema-snapshot (S-02)."""
    if not entries:
        raise InvalidInput("o ledger está vazio")
    view = ledger_view(entries, database)
    return {
        "kind": promote.SCHEMA_LEDGER_KIND,
        "schema_version": 1,
        "task": "S-05",
        "measured_at": _now(),
        "database": database,
        "latest_migration": view["latest"],
        "versions": view["versions"],
        "count": view["count"],
        "sha256": view["sha256"],
        "source": LEDGER_SOURCE,
    }


def _create_private(path: Path, text: str) -> None:
    """Cria um arquivo novo, só do dono (O_EXCL): evidência que existe nunca é sobrescrita."""
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError as error:
        raise InvalidInput(f"recuso sobrescrever {path}: já existe") from error
    except OSError as error:
        raise InvalidInput(f"não criei {path}: {error}") from error
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        handle.write(text)
    path.chmod(0o600)


def _write_private(path: Path, data: dict[str, Any]) -> None:
    _create_private(path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


# ------------------------------------------------------------ CLI


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    commands = parser.add_subparsers(dest="command", required=True)
    planned = commands.add_parser("plan")
    planned.add_argument("--policy", type=Path, required=True)
    planned.add_argument("--root", type=Path, default=REPO_ROOT)
    expect = commands.add_parser("expected")
    expect.add_argument("--plan", type=Path, required=True)
    expect.add_argument("--esperado", action="append", default=[])
    stepped = commands.add_parser("step-result")
    stepped.add_argument("--plan", type=Path, required=True)
    stepped.add_argument("--id", required=True)
    stepped.add_argument("--mode", required=True, choices=sorted(STEP_MODES))
    stepped.add_argument("--exit", type=int, required=True)
    stepped.add_argument("--stdout", type=Path, required=True)
    stepped.add_argument("--stderr", type=Path, required=True)
    stepped.add_argument("--expected", type=Path)
    proven = commands.add_parser("proofs")
    proven.add_argument("--backup-receipt", type=Path, required=True)
    proven.add_argument("--upgrade-rehearsal", type=Path, required=True)
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
    create = commands.add_parser("create")
    create.add_argument("--out", type=Path, required=True)
    receipt = commands.add_parser("receipt")
    receipt.add_argument("--out", type=Path, required=True)
    receipt.add_argument("--status", required=True, choices=sorted(STATUSES))
    receipt.add_argument("--sha", required=True)
    receipt.add_argument("--started-at", required=True)
    receipt.add_argument("--plan", type=Path, required=True)
    receipt.add_argument("--before", type=Path)
    receipt.add_argument("--after", type=Path)
    receipt.add_argument("--proofs", type=Path)
    receipt.add_argument("--expected", type=Path)
    receipt.add_argument("--steps", type=Path, action="append", default=[])
    receipt.add_argument("--migrate-exit", type=int)
    receipt.add_argument("--log")
    receipt.add_argument("--reason", default="")
    args = parser.parse_args(argv)

    try:
        if args.command == "plan":
            result = plan(load_policy(args.policy), _read(args.root / MIGRATE_SOURCE),
                          _read(args.root / promote.READINESS_SOURCE), args.root)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "expected":
            result = expected_counts(_json(args.plan), args.esperado)
            print(json.dumps(result, ensure_ascii=False))
            return 0
        if args.command == "step-result":
            given = None
            if args.expected:
                for item in _json(args.expected)["steps"]:
                    if item["id"] == args.id:
                        given = item["expected"]
            result = step_result(_json(args.plan), args.id, args.mode, args.exit,
                                 _read(args.stdout), _read(args.stderr), given)
            print(json.dumps(result, ensure_ascii=False))
            return {"preview": 0, "applied": 0, "refused": 3}.get(result["status"], 1)
        if args.command == "proofs":
            backup_data, backup_sha = _proof_file(args.backup_receipt)
            rehearsal_data, rehearsal_sha = _proof_file(args.upgrade_rehearsal)
            result = proofs(backup_data, rehearsal_data, dt.datetime.now(dt.timezone.utc))
            result["backup"].update(receipt=str(args.backup_receipt), receipt_sha256=backup_sha)
            result["rehearsal"].update(receipt=str(args.upgrade_rehearsal),
                                       receipt_sha256=rehearsal_sha)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "check-before":
            database, entries = parse_read(_read(args.ledger_raw))
            result = check_before(_json(args.plan), entries, database)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "check-after":
            before_database, before_entries = parse_read(_read(args.before_raw))
            after_database, after_entries = parse_read(_read(args.after_raw))
            result = check_after(_json(args.plan), before_entries, after_entries,
                                 before_database, after_database)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 1
        if args.command == "snapshot":
            database, entries = parse_read(_read(args.raw))
            data = snapshot(entries, database)
            _write_private(args.out, data)
            print(json.dumps({"status": "written", "out": str(args.out),
                              "latest_migration": data["latest_migration"],
                              "database": database}, ensure_ascii=False))
            return 0
        if args.command == "create":
            _create_private(args.out, "")
            print(json.dumps({"status": "created", "out": str(args.out)}, ensure_ascii=False))
            return 0
        planned_data = _json(args.plan)
        problems = list(planned_data.get("problems") or [])
        before_data = _json(args.before) if args.before else None
        after_data = _json(args.after) if args.after else None
        proofs_data = _json(args.proofs) if args.proofs else None
        for part in (proofs_data, before_data):
            if isinstance(part, dict):
                problems += part.get("problems") or []
        # Os passos antes da primeira migration: o que cada um fez, ou que não rodou.
        given = {item["id"]: item["expected"]
                 for item in (_json(args.expected)["steps"] if args.expected else [])}
        ran = {item["id"]: item for item in (_json(path) for path in args.steps)
               if isinstance(item, dict) and isinstance(item.get("id"), str)}
        steps_data = []
        for step in planned_data.get("before_first_migration") or []:
            if step["id"] in ran:
                steps_data.append(ran[step["id"]])
                problems += ran[step["id"]].get("problems") or []
            else:
                steps_data.append({"id": step["id"], "script": step["script"],
                                   "sha256": step.get("sha256"),
                                   "required_by": step.get("required_by"), "status": "not_run",
                                   "expected": given.get(step["id"])})
        if isinstance(after_data, dict):
            problems += after_data.get("problems") or []
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
            "proofs": proofs_data,
            "before_first_migration": steps_data,
            "database": ((before_data or {}).get("ledger") or {}).get("database"),
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
