#!/usr/bin/env python3
"""BT-CAP-002 (D-14): reservas e limites por serviço, com preflight e rollback exato.

Lógica sem conexão. O orquestrador `scripts/manaloom_capacity_resources.sh` lê o
EasyPanel (`projects.listProjectsAndServices`) e o Swarm (`docker service inspect`
e `docker service ps`), chama este módulo e só muda o que ele aprovar.

Quem manda nos recursos é o EasyPanel: um deploy dele recria a spec do Swarm com o
que está gravado lá. Por isso a aplicação grava nos dois lugares (updateResources no
EasyPanel, sem deployService, e `docker service update` só com as flags de recursos
no Swarm) e confere a spec inteira: depois de aplicar, só `TaskTemplate.Resources`
pode ter mudado; depois do rollback, a spec tem de ser idêntica à de antes (imagem,
env, recursos e deploy). O receipt guarda impressões digitais SHA-256 da spec e do que o EasyPanel
tem gravado (imagem, env e deploy), nunca os valores do env.

Nada do que a ferramenta grava em disco leva valor de env: a leitura do Swarm e a do
EasyPanel passam por `redact-inspect` e `redact-easypanel` antes de virar arquivo, e
cada valor vira `sha256:<hex>` (a impressão digital continua mudando com o valor).

Subcomandos:
  redact-inspect < saída de docker service inspect
  redact-easypanel --project PROJETO < resposta de projects.listProjectsAndServices
  plan --service NOME --snapshot S --easypanel E --inspect I --running R
       [--policy P] [--now AAAA-MM-DDTHH:MM:SSZ]
  check-apply --plan PLANO --inspect I --easypanel E --running R
  rollback-decision --receipt RECEIPT --inspect I --easypanel E
  check-rollback --receipt RECEIPT --inspect I --easypanel E --running R
  converged --inspect I --running R
  receipt --plan PLANO --status S [--apply-check C] [--rollback-check RC]
          --tool-git-sha SHA --out ARQUIVO

Saída JSON em stdout. Códigos: 0 PASS, 1 FAIL, 2 entrada inválida, 3 BLOCKED.
"""

from __future__ import annotations

import argparse
import copy
import datetime as dt
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent
DEFAULT_POLICY = REPO_ROOT / "server" / "config" / "capacity_policy.json"
TOOL = "scripts/manaloom_capacity_resources.sh"
RECEIPT_KIND = "brewtact-capacity-resources-receipt"
MIB = 1024 * 1024
NANO = 1_000_000_000
DIGEST_IMAGE = re.compile(r"@sha256:[0-9a-f]{64}$")
HASHED = re.compile(r"^sha256:[0-9a-f]{64}$")
EASYPANEL_FIELDS = ("projectName", "name", "type", "deploy", "resources")
SETTLED_UPDATE = {"", "completed", "rollback_completed"}

_spec = importlib.util.spec_from_file_location(
    "bt_cap_001_policy", HERE / "manaloom_capacity_policy.py"
)
capacity = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
sys.modules[_spec.name] = capacity
_spec.loader.exec_module(capacity)
InvalidInput = capacity.InvalidInput


# ------------------------------------------------------------ leitura


def _canonical(data: Any) -> str:
    return json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def spec_fingerprint(spec: dict[str, Any], *, without_resources: bool = False) -> str:
    """SHA-256 da spec inteira (imagem, env, recursos, deploy, rede e rótulos)."""
    data = copy.deepcopy(spec)
    if without_resources:
        (data.get("TaskTemplate") or {}).pop("Resources", None)
    return hashlib.sha256(_canonical(data).encode("utf-8")).hexdigest()


def _hashed(value: str) -> str:
    """Valor -> sha256:<hex>; já no formato, fica como está (idempotente)."""
    if HASHED.match(value):
        return value
    return "sha256:" + hashlib.sha256(value.encode("utf-8")).hexdigest()


def redact_inspect(raw: str) -> str:
    """Saída do `docker service inspect` sem valor de env (Spec e PreviousSpec)."""
    service = load_inspect(raw)
    for key in ("Spec", "PreviousSpec"):
        container = ((service.get(key) or {}).get("TaskTemplate") or {}).get("ContainerSpec")
        if isinstance(container, dict) and isinstance(container.get("Env"), list):
            redacted = []
            for item in container["Env"]:
                if not isinstance(item, str):
                    raise InvalidInput("Env com item que não é texto")
                name, separator, value = item.partition("=")
                redacted.append(f"{name}={_hashed(value)}" if separator else name)
            container["Env"] = redacted
    return json.dumps([service], ensure_ascii=False)


