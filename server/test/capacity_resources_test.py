#!/usr/bin/env python3
"""BT-CAP-002 (D-14): reservas e limites por serviço, com preflight e rollback exato.

A prova roda contra uma spec de serviço gravada
(server/test/fixtures/capacity/evolution_services_2026-09-23.json, montada com o que
a leitura do BT-CAP-001 registrou) e contra um plano de controle falso: um Docker
Swarm de mentira atrás do shim de ssh e um EasyPanel de mentira atrás do shim de
curl, os dois com estado em arquivo e defeitos injetáveis. Nenhuma conexão sai da
máquina. Cada falha injetada confere que a ferramenta devolve a spec inteira
(imagem, env, recursos e deploy) e o EasyPanel ao que estavam, ou para e avisa
quando voltar não seria exato.

Este arquivo também é o plano falso: os shims chamam
`python3 capacity_resources_test.py --fake-plane ssh|curl <estado> <argumentos>`.
"""

from __future__ import annotations

import copy
import datetime as dt
import hashlib
import importlib.util
import json
import os
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

THIS_FILE = Path(__file__).resolve()
REPO_ROOT = THIS_FILE.parents[2]
SCRIPT = REPO_ROOT / "scripts" / "manaloom_capacity_resources.sh"
MODULE_PATH = REPO_ROOT / "scripts" / "manaloom_capacity_resources.py"
POLICY_PATH = REPO_ROOT / "server" / "config" / "capacity_policy.json"
FIXTURE_PATH = REPO_ROOT / "server" / "test" / "fixtures" / "capacity" / (
    "evolution_services_2026-09-23.json")
RECEIPT_PATH = REPO_ROOT / "docs" / "qa" / "execution" / "2026-09-23" / "host-xmage-e-reinicio.md"
FAKE_HOST_KEY = "SHA256:" + "A" * 43
FAKE_GIT_SHA = "0123456789abcdef0123456789abcdef01234567"
SSH_TARGET = "root@evolution-cartinhas.2ta7qx.easypanel.host"
EASYPANEL_URL = "https://painel.exemplo.invalid"
EASYPANEL_TOKEN = "token-de-teste-nao-e-segredo-5c1d"
SECRET_MARKERS = ("modelo-nao-e-segredo", EASYPANEL_TOKEN)
TOOL_SERVICES = ("cartinhas", "manaloom-ops", "manaloom-web-public", "manaloom-app",
                 "manaloom-releases")
NOW = "2026-09-28T12:00:00Z"
MIB = 1024 * 1024

# Os únicos comandos que a ferramenta pode mandar ao host (fullmatch).
REMOTE_ALLOWED = {
    "inspect": re.compile(r"docker service inspect '(evolution_[a-z0-9-]+)'"),
    "ps": re.compile(
        r"docker service ps '(evolution_[a-z0-9-]+)' --filter desired-state=running "
        r"--format '\{\{\.Image\}\}\|\{\{\.CurrentState\}\}'"),
    "update": re.compile(
        r"docker service update --detach=true --limit-memory (\d+) --reserve-memory (\d+) "
        r"--limit-cpu ([0-9.]+) --reserve-cpu ([0-9.]+) '(evolution_[a-z0-9-]+)'"),
    "rollback": re.compile(r"docker service rollback --detach '(evolution_[a-z0-9-]+)'"),
}
EASYPANEL_ALLOWED = {"projects.listProjectsAndServices", "services.app.updateResources"}


# ------------------------------------------------------------------ plano falso


def _state_path(state_dir: Path) -> Path:
    return state_dir / "plane.json"


def load_plane(state_dir: Path) -> dict[str, Any]:
    return json.loads(_state_path(state_dir).read_text(encoding="utf-8"))


def save_plane(state_dir: Path, plane: dict[str, Any]) -> None:
    _state_path(state_dir).write_text(json.dumps(plane, ensure_ascii=False, indent=1),
                                      encoding="utf-8")


