#!/usr/bin/env python3
"""BT-CAP-001 (D-14): política de capacidade versionada, snapshot e preflight.

A política (`server/config/capacity_policy.json`) guarda a leitura de base do
host de produção com procedência (cada número aponta para o texto do receipt
que o registrou) e os limites do preflight. O snapshot vem de
`scripts/manaloom_capacity_snapshot.sh`, que só lê o host e o PostgreSQL de
produção; este módulo monta o JSON dele, confere a procedência e decide o
preflight. Nada aqui abre conexão ou muda estado.

Subcomandos:
  validate-policy [--policy P]
  snapshot --host-raw H --postgres-raw G --ssh-target T --host-key K
           --git-sha S --tree-clean true|false [--out O]
  validate-snapshot SNAPSHOT [--policy P]
  preflight --snapshot S [--policy P] [--now ISO-8601]

Saída: JSON em stdout. Código 0 quando válido ou PASS, 2 para entrada
inválida e 3 para BLOCKED.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_POLICY = REPO_ROOT / "server" / "config" / "capacity_policy.json"
SNAPSHOT_TOOL = "scripts/manaloom_capacity_snapshot.sh"
SNAPSHOT_KIND = "brewtact-capacity-snapshot"
PROVENANCE_KIND = "production_ssh_readonly"
HOST_KEY = re.compile(r"^SHA256:[A-Za-z0-9+/]{43}$")
GIT_SHA = re.compile(r"^[0-9a-f]{40}$")
UTC_TIMESTAMP = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
# Número no formato do receipt: "7.941", "1,36", "70", "3.694".
RECEIPT_NUMBER = re.compile(r"\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?")
# Nenhuma procedência pode apontar para cópia temporária ou worktree.
TEMPORARY_PATH = re.compile(
    r"(^|/)(tmp|private/tmp|var/folders)/|(^|/)\.claude/worktrees/|(^|/)worktrees?/"
)

THRESHOLD_KEYS = {
    "memory_available_min_mb": (int, float),
    "disk_root_used_max_percent": (int, float),
    "disk_root_free_min_gib": (int, float),
    "swap_used_max_percent": (int, float),
    "load1_per_cpu_max": (int, float),
    "postgres_connections_used_max_percent": (int, float),
    "snapshot_max_age_minutes": (int,),
}


class InvalidInput(ValueError):
    """Entrada fora do contrato: o chamador recebe código 2."""


def _load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise InvalidInput(f"não li {path}: {error}") from error
    if not isinstance(data, dict):
        raise InvalidInput(f"{path} não é um objeto JSON")
    return data


def _receipt_numbers(evidence: str) -> list[float]:
    numbers = []
    for match in RECEIPT_NUMBER.findall(evidence):
        numbers.append(float(match.replace(".", "").replace(",", ".")))
    return numbers


def _check_evidence(
    problems: list[str], label: str, item: Any, receipt_text: str
) -> None:
    if not isinstance(item, dict):
        problems.append(f"{label}: esperado {{value, evidence}}")
        return
    value = item.get("value")
    evidence = item.get("evidence")
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        problems.append(f"{label}: value não é número")
        return
    if not isinstance(evidence, str) or not evidence.strip():
        problems.append(f"{label}: sem evidence")
        return
    if evidence not in receipt_text:
        problems.append(f"{label}: evidence não está no receipt: {evidence!r}")
        return
    if not any(abs(number - value) < 1e-9 for number in _receipt_numbers(evidence)):
        problems.append(f"{label}: {value} não aparece em {evidence!r}")


def _is_temporary(path_text: str) -> bool:
    return bool(TEMPORARY_PATH.search(path_text))


def policy_problems(policy: dict[str, Any], repo_root: Path = REPO_ROOT) -> list[str]:
    """Lista o que falta na política; vazia quando ela vale."""
    problems: list[str] = []
    if policy.get("schema_version") != 1:
        problems.append("schema_version deve ser 1")
    production = policy.get("production")
    if not isinstance(production, dict) or not isinstance(
        production.get("ssh_target"), str
    ):
        problems.append("production.ssh_target ausente")
    elif production.get("host_key_sha256") is not None and not (
        isinstance(production["host_key_sha256"], str)
        and HOST_KEY.match(production["host_key_sha256"])
    ):
        problems.append("production.host_key_sha256 deve ser nulo ou SHA256:<43>")

    baseline = policy.get("baseline")
    if not isinstance(baseline, dict):
        return problems + ["baseline ausente"]
    measured_at = baseline.get("measured_at")
    if not isinstance(measured_at, str) or not UTC_TIMESTAMP.match(measured_at):
        problems.append("baseline.measured_at deve ser UTC (AAAA-MM-DDTHH:MM:SSZ)")

    provenance = baseline.get("provenance")
    receipt_text = ""
    if not isinstance(provenance, dict):
        problems.append("baseline.provenance ausente")
    else:
        for key in ("kind", "receipt", "authorization", "measured_by", "method"):
            if not isinstance(provenance.get(key), str) or not provenance[key].strip():
                problems.append(f"baseline.provenance.{key} ausente")
        if provenance.get("kind") != "receipt":
            problems.append("baseline.provenance.kind deve ser receipt")
        receipt = provenance.get("receipt")
        if isinstance(receipt, str):
            receipt_path = Path(receipt)
            if receipt_path.is_absolute() or ".." in receipt_path.parts:
                problems.append("o receipt tem de ser um caminho relativo do repositório")
            elif _is_temporary(receipt):
                problems.append("o receipt não pode vir de cópia temporária")
            elif not receipt.startswith("docs/qa/execution/"):
                problems.append("o receipt tem de estar em docs/qa/execution/")
            else:
                try:
                    receipt_text = (repo_root / receipt_path).read_text(encoding="utf-8")
                except OSError:
                    problems.append(f"receipt não encontrado: {receipt}")
        section = provenance.get("section")
        if receipt_text and isinstance(section, str) and section not in receipt_text:
            problems.append("baseline.provenance.section não está no receipt")

    for group in ("host", "services", "after_xmage_scaled_to_zero"):
        entries = baseline.get(group)
        if not isinstance(entries, dict) or not entries:
            problems.append(f"baseline.{group} ausente")
            continue
        for name, item in entries.items():
            if group == "services":
                if not isinstance(item, dict) or not item:
                    problems.append(f"baseline.services.{name} vazio")
                    continue
                for metric, measured in item.items():
                    if receipt_text:
                        _check_evidence(
                            problems,
                            f"baseline.services.{name}.{metric}",
                            measured,
                            receipt_text,
                        )
            elif receipt_text:
                _check_evidence(problems, f"baseline.{group}.{name}", item, receipt_text)
    host = baseline.get("host")
    if isinstance(host, dict):
        for required in ("cpu_count", "memory_total_mb", "memory_available_mb",
                         "disk_root_used_percent", "disk_root_free_gib"):
            if required not in host:
                problems.append(f"baseline.host.{required} ausente")
    not_measured = baseline.get("not_measured")
    if not isinstance(not_measured, list) or not all(
        isinstance(item, str) for item in not_measured
    ):
        problems.append("baseline.not_measured deve listar o que a leitura não cobriu")

    thresholds = policy.get("thresholds")
    if not isinstance(thresholds, dict):
        problems.append("thresholds ausente")
    else:
        for key, types in THRESHOLD_KEYS.items():
            value = thresholds.get(key)
            if not isinstance(value, types) or isinstance(value, bool) or value <= 0:
                problems.append(f"thresholds.{key} inválido")
        for percent in ("disk_root_used_max_percent", "swap_used_max_percent",
                        "postgres_connections_used_max_percent"):
            value = thresholds.get(percent)
            if isinstance(value, (int, float)) and not 0 < value <= 100:
                problems.append(f"thresholds.{percent} fora de 0-100")
        rationale = thresholds.get("rationale")
        if not isinstance(rationale, dict) or set(rationale) != set(THRESHOLD_KEYS):
            problems.append("thresholds.rationale deve justificar cada limite")
        if not isinstance(thresholds.get("status"), str):
            problems.append("thresholds.status ausente")
    return problems


def load_policy(path: Path) -> dict[str, Any]:
    policy = _load_json(path)
    problems = policy_problems(policy)
    if problems:
        raise InvalidInput("política inválida: " + "; ".join(problems))
    return policy


# ---------------------------------------------------------------- snapshot

_SIZE_UNITS = {
    "b": 1,
    "kb": 1000,
    "kib": 1024,
    "mb": 1000**2,
    "mib": 1024**2,
    "gb": 1000**3,
    "gib": 1024**3,
    "tb": 1000**4,
    "tib": 1024**4,
}
_SIZE = re.compile(r"^\s*([0-9]+(?:\.[0-9]+)?)\s*([A-Za-z]+)\s*$")
_TASK_NAME = re.compile(r"^(?P<service>.+)\.\d+\.[a-z0-9]{10,}$")


def _size_bytes(text: str) -> float:
    match = _SIZE.match(text)
    if not match or match.group(2).lower() not in _SIZE_UNITS:
        raise InvalidInput(f"tamanho inesperado no docker stats: {text!r}")
    return float(match.group(1)) * _SIZE_UNITS[match.group(2).lower()]


def _sections(raw: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current: str | None = None
    for line in raw.splitlines():
        if line.startswith("### "):
            current = line[4:].strip()
            if current in sections:
                raise InvalidInput(f"seção repetida na leitura do host: {current}")
            sections[current] = []
        elif current is not None:
            sections[current].append(line)
    expected = {"date", "nproc", "meminfo", "loadavg", "uptime", "kernel", "df",
                "docker_stats", "docker_services", "docker_resources", "end"}
    missing = expected - set(sections)
    if missing:
        raise InvalidInput("leitura do host incompleta: falta " + ", ".join(sorted(missing)))
    return sections


def parse_host(raw: str) -> tuple[str, dict[str, Any], list[dict[str, Any]]]:
    """Leitura do host -> (measured_at, host, serviços)."""
    sections = _sections(raw)
    measured_at = sections["date"][0].strip() if sections["date"] else ""
    if not UTC_TIMESTAMP.match(measured_at):
        raise InvalidInput(f"data do host inválida: {measured_at!r}")

    meminfo: dict[str, int] = {}
    for line in sections["meminfo"]:
        match = re.match(r"^(\w+):\s+(\d+)\s*kB$", line.strip())
        if match:
            meminfo[match.group(1)] = int(match.group(2))
    for key in ("MemTotal", "MemAvailable", "SwapTotal", "SwapFree"):
        if key not in meminfo:
            raise InvalidInput(f"/proc/meminfo sem {key}")
    load = sections["loadavg"][0].split()
    uptime_seconds = float(sections["uptime"][0].split()[0])
    df_lines = [line for line in sections["df"] if line.strip()]
    df_fields = df_lines[-1].split()
    total_bytes, used_bytes, free_bytes = (int(df_fields[1]), int(df_fields[2]),
                                           int(df_fields[3]))
    swap_total_mb = round(meminfo["SwapTotal"] / 1024)
    swap_used_mb = round((meminfo["SwapTotal"] - meminfo["SwapFree"]) / 1024)
    host = {
        "cpu_count": int(sections["nproc"][0].strip()),
        "memory_total_mb": round(meminfo["MemTotal"] / 1024),
        "memory_available_mb": round(meminfo["MemAvailable"] / 1024),
        "swap_total_mb": swap_total_mb,
        "swap_used_mb": swap_used_mb,
        "swap_used_percent": (
            round(100 * swap_used_mb / swap_total_mb, 1) if swap_total_mb else 0.0
        ),
        "load1": float(load[0]),
        "load5": float(load[1]),
        "load15": float(load[2]),
        "uptime_days": int(uptime_seconds // 86400),
        "kernel": sections["kernel"][0].strip(),
        "disk_root_total_gib": round(total_bytes / 1024**3, 1),
        "disk_root_free_gib": round(free_bytes / 1024**3, 1),
        # Como o df: usado sobre (usado + livre para usuários).
        "disk_root_used_percent": round(100 * used_bytes / (used_bytes + free_bytes), 1),
    }

    services: dict[str, dict[str, Any]] = {}

    def service(name: str) -> dict[str, Any]:
        return services.setdefault(name, {"name": name, "containers": 0})

    for line in sections["docker_services"]:
        if not line.strip():
            continue
        entry = json.loads(line)
        item = service(entry["Name"])
        item["replicas"] = entry.get("Replicas", "")
        item["mode"] = entry.get("Mode", "")
        item["image"] = entry.get("Image", "")
    for line in sections["docker_resources"]:
        if not line.strip():
            continue
        name, _, resources = line.partition("\t")
        service(name.strip())["resources"] = json.loads(resources) if resources.strip() else {}
    for line in sections["docker_stats"]:
        if not line.strip():
            continue
        entry = json.loads(line)
        container = entry["Name"]
        match = _TASK_NAME.match(container)
        item = service(match.group("service") if match else container)
        item["containers"] += 1
        # Contêiner subindo ou parando aparece com "--": fica sem leitura.
        try:
            used_text, _, limit_text = entry["MemUsage"].partition("/")
            used_mib = _size_bytes(used_text) / 1024**2
            limit_mib = _size_bytes(limit_text) / 1024**2
            cpu = float(entry["CPUPerc"].rstrip("%"))
        except (InvalidInput, ValueError, KeyError, AttributeError):
            item["containers_without_stats"] = item.get("containers_without_stats", 0) + 1
            continue
        item["memory_used_mib"] = round(item.get("memory_used_mib", 0) + used_mib, 1)
        item["memory_limit_mib"] = round(limit_mib, 1)
        item["cpu_percent"] = round(item.get("cpu_percent", 0.0) + cpu, 2)
    ordered = sorted(services.values(), key=lambda item: item["name"])
    for item in ordered:
        item["project"] = "evolution" if item["name"].startswith("evolution_") else "outro"
    return measured_at, host, ordered


def parse_postgres(raw: str) -> dict[str, Any]:
    """Saída de capacity_postgres.sql (psql -A -t -F TAB) -> dicionário."""
    values: dict[str, str] = {}
    relations: list[dict[str, Any]] = []
    schemas: dict[str, int] = {}
    states: dict[str, int] = {}
    for line in raw.splitlines():
        if not line.strip() or "\t" not in line:
            continue
        key, _, value = line.partition("\t")
        if key.startswith("relation_bytes:"):
            relations.append({"name": key.split(":", 1)[1], "bytes": int(value)})
        elif key.startswith("schema_bytes:"):
            schemas[key.split(":", 1)[1]] = int(value)
        elif key.startswith("connections_state:"):
            states[key.split(":", 1)[1]] = int(value)
        else:
            values[key] = value
    for required in ("transaction_read_only", "server_version", "max_connections",
                     "shared_buffers", "database_size_bytes", "connections_total"):
        if required not in values:
            raise InvalidInput(f"leitura do PostgreSQL sem {required}")
    if values["transaction_read_only"] != "on":
        raise InvalidInput("a leitura do PostgreSQL não rodou em transação READ ONLY")
    return {
        "transaction_read_only": values["transaction_read_only"],
        "server_version": values["server_version"],
        "max_connections": int(values["max_connections"]),
        "shared_buffers": values["shared_buffers"],
        "effective_cache_size": values.get("effective_cache_size", ""),
        "work_mem": values.get("work_mem", ""),
        "database_size_bytes": int(values["database_size_bytes"]),
        "connections_total": int(values["connections_total"]),
        "connections_by_state": dict(sorted(states.items())),
        "largest_relations": relations,
        "schema_bytes": dict(sorted(schemas.items())),
    }


def build_snapshot(
    *,
    host_raw: str,
    postgres_raw: str,
    ssh_target: str,
    host_key: str,
    git_sha: str,
    tree_clean: bool,
    collected_at: str,
) -> dict[str, Any]:
    measured_at, host, services = parse_host(host_raw)
    return {
        "schema_version": 1,
        "kind": SNAPSHOT_KIND,
        "measured_at": measured_at,
        "provenance": {
            "kind": PROVENANCE_KIND,
            "authorization": "D-14",
            "ssh_target": ssh_target,
            "host_key_sha256": host_key,
            "tool": SNAPSHOT_TOOL,
            "tool_git_sha": git_sha,
            "tool_tree_clean": tree_clean,
            "collected_at": collected_at,
        },
        "host": host,
        "services": services,
        "postgres": parse_postgres(postgres_raw),
    }


def snapshot_problems(snapshot: dict[str, Any], policy: dict[str, Any]) -> list[str]:
    """A procedência exige leitura do host de produção pela ferramenta versionada."""
    problems: list[str] = []
    if snapshot.get("schema_version") != 1 or snapshot.get("kind") != SNAPSHOT_KIND:
        problems.append("não é um snapshot de capacidade v1")
    measured_at = snapshot.get("measured_at")
    if not isinstance(measured_at, str) or not UTC_TIMESTAMP.match(measured_at):
        problems.append("measured_at deve ser UTC (AAAA-MM-DDTHH:MM:SSZ)")
    provenance = snapshot.get("provenance")
    if not isinstance(provenance, dict):
        return problems + ["provenance ausente"]
    if provenance.get("kind") != PROVENANCE_KIND:
        problems.append("provenance.kind deve ser production_ssh_readonly")
    if provenance.get("ssh_target") != policy["production"]["ssh_target"]:
        problems.append("provenance.ssh_target não é o host de produção da política")
    if not isinstance(provenance.get("host_key_sha256"), str) or not HOST_KEY.match(
        provenance["host_key_sha256"]
    ):
        problems.append("provenance.host_key_sha256 ausente ou inválido")
    pinned = policy["production"].get("host_key_sha256")
    if pinned is not None and provenance.get("host_key_sha256") != pinned:
        problems.append("provenance.host_key_sha256 diverge da âncora fixada na política")
    # A ferramenta é a versionada, pelo caminho do repositório: um caminho
    # absoluto (cópia em /tmp ou worktree) não vale.
    if provenance.get("tool") != SNAPSHOT_TOOL:
        problems.append(f"provenance.tool deve ser {SNAPSHOT_TOOL}")
    if not isinstance(provenance.get("tool_git_sha"), str) or not GIT_SHA.match(
        provenance["tool_git_sha"]
    ):
        problems.append("provenance.tool_git_sha ausente ou inválido")
    host = snapshot.get("host")
    if not isinstance(host, dict):
        problems.append("host ausente")
    postgres = snapshot.get("postgres")
    if not isinstance(postgres, dict):
        problems.append("postgres ausente")
    elif postgres.get("transaction_read_only") != "on":
        problems.append("a leitura do PostgreSQL não foi só de leitura")
    return problems


def preflight(
    snapshot: dict[str, Any], policy: dict[str, Any], now: dt.datetime
) -> dict[str, Any]:
    """PASS só com procedência válida, snapshot fresco e folga em tudo."""
    reasons = snapshot_problems(snapshot, policy)
    limits = policy["thresholds"]
    checks: dict[str, Any] = {}
    if not reasons:
        measured = dt.datetime.strptime(
            snapshot["measured_at"], "%Y-%m-%dT%H:%M:%SZ"
        ).replace(tzinfo=dt.timezone.utc)
        age_minutes = (now - measured).total_seconds() / 60
        checks["snapshot_age_minutes"] = round(age_minutes, 1)
        if age_minutes < -5:
            reasons.append("snapshot com data no futuro")
        elif age_minutes > limits["snapshot_max_age_minutes"]:
            reasons.append(
                f"snapshot com {age_minutes:.0f} min; o limite é "
                f"{limits['snapshot_max_age_minutes']} min"
            )
        host = snapshot["host"]
        postgres = snapshot["postgres"]
        comparisons = [
            ("memory_available_mb", host["memory_available_mb"], ">=",
             limits["memory_available_min_mb"]),
            ("disk_root_used_percent", host["disk_root_used_percent"], "<=",
             limits["disk_root_used_max_percent"]),
            ("disk_root_free_gib", host["disk_root_free_gib"], ">=",
             limits["disk_root_free_min_gib"]),
            ("load1_per_cpu", round(host["load1"] / host["cpu_count"], 2), "<=",
             limits["load1_per_cpu_max"]),
            ("postgres_connections_used_percent",
             round(100 * postgres["connections_total"] / postgres["max_connections"], 1),
             "<=", limits["postgres_connections_used_max_percent"]),
        ]
        if host["swap_total_mb"]:
            comparisons.append(("swap_used_percent", host["swap_used_percent"], "<=",
                                limits["swap_used_max_percent"]))
        else:
            checks["swap_used_percent"] = "sem swap no host"
        for name, value, operator, limit in comparisons:
            ok = value >= limit if operator == ">=" else value <= limit
            checks[name] = {"value": value, "limit": f"{operator} {limit}", "ok": ok}
            if not ok:
                reasons.append(f"{name} = {value}, exige {operator} {limit}")
    return {
        "status": "PASS" if not reasons else "BLOCKED",
        "policy_version": policy.get("version"),
        "measured_at": snapshot.get("measured_at"),
        "checks": checks,
        "reasons": reasons,
    }


def _parse_now(text: str | None) -> dt.datetime:
    if text is None:
        return dt.datetime.now(dt.timezone.utc)
    if not UTC_TIMESTAMP.match(text):
        raise InvalidInput("--now deve ser UTC (AAAA-MM-DDTHH:MM:SSZ)")
    return dt.datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    commands = parser.add_subparsers(dest="command", required=True)
    validate = commands.add_parser("validate-policy")
    validate.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    snapshot = commands.add_parser("snapshot")
    snapshot.add_argument("--host-raw", type=Path, required=True)
    snapshot.add_argument("--postgres-raw", type=Path, required=True)
    snapshot.add_argument("--ssh-target", required=True)
    snapshot.add_argument("--host-key", required=True)
    snapshot.add_argument("--git-sha", required=True)
    snapshot.add_argument("--tree-clean", choices=("true", "false"), required=True)
    snapshot.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    snapshot.add_argument("--out", type=Path)
    check = commands.add_parser("validate-snapshot")
    check.add_argument("snapshot", type=Path)
    check.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    gate = commands.add_parser("preflight")
    gate.add_argument("--snapshot", type=Path, required=True)
    gate.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    gate.add_argument("--now")
    args = parser.parse_args(argv)

    try:
        if args.command == "validate-policy":
            policy = load_policy(args.policy)
            print(json.dumps({"status": "valid", "version": policy.get("version")},
                             ensure_ascii=False))
            return 0
        policy = load_policy(args.policy)
        if args.command == "snapshot":
            result = build_snapshot(
                host_raw=args.host_raw.read_text(encoding="utf-8"),
                postgres_raw=args.postgres_raw.read_text(encoding="utf-8"),
                ssh_target=args.ssh_target,
                host_key=args.host_key,
                git_sha=args.git_sha,
                tree_clean=args.tree_clean == "true",
                collected_at=dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            )
            problems = snapshot_problems(result, policy)
            if problems:
                raise InvalidInput("snapshot sem procedência: " + "; ".join(problems))
            text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
            if args.out:
                args.out.write_text(text, encoding="utf-8")
            else:
                sys.stdout.write(text)
            return 0
        if args.command == "validate-snapshot":
            problems = snapshot_problems(_load_json(args.snapshot), policy)
            print(json.dumps({"status": "valid" if not problems else "invalid",
                              "problems": problems}, ensure_ascii=False))
            return 0 if not problems else 2
        result = preflight(_load_json(args.snapshot), policy, _parse_now(args.now))
        print(json.dumps(result, ensure_ascii=False))
        return 0 if result["status"] == "PASS" else 3
    except InvalidInput as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    sys.exit(main())