def redact_easypanel(raw: str, project: str) -> str:
    """Só os serviços do projeto, só os campos usados, e o env como impressão digital."""
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as error:
        raise InvalidInput(f"resposta do EasyPanel ilegível: {error}") from error
    services = ((data or {}).get("json") or {}).get("services")
    if not isinstance(services, list):
        raise InvalidInput("resposta do EasyPanel sem json.services")
    kept = []
    for item in services:
        if not isinstance(item, dict) or item.get("projectName") != project:
            continue
        entry = {key: item[key] for key in EASYPANEL_FIELDS if key in item}
        entry["source"] = {"image": (item.get("source") or {}).get("image")}
        entry["env"] = _hashed(str(item.get("env") or ""))
        kept.append(entry)
    return json.dumps({"json": {"services": kept}}, ensure_ascii=False)


def load_inspect(raw: str) -> dict[str, Any]:
    """Saída de `docker service inspect <serviço>`: uma lista com um serviço."""
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as error:
        raise InvalidInput(f"docker service inspect ilegível: {error}") from error
    if not isinstance(data, list) or len(data) != 1 or not isinstance(data[0], dict):
        raise InvalidInput("docker service inspect deve trazer exatamente um serviço")
    service = data[0]
    if not isinstance(service.get("Spec"), dict):
        raise InvalidInput("docker service inspect sem Spec")
    return service


def load_easypanel(raw: str, project: str, name: str) -> dict[str, Any] | None:
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as error:
        raise InvalidInput(f"resposta do EasyPanel ilegível: {error}") from error
    services = ((data or {}).get("json") or {}).get("services")
    if not isinstance(services, list):
        raise InvalidInput("resposta do EasyPanel sem json.services")
    matches = [item for item in services if isinstance(item, dict)
               and item.get("projectName") == project and item.get("name") == name]
    if len(matches) > 1:
        raise InvalidInput(f"o EasyPanel tem {len(matches)} serviços {project}/{name}")
    return matches[0] if matches else None


def running_tasks(raw: str) -> list[dict[str, str]]:
    """Linhas `imagem|estado` de `docker service ps --filter desired-state=running`."""
    tasks = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        image, _, state = line.partition("|")
        tasks.append({"image": image.strip(), "state": state.strip()})
    return tasks


def swarm_resources(spec: dict[str, Any]) -> dict[str, int]:
    resources = (spec.get("TaskTemplate") or {}).get("Resources") or {}
    limits = resources.get("Limits") or {}
    reservations = resources.get("Reservations") or {}
    return {
        "memory_limit_bytes": int(limits.get("MemoryBytes") or 0),
        "memory_reservation_bytes": int(reservations.get("MemoryBytes") or 0),
        "cpu_limit_nano": int(limits.get("NanoCPUs") or 0),
        "cpu_reservation_nano": int(reservations.get("NanoCPUs") or 0),
    }


def easypanel_resources(entry: dict[str, Any]) -> dict[str, float] | None:
    resources = entry.get("resources")
    if not isinstance(resources, dict):
        return None
    keys = ("memoryReservation", "memoryLimit", "cpuReservation", "cpuLimit")
    normalized = {}
    for key in keys:
        value = resources.get(key)
        if value is None:
            value = 0
        if not isinstance(value, (int, float)) or isinstance(value, bool) or value < 0:
            return None
        normalized[key] = value
    return normalized


def easypanel_as_swarm(resources: dict[str, float]) -> dict[str, int]:
    return {
        "memory_limit_bytes": int(round(resources["memoryLimit"] * MIB)),
        "memory_reservation_bytes": int(round(resources["memoryReservation"] * MIB)),
        "cpu_limit_nano": int(round(resources["cpuLimit"] * NANO)),
        "cpu_reservation_nano": int(round(resources["cpuReservation"] * NANO)),
    }


def easypanel_view(entry: dict[str, Any]) -> dict[str, Any]:
    """O que o EasyPanel recria no próximo deploy, sem valor de env."""
    env_text = str(entry.get("env") or "")
    return {
        "image": (entry.get("source") or {}).get("image"),
        "env_sha256": _hashed(env_text)[len("sha256:"):],
        "deploy_sha256": hashlib.sha256(_canonical(entry.get("deploy")).encode("utf-8")).hexdigest(),
        "resources": easypanel_resources(entry),
    }


