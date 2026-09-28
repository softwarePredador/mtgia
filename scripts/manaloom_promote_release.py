#!/usr/bin/env python3
"""BT-REL-001 (D-13): transação de promoção full-stack com rollback comprovado.

Lógica sem conexão. O orquestrador `scripts/manaloom_promote_release.sh` lê o
EasyPanel, o Swarm e as sondas públicas, chama os deploys de cada superfície na
ordem da D-13 (backend, ops, site, /app e Android) e só muda o que este módulo
aprovar.

A transação é tudo ou nada. Antes da primeira mudança, grava a linha de base de
todas as superfícies e exige que cada uma seja reversível. Cada passo entra num
diário encadeado (JSONL, cada linha com o SHA-256 da anterior) antes de acontecer.
Se uma superfície falha, as já promovidas voltam na ordem inversa e cada volta é
provada contra a linha de base: identidade (imagem, env, réplicas e recursos),
origem do EasyPanel e a sonda pública. Um diário sem fim é uma transação
interrompida e fica visível: o `journal-status` devolve 4, e o orquestrador não
começa outra promoção.

As leituras chegam já redigidas (`manaloom_capacity_resources.py redact-*`):
nenhum valor de env entra no diário, só nomes e impressões digitais.

Subcomandos:
  validate-config [--config C]
  plan [--config C] [--surfaces a,b]            linhas id, serviço, deploy e sonda
  view --surface ID --inspect I --easypanel E --running R --marker M
  baseline-check --surface ID --view V
  check-deployed --surface ID --baseline V0 --view V --result R --sha SHA --release-mode M
  compensation-decision --surface ID --baseline V0 --view V
  check-restored --surface ID --baseline V0 --view V
  check-converged --surface ID --committed C --view V
  journal-append --journal J --event E [--data-file F]
  journal-status --journal J
  latest-open --dir D                           diário aberto mais novo, se houver

Saída JSON em stdout. Códigos: 0 PASS, 1 FAIL, 2 entrada inválida, 3 BLOCKED,
4 transação interrompida.
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
DEFAULT_CONFIG = REPO_ROOT / "server" / "config" / "release_promotion.json"
JOURNAL_KIND = "brewtact-release-promotion-journal"
D13_ORDER = ("backend", "site", "app", "android")
STRATEGIES = {"swarm_rollback", "easypanel_redeploy"}
EASYPANEL_SOURCES = {"managed", "swarm_direct", "detect"}
PROBE_KINDS = {"json_field", "body_sha256", "status_only"}
DIGEST_IMAGE = re.compile(r"@sha256:[0-9a-f]{64}$")
GIT_SHA = re.compile(r"^[0-9a-f]{40}$")
SURFACE_ID = re.compile(r"^[a-z][a-z0-9_]*$")
END_STATUSES = {"committed", "rolled_back", "rollback_failed", "blocked"}
EVENTS = {
    "begin", "surface_started", "surface_committed", "surface_failed",
    "compensation_started", "surface_restored", "surface_restore_failed",
    "converged", "aborted", "end", "resolved",
}

_spec = importlib.util.spec_from_file_location(
    "bt_cap_002_resources", HERE / "manaloom_capacity_resources.py"
)
resources = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
sys.modules[_spec.name] = resources
_spec.loader.exec_module(resources)
# Um só tipo de erro de entrada para a leitura (BT-CAP-002) e para o diário.
InvalidInput = resources.InvalidInput


def _canonical(data: Any) -> str:
    return json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _now() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ------------------------------------------------------------ configuração


def config_problems(config: dict[str, Any], repo_root: Path = REPO_ROOT) -> list[str]:
    problems: list[str] = []
    if config.get("schema_version") != 1 or config.get("policy") != "brewtact-release-promotion":
        problems.append("não é a política de promoção v1")
    if config.get("task") != "BT-REL-001":
        problems.append("task deve ser BT-REL-001")
    if "D-13" not in (config.get("decisions") or []):
        problems.append("decisions deve citar a D-13")
    if not isinstance(config.get("version"), str) or not config["version"]:
        problems.append("version ausente")
    if config.get("project") != "evolution":
        problems.append("project deve ser evolution")
    for key in ("control_plane_release", "order_rationale"):
        if not isinstance(config.get(key), str) or not config[key].strip():
            problems.append(f"{key} ausente")
    transaction = config.get("transaction")
    if not isinstance(transaction, dict) or transaction.get("all_or_nothing") is not True:
        problems.append("transaction.all_or_nothing deve ser true")
    surfaces = config.get("surfaces")
    if not isinstance(surfaces, list) or not surfaces:
        return problems + ["surfaces vazio"]
    ids: list[str] = []
    services: set[str] = set()
    for index, surface in enumerate(surfaces):
        label = f"surfaces[{index}]"
        if not isinstance(surface, dict):
            problems.append(f"{label} inválido")
            continue
        surface_id = surface.get("id")
        if not isinstance(surface_id, str) or not SURFACE_ID.match(surface_id):
            problems.append(f"{label}.id inválido")
            continue
        label = f"surfaces.{surface_id}"
        if surface_id in ids:
            problems.append(f"{label} repetido")
        ids.append(surface_id)
        service = surface.get("service")
        if not isinstance(service, str) or not re.match(r"^[a-z0-9-]+$", service):
            problems.append(f"{label}.service inválido")
        elif service in services:
            problems.append(f"{label}.service repetido")
        else:
            services.add(service)
        deploy = surface.get("deploy")
        if not (isinstance(deploy, str) and deploy.startswith("scripts/") and deploy.endswith(".sh")
                and ".." not in deploy):
            problems.append(f"{label}.deploy deve ser um script de scripts/")
        elif not (repo_root / deploy).is_file():
            problems.append(f"{label}.deploy não existe: {deploy}")
        if surface.get("easypanel_source") not in EASYPANEL_SOURCES:
            problems.append(f"{label}.easypanel_source desconhecido")
        if not isinstance(surface.get("env_in_swarm_spec"), bool):
            problems.append(f"{label}.env_in_swarm_spec deve ser booleano")
        statuses = surface.get("success_status")
        if not (isinstance(statuses, list) and statuses
                and all(isinstance(item, str) and item for item in statuses)):
            problems.append(f"{label}.success_status vazio")
        if surface.get("same_sha_field") != "git_sha":
            problems.append(f"{label}.same_sha_field deve ser git_sha")
        strategies = surface.get("compensation")
        if not (isinstance(strategies, list) and strategies
                and set(strategies) <= STRATEGIES and len(set(strategies)) == len(strategies)):
            problems.append(f"{label}.compensation inválido")
        elif strategies[0] != "swarm_rollback":
            problems.append(f"{label}: a spec anterior exata vem sempre primeiro")
        elif "easypanel_redeploy" in strategies:
            # O redeploy do EasyPanel recria a spec com o env do EasyPanel: o env que o
            # deploy grava direto na spec se perderia, e a origem tem de ser o EasyPanel.
            if surface.get("env_in_swarm_spec") is not False:
                problems.append(f"{label}: redeploy pelo EasyPanel perderia o env da spec")
            if surface.get("easypanel_source") != "managed":
                problems.append(f"{label}: redeploy pelo EasyPanel exige origem managed")
        probe = surface.get("probe")
        if probe is not None:
            if not isinstance(probe, dict) or probe.get("kind") not in PROBE_KINDS:
                problems.append(f"{label}.probe inválido")
            else:
                for key in ("url", "fallback_url"):
                    if key in probe and not (isinstance(probe[key], str)
                                             and probe[key].startswith("https://")):
                        problems.append(f"{label}.probe.{key} deve ser HTTPS")
                if "url" not in probe:
                    problems.append(f"{label}.probe.url ausente")
                if probe["kind"] == "json_field" and not isinstance(probe.get("field"), str):
                    problems.append(f"{label}.probe.field ausente")
        if not isinstance(surface.get("rationale"), str) or not surface["rationale"].strip():
            problems.append(f"{label}.rationale ausente")
    positions = {surface_id: index for index, surface_id in enumerate(ids)}
    missing = [surface_id for surface_id in D13_ORDER if surface_id not in positions]
    if missing:
        problems.append("a ordem da D-13 exige as superfícies " + ", ".join(missing))
    elif [positions[item] for item in D13_ORDER] != sorted(positions[item] for item in D13_ORDER):
        problems.append("a ordem das superfícies viola a D-13 (backend, site, /app e Android)")
    return problems


def load_config(path: Path, repo_root: Path = REPO_ROOT) -> dict[str, Any]:
    try:
        config = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise InvalidInput(f"não li a política de promoção {path}: {error}") from error
    problems = config_problems(config, repo_root)
    if problems:
        raise InvalidInput("política de promoção inválida: " + "; ".join(problems))
    return config


def surface_config(config: dict[str, Any], surface_id: str) -> dict[str, Any]:
    for surface in config["surfaces"]:
        if surface["id"] == surface_id:
            return {**surface, "swarm_service": f"{config['project']}_{surface['service']}"}
    raise InvalidInput(f"superfície desconhecida: {surface_id}")


def selected_surfaces(config: dict[str, Any], wanted: str | None) -> list[dict[str, Any]]:
    """As superfícies pedidas, sempre na ordem da política (a da D-13)."""
    ids = [surface["id"] for surface in config["surfaces"]]
    if not wanted:
        chosen = ids
    else:
        chosen = [item.strip() for item in wanted.split(",") if item.strip()]
        unknown = [item for item in chosen if item not in ids]
        if unknown or len(set(chosen)) != len(chosen) or not chosen:
            raise InvalidInput("superfícies inválidas: " + wanted)
    return [surface_config(config, surface_id) for surface_id in ids if surface_id in chosen]


# ------------------------------------------------------------ leitura de uma superfície


def identity_of(spec_view: dict[str, Any]) -> dict[str, Any]:
    """O que tem de voltar igual: imagem, env, réplicas e recursos."""
    return {key: spec_view[key] for key in ("image", "env_sha256", "replicas", "resources")}


def view(
    surface: dict[str, Any], inspect_raw: str, easypanel_raw: str, running_raw: str,
    marker: str, project: str,
) -> dict[str, Any]:
    service = resources.load_inspect(inspect_raw)
    spec = service["Spec"]
    if spec.get("Name") != surface["swarm_service"]:
        raise InvalidInput(f"a spec lida é de {spec.get('Name')}, não de {surface['swarm_service']}")
    spec_view = resources.deploy_view(service)
    previous = service.get("PreviousSpec")
    spec_view["previous_spec_sha256"] = (
        resources.spec_fingerprint(previous) if isinstance(previous, dict) else None)
    problems = resources._converged(service, resources.running_tasks(running_raw))
    entry = resources.load_easypanel(easypanel_raw, project, surface["service"])
    easypanel = None
    if entry is not None:
        easypanel = {"type": entry.get("type"), **resources.easypanel_view(entry)}
    return {
        "surface": surface["id"],
        "swarm_service": surface["swarm_service"],
        "spec": spec_view,
        "identity_sha256": _sha256(_canonical(identity_of(spec_view))),
        "easypanel": easypanel,
        "marker": marker,
        "converged": not problems,
        "problems": problems,
    }


def easypanel_managed(surface: dict[str, Any], baseline: dict[str, Any]) -> bool:
    """O EasyPanel é a origem da superfície (no detect, conforme a linha de base)."""
    if surface["easypanel_source"] == "managed":
        return True
    if surface["easypanel_source"] == "detect":
        return baseline.get("easypanel") is not None
    return False


def baseline_problems(surface: dict[str, Any], current: dict[str, Any]) -> list[str]:
    """A linha de base só vale se der para voltar a ela."""
    problems = list(current["problems"])
    spec = current["spec"]
    if not isinstance(spec["replicas"], int) or spec["replicas"] < 1:
        problems.append(f"{current['swarm_service']} sem réplicas no ar")
    if not DIGEST_IMAGE.search(spec["image"] or ""):
        problems.append(f"a imagem de {current['swarm_service']} não é um digest: {spec['image']}")
    if spec["update_state"] not in resources.SETTLED_UPDATE:
        problems.append(f"atualização do Swarm em andamento: {spec['update_state']}")
    easypanel = current["easypanel"]
    if surface["easypanel_source"] == "managed" and easypanel is None:
        problems.append(f"o EasyPanel não tem o serviço {surface['service']}")
    if easypanel is not None and easypanel.get("type") != "app":
        problems.append(f"o serviço {surface['service']} não é app no EasyPanel")
    if surface.get("probe") and not current["marker"]:
        problems.append(f"a sonda de {surface['id']} não respondeu")
    return problems


# ------------------------------------------------------------ conferências


def check_deployed(
    surface: dict[str, Any], baseline: dict[str, Any], current: dict[str, Any],
    result: dict[str, Any] | None, sha: str, release_mode: str,
) -> dict[str, Any]:
    """O deploy disse que subiu: a spec, a tarefa, a origem e a sonda confirmam."""
    problems: list[str] = []
    if not isinstance(result, dict):
        return {"status": "FAIL", "problems": ["o deploy não devolveu o JSON de saída"]}
    if result.get("status") not in surface["success_status"]:
        problems.append(f"status do deploy inesperado: {result.get('status')}")
    # D-13: a superfície que declara o modo (o /app) tem de sair no modo da transação.
    if "release_mode" in result and result["release_mode"] != release_mode:
        problems.append(f"o deploy saiu em {result['release_mode']}, não em {release_mode}")
    image = result.get("image_digest_ref")
    if not isinstance(image, str) or not DIGEST_IMAGE.search(image):
        problems.append("o deploy não devolveu image_digest_ref por digest")
    if result.get(surface["same_sha_field"]) != sha:
        problems.append(f"o deploy é de outro SHA: {result.get(surface['same_sha_field'])}")
    problems += current["problems"]
    if current["spec"]["image"] != image:
        problems.append(f"a spec está em {current['spec']['image']}, não em {image}")
    if easypanel_managed(surface, baseline):
        configured = (current["easypanel"] or {}).get("image")
        if configured != image:
            problems.append(f"a origem do EasyPanel está em {configured}, não em {image}")
    probe = surface.get("probe")
    if probe:
        if probe["kind"] == "json_field" and current["marker"] != f"field:{sha}":
            problems.append(f"a sonda de {surface['id']} não mostra o SHA novo: {current['marker']}")
        if probe["kind"] == "status_only" and current["marker"] != "http:200":
            problems.append(f"a sonda de {surface['id']} respondeu {current['marker']}")
        if probe["kind"] == "body_sha256" and (
                not current["marker"] or current["marker"] == baseline["marker"]):
            problems.append(f"a sonda de {surface['id']} não mudou depois do deploy")
    committed = {
        "image": current["spec"]["image"],
        "identity_sha256": current["identity_sha256"],
        "spec_sha256": current["spec"]["spec_sha256"],
        "marker": current["marker"],
    }
    return {"status": "PASS" if not problems else "FAIL", "committed": committed,
            "problems": problems}


def compensation_decision(
    surface: dict[str, Any], baseline: dict[str, Any], current: dict[str, Any],
) -> dict[str, Any]:
    """Como voltar esta superfície à linha de base, ou por que não dá."""
    reasons: list[str] = []
    base_spec = baseline["spec"]
    if current["identity_sha256"] == baseline["identity_sha256"]:
        swarm = "already"
    elif (current["spec"]["previous_spec_sha256"] == base_spec["spec_sha256"]
          and "swarm_rollback" in surface["compensation"]):
        swarm = "swarm_rollback"
    elif "easypanel_redeploy" in surface["compensation"] and easypanel_managed(surface, baseline):
        swarm = "easypanel_redeploy"
    else:
        swarm = None
        reasons.append(
            f"{surface['id']}: a spec anterior não é a de antes e a política não permite "
            "redeploy pelo EasyPanel; voltar não seria exato")
    easypanel = "not_managed"
    if easypanel_managed(surface, baseline):
        configured = (current["easypanel"] or {}).get("image")
        if current["easypanel"] is None:
            easypanel = None
            reasons.append(f"{surface['id']}: o EasyPanel não tem mais o serviço")
        elif configured == base_spec["image"]:
            easypanel = "already"
        else:
            easypanel = "restore_image"
    if reasons:
        return {"status": "BLOCKED", "swarm": swarm, "easypanel": easypanel,
                "image": base_spec["image"], "reasons": reasons}
    return {"status": "PASS", "swarm": swarm, "easypanel": easypanel, "image": base_spec["image"]}


def check_restored(
    surface: dict[str, Any], baseline: dict[str, Any], current: dict[str, Any],
) -> dict[str, Any]:
    """Voltou: identidade, origem e sonda iguais às de antes, e o serviço convergiu."""
    problems = list(current["problems"])
    base_spec = baseline["spec"]
    for key, label in (("image", "a imagem"), ("env_sha256", "o env"),
                       ("replicas", "as réplicas"), ("resources", "os recursos")):
        if current["spec"][key] != base_spec[key]:
            problems.append(f"{label} não voltou ao de antes")
    if easypanel_managed(surface, baseline):
        now = current["easypanel"] or {}
        before = baseline["easypanel"] or {}
        if now.get("image") != base_spec["image"]:
            problems.append(f"a origem do EasyPanel está em {now.get('image')}")
        if now.get("env_sha256") != before.get("env_sha256"):
            problems.append("o env do EasyPanel mudou")
    if surface.get("probe") and current["marker"] != baseline["marker"]:
        problems.append(f"a sonda de {surface['id']} não voltou ao marcador de antes")
    exact = (current["spec"]["spec_sha256"] == base_spec["spec_sha256"]
             and (current["easypanel"] or {}).get("image") ==
             (baseline["easypanel"] or {}).get("image"))
    return {"status": "PASS" if not problems else "FAIL",
            "level": "exact" if exact else "identity", "problems": problems}


def check_converged(
    surface: dict[str, Any], committed: dict[str, Any], current: dict[str, Any],
) -> dict[str, Any]:
    """No fim da transação, a superfície segue no que foi promovido."""
    problems = list(current["problems"])
    if current["identity_sha256"] != committed["identity_sha256"]:
        problems.append(f"{surface['id']} mudou depois de promovida")
    if surface.get("probe") and current["marker"] != committed["marker"]:
        problems.append(f"a sonda de {surface['id']} mudou depois de promovida")
    return {"status": "PASS" if not problems else "FAIL", "problems": problems}


# ------------------------------------------------------------ diário


def _read_lines(path: Path) -> list[str]:
    if not path.exists():
        return []
    return [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def parse_journal(path: Path) -> list[dict[str, Any]]:
    """Lê o diário e confere a corrente: sequência e SHA-256 da linha anterior."""
    records = []
    previous_line = None
    for number, line in enumerate(_read_lines(path), start=1):
        try:
            record = json.loads(line)
        except json.JSONDecodeError as error:
            raise InvalidInput(f"linha {number} do diário ilegível: {error}") from error
        if record.get("kind") != JOURNAL_KIND or record.get("seq") != number:
            raise InvalidInput(f"linha {number} fora da sequência do diário")
        expected = _sha256(previous_line) if previous_line is not None else None
        if record.get("prev_sha256") != expected:
            raise InvalidInput(f"linha {number} quebra a corrente do diário")
        if record.get("event") not in EVENTS:
            raise InvalidInput(f"linha {number} com evento desconhecido: {record.get('event')}")
        if (number == 1) != (record["event"] == "begin"):
            raise InvalidInput(f"linha {number}: o diário começa com begin, e só uma vez")
        records.append(record)
        previous_line = line
    return records


def journal_append(path: Path, event: str, data: dict[str, Any]) -> dict[str, Any]:
    if event not in EVENTS:
        raise InvalidInput(f"evento desconhecido: {event}")
    records = parse_journal(path)
    events = [record["event"] for record in records]
    if not records and event != "begin":
        raise InvalidInput("o diário começa com begin")
    if records and event == "begin":
        raise InvalidInput("o diário já começou")
    if "end" in events and event != "resolved":
        raise InvalidInput("o diário já terminou; só cabe resolved")
    if event == "resolved" and "resolved" in events:
        raise InvalidInput("o diário já foi resolvido")
    if event == "end" and data.get("status") not in END_STATUSES:
        raise InvalidInput(f"status de fim inválido: {data.get('status')}")
    lines = _read_lines(path)
    record = {
        "kind": JOURNAL_KIND,
        "seq": len(records) + 1,
        "at": _now(),
        "event": event,
        "prev_sha256": _sha256(lines[-1]) if lines else None,
        "data": data,
    }
    text = json.dumps(record, ensure_ascii=False, sort_keys=True)
    created = not path.exists()
    with path.open("a", encoding="utf-8") as handle:
        handle.write(text + "\n")
        handle.flush()
        os.fsync(handle.fileno())
    if created:
        path.chmod(0o600)
    return record


def journal_status(path: Path) -> dict[str, Any]:
    """Estado do diário. Sem fim, a transação foi interrompida e fica visível."""
    records = parse_journal(path)
    if not records:
        raise InvalidInput(f"diário vazio: {path}")
    begin = records[0]["data"]
    surfaces: dict[str, str] = {}
    levels: dict[str, str] = {}
    end = None
    resolved = None
    for record in records:
        data = record["data"]
        surface = data.get("surface")
        state = {
            "surface_started": "started",
            "surface_committed": "committed",
            "surface_failed": "failed",
            "surface_restored": "restored",
            "surface_restore_failed": "restore_failed",
        }.get(record["event"])
        if surface and state:
            surfaces[surface] = state
            if state == "restored":
                levels[surface] = data.get("level", "")
        if record["event"] == "end":
            end = data
        if record["event"] == "resolved":
            resolved = data
    if resolved is not None:
        status, code = "resolved", 0
    elif end is None:
        status, code = "incomplete", 4
    else:
        status = end["status"]
        code = 1 if status == "rollback_failed" else 0
    return {
        "status": status,
        "journal": str(path),
        "sha": begin.get("sha"),
        "release_mode": begin.get("release_mode"),
        "surfaces": surfaces,
        "restore_levels": levels,
        "events": len(records),
        "last_event": records[-1]["event"],
        "exit_code": code,
    }


def latest_open(directory: Path) -> dict[str, Any]:
    """O diário que ainda bloqueia promoção: sem fim, ou com rollback não provado."""
    journals = sorted(directory.glob("promocao-*.jsonl"))
    for path in reversed(journals):
        try:
            state = journal_status(path)
        except InvalidInput as error:
            return {"status": "corrupt", "journal": str(path), "error": str(error),
                    "exit_code": 4}
        if state["status"] in {"incomplete", "rollback_failed"}:
            return state
    return {"status": "none", "exit_code": 0}


# ------------------------------------------------------------ CLI


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        raise InvalidInput(f"não li {path}: {error}") from error


def _json(path: Path) -> Any:
    try:
        return json.loads(_read(path))
    except json.JSONDecodeError as error:
        raise InvalidInput(f"{path} não é JSON: {error}") from error


def _result(path: Path) -> dict[str, Any] | None:
    """Última linha JSON da saída de um deploy; nada legível vira None."""
    try:
        lines = [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    except OSError:
        return None
    for line in reversed(lines):
        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            continue
        return data if isinstance(data, dict) else None
    return None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("validate-config")
    planned = commands.add_parser("plan")
    planned.add_argument("--surfaces")
    viewed = commands.add_parser("view")
    for name in ("--inspect", "--easypanel", "--running"):
        viewed.add_argument(name, type=Path, required=True)
    viewed.add_argument("--surface", required=True)
    viewed.add_argument("--marker", default="")
    base = commands.add_parser("baseline-check")
    base.add_argument("--surface", required=True)
    base.add_argument("--view", type=Path, required=True)
    deployed = commands.add_parser("check-deployed")
    deployed.add_argument("--surface", required=True)
    deployed.add_argument("--baseline", type=Path, required=True)
    deployed.add_argument("--view", type=Path, required=True)
    deployed.add_argument("--result", type=Path, required=True)
    deployed.add_argument("--sha", required=True)
    deployed.add_argument("--release-mode", required=True,
                          choices=("control_plane", "product_open"))
    decision = commands.add_parser("compensation-decision")
    restored = commands.add_parser("check-restored")
    for command in (decision, restored):
        command.add_argument("--surface", required=True)
        command.add_argument("--baseline", type=Path, required=True)
        command.add_argument("--view", type=Path, required=True)
    converged = commands.add_parser("check-converged")
    converged.add_argument("--surface", required=True)
    converged.add_argument("--committed", type=Path, required=True)
    converged.add_argument("--view", type=Path, required=True)
    append = commands.add_parser("journal-append")
    append.add_argument("--journal", type=Path, required=True)
    append.add_argument("--event", required=True)
    append.add_argument("--data-file", type=Path)
    status = commands.add_parser("journal-status")
    status.add_argument("--journal", type=Path, required=True)
    opened = commands.add_parser("latest-open")
    opened.add_argument("--dir", type=Path, required=True)
    args = parser.parse_args(argv)

    try:
        if args.command == "journal-append":
            data = _json(args.data_file) if args.data_file else {}
            if not isinstance(data, dict):
                raise InvalidInput("os dados do evento têm de ser um objeto")
            record = journal_append(args.journal, args.event, data)
            print(json.dumps({"status": "appended", "seq": record["seq"]}))
            return 0
        if args.command == "journal-status":
            state = journal_status(args.journal)
            print(json.dumps(state, ensure_ascii=False))
            return state["exit_code"]
        if args.command == "latest-open":
            state = latest_open(args.dir)
            print(json.dumps(state, ensure_ascii=False))
            return state["exit_code"]
        config = load_config(args.config)
        if args.command == "validate-config":
            print(json.dumps({"status": "valid", "version": config["version"]}))
            return 0
        if args.command == "plan":
            for surface in selected_surfaces(config, args.surfaces):
                probe = surface.get("probe") or {}
                print("\t".join([
                    surface["id"], surface["service"], surface["swarm_service"],
                    surface["deploy"], probe.get("kind", "none"), probe.get("url", ""),
                    probe.get("field", ""), probe.get("fallback_url", ""),
                ]))
            return 0
        surface = surface_config(config, args.surface)
        if args.command == "view":
            result = view(surface, _read(args.inspect), _read(args.easypanel),
                          _read(args.running), args.marker, config["project"])
            print(json.dumps(result, ensure_ascii=False))
            return 0
        if args.command == "baseline-check":
            problems = baseline_problems(surface, _json(args.view))
            print(json.dumps({"status": "PASS" if not problems else "BLOCKED",
                              "surface": surface["id"], "problems": problems},
                             ensure_ascii=False))
            return 0 if not problems else 3
        if args.command == "check-deployed":
            if not GIT_SHA.match(args.sha):
                raise InvalidInput("--sha deve ser o SHA completo")
            result = check_deployed(surface, _json(args.baseline), _json(args.view),
                                    _result(args.result), args.sha, args.release_mode)
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 1
        if args.command == "compensation-decision":
            result = compensation_decision(surface, _json(args.baseline), _json(args.view))
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 3
        if args.command == "check-restored":
            result = check_restored(surface, _json(args.baseline), _json(args.view))
            print(json.dumps(result, ensure_ascii=False))
            return 0 if result["status"] == "PASS" else 1
        result = check_converged(surface, _json(args.committed), _json(args.view))
        print(json.dumps(result, ensure_ascii=False))
        return 0 if result["status"] == "PASS" else 1
    except (InvalidInput, KeyError, ValueError, TypeError) as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    sys.exit(main())