def _log(state_dir: Path, entry: dict[str, Any]) -> None:
    with (state_dir / "calls.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry, ensure_ascii=False) + "\n")


def _running(service: dict[str, Any], state: str = "Running 4 seconds ago") -> list[dict[str, str]]:
    spec = service["Spec"]
    replicas = spec["Mode"]["Replicated"]["Replicas"]
    image = spec["TaskTemplate"]["ContainerSpec"]["Image"]
    return [{"image": image, "state": state} for _ in range(replicas)]


def swarm_update_resources(plane: dict[str, Any], name: str, limit_memory: int,
                           reserve_memory: int, limit_cpu: str, reserve_cpu: str) -> None:
    """O que `docker service update` com as flags de recursos faz na spec."""
    service = plane["swarm"][name]
    service["PreviousSpec"] = copy.deepcopy(service["Spec"])
    service["Spec"]["TaskTemplate"]["Resources"] = {
        "Limits": {"NanoCPUs": int(round(float(limit_cpu) * 1e9)), "MemoryBytes": limit_memory},
        "Reservations": {"NanoCPUs": int(round(float(reserve_cpu) * 1e9)),
                         "MemoryBytes": reserve_memory},
    }
    service["Version"]["Index"] += 1
    service["UpdateStatus"] = {"State": "completed"}
    plane["tasks"][name] = _running(service)


def swarm_rollback(plane: dict[str, Any], name: str) -> bool:
    """`docker service rollback`: a spec volta à anterior, e a atual vira a anterior."""
    service = plane["swarm"][name]
    previous = service.get("PreviousSpec")
    if not isinstance(previous, dict):
        return False
    service["PreviousSpec"] = service["Spec"]
    service["Spec"] = previous
    service["Version"]["Index"] += 1
    service["UpdateStatus"] = {"State": "rollback_completed"}
    plane["tasks"][name] = _running(service)
    return True


def other_deploy(plane: dict[str, Any], name: str, digest: str = "c" * 64) -> None:
    """Outro deploy (do EasyPanel) depois da aplicação: troca a imagem nos dois lugares."""
    service = plane["swarm"][name]
    service["PreviousSpec"] = copy.deepcopy(service["Spec"])
    image = re.sub(r"@sha256:[0-9a-f]{64}$", f"@sha256:{digest}",
                   service["Spec"]["TaskTemplate"]["ContainerSpec"]["Image"])
    service["Spec"]["TaskTemplate"]["ContainerSpec"]["Image"] = image
    service["Version"]["Index"] += 1
    plane["tasks"][name] = _running(service)
    short = name.split("_", 1)[1]
    for entry in plane["easypanel"]["json"]["services"]:
        if entry["projectName"] == "evolution" and entry["name"] == short:
            entry["source"]["image"] = image


def _scan_for_leaks(state_dir: Path) -> None:
    """A cada chamada, procura valor de env nos arquivos de trabalho da ferramenta."""
    plane = load_plane(state_dir)
    watch = plane.get("watch_dir")
    if not watch:
        return
    for path in Path(watch).glob("manaloom-capacity-resources.*/*"):
        if not path.is_file():
            continue
        content = path.read_text(encoding="utf-8", errors="ignore")
        if any(marker in content for marker in SECRET_MARKERS):
            _log(state_dir, {"program": "leak", "file": path.name})


def swarm_only_update(plane: dict[str, Any], name: str, digest: str = "f" * 64) -> None:
    """Mudança direto no Swarm (fora do EasyPanel): troca só a imagem da spec."""
    service = plane["swarm"][name]
    service["PreviousSpec"] = copy.deepcopy(service["Spec"])
    container = service["Spec"]["TaskTemplate"]["ContainerSpec"]
    container["Image"] = re.sub(r"@sha256:[0-9a-f]{64}$", f"@sha256:{digest}", container["Image"])
    service["Version"]["Index"] += 1
    plane["tasks"][name] = _running(service)


def _fake_docker(state_dir: Path, command: str) -> int:
    plane = load_plane(state_dir)
    faults = plane.setdefault("faults", {})
    kind = next((key for key, pattern in REMOTE_ALLOWED.items() if pattern.fullmatch(command)),
                None)
    _log(state_dir, {"program": "ssh", "remote": command, "kind": kind})
    if kind is None:
        print(f"comando fora da lista: {command}", file=sys.stderr)
        return 97
    match = REMOTE_ALLOWED[kind].fullmatch(command)
    name = match.groups()[-1]
    service = plane["swarm"].get(name)
    if service is None:
        print(f"Error: no such service: {name}", file=sys.stderr)
        return 1
    if kind == "inspect":
        print(json.dumps([service], ensure_ascii=False))
        return 0
    if kind == "ps":
        for task in plane["tasks"].get(name, []):
            print(f"{task['image']}|{task['state']}")
        return 0
    if kind == "update":
        if faults.get("update_fails"):
            print("Error response from daemon: rpc error: code = Unknown", file=sys.stderr)
            return 1
        before = copy.deepcopy(service["Spec"])
        limit_memory, reserve_memory, limit_cpu, reserve_cpu, _ = match.groups()
        swarm_update_resources(plane, name, int(limit_memory), int(reserve_memory),
                               limit_cpu, reserve_cpu)
        plane["counters"]["updates"] = plane["counters"].get("updates", 0) + 1
        if faults.get("update_changes_env"):
            service["Spec"]["TaskTemplate"]["ContainerSpec"]["Env"].append("EXTRA=1")
        if faults.get("update_auto_rollback"):
            # O Swarm desfez sozinho (FailureAction=rollback): spec de antes, sem anterior.
            service["Spec"] = before
            service.pop("PreviousSpec", None)
            service["UpdateStatus"] = {"State": "rollback_completed"}
            plane["tasks"][name] = _running(service)
        if faults.get("update_paused"):
            service["UpdateStatus"] = {"State": "paused"}
            plane["tasks"][name] = _running(service, "Pending 3 seconds ago")
        if faults.get("other_deploy_after_update"):
            other_deploy(plane, name)
        save_plane(state_dir, plane)
        return 0
    if faults.get("rollback_fails"):
        print("Error response from daemon: rollback failed", file=sys.stderr)
        return 1
    if not swarm_rollback(plane, name):
        print(f"Error: service {name} does not have a previous spec", file=sys.stderr)
        return 1
    save_plane(state_dir, plane)
    return 0


def _fake_ssh(state_dir: Path, argv: list[str]) -> int:
    if len(argv) < 2 or argv[-2] != SSH_TARGET or "StrictHostKeyChecking=yes" not in argv:
        _log(state_dir, {"program": "ssh", "refused": argv})
        return 255
    return _fake_docker(state_dir, argv[-1])


def _fake_curl(state_dir: Path, argv: list[str]) -> int:
    plane = load_plane(state_dir)
    faults = plane.setdefault("faults", {})
    headers = [argv[index + 1] for index, arg in enumerate(argv[:-1]) if arg == "-H"]
    data = next((argv[index + 1] for index, arg in enumerate(argv[:-1]) if arg == "--data"),
                None)
    url = argv[-1]
    prefix = f"{EASYPANEL_URL}/api/trpc/"
    procedure = url[len(prefix):] if url.startswith(prefix) else None
    payload = json.loads(data)["json"] if data else None
    _log(state_dir, {"program": "curl", "procedure": procedure, "payload": payload,
                     "https_only": "--proto" in argv and "=https" in argv})
    if f"Authorization: Bearer {EASYPANEL_TOKEN}" not in headers:
        return 22
    if procedure == "projects.listProjectsAndServices":
        if faults.get("list_fails_after_update") and plane["counters"].get("updates"):
            faults.pop("list_fails_after_update")
            save_plane(state_dir, plane)
            return 22
        print(json.dumps(plane["easypanel"], ensure_ascii=False))
        return 0
    if procedure == "services.app.updateResources":
        if faults.get("easypanel_update_fails"):
            return 22
        for entry in plane["easypanel"]["json"]["services"]:
            if (entry["projectName"] == payload["projectName"]
                    and entry["name"] == payload["serviceName"] and entry["type"] == "app"):
                entry["resources"] = payload["resources"]
                save_plane(state_dir, plane)
                print(json.dumps({"result": {"data": {"json": None}}}))
                return 0
        return 22
    return 22


def fake_plane_main(argv: list[str]) -> int:
    program, state_dir, rest = argv[0], Path(argv[1]), argv[2:]
    _scan_for_leaks(state_dir)
    if program == "ssh":
        return _fake_ssh(state_dir, rest)
    if program == "curl":
        return _fake_curl(state_dir, rest)
    return 97


if __name__ == "__main__" and sys.argv[1:2] == ["--fake-plane"]:
    sys.exit(fake_plane_main(sys.argv[2:]))


# ------------------------------------------------------------------ módulo e fixture


def _load_module():
    spec = importlib.util.spec_from_file_location("bt_cap_002_resources", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


resources = _load_module()
capacity = resources.capacity


def _fixture() -> dict[str, Any]:
    return json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def _policy() -> dict[str, Any]:
    return json.loads(POLICY_PATH.read_text(encoding="utf-8"))


def _host_raw(fixture: dict[str, Any], measured_at: str = NOW,
              replace: dict[str, str] | None = None) -> str:
    raw = fixture["snapshot_host_raw"].replace("{MEASURED_AT}", measured_at)
    for old, new in (replace or {}).items():
        assert old in raw, old
        raw = raw.replace(old, new)
    return raw


def _snapshot(fixture: dict[str, Any], measured_at: str = NOW,
              replace: dict[str, str] | None = None) -> dict[str, Any]:
    return capacity.build_snapshot(
        host_raw=_host_raw(fixture, measured_at, replace),
        postgres_raw=fixture["postgres_raw"],
        ssh_target=_policy()["production"]["ssh_target"],
        host_key=FAKE_HOST_KEY,
        git_sha=FAKE_GIT_SHA,
        tree_clean=True,
        collected_at=measured_at,
    )


def _now() -> dt.datetime:
    return dt.datetime.strptime(NOW, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)


def _plane_from_fixture(fixture: dict[str, Any]) -> dict[str, Any]:
    return {
        "swarm": copy.deepcopy(fixture["swarm"]),
        "tasks": copy.deepcopy(fixture["tasks"]),
        "easypanel": copy.deepcopy(fixture["easypanel"]),
        "faults": {},
        "counters": {},
    }


def _inspect_raw(plane: dict[str, Any], name: str) -> str:
    return json.dumps([plane["swarm"][f"evolution_{name}"]])


def _running_raw(plane: dict[str, Any], name: str) -> str:
    return "".join(f"{task['image']}|{task['state']}\n"
                   for task in plane["tasks"][f"evolution_{name}"])


def _easypanel_raw(plane: dict[str, Any]) -> str:
    return json.dumps(plane["easypanel"])


def _easypanel_entry(plane: dict[str, Any], name: str) -> dict[str, Any]:
    return next(entry for entry in plane["easypanel"]["json"]["services"]
                if entry["projectName"] == "evolution" and entry["name"] == name)


def _plan(plane: dict[str, Any], name: str, snapshot: dict[str, Any] | None = None,
          policy: dict[str, Any] | None = None) -> dict[str, Any]:
    return resources.plan(
        service_name=name,
        policy=policy or _policy(),
        snapshot=snapshot or _snapshot(_fixture()),
        easypanel_raw=_easypanel_raw(plane),
        inspect_raw=_inspect_raw(plane, name),
        running_raw=_running_raw(plane, name),
        now=_now(),
    )


def _apply_in_plane(plane: dict[str, Any], plan_data: dict[str, Any]) -> None:
    """O que a ferramenta faz quando tudo corre bem, direto no plano falso."""
    name = plan_data["service"]
    _easypanel_entry(plane, name)["resources"] = dict(plan_data["desired"]["easypanel"])
    swarm = plan_data["desired"]["swarm"]
    swarm_update_resources(plane, plan_data["swarm_service"], swarm["memory_limit_bytes"],
                           swarm["memory_reservation_bytes"],
                           str(plan_data["desired"]["easypanel"]["cpuLimit"]),
                           str(plan_data["desired"]["easypanel"]["cpuReservation"]))


def _receipt(plan_data: dict[str, Any], plane: dict[str, Any]) -> dict[str, Any]:
    check = resources.check_apply(plan_data, _inspect_raw(plane, plan_data["service"]),
                                  _easypanel_raw(plane), _running_raw(plane, plan_data["service"]),
                                  "evolution")
    return resources.build_receipt(plan_data, "applied", check, None, FAKE_GIT_SHA)


# ------------------------------------------------------------------ fixture


class FixtureTest(unittest.TestCase):
    def test_numbers_come_from_the_bt_cap_001_reading(self) -> None:
        fixture = _fixture()
        receipt_text = RECEIPT_PATH.read_text(encoding="utf-8")
        self.assertEqual(fixture["fonte"]["receipt"],
                         "docs/qa/execution/2026-09-23/host-xmage-e-reinicio.md")
        self.assertIn(fixture["fonte"]["section"], receipt_text)
        for item in fixture["lido"]:
            with self.subTest(campo=item["campo"]):
                self.assertIn(item["evidence"], receipt_text)
                self.assertTrue(any(abs(number - item["value"]) < 1e-9
                                    for number in capacity._receipt_numbers(item["evidence"])))
        snapshot = _snapshot(fixture)
        self.assertEqual(snapshot["host"]["cpu_count"], 4)
        self.assertEqual(snapshot["host"]["memory_total_mb"], 7941)
        self.assertEqual(snapshot["host"]["memory_available_mb"], 6484)

    def test_only_the_xmage_services_had_limits_and_they_were_scaled_to_zero(self) -> None:
        fixture = _fixture()
        for name, service in fixture["swarm"].items():
            with self.subTest(service=name):
                spec = service["Spec"]
                limits = spec["TaskTemplate"]["Resources"]["Limits"]
                replicas = spec["Mode"]["Replicated"]["Replicas"]
                self.assertRegex(spec["TaskTemplate"]["ContainerSpec"]["Image"],
                                 r"@sha256:[0-9a-f]{64}$")
                if "xmage" in name:
                    self.assertEqual(limits["MemoryBytes"], 4 * 1024 ** 3)
                    self.assertEqual(replicas, 0)
                else:
                    self.assertEqual(limits, {})
                    self.assertEqual(replicas, 1)

    def test_env_values_in_the_fixture_are_models(self) -> None:
        fixture = _fixture()
        secret_keys = re.compile(r"(SECRET|PASS|KEY|TOKEN)")
        for name, service in fixture["swarm"].items():
            for item in service["Spec"]["TaskTemplate"]["ContainerSpec"]["Env"]:
                key, _, value = item.partition("=")
                if secret_keys.search(key):
                    self.assertIn("modelo-nao-e-segredo", value, f"{name}: {key}")


# ------------------------------------------------------------------ política


class PolicySectionTest(unittest.TestCase):
    def _problems(self, mutate) -> list[str]:
        policy = _policy()
        mutate(policy["reservations_and_limits"])
        return capacity.policy_problems(policy)

    def test_versioned_section_is_valid(self) -> None:
        policy = _policy()
        self.assertEqual(capacity.policy_problems(policy), [])
        section = policy["reservations_and_limits"]
        self.assertEqual(section["owner_task"], "BT-CAP-002")
        total = sum(entry["memory_reservation_mb"] for entry in section["services"].values())
        self.assertEqual(total, 2656)
        tool = {name for name, entry in section["services"].items()
                if entry["applied_by"] == capacity.RESOURCE_TOOL}
        self.assertEqual(tool, set(TOOL_SERVICES))
        self.assertEqual(section["services"]["manaloom-postgres"]["applied_by"],
                         "pendente_do_dono")

    def test_refuses_incoherent_numbers(self) -> None:
        cases = {
            "abaixo de 4 vezes o uso lido": lambda s: s["services"]["cartinhas"].update(
                memory_limit_mb=150),
            "reserva de memória acima do limite": lambda s: s["services"]["cartinhas"].update(
                memory_reservation_mb=2048),
            "limite de CPU acima": lambda s: s["services"]["cartinhas"].update(cpu_limit=8),
            "reserva de CPU acima do limite": lambda s: s["services"]["manaloom-app"].update(
                cpu_reservation=1.0),
            "sem limite de memória": lambda s: s["services"]["cartinhas"].update(
                memory_limit_mb=0),
            "só aplica recursos em app": lambda s: s["services"]["xmage-interactive"].update(
                applied_by=capacity.RESOURCE_TOOL),
            "PostgreSQL só com decisão do dono": lambda s: s["services"][
                "manaloom-postgres"].update(applied_by="scripts/manaloom_deploy_battle_sidecars.sh"),
            "a soma das reservas": lambda s: s["services"]["manaloom-postgres"].update(
                memory_reservation_mb=6000),
            "evidence não está no receipt": lambda s: s["services"]["cartinhas"]["observed"][
                "memory_mib_below"].update(evidence="ficavam abaixo de 10 MiB cada"),
            "rationale ausente": lambda s: s["services"]["cartinhas"].pop("rationale"),
            "owner_task": lambda s: s.update(owner_task="BT-CAP-001"),
            "rules.rationale": lambda s: s["rules"]["rationale"].pop("limit_headroom_factor"),
        }
        for expected, mutate in cases.items():
            with self.subTest(expected=expected):
                problems = self._problems(mutate)
                self.assertTrue(any(expected in problem for problem in problems), problems)


# ------------------------------------------------------------------ plano


class PlanTest(unittest.TestCase):
    def test_passes_for_every_service_of_the_tool(self) -> None:
        fixture = _fixture()
        policy = _policy()
        for name in TOOL_SERVICES:
            with self.subTest(service=name):
                plane = _plane_from_fixture(fixture)
                result = _plan(plane, name)
                self.assertEqual(result["status"], "PASS", result["reasons"])
                entry = policy["reservations_and_limits"]["services"][name]
                self.assertEqual(result["desired"]["swarm"], {
                    "memory_limit_bytes": entry["memory_limit_mb"] * MIB,
                    "memory_reservation_bytes": entry["memory_reservation_mb"] * MIB,
                    "cpu_limit_nano": int(round(entry["cpu_limit"] * 1e9)),
                    "cpu_reservation_nano": int(round(entry["cpu_reservation"] * 1e9)),
                })
                self.assertNotIn("already_applied", result)
                self.assertEqual(result["before"]["resources"], {
                    "memory_limit_bytes": 0, "memory_reservation_bytes": 0,
                    "cpu_limit_nano": 0, "cpu_reservation_nano": 0})
                # Só o carmatch reservava memória (256 MiB); o XMage está em 0 réplicas.
                self.assertEqual(result["node_reservations"]["memory_mib_after"],
                                 256 + entry["memory_reservation_mb"])
                self.assertEqual(result["node_reservations"]["memory_budget_mib"], 7941 - 2048)

    def test_before_keeps_fingerprints_and_never_env_values(self) -> None:
        plane = _plane_from_fixture(_fixture())
        result = _plan(plane, "cartinhas")
        before = result["before"]
        self.assertEqual(before["env_keys"], ["DB_PASS", "ENVIRONMENT", "JWT_SECRET",
                                              "MANALOOM_TRUSTED_PROXY_HOPS",
                                              "MANALOOM_TRUSTED_PROXY_PEERS", "PORT"])
        self.assertRegex(before["spec_sha256"], r"^[0-9a-f]{64}$")
        self.assertRegex(before["easypanel"]["env_sha256"], r"^[0-9a-f]{64}$")
        text = json.dumps(result)
        for marker in SECRET_MARKERS:
            self.assertNotIn(marker, text)

    def test_blocks_services_that_are_not_of_the_tool(self) -> None:
        plane = _plane_from_fixture(_fixture())
        for name, expected in (
            ("xmage-sidecar", "manaloom_deploy_battle_sidecars.sh"),
            ("manaloom-postgres", "pendente_do_dono"),
        ):
            with self.subTest(service=name):
                result = resources.plan(
                    service_name=name, policy=_policy(), snapshot=_snapshot(_fixture()),
                    easypanel_raw="{}", inspect_raw="[]", running_raw="", now=_now())
                self.assertEqual(result["status"], "BLOCKED")
                self.assertIn(expected, result["reasons"][0])
        result = resources.plan(
            service_name="worker", policy=_policy(), snapshot=_snapshot(_fixture()),
            easypanel_raw="{}", inspect_raw="[]", running_raw="", now=_now())
        self.assertEqual(result["status"], "BLOCKED")
        self.assertIn("não está na política", result["reasons"][0])

    def _blocked(self, plane: dict[str, Any], expected: str, name: str = "cartinhas",
                 snapshot: dict[str, Any] | None = None) -> None:
        result = _plan(plane, name, snapshot)
        self.assertEqual(result["status"], "BLOCKED")
        self.assertTrue(any(expected in reason for reason in result["reasons"]),
                        result["reasons"])

    def test_blocks_a_service_that_is_not_stable(self) -> None:
        fixture = _fixture()
        plane = _plane_from_fixture(fixture)
        plane["tasks"]["evolution_cartinhas"][0]["image"] = "localhost:5000/manaloom/cartinhas@sha256:" + "d" * 64
        self._blocked(plane, "não convergiu")

        plane = _plane_from_fixture(fixture)
        plane["swarm"]["evolution_cartinhas"]["UpdateStatus"] = {"State": "updating"}
        self._blocked(plane, "atualização do Swarm em andamento")

        plane = _plane_from_fixture(fixture)
        tag = "localhost:5000/manaloom/cartinhas:latest"
        plane["swarm"]["evolution_cartinhas"]["Spec"]["TaskTemplate"]["ContainerSpec"]["Image"] = tag
        plane["tasks"]["evolution_cartinhas"] = [{"image": tag, "state": "Running 1 hour ago"}]
        _easypanel_entry(plane, "cartinhas")["source"]["image"] = tag
        self._blocked(plane, "não é um digest imutável")

        plane = _plane_from_fixture(fixture)
        plane["swarm"]["evolution_manaloom-releases"]["Spec"]["Mode"]["Replicated"]["Replicas"] = 0
        plane["tasks"]["evolution_manaloom-releases"] = []
        self._blocked(plane, "sem réplicas no ar", "manaloom-releases")

    def test_blocks_when_easypanel_and_swarm_disagree(self) -> None:
        fixture = _fixture()
        plane = _plane_from_fixture(fixture)
        _easypanel_entry(plane, "cartinhas")["source"]["image"] = (
            "localhost:5000/manaloom/cartinhas@sha256:" + "e" * 64)
        self._blocked(plane, "um deploy do EasyPanel trocaria a imagem")

        plane = _plane_from_fixture(fixture)
        _easypanel_entry(plane, "cartinhas")["resources"]["memoryLimit"] = 512
        self._blocked(plane, "recursos do EasyPanel divergem")

        plane = _plane_from_fixture(fixture)
        _easypanel_entry(plane, "cartinhas").pop("resources")
        self._blocked(plane, "não devolveu resources legíveis")

        plane = _plane_from_fixture(fixture)
        plane["easypanel"]["json"]["services"] = [
            entry for entry in plane["easypanel"]["json"]["services"]
            if entry["name"] != "cartinhas"]
        self._blocked(plane, "o EasyPanel não tem o serviço")

    def test_blocks_without_headroom_or_without_a_fresh_reading(self) -> None:
        fixture = _fixture()
        plane = _plane_from_fixture(fixture)
        self._blocked(plane, "preflight de capacidade BLOCKED",
                      snapshot=_snapshot(fixture, "2026-09-28T10:00:00Z"))
        carmatch = ('carmatch_worker\t{"Limits": {"MemoryBytes": 1073741824, "NanoCPUs": '
                    '1000000000}, "Reservations": {"MemoryBytes": 268435456, "NanoCPUs": '
                    '250000000}}')
        self._blocked(plane, "a soma das reservas de memória do nó", snapshot=_snapshot(
            fixture, replace={carmatch: carmatch.replace("268435456", str(5800 * MIB))}))
        self._blocked(plane, "a soma das reservas de CPU", snapshot=_snapshot(
            fixture, replace={carmatch: carmatch.replace('"NanoCPUs": 250000000',
                                                         '"NanoCPUs": 3900000000')}))
        self._blocked(plane, "abaixo de 4 vezes o uso lido", snapshot=_snapshot(
            fixture, replace={'"45.1MiB / 7.755GiB"': '"400MiB / 7.755GiB"'}))
        stats = next(line for line in _host_raw(fixture).splitlines()
                     if '"Name": "evolution_cartinhas.1.' in line)
        self._blocked(plane, "o snapshot não mediu a memória", snapshot=_snapshot(
            fixture, replace={stats + "\n": ""}))

    def test_refuses_the_spec_of_another_service(self) -> None:
        plane = _plane_from_fixture(_fixture())
        with self.assertRaises(capacity.InvalidInput):
            resources.plan(service_name="cartinhas", policy=_policy(),
                           snapshot=_snapshot(_fixture()), easypanel_raw=_easypanel_raw(plane),
                           inspect_raw=_inspect_raw(plane, "manaloom-ops"),
                           running_raw=_running_raw(plane, "manaloom-ops"), now=_now())

    def test_marks_already_applied(self) -> None:
        plane = _plane_from_fixture(_fixture())
        _apply_in_plane(plane, _plan(plane, "manaloom-app"))
        result = _plan(plane, "manaloom-app")
        self.assertEqual(result["status"], "PASS", result["reasons"])
        self.assertTrue(result["already_applied"])


# ------------------------------------------------------------------ conferências


class ChecksTest(unittest.TestCase):
    def setUp(self) -> None:
        self.plane = _plane_from_fixture(_fixture())
        self.plan = _plan(self.plane, "cartinhas")
        self.assertEqual(self.plan["status"], "PASS")

    def _check_apply(self) -> dict[str, Any]:
        return resources.check_apply(self.plan, _inspect_raw(self.plane, "cartinhas"),
                                     _easypanel_raw(self.plane),
                                     _running_raw(self.plane, "cartinhas"), "evolution")

    def test_apply_passes_when_only_resources_changed_in_both_places(self) -> None:
        _apply_in_plane(self.plane, self.plan)
        result = self._check_apply()
        self.assertEqual(result["status"], "PASS", result["problems"])
        self.assertEqual(result["after"]["spec_sha256_without_resources"],
                         self.plan["before"]["spec_sha256_without_resources"])
        self.assertNotEqual(result["after"]["spec_sha256"], self.plan["before"]["spec_sha256"])

    def test_apply_fails_on_any_other_change(self) -> None:
        cases = {
            "o env mudou": lambda plane: plane["swarm"]["evolution_cartinhas"]["Spec"][
                "TaskTemplate"]["ContainerSpec"]["Env"].append("EXTRA=1"),
            "a imagem mudou": lambda plane: other_deploy(plane, "evolution_cartinhas"),
            "recursos gravados no EasyPanel diferentes": lambda plane: _easypanel_entry(
                plane, "cartinhas").update(resources=self.plan["before"]["easypanel"]["resources"]),
            "o env gravado no EasyPanel mudou": lambda plane: _easypanel_entry(
                plane, "cartinhas").update(env="PORT=8081"),
            "o deploy gravado no EasyPanel mudou": lambda plane: _easypanel_entry(
                plane, "cartinhas")["deploy"].update(replicas=2),
            "tarefa fora da spec": lambda plane: plane["tasks"]["evolution_cartinhas"][0].update(
                state="Pending 2 seconds ago"),
            "a spec mudou além dos recursos": lambda plane: plane["swarm"][
                "evolution_cartinhas"]["Spec"]["UpdateConfig"].update(Order="start-first"),
        }
        for expected, mutate in cases.items():
            with self.subTest(expected=expected):
                self.setUp()
                _apply_in_plane(self.plane, self.plan)
                mutate(self.plane)
                result = self._check_apply()
                self.assertEqual(result["status"], "FAIL")
                self.assertTrue(any(expected in problem for problem in result["problems"]),
                                result["problems"])

    def _decision(self, receipt: dict[str, Any]) -> dict[str, Any]:
        return resources.rollback_decision(receipt, _inspect_raw(self.plane, "cartinhas"),
                                           _easypanel_raw(self.plane), "evolution")

    def test_rollback_decision_follows_our_change_only(self) -> None:
        _apply_in_plane(self.plane, self.plan)
        receipt = _receipt(self.plan, self.plane)
        self.assertEqual(self._decision(receipt),
                         {"status": "PASS", "swarm": "swarm_rollback",
                          "easypanel": "restore_resources"})
        # Parada no meio (sem conferência gravada): só vale se a diferença for a pedida.
        partial = resources.build_receipt(self.plan, "applied", None, None, FAKE_GIT_SHA)
        self.assertEqual(self._decision(partial)["swarm"], "swarm_rollback")
        self.plane["swarm"]["evolution_cartinhas"]["Spec"]["TaskTemplate"]["ContainerSpec"][
            "Env"].append("EXTRA=1")
        self.assertEqual(self._decision(partial)["status"], "BLOCKED")

    def test_rollback_decision_already_restored_and_easypanel_only(self) -> None:
        receipt = resources.build_receipt(self.plan, "applied", None, None, FAKE_GIT_SHA)
        self.assertEqual(self._decision(receipt),
                         {"status": "PASS", "swarm": "already_restored",
                          "easypanel": "already_restored"})
        _easypanel_entry(self.plane, "cartinhas")["resources"] = dict(
            self.plan["desired"]["easypanel"])
        self.assertEqual(self._decision(receipt)["easypanel"], "restore_resources")

    def test_rollback_decision_blocks_after_another_change(self) -> None:
        _apply_in_plane(self.plane, self.plan)
        receipt = _receipt(self.plan, self.plane)
        other_deploy(self.plane, "evolution_cartinhas")
        decision = self._decision(receipt)
        self.assertEqual(decision["status"], "BLOCKED")
        self.assertTrue(any("plano manual com o receipt" in reason
                            for reason in decision["reasons"]))

        # Outra mudança e o rollback dela: a spec atual volta a ser a nossa, mas a
        # anterior já não é a de antes; `docker service rollback` iria para a outra.
        self.setUp()
        _apply_in_plane(self.plane, self.plan)
        receipt = _receipt(self.plan, self.plane)
        swarm_only_update(self.plane, "evolution_cartinhas")
        swarm_rollback(self.plane, "evolution_cartinhas")
        self.assertEqual(resources.spec_fingerprint(self.plane["swarm"]["evolution_cartinhas"]["Spec"]),
                         receipt["after"]["spec_sha256"])
        decision = self._decision(receipt)
        self.assertEqual(decision["status"], "BLOCKED")
        self.assertIsNone(decision["swarm"])

        self.setUp()
        _apply_in_plane(self.plane, self.plan)
        receipt = _receipt(self.plan, self.plane)
        _easypanel_entry(self.plane, "cartinhas")["resources"]["memoryLimit"] = 999
        self.assertEqual(self._decision(receipt)["status"], "BLOCKED")

        self.setUp()
        _apply_in_plane(self.plane, self.plan)
        receipt = _receipt(self.plan, self.plane)
        _easypanel_entry(self.plane, "cartinhas")["env"] += "\nNOVA=1"
        self.assertEqual(self._decision(receipt)["status"], "BLOCKED")

    def test_check_rollback_demands_the_whole_spec_back(self) -> None:
        _apply_in_plane(self.plane, self.plan)
        receipt = _receipt(self.plan, self.plane)
        swarm_rollback(self.plane, "evolution_cartinhas")
        _easypanel_entry(self.plane, "cartinhas")["resources"] = dict(
            self.plan["before"]["easypanel"]["resources"])
        passed = resources.check_rollback(receipt, _inspect_raw(self.plane, "cartinhas"),
                                          _easypanel_raw(self.plane),
                                          _running_raw(self.plane, "cartinhas"), "evolution")
        self.assertEqual(passed["status"], "PASS", passed["problems"])

        def check() -> dict[str, Any]:
            return resources.check_rollback(receipt, _inspect_raw(self.plane, "cartinhas"),
                                            _easypanel_raw(self.plane),
                                            _running_raw(self.plane, "cartinhas"), "evolution")

        spec = self.plane["swarm"]["evolution_cartinhas"]["Spec"]
        spec["RollbackConfig"]["Order"] = "start-first"
        self.assertIn("rollback_config diferente do de antes", check()["problems"])
        spec["RollbackConfig"]["Order"] = "stop-first"
        # Só a impressão digital da spec inteira pega uma mudança de rótulo ou rede.
        spec["Labels"]["outro"] = "valor"
        self.assertEqual(check()["problems"],
                         ["a spec não voltou à de antes (imagem, env, recursos ou deploy)"])
        spec["Labels"].pop("outro")
        _easypanel_entry(self.plane, "cartinhas")["resources"] = dict(
            self.plan["desired"]["easypanel"])
        self.assertEqual(check()["problems"], [
            "o EasyPanel não voltou ao de antes (imagem, env, deploy ou recursos)"])

    def test_redaction_keeps_fingerprints_and_drops_values(self) -> None:
        raw = _inspect_raw(self.plane, "cartinhas")
        redacted = resources.redact_inspect(raw)
        for marker in SECRET_MARKERS:
            self.assertNotIn(marker, redacted)
        self.assertEqual(resources.redact_inspect(redacted), redacted)
        env = json.loads(redacted)[0]["Spec"]["TaskTemplate"]["ContainerSpec"]["Env"]
        self.assertTrue(all(re.fullmatch(r"[A-Z_]+=sha256:[0-9a-f]{64}", item) for item in env))
        changed = copy.deepcopy(self.plane)
        changed["swarm"]["evolution_cartinhas"]["Spec"]["TaskTemplate"]["ContainerSpec"][
            "Env"][-1] = "DB_PASS=outro-valor"
        self.assertNotEqual(
            resources.spec_fingerprint(json.loads(redacted)[0]["Spec"]),
            resources.spec_fingerprint(json.loads(resources.redact_inspect(
                _inspect_raw(changed, "cartinhas")))[0]["Spec"]))

        panel = resources.redact_easypanel(_easypanel_raw(self.plane), "evolution")
        for marker in SECRET_MARKERS:
            self.assertNotIn(marker, panel)
        services = json.loads(panel)["json"]["services"]
        self.assertEqual({entry["projectName"] for entry in services}, {"evolution"})
        entry = resources.load_easypanel(panel, "evolution", "cartinhas")
        self.assertEqual(resources.easypanel_view(entry),
                         resources.easypanel_view(_easypanel_entry(self.plane, "cartinhas")))
        self.assertEqual(resources.redact_easypanel(panel, "evolution"), panel)

    def test_fingerprint_ignores_key_order_but_not_values(self) -> None:
        spec = self.plane["swarm"]["evolution_cartinhas"]["Spec"]
        reordered = json.loads(json.dumps(spec, sort_keys=True))
        self.assertEqual(resources.spec_fingerprint(spec), resources.spec_fingerprint(reordered))
        changed = copy.deepcopy(spec)
        changed["TaskTemplate"]["ContainerSpec"]["Env"][0] = "PORT=8081"
        self.assertNotEqual(resources.spec_fingerprint(spec), resources.spec_fingerprint(changed))
        changed = copy.deepcopy(spec)
        changed["TaskTemplate"]["Resources"] = {"Limits": {"MemoryBytes": 1}}
        self.assertEqual(resources.spec_fingerprint(spec, without_resources=True),
                         resources.spec_fingerprint(changed, without_resources=True))


# ------------------------------------------------------------------ ferramenta


class ToolTest(unittest.TestCase):
    """A ferramenta de verdade, contra o plano falso."""

    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="bt-cap-002-"))
        base = Path.home() / ".cache" / "manaloom-capacity-resources-test"
        base.mkdir(parents=True, exist_ok=True)
        # O receipt recusa /tmp e worktree: o diretório de receipts fica em ~/.cache.
        self.receipts = Path(tempfile.mkdtemp(prefix="receipts-", dir=base))
        self.repo = self.tmp / "repo"
        for relative in (
            "scripts/manaloom_capacity_resources.sh",
            "scripts/manaloom_capacity_resources.py",
            "scripts/manaloom_capacity_policy.py",
            "scripts/manaloom_read_env.py",
            "scripts/lib/manaloom_mutation_guard.sh",
            "scripts/lib/manaloom_safe_env.sh",
            "scripts/lib/manaloom_release_runtime_contract.sh",
            "server/config/capacity_policy.json",
            "docs/qa/execution/2026-09-23/host-xmage-e-reinicio.md",
        ):
            target = self.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        self.state = self.tmp / "plane"
        self.state.mkdir()
        self.fixture = _fixture()
        plane = _plane_from_fixture(self.fixture)
        plane["watch_dir"] = str(self.tmp)
        save_plane(self.state, plane)
        bin_dir = self.tmp / "bin"
        bin_dir.mkdir()

        def shim(name: str, body: str) -> None:
            path = bin_dir / name
            path.write_text("#!/bin/bash\n" + body, encoding="utf-8")
            path.chmod(0o755)

        plane = f'exec "{sys.executable}" "{THIS_FILE}" --fake-plane'
        shim("ssh", f'{plane} ssh "{self.state}" "$@"\n')
        shim("curl", f'{plane} curl "{self.state}" "$@"\n')
        shim("ssh-keyscan", 'echo "evolution-cartinhas.2ta7qx.easypanel.host ssh-ed25519 AAAAC3Nza"\n')
        shim("ssh-keygen", f'cat >/dev/null\necho "256 {FAKE_HOST_KEY} host (ED25519)"\n')
        shim("git", 'if [[ "$3" == "rev-parse" ]]; then echo ' + FAKE_GIT_SHA + "; fi\n")
        (bin_dir / "python3").symlink_to(sys.executable)
        key = self.tmp / "deploy_key"
        key.write_text("chave de teste\n", encoding="utf-8")
        env_file = self.tmp / "server.env"
        env_file.write_text(
            f"EASYPANEL_BASE_URL={EASYPANEL_URL}\nEASYPANEL_API_TOKEN={EASYPANEL_TOKEN}\n"
            f"MANALOOM_EASYPANEL_SSH_KEY={key}\n", encoding="utf-8")
        self.env = {
            "PATH": f"{bin_dir}:/usr/bin:/bin",
            "HOME": str(self.tmp),
            "TMPDIR": str(self.tmp),
            "LC_ALL": "C.UTF-8",
            "PYTHONDONTWRITEBYTECODE": "1",
            "MANALOOM_NEW_SERVER_ENV": str(env_file),
            "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256": FAKE_HOST_KEY,
            "MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256":
                hashlib.sha256(EASYPANEL_URL.encode()).hexdigest(),
            "MANALOOM_CONFIRM_LIVE_MUTATIONS": "I_HAVE_EXPLICIT_APPROVAL",
            "MANALOOM_CAPACITY_WAIT_ATTEMPTS": "3",
            "MANALOOM_CAPACITY_WAIT_SECONDS": "0",
        }
        measured = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        self.snapshot = self.tmp / "snapshot.json"
        self.snapshot.write_text(json.dumps(_snapshot(self.fixture, measured)), encoding="utf-8")
        self.outputs: list[str] = []

    def tearDown(self) -> None:
        shutil.rmtree(self.tmp, ignore_errors=True)
        shutil.rmtree(self.receipts, ignore_errors=True)

    # -- utilitários

    def run_tool(self, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
        result = subprocess.run(
            ["/bin/bash", str(self.repo / "scripts/manaloom_capacity_resources.sh"), *args],
            capture_output=True, text=True, env=env or self.env, check=False, timeout=180,
        )
        self.outputs.append(result.stdout + result.stderr)
        return result

    def apply(self, service: str = "cartinhas", **env_overrides: str) -> subprocess.CompletedProcess:
        env = dict(self.env, **env_overrides)
        return self.run_tool("--execute", "--apply", "--service", service, "--snapshot",
                             str(self.snapshot), "--receipt-dir", str(self.receipts), env=env)

    def set_faults(self, **faults: bool) -> None:
        plane = load_plane(self.state)
        plane["faults"] = faults
        save_plane(self.state, plane)

    def calls(self) -> list[dict[str, Any]]:
        log = self.state / "calls.jsonl"
        if not log.exists():
            return []
        return [json.loads(line) for line in log.read_text(encoding="utf-8").splitlines()]

    def mutations(self) -> list[str]:
        found = []
        for call in self.calls():
            if call["program"] == "ssh" and call.get("kind") in {"update", "rollback"}:
                found.append(call["kind"])
            if call["program"] == "curl" and call["procedure"] == "services.app.updateResources":
                found.append("easypanel")
        return found

    def receipts_written(self) -> dict[str, dict[str, Any]]:
        return {path.name: json.loads(path.read_text(encoding="utf-8"))
                for path in sorted(self.receipts.glob("*.json"))}

    def only_receipt(self, pattern: str = r"capacidade-cartinhas-\d{8}T\d{6}Z\.json") -> dict[str, Any]:
        written = {name: data for name, data in self.receipts_written().items()
                   if re.fullmatch(pattern, name)}
        self.assertEqual(len(written), 1, list(self.receipts_written()))
        return next(iter(written.values()))

    def assert_back_to_the_fixture(self, name: str = "cartinhas") -> None:
        plane = load_plane(self.state)
        swarm = f"evolution_{name}"
        self.assertEqual(resources.spec_fingerprint(plane["swarm"][swarm]["Spec"]),
                         resources.spec_fingerprint(self.fixture["swarm"][swarm]["Spec"]))
        original = next(entry for entry in self.fixture["easypanel"]["json"]["services"]
                        if entry["projectName"] == "evolution" and entry["name"] == name)
        self.assertEqual(resources.easypanel_view(_easypanel_entry(plane, name)),
                         resources.easypanel_view(original))

    def assert_contract_kept(self) -> None:
        """Toda chamada ficou na lista fechada e nada de segredo saiu."""
        leaks = [call for call in self.calls() if call["program"] == "leak"]
        self.assertEqual(leaks, [], "valor de env gravado em arquivo de trabalho")
        for call in self.calls():
            if call["program"] == "ssh":
                self.assertNotIn("refused", call)
                self.assertIsNotNone(call["kind"], call)
            else:
                self.assertIn(call["procedure"], EASYPANEL_ALLOWED, call)
                self.assertTrue(call["https_only"], call)
        texts = self.outputs + [path.read_text(encoding="utf-8")
                                for path in self.receipts.glob("*.json")]
        for text in texts:
            for marker in SECRET_MARKERS:
                self.assertNotIn(marker, text)
        for path in self.receipts.glob("*.json"):
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600, path)

    # -- casos

    def test_without_execute_it_only_describes(self) -> None:
        result = self.run_tool()
        self.assertEqual(result.returncode, 0, result.stderr)
        described = json.loads(result.stdout)
        self.assertEqual(described["status"], "dry_run")
        self.assertEqual(set(described["easypanel"]), EASYPANEL_ALLOWED)
        self.assertEqual(set(described["services"]), set(
            _policy()["reservations_and_limits"]["services"]))
        self.assertEqual(self.calls(), [])

    def test_plan_only_reads(self) -> None:
        result = self.run_tool("--execute", "--plan", "--service", "cartinhas",
                               "--snapshot", str(self.snapshot))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(result.stdout)["status"], "PASS")
        self.assertEqual(self.mutations(), [])
        self.assertEqual(self.receipts_written(), {})
        self.assert_back_to_the_fixture()
        self.assert_contract_kept()

    def test_apply_changes_only_the_resources_in_both_places(self) -> None:
        result = self.apply()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update"])
        receipt = self.only_receipt()
        self.assertEqual(receipt["status"], "applied")
        self.assertEqual(receipt["tool_git_sha"], FAKE_GIT_SHA)
        self.assertEqual(receipt["apply_problems"], [])
        plane = load_plane(self.state)
        spec = plane["swarm"]["evolution_cartinhas"]["Spec"]
        original = self.fixture["swarm"]["evolution_cartinhas"]["Spec"]
        self.assertEqual(resources.spec_fingerprint(spec, without_resources=True),
                         resources.spec_fingerprint(original, without_resources=True))
        self.assertEqual(spec["TaskTemplate"]["Resources"], {
            "Limits": {"NanoCPUs": 2_000_000_000, "MemoryBytes": 1536 * MIB},
            "Reservations": {"NanoCPUs": 250_000_000, "MemoryBytes": 256 * MIB}})
        entry = _easypanel_entry(plane, "cartinhas")
        self.assertEqual(entry["resources"], {"memoryReservation": 256, "memoryLimit": 1536,
                                              "cpuReservation": 0.25, "cpuLimit": 2.0})
        update = next(call["remote"] for call in self.calls() if call.get("kind") == "update")
        self.assertEqual(update, "docker service update --detach=true --limit-memory 1610612736 "
                                 "--reserve-memory 268435456 --limit-cpu 2 --reserve-cpu 0.25 "
                                 "'evolution_cartinhas'")
        # Os outros serviços ficaram como estavam.
        for name in TOOL_SERVICES[1:]:
            self.assert_back_to_the_fixture(name)
        self.assert_contract_kept()

        again = self.apply()
        self.assertEqual(again.returncode, 0, again.stderr)
        self.assertIn("já são os da política", again.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update"])

    def test_rollback_from_the_receipt_restores_the_exact_spec(self) -> None:
        self.assertEqual(self.apply().returncode, 0)
        receipt_path = next(self.receipts.glob("capacidade-cartinhas-2*.json"))
        result = self.run_tool("--execute", "--rollback", str(receipt_path),
                               "--receipt-dir", str(self.receipts))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update", "easypanel", "rollback"])
        self.assert_back_to_the_fixture()
        rolled = self.only_receipt(r"capacidade-cartinhas-rollback-\d{8}T\d{6}Z\.json")
        self.assertEqual(rolled["status"], "rolled_back")
        self.assertEqual(rolled["rollback"]["status"], "PASS")
        self.assert_contract_kept()

    def test_rollback_is_blocked_after_another_deploy(self) -> None:
        self.assertEqual(self.apply().returncode, 0)
        receipt_path = next(self.receipts.glob("capacidade-cartinhas-2*.json"))
        plane = load_plane(self.state)
        other_deploy(plane, "evolution_cartinhas")
        save_plane(self.state, plane)
        result = self.run_tool("--execute", "--rollback", str(receipt_path),
                               "--receipt-dir", str(self.receipts))
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn("nada mudou", result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update"])
        self.assertEqual(load_plane(self.state), plane)
        self.assert_contract_kept()

    def test_rollback_needs_an_applied_receipt_and_approval(self) -> None:
        self.assertEqual(self.apply().returncode, 0)
        receipt_path = next(self.receipts.glob("capacidade-cartinhas-2*.json"))
        env = dict(self.env)
        del env["MANALOOM_CONFIRM_LIVE_MUTATIONS"]
        result = self.run_tool("--execute", "--rollback", str(receipt_path),
                               "--receipt-dir", str(self.receipts), env=env)
        self.assertEqual(result.returncode, 2)
        blocked = json.loads(receipt_path.read_text(encoding="utf-8"))
        blocked["status"] = "blocked"
        other = self.tmp / "blocked.json"
        other.write_text(json.dumps(blocked), encoding="utf-8")
        result = self.run_tool("--execute", "--rollback", str(other),
                               "--receipt-dir", str(self.receipts))
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.mutations(), ["easypanel", "update"])

    def test_a_wrong_result_is_rolled_back_automatically(self) -> None:
        self.set_faults(update_changes_env=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("rollback dos recursos provado", result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update", "easypanel", "rollback"])
        receipt = self.only_receipt()
        self.assertEqual(receipt["status"], "rolled_back")
        self.assertIn("o env mudou", receipt["apply_problems"])
        self.assertEqual(receipt["rollback"]["status"], "PASS")
        self.assert_back_to_the_fixture()
        self.assert_contract_kept()

    def test_a_paused_update_is_rolled_back(self) -> None:
        self.set_faults(update_paused=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update", "easypanel", "rollback"])
        self.assertEqual(self.only_receipt()["status"], "rolled_back")
        self.assert_back_to_the_fixture()
        self.assert_contract_kept()

    def test_a_swarm_auto_rollback_only_needs_the_easypanel_back(self) -> None:
        self.set_faults(update_auto_rollback=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update", "easypanel"])
        self.assertEqual(self.only_receipt()["status"], "rolled_back")
        self.assert_back_to_the_fixture()
        self.assert_contract_kept()

    def test_a_failed_swarm_update_restores_the_easypanel(self) -> None:
        self.set_faults(update_fails=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("a aplicação parou no meio", result.stderr)
        # A tentativa de update falhou no daemon: nada de rollback no Swarm.
        self.assertEqual(self.mutations(), ["easypanel", "update", "easypanel"])
        receipt = self.only_receipt()
        self.assertEqual(receipt["status"], "rolled_back")
        self.assertEqual(receipt["rollback"]["status"], "PASS")
        self.assert_back_to_the_fixture()
        self.assert_contract_kept()

    def test_a_failed_easypanel_update_changes_nothing(self) -> None:
        self.set_faults(easypanel_update_fails=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual([call["kind"] for call in self.calls()
                          if call["program"] == "ssh" and call["kind"] in {"update", "rollback"}], [])
        self.assertEqual(self.only_receipt()["status"], "rolled_back")
        self.assert_back_to_the_fixture()
        self.assert_contract_kept()

    def test_an_interruption_after_the_update_is_undone_exactly(self) -> None:
        # A leitura depois de aplicar falha: a saída passa pelo trap, sem conferência.
        self.set_faults(list_fails_after_update=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("a aplicação parou no meio", result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update", "easypanel", "rollback"])
        receipt = self.only_receipt()
        self.assertEqual(receipt["status"], "rolled_back")
        self.assertIsNone(receipt["after"])
        self.assert_back_to_the_fixture()
        self.assert_contract_kept()

    def test_a_rollback_that_does_not_restore_is_critical(self) -> None:
        self.set_faults(update_changes_env=True, rollback_fails=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("CRITICAL", result.stderr)
        receipt = self.only_receipt()
        self.assertEqual(receipt["status"], "rollback_failed")
        self.assertEqual(receipt["rollback"]["status"], "FAIL")
        self.assert_contract_kept()

    def test_another_deploy_in_the_middle_is_never_overwritten(self) -> None:
        self.set_faults(other_deploy_after_update=True)
        result = self.apply()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("CRITICAL", result.stderr)
        self.assertEqual(self.mutations(), ["easypanel", "update"])
        receipt = self.only_receipt()
        self.assertEqual(receipt["status"], "rollback_failed")
        self.assertEqual(receipt["rollback"]["status"], "BLOCKED")
        image = load_plane(self.state)["swarm"]["evolution_cartinhas"]["Spec"]["TaskTemplate"][
            "ContainerSpec"]["Image"]
        self.assertTrue(image.endswith("@sha256:" + "c" * 64))
        self.assert_contract_kept()

    def test_a_blocked_plan_writes_a_blocked_receipt_and_changes_nothing(self) -> None:
        plane = load_plane(self.state)
        _easypanel_entry(plane, "cartinhas")["source"]["image"] = (
            "localhost:5000/manaloom/cartinhas@sha256:" + "e" * 64)
        save_plane(self.state, plane)
        result = self.apply()
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertEqual(self.mutations(), [])
        receipt = self.only_receipt()
        self.assertEqual(receipt["status"], "blocked")
        self.assertTrue(any("trocaria a imagem" in reason for reason in receipt["reasons"]))
        result = self.apply("xmage-sidecar")
        self.assertEqual(result.returncode, 3)
        self.assertEqual(self.mutations(), [])
        self.assert_contract_kept()

    def test_mutation_needs_approval_anchors_and_a_durable_receipt_dir(self) -> None:
        env = dict(self.env)
        del env["MANALOOM_CONFIRM_LIVE_MUTATIONS"]
        self.assertEqual(self.run_tool("--execute", "--apply", "--service", "cartinhas",
                                       "--snapshot", str(self.snapshot), "--receipt-dir",
                                       str(self.receipts), env=env).returncode, 2)
        temporary = self.tmp / "receipts"
        temporary.mkdir()
        self.assertEqual(self.run_tool("--execute", "--apply", "--service", "cartinhas",
                                       "--snapshot", str(self.snapshot), "--receipt-dir",
                                       str(temporary)).returncode, 2)
        for key, value in (("MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256", None),
                           ("MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256", "f" * 64),
                           ("MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256", None),
                           ("MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256", "SHA256:" + "B" * 43)):
            with self.subTest(anchor=key, value=value):
                env = dict(self.env)
                if value is None:
                    del env[key]
                else:
                    env[key] = value
                result = self.run_tool("--execute", "--plan", "--service", "cartinhas",
                                       "--snapshot", str(self.snapshot), env=env)
                self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