def desired_easypanel(entry: dict[str, Any]) -> dict[str, float]:
    return {
        "memoryReservation": entry["memory_reservation_mb"],
        "memoryLimit": entry["memory_limit_mb"],
        "cpuReservation": entry["cpu_reservation"],
        "cpuLimit": entry["cpu_limit"],
    }


def _cpu_text(nano: int) -> str:
    text = f"{nano / NANO:.9f}".rstrip("0").rstrip(".")
    return text or "0"


def swarm_flags(desired_swarm: dict[str, int]) -> dict[str, str]:
    """Os valores exatos das flags de `docker service update`, sem depender do jq."""
    return {
        "limit_memory": str(desired_swarm["memory_limit_bytes"]),
        "reserve_memory": str(desired_swarm["memory_reservation_bytes"]),
        "limit_cpu": _cpu_text(desired_swarm["cpu_limit_nano"]),
        "reserve_cpu": _cpu_text(desired_swarm["cpu_reservation_nano"]),
    }


def _replicas(spec: dict[str, Any]) -> int | None:
    replicated = (spec.get("Mode") or {}).get("Replicated")
    if isinstance(replicated, dict) and isinstance(replicated.get("Replicas"), int):
        return replicated["Replicas"]
    return None


def _update_state(service: dict[str, Any]) -> str:
    status = service.get("UpdateStatus")
    if isinstance(status, dict):
        return str(status.get("State") or "")
    return ""


def deploy_view(service: dict[str, Any]) -> dict[str, Any]:
    """O que o receipt guarda do serviço, sem valor de env."""
    spec = service["Spec"]
    container = (spec.get("TaskTemplate") or {}).get("ContainerSpec") or {}
    env = container.get("Env") or []
    return {
        "image": container.get("Image", ""),
        "replicas": _replicas(spec),
        "env_keys": sorted({item.split("=", 1)[0] for item in env if isinstance(item, str)}),
        "env_sha256": hashlib.sha256(_canonical(sorted(env)).encode("utf-8")).hexdigest(),
        "resources": swarm_resources(spec),
        "update_config": spec.get("UpdateConfig"),
        "rollback_config": spec.get("RollbackConfig"),
        "spec_sha256": spec_fingerprint(spec),
        "spec_sha256_without_resources": spec_fingerprint(spec, without_resources=True),
        "version": (service.get("Version") or {}).get("Index"),
        "update_state": _update_state(service),
    }


# ------------------------------------------------------------ plano e preflight


def _reservations_on_node(snapshot: dict[str, Any], skip: str) -> tuple[int, int]:
    """Reservas de memória e CPU de todos os serviços do nó, menos [skip]."""
    memory = cpu = 0
    for service in snapshot.get("services", []):
        if service.get("name") == skip:
            continue
        replicas = str(service.get("replicas", ""))
        running = int(replicas.split("/", 1)[0]) if re.match(r"^\d+/\d+$", replicas) else 0
        reservations = (service.get("resources") or {}).get("Reservations") or {}
        memory += int(reservations.get("MemoryBytes") or 0) * running
        cpu += int(reservations.get("NanoCPUs") or 0) * running
    return memory, cpu


