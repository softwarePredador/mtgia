#!/usr/bin/env python3
"""BT-DR-001 (D-12, D-81): cadência do backup local e do ensaio de restauração.

A política (`server/config/backup_policy.json`) fixa o RPO e o RTO da D-12, o
destino local da D-81 e a cadência. Este módulo só lê arquivos da máquina de
operação: os dumps em `backups/manaloom-postgres/` e as evidências do ensaio
em `drills/<carimbo>/restore-result.json`. Não abre conexão nenhuma.

Subcomandos:
  validate-policy [--policy P]
  check --backup-dir D [--policy P] [--now ISO-8601]
  receipt --backup-dir D --backup-file F [--drill-evidence E] --git-sha S
          --out O [--policy P] [--now ISO-8601]

Saída: JSON em stdout. Código 0 quando válido ou PASS, 2 para entrada
inválida e 3 para BLOCKED (a cadência não está cumprida).
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_POLICY = REPO_ROOT / "server" / "config" / "backup_policy.json"
BACKUP_NAME = re.compile(r"^manaloom-postgres-(\d{8}T\d{6}Z)\.dump$")
UTC_TIMESTAMP = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
GIT_SHA = re.compile(r"^[0-9a-f]{40}$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
# O backup e as evidências não podem viver em cópia temporária ou worktree.
TEMPORARY_PATH = re.compile(
    r"(^|/)(tmp|private/tmp|var/folders)/|(^|/)\.claude/worktrees/|(^|/)worktrees?/"
)
RECEIPT_NUMBER = re.compile(r"\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?")


class InvalidInput(ValueError):
    """Entrada fora do contrato: o chamador recebe código 2."""


def _utc(text: str) -> dt.datetime:
    return dt.datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)


def _load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise InvalidInput(f"não li {path}: {error}") from error
    if not isinstance(data, dict):
        raise InvalidInput(f"{path} não é um objeto JSON")
    return data


def policy_problems(policy: dict[str, Any], repo_root: Path = REPO_ROOT) -> list[str]:
    """Lista o que falta na política; vazia quando ela vale."""
    problems: list[str] = []
    if policy.get("schema_version") != 1:
        problems.append("schema_version deve ser 1")
    objectives = policy.get("objectives")
    if not isinstance(objectives, dict):
        return problems + ["objectives ausente"]
    rpo = objectives.get("rpo_hours")
    rto = objectives.get("rto_hours")
    if not isinstance(rpo, int) or isinstance(rpo, bool) or rpo <= 0:
        problems.append("objectives.rpo_hours inválido")
    if not isinstance(rto, int) or isinstance(rto, bool) or rto <= 0:
        problems.append("objectives.rto_hours inválido")
    source = objectives.get("source")
    evidence = objectives.get("evidence")
    if isinstance(source, str) and isinstance(evidence, str):
        try:
            source_text = (repo_root / source).read_text(encoding="utf-8")
        except OSError:
            source_text = ""
            problems.append(f"objectives.source não encontrado: {source}")
        if source_text and evidence not in source_text:
            problems.append("objectives.evidence não está na fonte da decisão")
        numbers = [int(n) for n in re.findall(r"\d+", evidence)]
        if numbers != [rpo, rto]:
            problems.append("objectives.rpo_hours e rto_hours divergem da evidência")
    else:
        problems.append("objectives.source e objectives.evidence são obrigatórios")

    backup = policy.get("backup")
    if not isinstance(backup, dict):
        problems.append("backup ausente")
    else:
        if backup.get("offsite_copy") is not False:
            problems.append("backup.offsite_copy deve ser false (D-81)")
        if backup.get("destination") != "backups/manaloom-postgres/":
            problems.append("backup.destination deve ser backups/manaloom-postgres/ (D-81)")
        if backup.get("script") != "scripts/manaloom_easypanel_backup.sh":
            problems.append("backup.script deve ser scripts/manaloom_easypanel_backup.sh")
        retention = backup.get("retention_days")
        if retention is not None and (not isinstance(retention, int) or retention <= 0):
            problems.append("backup.retention_days deve ser nulo (não decidido) ou positivo")
        if not backup.get("retention_note"):
            problems.append(
                "backup.retention_note deve dizer a decisão do prazo ou por que não há prazo"
            )
    drill = policy.get("drill")
    if not isinstance(drill, dict) or drill.get("script") != "scripts/manaloom_full_restore_drill.sh":
        problems.append("drill.script deve ser scripts/manaloom_full_restore_drill.sh")
    elif drill.get("network") != "none":
        problems.append("o ensaio tem de ser isolado (drill.network = none)")

    cadence = policy.get("cadence")
    if not isinstance(cadence, dict):
        problems.append("cadence ausente")
    else:
        interval = cadence.get("backup_max_interval_hours")
        if not isinstance(interval, int) or interval <= 0:
            problems.append("cadence.backup_max_interval_hours inválido")
        elif isinstance(rpo, int) and interval > rpo:
            problems.append("cadence.backup_max_interval_hours não pode passar do RPO")
        days = cadence.get("drill_max_interval_days")
        if not isinstance(days, int) or days <= 0:
            problems.append("cadence.drill_max_interval_days inválido")
        rationale = cadence.get("rationale")
        expected = {"backup_max_interval_hours", "drill_max_interval_days",
                    "drill_after_production_migration"}
        if not isinstance(rationale, dict) or set(rationale) != expected:
            problems.append("cadence.rationale deve justificar cada item")

    runbook = policy.get("runbook")
    if not isinstance(runbook, str) or not runbook.startswith("docs/runbooks/"):
        problems.append("runbook tem de estar em docs/runbooks/")
    else:
        try:
            runbook_text = (repo_root / runbook).read_text(encoding="utf-8")
        except OSError:
            runbook_text = ""
            problems.append(f"runbook não encontrado: {runbook}")
        if runbook_text and isinstance(evidence, str) and evidence not in runbook_text:
            problems.append("o runbook não traz o RPO e o RTO da política")

    first = policy.get("first_cycle")
    if not isinstance(first, dict) or not isinstance(first.get("receipt"), str):
        problems.append("first_cycle.receipt ausente")
    else:
        receipt = first["receipt"]
        if not receipt.startswith("docs/qa/execution/") or ".." in Path(receipt).parts:
            problems.append("first_cycle.receipt tem de estar em docs/qa/execution/")
        else:
            try:
                receipt_text = (repo_root / receipt).read_text(encoding="utf-8")
            except OSError:
                receipt_text = ""
                problems.append(f"first_cycle.receipt não encontrado: {receipt}")
            for key, item in first.items():
                if key == "receipt" or not receipt_text:
                    continue
                if not isinstance(item, dict) or not isinstance(item.get("evidence"), str):
                    problems.append(f"first_cycle.{key}: esperado {{value, evidence}}")
                    continue
                if item["evidence"] not in receipt_text:
                    problems.append(f"first_cycle.{key}: evidence não está no receipt")
                    continue
                value = item.get("value")
                if isinstance(value, str):
                    if value not in item["evidence"]:
                        problems.append(f"first_cycle.{key}: {value} não aparece na evidence")
                elif isinstance(value, (int, float)) and not isinstance(value, bool):
                    numbers = [
                        float(n.replace(".", "").replace(",", "."))
                        for n in RECEIPT_NUMBER.findall(item["evidence"])
                    ]
                    if not any(abs(n - value) < 1e-9 for n in numbers):
                        problems.append(f"first_cycle.{key}: {value} não aparece na evidence")
                else:
                    problems.append(f"first_cycle.{key}: value inválido")
    return problems


def load_policy(path: Path) -> dict[str, Any]:
    policy = _load_json(path)
    problems = policy_problems(policy)
    if problems:
        raise InvalidInput("política inválida: " + "; ".join(problems))
    return policy


def durable_dir(path: Path) -> Path:
    resolved = path.expanduser().resolve()
    if TEMPORARY_PATH.search(str(resolved)):
        raise InvalidInput(
            f"o backup tem de ficar num diretório durável, não em {resolved}"
        )
    return resolved


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _backups(backup_dir: Path) -> list[tuple[dt.datetime, Path]]:
    found = []
    for path in backup_dir.glob("manaloom-postgres-*.dump"):
        match = BACKUP_NAME.match(path.name)
        if match and path.is_file() and path.stat().st_size >= 1024:
            stamp = dt.datetime.strptime(match.group(1), "%Y%m%dT%H%M%SZ").replace(
                tzinfo=dt.timezone.utc
            )
            found.append((stamp, path))
    return sorted(found)


def _drills(backup_dir: Path) -> list[dict[str, Any]]:
    drills = []
    for evidence in sorted((backup_dir / "drills").glob("*/restore-result.json")):
        try:
            data = json.loads(evidence.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(data, dict):
            continue
        data["_evidence"] = str(evidence.relative_to(backup_dir))
        drills.append(data)
    return drills


def check(backup_dir: Path, policy: dict[str, Any], now: dt.datetime) -> dict[str, Any]:
    """PASS com backup dentro do RPO e ensaio isolado recente, aprovado e no RTO."""
    backup_dir = durable_dir(backup_dir)
    cadence = policy["cadence"]
    rto_seconds = policy["objectives"]["rto_hours"] * 3600
    reasons: list[str] = []
    result: dict[str, Any] = {"policy_version": policy.get("version")}

    backups = _backups(backup_dir)
    if not backups:
        reasons.append("nenhum backup em " + str(backup_dir))
        result["latest_backup"] = None
    else:
        stamp, path = backups[-1]
        age_hours = (now - stamp).total_seconds() / 3600
        result["latest_backup"] = {
            "file": path.name,
            "bytes": path.stat().st_size,
            "created_at": stamp.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "age_hours": round(age_hours, 1),
        }
        if age_hours > cadence["backup_max_interval_hours"]:
            reasons.append(
                f"o último backup tem {age_hours:.1f} h; o RPO pede no máximo "
                f"{cadence['backup_max_interval_hours']} h"
            )

    by_name = {path.name: path for _, path in backups}
    passed = []
    for drill in _drills(backup_dir):
        if drill.get("status") != "passed" or drill.get("mode") != "full":
            continue
        if drill.get("runner") != policy["drill"]["runner"] or drill.get("remote_writes") is not False:
            continue
        started, completed = drill.get("started_at"), drill.get("completed_at")
        if not (isinstance(started, str) and isinstance(completed, str)
                and UTC_TIMESTAMP.match(started) and UTC_TIMESTAMP.match(completed)):
            continue
        drill["_duration_seconds"] = int((_utc(completed) - _utc(started)).total_seconds())
        drill["_completed"] = _utc(completed)
        passed.append(drill)
    if not passed:
        reasons.append("nenhum ensaio de restauração isolado aprovado")
        result["latest_drill"] = None
    else:
        latest = max(passed, key=lambda drill: drill["_completed"])
        # Só o dump do último ensaio é conferido: se ainda existir, o SHA-256
        # que o ensaio registrou tem de ser o do arquivo.
        backup_info = latest.get("backup") if isinstance(latest.get("backup"), dict) else {}
        restored = by_name.get(str(backup_info.get("file")))
        latest["_backup_matches"] = (
            None if restored is None else _sha256(restored) == backup_info.get("sha256")
        )
        age_days = (now - latest["_completed"]).total_seconds() / 86400
        result["latest_drill"] = {
            "evidence": latest["_evidence"],
            "backup_file": (latest.get("backup") or {}).get("file"),
            "completed_at": latest["completed_at"],
            "age_days": round(age_days, 2),
            "duration_seconds": latest["_duration_seconds"],
            "table_count": latest.get("table_count"),
            "backup_checksum_matches": latest["_backup_matches"],
        }
        if age_days > cadence["drill_max_interval_days"]:
            reasons.append(
                f"o último ensaio tem {age_days:.1f} dias; a cadência pede no máximo "
                f"{cadence['drill_max_interval_days']}"
            )
        if latest["_duration_seconds"] > rto_seconds:
            reasons.append(
                f"a restauração levou {latest['_duration_seconds']} s; o RTO é "
                f"{policy['objectives']['rto_hours']} h"
            )
        if latest["_backup_matches"] is False:
            reasons.append("o SHA-256 do dump ensaiado não bate com o arquivo do backup")
        min_tables = policy["drill"]["min_tables"]
        if not isinstance(latest.get("table_count"), int) or latest["table_count"] < min_tables:
            reasons.append(f"o ensaio restaurou menos de {min_tables} tabelas")
    result["retention"] = retention_report(backups, passed, policy, now)
    result["status"] = "PASS" if not reasons else "BLOCKED"
    result["reasons"] = reasons
    return result


def retention_report(
    backups: list[tuple[dt.datetime, Path]],
    passed: list[dict[str, Any]],
    policy: dict[str, Any],
    now: dt.datetime,
) -> dict[str, Any] | None:
    """D-84: os dumps vencidos pela guarda, só listados.

    Ficam sempre o dump mais novo e o mais novo com ensaio aprovado. Nada é
    apagado aqui: apagar pede o sim do dono na hora, até a rotação ser
    automatizada.
    """
    days = policy["backup"].get("retention_days")
    if not isinstance(days, int):
        return None
    drilled = {str((drill.get("backup") or {}).get("file")) for drill in passed
               if isinstance(drill.get("backup"), dict)}
    keep: set[str] = set()
    if backups:
        keep.add(backups[-1][1].name)
    newest_drilled = [path.name for _, path in backups if path.name in drilled]
    if newest_drilled:
        keep.add(newest_drilled[-1])
    expired = [
        path.name for stamp, path in backups
        if (now - stamp).total_seconds() > days * 86400 and path.name not in keep
    ]
    return {
        "days": days,
        "keep": sorted(keep),
        "expired": expired,
        "delete": "só com o sim do dono na hora (D-84); este check não apaga nada",
    }


def build_receipt(
    *,
    backup_dir: Path,
    backup_file: Path,
    drill_evidence: Path | None,
    git_sha: str,
    policy: dict[str, Any],
    now: dt.datetime,
) -> dict[str, Any]:
    backup_dir = durable_dir(backup_dir)
    backup_file = backup_file.expanduser().resolve()
    if backup_file.parent != backup_dir or not BACKUP_NAME.match(backup_file.name):
        raise InvalidInput("o dump do ciclo tem de estar no diretório do backup")
    if not GIT_SHA.match(git_sha):
        raise InvalidInput("git_sha inválido")
    drill = None
    if drill_evidence is not None:
        drill_evidence = drill_evidence.expanduser().resolve()
        if backup_dir not in drill_evidence.parents:
            raise InvalidInput("a evidência do ensaio tem de ficar em <backup>/drills/")
        data = _load_json(drill_evidence)
        drill = {
            "evidence": str(drill_evidence.relative_to(backup_dir)),
            "status": data.get("status"),
            "table_count": data.get("table_count"),
            "started_at": data.get("started_at"),
            "completed_at": data.get("completed_at"),
        }
    return {
        "schema_version": 1,
        "kind": "brewtact-backup-cycle",
        "decisions": policy.get("decisions"),
        "recorded_at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "tool_git_sha": git_sha,
        "backup": {
            "file": backup_file.name,
            "bytes": backup_file.stat().st_size,
            "sha256": _sha256(backup_file),
        },
        "drill": drill,
        "cadence": check(backup_dir, policy, now),
    }


def _parse_now(text: str | None) -> dt.datetime:
    if text is None:
        return dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
    if not UTC_TIMESTAMP.match(text):
        raise InvalidInput("--now deve ser UTC (AAAA-MM-DDTHH:MM:SSZ)")
    return _utc(text)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    commands = parser.add_subparsers(dest="command", required=True)
    validate = commands.add_parser("validate-policy")
    validate.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    verify = commands.add_parser("check")
    verify.add_argument("--backup-dir", type=Path, required=True)
    verify.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    verify.add_argument("--now")
    record = commands.add_parser("receipt")
    record.add_argument("--backup-dir", type=Path, required=True)
    record.add_argument("--backup-file", type=Path, required=True)
    record.add_argument("--drill-evidence", type=Path)
    record.add_argument("--git-sha", required=True)
    record.add_argument("--out", type=Path, required=True)
    record.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    record.add_argument("--now")
    args = parser.parse_args(argv)
    try:
        policy = load_policy(args.policy)
        if args.command == "validate-policy":
            print(json.dumps({"status": "valid", "version": policy.get("version")},
                             ensure_ascii=False))
            return 0
        now = _parse_now(args.now)
        if args.command == "check":
            result = check(args.backup_dir, policy, now)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        receipt = build_receipt(
            backup_dir=args.backup_dir,
            backup_file=args.backup_file,
            drill_evidence=args.drill_evidence,
            git_sha=args.git_sha,
            policy=policy,
            now=now,
        )
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + "\n",
                            encoding="utf-8")
        args.out.chmod(0o600)
        print(json.dumps({"status": receipt["cadence"]["status"], "receipt": str(args.out)},
                         ensure_ascii=False))
        return 0 if receipt["cadence"]["status"] == "PASS" else 3
    except InvalidInput as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    sys.exit(main())