def plan(
    *,
    service_name: str,
    policy: dict[str, Any],
    snapshot: dict[str, Any],
    easypanel_raw: str,
    inspect_raw: str,
    running_raw: str,
    now: dt.datetime,
) -> dict[str, Any]:
    """PASS só quando aplicar os recursos da política é seguro e reversível."""
    reasons: list[str] = []
    section = policy["reservations_and_limits"]
    project = policy["production"]["easypanel_project"]
    swarm_name = f"{project}_{service_name}"
    entry = section["services"].get(service_name)
    result: dict[str, Any] = {
        "task": "BT-CAP-002",
        "service": service_name,
        "swarm_service": swarm_name,
        "policy_version": policy.get("version"),
    }
    if entry is None:
        return {**result, "status": "BLOCKED",
                "reasons": [f"{service_name} não está na política (outro projeto ou serviço novo)"]}
    if entry["applied_by"] != capacity.RESOURCE_TOOL:
        return {**result, "status": "BLOCKED", "reasons": [
            f"os recursos de {service_name} não são desta ferramenta: {entry['applied_by']}"]}

    gate = capacity.preflight(snapshot, policy, now)
    result["capacity_preflight"] = {key: gate[key] for key in ("status", "measured_at", "reasons")}
    if gate["status"] != "PASS":
        reasons.append("preflight de capacidade BLOCKED: " + "; ".join(gate["reasons"]))

    service = load_inspect(inspect_raw)
    spec = service["Spec"]
    if spec.get("Name") != swarm_name:
        raise InvalidInput(f"a spec lida é de {spec.get('Name')}, não de {swarm_name}")
    before = deploy_view(service)
    tasks = running_tasks(running_raw)
    easypanel_entry = load_easypanel(easypanel_raw, project, service_name)
    desired = desired_easypanel(entry)
    desired_swarm = easypanel_as_swarm(desired)
    result.update({
        "before": before,
        "desired": {"easypanel": desired, "swarm": desired_swarm,
                    "flags": swarm_flags(desired_swarm)},
        "running_tasks": len(tasks),
    })

    # Deploy estável e reversível: réplicas no ar com a imagem da spec, por digest.
    replicas = before["replicas"]
    if replicas is None or replicas < 1:
        reasons.append(f"{swarm_name} sem réplicas no ar ({replicas}); nada a proteger agora")
    elif len(tasks) != replicas or any(
        task["image"] != before["image"] or not task["state"].startswith("Running")
        for task in tasks
    ):
        reasons.append(f"{swarm_name} não convergiu: {len(tasks)}/{replicas} tarefas com a imagem da spec")
    if not DIGEST_IMAGE.search(before["image"]):
        reasons.append(f"a imagem da spec não é um digest imutável: {before['image']}")
    if before["update_state"] not in SETTLED_UPDATE:
        reasons.append(f"atualização do Swarm em andamento: {before['update_state']}")

    # O EasyPanel e o Swarm têm de concordar: senão o próximo deploy muda outra coisa.
    if easypanel_entry is None:
        reasons.append(f"o EasyPanel não tem o serviço {project}/{service_name}")
    else:
        if easypanel_entry.get("type") != "app":
            reasons.append(f"o serviço {service_name} não é app no EasyPanel")
        configured = (easypanel_entry.get("source") or {}).get("image")
        if configured != before["image"]:
            reasons.append("a imagem gravada no EasyPanel diverge da spec do Swarm; um deploy "
                           f"do EasyPanel trocaria a imagem ({configured} != {before['image']})")
        view = easypanel_view(easypanel_entry)
        result["before"]["easypanel"] = view
        if view["resources"] is None:
            reasons.append("o EasyPanel não devolveu resources legíveis para o serviço")
        elif easypanel_as_swarm(view["resources"]) != before["resources"]:
            reasons.append("os recursos do EasyPanel divergem dos da spec do Swarm")

    # Reservas: a soma do nó cabe na memória menos a margem (o Swarm não agenda acima).
    if gate["status"] == "PASS":
        host = snapshot["host"]
        rules = section["rules"]
        others_memory, others_cpu = _reservations_on_node(snapshot, swarm_name)
        want = result["desired"]["swarm"]
        total_memory = others_memory + want["memory_reservation_bytes"] * max(replicas or 0, 1)
        budget = (host["memory_total_mb"] - rules["unreserved_margin_mb"]) * MIB
        total_cpu = others_cpu + want["cpu_reservation_nano"] * max(replicas or 0, 1)
        result["node_reservations"] = {
            "memory_mib_after": round(total_memory / MIB, 1),
            "memory_budget_mib": round(budget / MIB, 1),
            "cpu_after": round(total_cpu / NANO, 2),
            "cpu_count": host["cpu_count"],
        }
        if total_memory > budget:
            reasons.append(f"a soma das reservas de memória do nó ficaria em "
                           f"{total_memory / MIB:.0f} MiB, acima de {budget / MIB:.0f} MiB")
        if total_cpu > host["cpu_count"] * NANO:
            reasons.append(f"a soma das reservas de CPU ficaria em {total_cpu / NANO:.2f}, "
                           f"acima de {host['cpu_count']} vCPU")
        # Limite longe do uso de agora, lido no mesmo snapshot.
        used = next((item.get("memory_used_mib") for item in snapshot.get("services", [])
                     if item.get("name") == swarm_name), None)
        if used is None:
            reasons.append(f"o snapshot não mediu a memória de {swarm_name}")
        elif entry["memory_limit_mb"] < rules["limit_headroom_factor"] * used:
            reasons.append(f"limite de {entry['memory_limit_mb']} MiB abaixo de "
                           f"{rules['limit_headroom_factor']} vezes o uso lido ({used} MiB)")
        result["memory_used_mib"] = used
    if before["resources"] == result["desired"]["swarm"]:
        result["already_applied"] = True
    result["status"] = "PASS" if not reasons else "BLOCKED"
    result["reasons"] = reasons
    return result


# ------------------------------------------------------------ conferências


def _converged(service: dict[str, Any], tasks: list[dict[str, str]]) -> list[str]:
    view = deploy_view(service)
    problems = []
    if view["update_state"] not in SETTLED_UPDATE:
        problems.append(f"atualização do Swarm não terminou: {view['update_state']}")
    if view["replicas"] is not None and len(tasks) != view["replicas"]:
        problems.append(f"{len(tasks)} tarefas no ar para {view['replicas']} réplicas")
    for task in tasks:
        if task["image"] != view["image"] or not task["state"].startswith("Running"):
            problems.append(f"tarefa fora da spec: {task['image']} ({task['state']})")
    return problems


def check_apply(
    plan_data: dict[str, Any], inspect_raw: str, easypanel_raw: str, running_raw: str,
    project: str,
) -> dict[str, Any]:
    """Depois de aplicar: só os recursos mudaram, nos dois lugares, e o serviço convergiu."""
    service = load_inspect(inspect_raw)
    after = deploy_view(service)
    before = plan_data["before"]
    problems = _converged(service, running_tasks(running_raw))
    if after["spec_sha256_without_resources"] != before["spec_sha256_without_resources"]:
        problems.append("a spec mudou além dos recursos (imagem, env, deploy, rede ou rótulos)")
    if after["image"] != before["image"]:
        problems.append(f"a imagem mudou: {before['image']} -> {after['image']}")
    if after["env_sha256"] != before["env_sha256"]:
        problems.append("o env mudou")
    if after["resources"] != plan_data["desired"]["swarm"]:
        problems.append(f"recursos da spec diferentes do pedido: {after['resources']}")
    entry = load_easypanel(easypanel_raw, project, plan_data["service"])
    view = easypanel_view(entry) if entry else None
    after["easypanel"] = view
    if view is None:
        problems.append("o EasyPanel não tem mais o serviço")
    else:
        if view["resources"] != plan_data["desired"]["easypanel"]:
            problems.append(f"recursos gravados no EasyPanel diferentes do pedido: {view['resources']}")
        for key, label in (("image", "a imagem"), ("env_sha256", "o env"), ("deploy_sha256", "o deploy")):
            if view[key] != before["easypanel"][key]:
                problems.append(f"{label} gravado no EasyPanel mudou")
    return {"status": "PASS" if not problems else "FAIL", "after": after, "problems": problems}


MANUAL_PLAN = ("plano manual com o receipt: services.app.updateResources com "
               "before.easypanel.resources e docker service update com before.resources")


def rollback_decision(
    receipt: dict[str, Any], inspect_raw: str, easypanel_raw: str, project: str,
) -> dict[str, Any]:
    """Como voltar: só enquanto a nossa mudança ainda for a última nos dois lugares.

    Swarm: a spec atual já é a de antes, ou é a que aplicamos e a anterior dela é a de
    antes (aí `docker service rollback` devolve a spec exata). Sem conferência gravada
    (parada no meio), a spec atual só pode diferir da de antes nos recursos pedidos.
    EasyPanel: imagem, env e deploy iguais aos de antes; recursos os pedidos ou os de antes.
    """
    before = receipt["before"]
    desired = receipt["desired"]
    reasons: list[str] = []
    service = load_inspect(inspect_raw)
    spec = service["Spec"]
    if spec.get("Name") != receipt["swarm_service"]:
        raise InvalidInput(f"a spec lida é de {spec.get('Name')}, não de {receipt['swarm_service']}")
    current = spec_fingerprint(spec)
    previous = (spec_fingerprint(service["PreviousSpec"])
                if isinstance(service.get("PreviousSpec"), dict) else None)
    applied = (receipt.get("after") or {}).get("spec_sha256")
    if current == before["spec_sha256"]:
        swarm_action = "already_restored"
    elif previous != before["spec_sha256"]:
        swarm_action = None
    elif applied:
        swarm_action = "swarm_rollback" if current == applied else None
    elif (spec_fingerprint(spec, without_resources=True) == before["spec_sha256_without_resources"]
          and swarm_resources(spec) == desired["swarm"]):
        swarm_action = "swarm_rollback"
    else:
        swarm_action = None
    if swarm_action is None:
        reasons.append("a spec do serviço mudou depois da aplicação (outro deploy ou "
                       "outra mudança): o rollback do Swarm não seria exato")

    entry = load_easypanel(easypanel_raw, project, receipt["service"])
    view = easypanel_view(entry) if entry else None
    easypanel_action = None
    if view is None:
        reasons.append("o EasyPanel não tem mais o serviço")
    elif any(view[key] != before["easypanel"][key]
             for key in ("image", "env_sha256", "deploy_sha256")):
        reasons.append("imagem, env ou deploy gravados no EasyPanel mudaram depois da aplicação")
    elif view["resources"] == before["easypanel"]["resources"]:
        easypanel_action = "already_restored"
    elif view["resources"] == desired["easypanel"]:
        easypanel_action = "restore_resources"
    else:
        reasons.append("os recursos do EasyPanel não são nem os pedidos nem os de antes")
    if reasons:
        return {"status": "BLOCKED", "swarm": swarm_action, "easypanel": easypanel_action,
                "reasons": reasons + [MANUAL_PLAN]}
    return {"status": "PASS", "swarm": swarm_action, "easypanel": easypanel_action}


def check_rollback(
    receipt: dict[str, Any], inspect_raw: str, easypanel_raw: str, running_raw: str,
    project: str,
) -> dict[str, Any]:
    """Depois do rollback: a spec inteira e os recursos do EasyPanel iguais aos de antes."""
    service = load_inspect(inspect_raw)
    after = deploy_view(service)
    before = receipt["before"]
    problems = _converged(service, running_tasks(running_raw))
    if after["spec_sha256"] != before["spec_sha256"]:
        problems.append("a spec não voltou à de antes (imagem, env, recursos ou deploy)")
    for key in ("image", "env_sha256", "resources", "replicas", "update_config",
                "rollback_config"):
        if after[key] != before[key]:
            problems.append(f"{key} diferente do de antes")
    entry = load_easypanel(easypanel_raw, project, receipt["service"])
    view = easypanel_view(entry) if entry else None
    after["easypanel"] = view
    if view != before["easypanel"]:
        problems.append("o EasyPanel não voltou ao de antes (imagem, env, deploy ou recursos)")
    return {"status": "PASS" if not problems else "FAIL", "after": after, "problems": problems}


def build_receipt(
    plan_data: dict[str, Any], status: str, apply_check: dict[str, Any] | None,
    rollback_check: dict[str, Any] | None, tool_git_sha: str,
) -> dict[str, Any]:
    if not capacity.GIT_SHA.match(tool_git_sha):
        raise InvalidInput("tool_git_sha inválido")
    return {
        "schema_version": 1,
        "kind": RECEIPT_KIND,
        "task": "BT-CAP-002",
        "authorization": "D-14",
        "tool": TOOL,
        "tool_git_sha": tool_git_sha,
        "written_at": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": status,
        "service": plan_data["service"],
        "swarm_service": plan_data["swarm_service"],
        "policy_version": plan_data["policy_version"],
        "capacity_preflight": plan_data.get("capacity_preflight"),
        "node_reservations": plan_data.get("node_reservations"),
        "reasons": plan_data.get("reasons"),
        "before": plan_data.get("before"),
        "desired": plan_data.get("desired"),
        "after": (apply_check or {}).get("after"),
        "apply_problems": (apply_check or {}).get("problems"),
        "rollback": rollback_check,
    }


# ------------------------------------------------------------ CLI


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        raise InvalidInput(f"não li {path}: {error}") from error


def _read_check(path: Path | None) -> dict[str, Any] | None:
    """Conferência para o receipt: ilegível vira registro, nunca some o receipt."""
    if path is None:
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return {"status": "unreadable", "problems": [f"conferência ilegível: {error}"]}
    if not isinstance(data, dict):
        return {"status": "unreadable", "problems": ["conferência não é um objeto JSON"]}
    return data


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("redact-inspect")
    redact = commands.add_parser("redact-easypanel")
    redact.add_argument("--project", required=True)
    make_plan = commands.add_parser("plan")
    make_plan.add_argument("--service", required=True)
    make_plan.add_argument("--snapshot", type=Path, required=True)
    for name in ("--easypanel", "--inspect", "--running"):
        make_plan.add_argument(name, type=Path, required=True)
    make_plan.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    make_plan.add_argument("--now")
    applied = commands.add_parser("check-apply")
    applied.add_argument("--plan", type=Path, required=True)
    for name in ("--easypanel", "--inspect", "--running"):
        applied.add_argument(name, type=Path, required=True)
    decision = commands.add_parser("rollback-decision")
    decision.add_argument("--receipt", type=Path, required=True)
    decision.add_argument("--inspect", type=Path, required=True)
    decision.add_argument("--easypanel", type=Path, required=True)
    restored = commands.add_parser("check-rollback")
    restored.add_argument("--receipt", type=Path, required=True)
    for name in ("--easypanel", "--inspect", "--running"):
        restored.add_argument(name, type=Path, required=True)
    settled = commands.add_parser("converged")
    settled.add_argument("--inspect", type=Path, required=True)
    settled.add_argument("--running", type=Path, required=True)
    receipt = commands.add_parser("receipt")
    receipt.add_argument("--plan", type=Path, required=True)
    receipt.add_argument("--status", required=True,
                         choices=("applied", "rolled_back", "rollback_failed", "blocked"))
    receipt.add_argument("--apply-check", type=Path)
    receipt.add_argument("--rollback-check", type=Path)
    receipt.add_argument("--tool-git-sha", required=True)
    receipt.add_argument("--out", type=Path, required=True)
    args = parser.parse_args(argv)

    try:
        if args.command == "redact-inspect":
            print(redact_inspect(sys.stdin.read()))
            return 0
        if args.command == "redact-easypanel":
            print(redact_easypanel(sys.stdin.read(), args.project))
            return 0
        if args.command == "plan":
            policy = capacity.load_policy(args.policy)
            result = plan(
                service_name=args.service,
                policy=policy,
                snapshot=json.loads(_read(args.snapshot)),
                easypanel_raw=_read(args.easypanel),
                inspect_raw=_read(args.inspect),
                running_raw=_read(args.running),
                now=capacity._parse_now(args.now),
            )
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "check-apply":
            plan_data = json.loads(_read(args.plan))
            project = plan_data["swarm_service"][: -len(plan_data["service"]) - 1]
            result = check_apply(plan_data, _read(args.inspect), _read(args.easypanel),
                                 _read(args.running), project)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 1
        if args.command == "rollback-decision":
            receipt_data = json.loads(_read(args.receipt))
            project = receipt_data["swarm_service"][: -len(receipt_data["service"]) - 1]
            result = rollback_decision(receipt_data, _read(args.inspect),
                                       _read(args.easypanel), project)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "check-rollback":
            receipt_data = json.loads(_read(args.receipt))
            project = receipt_data["swarm_service"][: -len(receipt_data["service"]) - 1]
            result = check_rollback(receipt_data, _read(args.inspect), _read(args.easypanel),
                                    _read(args.running), project)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 1
        if args.command == "converged":
            service = load_inspect(_read(args.inspect))
            problems = _converged(service, running_tasks(_read(args.running)))
            state = _update_state(service)
            status = "PASS" if not problems else (
                "PAUSED" if state in {"paused", "rollback_paused"} else "WAITING")
            print(json.dumps({"status": status, "problems": problems}, ensure_ascii=False))
            return {"PASS": 0, "WAITING": 1, "PAUSED": 3}[status]
        plan_data = json.loads(_read(args.plan))
        apply_check = _read_check(args.apply_check)
        rollback_check = _read_check(args.rollback_check)
        result = build_receipt(plan_data, args.status, apply_check, rollback_check,
                               args.tool_git_sha)
        args.out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                            encoding="utf-8")
        args.out.chmod(0o600)
        print(json.dumps({"status": "written", "receipt": str(args.out)}, ensure_ascii=False))
        return 0
    except (InvalidInput, KeyError, ValueError) as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    sys.exit(main())
