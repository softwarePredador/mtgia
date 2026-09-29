#!/usr/bin/env python3
"""BT-REL-001 (D-13): transação de promoção full-stack e rollback comprovado.

A prova roda a ferramenta de verdade (`scripts/manaloom_promote_release.sh`) num
repositório git descartável, com o SHA no origin/master e a matriz de capabilities
toda off (o /app sai como release de plano de controle, D-13). O resto é falso:
- um Docker Swarm e um EasyPanel de mentira, montados com as specs gravadas do
  BT-CAP-002 (server/test/fixtures/capacity/), atrás dos shims de ssh e curl;
- as sondas públicas (health do backend, healthz do site, release.json do /app e do
  release host), que respondem conforme a imagem no ar;
- os cinco deploys, trocados por stubs que mudam o plano falso como os scripts de
  verdade (uma atualização da spec no backend, ops e site; duas no /app e no
  Android) e injetam defeitos: falha antes ou depois de mudar, rollback próprio,
  saída mentirosa, SHA errado, SIGTERM e SIGKILL no orquestrador.
Nenhuma conexão sai da máquina. Este arquivo também é o plano falso: os shims
chamam `python3 release_promotion_test.py --fake-plane|--fake-deploy ...`.
"""

from __future__ import annotations

# Só o necessário para o plano falso: os shims chamam este arquivo dezenas de vezes
# por promoção, e as importações pesadas (unittest, subprocess) ficam para depois.
import copy
import datetime as dt
import hashlib
import json
import os
import re
import signal
import sys
from pathlib import Path
from typing import Any

THIS_FILE = Path(__file__).resolve()
REPO_ROOT = THIS_FILE.parents[2]
SCRIPT = REPO_ROOT / "scripts" / "manaloom_promote_release.sh"
MODULE_PATH = REPO_ROOT / "scripts" / "manaloom_promote_release.py"
CONFIG_PATH = REPO_ROOT / "server" / "config" / "release_promotion.json"
FIXTURE_PATH = REPO_ROOT / "server" / "test" / "fixtures" / "capacity" / (
    "evolution_services_2026-09-23.json")
FAKE_HOST_KEY = "SHA256:" + "A" * 43
SSH_TARGET = "root@evolution-cartinhas.2ta7qx.easypanel.host"
EASYPANEL_URL = "https://painel.exemplo.invalid"
EASYPANEL_TOKEN = "token-de-teste-nao-e-segredo-7e2a"
SECRET_MARKERS = ("modelo-nao-e-segredo", EASYPANEL_TOKEN)
OLD_SHA = "1" * 40
ORDER = ("backend", "ops", "site", "app", "android")
SERVICES = {"backend": "cartinhas", "ops": "manaloom-ops", "site": "manaloom-web-public",
            "app": "manaloom-app", "android": "manaloom-releases"}
REPOS = {"backend": "cartinhas", "ops": "ops", "site": "web-public", "app": "app-web",
         "android": "mobile-releases"}
STATUS = {"android": "published"}
TWO_UPDATES = {"app", "android"}
ENV_IN_SPEC = {"backend", "ops", "site"}
DEPLOYS = {
    "backend": "scripts/manaloom_deploy_backend_image.sh",
    "ops": "scripts/manaloom_deploy_ops_image.sh",
    "site": "scripts/manaloom_deploy_public_web.sh",
    "app": "scripts/manaloom_deploy_flutter_web.sh",
    "android": "scripts/manaloom_publish_android_release.sh",
}
PUBLIC = "https://evolution-manaloom-web-public.2ta7qx.easypanel.host"
PROBES = {
    "https://evolution-cartinhas.2ta7qx.easypanel.host/health": "backend",
    "https://evolution-cartinhas.2ta7qx.easypanel.host/capabilities": "backend",
    f"{PUBLIC}/healthz": "site",
    f"{PUBLIC}/release.json": "site",
    f"{PUBLIC}/app/release.json": "app",
    f"{PUBLIC}/app/flutter_bootstrap.js": "app",
    f"{PUBLIC}/app/assets/assets/release/release-identity.json": "app",
    f"{PUBLIC}/downloads/release.json": "android",
}
# A matriz que as imagens antigas servem (outra, de um SHA anterior).
OLD_DIGEST = "0" * 64
# O asset embarcado de um build sem identidade (o arquivo commitado do app).
DEVELOPMENT_IDENTITY = {"schema_version": 1, "status": "development_build",
                        "release_identity_embedded": False}
FLAGS_OFF = {"battle_live_spectator_enabled": False, "interactive_battle_enabled": False}
REMOTE_ALLOWED = {
    "inspect": re.compile(r"docker service inspect '(evolution_[a-z0-9-]+)'"),
    "ps": re.compile(
        r"docker service ps '(evolution_[a-z0-9-]+)' --filter desired-state=running "
        r"--format '\{\{\.Image\}\}\|\{\{\.CurrentState\}\}'"),
    "rollback": re.compile(r"docker service rollback --detach '(evolution_[a-z0-9-]+)'"),
}
EASYPANEL_ALLOWED = {"projects.listProjectsAndServices", "services.app.updateSourceImage",
                     "services.app.deployService"}
EASYPANEL_DEFAULT_UPDATE = {"Parallelism": 1, "FailureAction": "pause", "Monitor": 5000000000,
                            "MaxFailureRatio": 0, "Order": "stop-first"}


# ------------------------------------------------------------------ plano falso


def load_plane(state_dir: Path) -> dict[str, Any]:
    return json.loads((state_dir / "plane.json").read_text(encoding="utf-8"))


def save_plane(state_dir: Path, plane: dict[str, Any]) -> None:
    (state_dir / "plane.json").write_text(json.dumps(plane, ensure_ascii=False, indent=1),
                                          encoding="utf-8")


def _log(state_dir: Path, entry: dict[str, Any]) -> None:
    with (state_dir / "calls.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry, ensure_ascii=False) + "\n")


def swarm_name(surface: str) -> str:
    return f"evolution_{SERVICES[surface]}"


def new_image(surface: str, sha: str) -> str:
    digest = hashlib.sha256(f"{surface}:{sha}".encode()).hexdigest()
    return f"localhost:5000/manaloom/{REPOS[surface]}@sha256:{digest}"


def _running(service: dict[str, Any], state: str = "Running 5 seconds ago") -> list[dict[str, str]]:
    spec = service["Spec"]
    image = spec["TaskTemplate"]["ContainerSpec"]["Image"]
    return [{"image": image, "state": state}
            for _ in range(spec["Mode"]["Replicated"]["Replicas"])]


def _set_env(spec: dict[str, Any], key: str, value: str) -> None:
    env = spec["TaskTemplate"]["ContainerSpec"]["Env"]
    env[:] = [item for item in env if not item.startswith(f"{key}=")] + [f"{key}={value}"]


def easypanel_entry(plane: dict[str, Any], surface: str) -> dict[str, Any] | None:
    return next((entry for entry in plane["easypanel"]["json"]["services"]
                 if entry["projectName"] == "evolution" and entry["name"] == SERVICES[surface]),
                None)


def swarm_update(plane: dict[str, Any], name: str, change) -> None:
    service = plane["swarm"][name]
    service["PreviousSpec"] = copy.deepcopy(service["Spec"])
    change(service["Spec"])
    service["Version"]["Index"] += 1
    service["UpdateStatus"] = {"State": "completed"}
    plane["tasks"][name] = _running(service)


def swarm_rollback(plane: dict[str, Any], name: str) -> bool:
    service = plane["swarm"][name]
    if not isinstance(service.get("PreviousSpec"), dict):
        return False
    service["PreviousSpec"], service["Spec"] = service["Spec"], service["PreviousSpec"]
    service["Version"]["Index"] += 1
    service["UpdateStatus"] = {"State": "rollback_completed"}
    plane["tasks"][name] = _running(service)
    return True


def easypanel_deploy(plane: dict[str, Any], surface: str) -> None:
    """deployService: a spec sai do que o EasyPanel guarda (imagem, env e política dele)."""
    entry = easypanel_entry(plane, surface)

    def change(spec: dict[str, Any]) -> None:
        spec["TaskTemplate"]["ContainerSpec"]["Image"] = entry["source"]["image"]
        spec["TaskTemplate"]["ContainerSpec"]["Env"] = [
            line for line in entry["env"].split("\n") if line]
        spec["UpdateConfig"] = dict(EASYPANEL_DEFAULT_UPDATE)

    swarm_update(plane, swarm_name(surface), change)


def _current_image(plane: dict[str, Any], surface: str) -> str:
    return plane["swarm"][swarm_name(surface)]["Spec"]["TaskTemplate"]["ContainerSpec"]["Image"]


def probe_response(plane: dict[str, Any], url: str) -> tuple[int, str]:
    surface = PROBES.get(url)
    if surface is None:
        return 404, "not found"
    frozen = plane.get("frozen", {}).get(url)
    if frozen is not None:
        return frozen[0], frozen[1]
    tasks = plane["tasks"][swarm_name(surface)]
    if not tasks or not all(task["state"].startswith("Running") for task in tasks):
        return 502, "bad gateway"
    image = _current_image(plane, surface)
    # Identidade que a imagem leva (BT-REL-002); as imagens antigas não têm.
    ident = plane.get("identity", {}).get(image)
    digest = (ident or {}).get("digest", OLD_DIGEST)
    if surface == "backend":
        if url.endswith("/capabilities"):
            return 200, json.dumps({"product": "brewtact", "policy_digest_sha256": digest,
                                    "configuration_status": "valid"})
        return 200, json.dumps({"status": "healthy", "git_sha": plane["image_sha"].get(image),
                                "release_capabilities": {"policy_digest_sha256": digest},
                                "timestamp": dt.datetime.now().isoformat()})
    if surface == "site":
        if url.endswith("/release.json"):
            if ident is None:
                return 404, "not found"
            return 200, json.dumps({"schema_version": 1, "product": "brewtact",
                                    "surface": "site", "git_sha": ident["sha"]})
        return 200, "ok"
    if url.endswith("/app/release.json"):
        if image not in plane["release_json_images"]:
            return 404, "not found"
        return 200, json.dumps({"git_sha": plane["image_sha"].get(image), "image": image,
                                "product": "brewtact", "surface": "app",
                                "release_mode": "control_plane",
                                "release_capabilities": {"policy_digest_sha256": digest},
                                "features": (ident or {}).get("flags", FLAGS_OFF)})
    if url.endswith("release-identity.json"):
        if ident is None:
            return 200, json.dumps(DEVELOPMENT_IDENTITY)
        return 200, json.dumps({"schema_version": 1, "status": ident["status"],
                                "product": "brewtact", "surface": "app",
                                "git_sha": ident["sha"], "release_mode": "control_plane",
                                "features": ident["flags"],
                                "release_capabilities": {"policy_digest_sha256": digest}})
    if url.endswith("flutter_bootstrap.js"):
        return 200, f"// bootstrap {image}"
    return 200, json.dumps({"image": image, "git_sha": plane["image_sha"].get(image),
                            "product": "brewtact", "surface": "android",
                            "release_mode": "control_plane",
                            "release_capabilities": {"policy_digest_sha256": digest}})


def _scan_for_leaks(state_dir: Path, plane: dict[str, Any]) -> None:
    """Procura valor de env nos arquivos de trabalho novos desde a última chamada."""
    watch = plane.get("watch_dir")
    if not watch:
        return
    mark = state_dir / "scan_mark"
    since = mark.stat().st_mtime_ns if mark.exists() else 0
    mark.touch()
    for path in Path(watch).glob("manaloom-promote.*/*"):
        if path.is_file() and path.stat().st_mtime_ns >= since:
            content = path.read_text(encoding="utf-8", errors="ignore")
            if any(marker in content for marker in SECRET_MARKERS):
                _log(state_dir, {"program": "leak", "file": path.name})


def _fake_ssh(state_dir: Path, argv: list[str]) -> int:
    plane = load_plane(state_dir)
    if len(argv) < 2 or argv[-2] != SSH_TARGET or "StrictHostKeyChecking=yes" not in argv:
        _log(state_dir, {"program": "ssh", "refused": argv})
        return 255
    command = argv[-1]
    kind = next((key for key, pattern in REMOTE_ALLOWED.items() if pattern.fullmatch(command)),
                None)
    _log(state_dir, {"program": "ssh", "remote": command, "kind": kind})
    if kind is None:
        return 97
    name = REMOTE_ALLOWED[kind].fullmatch(command).group(1)
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
    if plane["faults"].get("swarm_rollback_fails"):
        print("Error response from daemon: rollback failed", file=sys.stderr)
        return 1
    if not swarm_rollback(plane, name):
        print(f"Error: service {name} does not have a previous spec", file=sys.stderr)
        return 1
    save_plane(state_dir, plane)
    return 0


def _fake_curl(state_dir: Path, argv: list[str]) -> int:
    plane = load_plane(state_dir)
    url = argv[-1]
    headers = [argv[index + 1] for index, arg in enumerate(argv[:-1]) if arg == "-H"]
    data = next((argv[index + 1] for index, arg in enumerate(argv[:-1]) if arg == "--data"),
                None)
    prefix = f"{EASYPANEL_URL}/api/trpc/"
    if not url.startswith(prefix):
        status, body = probe_response(plane, url)
        _log(state_dir, {"program": "curl", "probe": url, "status": status,
                         "https_only": "--proto" in argv})
        output = next((argv[index + 1] for index, arg in enumerate(argv[:-1]) if arg == "-o"),
                      None)
        if "-w" in argv:
            if output and output != "/dev/null":
                Path(output).write_text(body, encoding="utf-8")
            print(status, end="")
            return 0
        if status >= 400 and any(arg.startswith("-") and "f" in arg and not arg.startswith("--")
                                  for arg in argv):
            return 22
        print(body, end="")
        return 0
    procedure = url[len(prefix):]
    payload = json.loads(data)["json"] if data else None
    _log(state_dir, {"program": "curl", "procedure": procedure, "payload": payload,
                     "https_only": "--proto" in argv and "=https" in argv})
    if f"Authorization: Bearer {EASYPANEL_TOKEN}" not in headers:
        return 22
    if procedure == "projects.listProjectsAndServices":
        print(json.dumps(plane["easypanel"], ensure_ascii=False))
        return 0
    surface = next((key for key, value in SERVICES.items()
                    if payload and value == payload.get("serviceName")), None)
    entry = easypanel_entry(plane, surface) if surface else None
    if entry is None:
        return 22
    if procedure == "services.app.updateSourceImage":
        entry["source"]["image"] = payload["image"]
    elif procedure == "services.app.deployService":
        easypanel_deploy(plane, surface)
    else:
        return 22
    save_plane(state_dir, plane)
    print(json.dumps({"result": {"data": {"json": None}}}))
    return 0


def _fake_deploy(surface: str, state_dir: Path) -> int:
    """O deploy de uma superfície, como o script de verdade muda a produção."""
    plane = load_plane(state_dir)
    sha = os.environ.get("MANALOOM_RELEASE_SOURCE_SHA", "")
    faults = set(filter(None, plane["faults"].get(surface, "").split(",")))
    _log(state_dir, {"program": "deploy", "surface": surface, "sha": sha,
                     "faults": sorted(faults)})
    if "fail_before" in faults:
        print("BLOCKED: pré-condição do deploy falhou", file=sys.stderr)
        return 2
    image = new_image(surface, sha)
    name = swarm_name(surface)
    output = {"status": STATUS.get(surface, "deployed"), "service": name,
              "image_digest_ref": image, "git_sha": sha}
    if surface == "app":
        output["release_mode"] = "product_open" if "product_open" in faults else "control_plane"
    if "lie" in faults:
        print(json.dumps(output))
        return 0
    before_easypanel = copy.deepcopy(easypanel_entry(plane, surface))
    urls = [url for url, owner in PROBES.items() if owner == surface]
    if "stale_probe" in faults:
        # A sonda pública segue mostrando o de antes (cache ou proxy velho).
        plane.setdefault("frozen", {}).update(
            {url: list(probe_response(plane, url)) for url in urls})
    plane["image_sha"][image] = sha
    identity = {"sha": sha, "digest": plane["policy_digest"], "flags": dict(FLAGS_OFF),
                "status": "release"}
    if "wrong_digest" in faults:
        identity["digest"] = "e" * 64
    if "flag_on" in faults:
        identity["flags"]["interactive_battle_enabled"] = True
    if "dev_identity" in faults:
        identity["status"] = "development_build"
    if "stale_identity" in faults:
        identity["sha"] = OLD_SHA
    plane.setdefault("identity", {})[image] = identity
    if surface == "app":
        plane["release_json_images"].append(image)
    if surface in TWO_UPDATES:
        def tweak(spec: dict[str, Any]) -> None:
            if "tweak_changes_config" in faults:
                spec["UpdateConfig"]["Monitor"] = 45000000000
        swarm_update(plane, name, tweak)
        entry = easypanel_entry(plane, surface)
        entry["source"]["image"] = image

        def patch(spec: dict[str, Any]) -> None:
            spec["TaskTemplate"]["ContainerSpec"]["Image"] = image
        swarm_update(plane, name, patch)
    else:
        def change(spec: dict[str, Any]) -> None:
            spec["TaskTemplate"]["ContainerSpec"]["Image"] = image
            if "stale_env" not in faults:
                _set_env(spec, "GIT_SHA", sha)
        swarm_update(plane, name, change)
        entry = easypanel_entry(plane, surface)
        if entry is not None and surface != "ops" and "skip_easypanel" not in faults:
            entry["source"]["image"] = image
    if "sticky_probe" in faults:
        # A sonda fica presa no novo, mesmo depois de a superfície voltar.
        plane.setdefault("frozen", {}).update(
            {url: list(probe_response(plane, url)) for url in urls})
    if "revert_backend" in faults:
        # Alguém volta o backend enquanto a transação segue.
        swarm_rollback(plane, swarm_name("backend"))
    if "concurrent_change" in faults:
        # Outra mudança na spec depois do deploy (fora desta transação).
        swarm_update(plane, name, lambda spec: spec["Labels"].update(outro="valor"))
    if "fail_self_rollback" in faults:
        # O rollback do próprio script: spec anterior e origem de volta.
        swarm_rollback(plane, name)
        if before_easypanel is not None:
            easypanel_entry(plane, surface)["source"]["image"] = before_easypanel["source"]["image"]
        save_plane(state_dir, plane)
        print("rollback comprovado", file=sys.stderr)
        return 1
    save_plane(state_dir, plane)
    if "fail_after" in faults:
        print("servico nao convergiu", file=sys.stderr)
        return 1
    if "wrong_sha" in faults:
        output["git_sha"] = "f" * 40
    if faults & {"sigterm", "sigkill"}:
        os.kill(os.getppid(), signal.SIGTERM if "sigterm" in faults else signal.SIGKILL)
        return 1
    print("log do deploy sem segredo", file=sys.stderr)
    print(json.dumps(output))
    return 0


if __name__ == "__main__" and sys.argv[1:2] == ["--fake-plane"]:
    _program, _state = sys.argv[2], Path(sys.argv[3])
    _scan_for_leaks(_state, load_plane(_state))
    sys.exit(_fake_ssh(_state, sys.argv[4:]) if _program == "ssh"
             else _fake_curl(_state, sys.argv[4:]))
if __name__ == "__main__" and sys.argv[1:2] == ["--fake-deploy"]:
    sys.exit(_fake_deploy(sys.argv[2], Path(sys.argv[3])))

import contextlib  # noqa: E402
import importlib.util  # noqa: E402
import io  # noqa: E402
import shutil  # noqa: E402
import stat  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402
import unittest  # noqa: E402
from unittest import mock  # noqa: E402


# ------------------------------------------------------------------ módulo e fixture


def _load_module():
    spec = importlib.util.spec_from_file_location("bt_rel_001_promote", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


promote = _load_module()
resources = promote.resources
capacity = resources.capacity
identity_gate = promote.identity


def _config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def _fixture() -> dict[str, Any]:
    return json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))


def initial_plane() -> dict[str, Any]:
    fixture = _fixture()
    plane = {
        "swarm": copy.deepcopy(fixture["swarm"]),
        "tasks": copy.deepcopy(fixture["tasks"]),
        "easypanel": copy.deepcopy(fixture["easypanel"]),
        "faults": {},
        "image_sha": {},
        "release_json_images": [],
        "identity": {},
        # O digest da matriz commitada (o arquivo que a ferramenta lê no SHA).
        "policy_digest": hashlib.sha256(
            (REPO_ROOT / "server/config/release_capabilities.json").read_bytes()).hexdigest(),
    }
    for surface in ORDER:
        name = swarm_name(surface)
        spec = plane["swarm"][name]["Spec"]
        plane["image_sha"][spec["TaskTemplate"]["ContainerSpec"]["Image"]] = OLD_SHA
        if surface in ENV_IN_SPEC:
            # O env que o deploy grava direto na spec (o EasyPanel não o tem).
            _set_env(spec, "GIT_SHA", OLD_SHA)
    # O ops sobe direto no Swarm: o EasyPanel não é a origem dele.
    plane["easypanel"]["json"]["services"] = [
        entry for entry in plane["easypanel"]["json"]["services"]
        if entry["name"] != "manaloom-ops"]
    return plane


def _redacted_view(surface: str, plane: dict[str, Any], marker: str) -> dict[str, Any]:
    config = _config()
    return promote.view(
        promote.surface_config(config, surface),
        resources.redact_inspect(json.dumps([plane["swarm"][swarm_name(surface)]])),
        resources.redact_easypanel(json.dumps(plane["easypanel"]), "evolution"),
        "".join(f"{task['image']}|{task['state']}\n" for task in plane["tasks"][swarm_name(surface)]),
        marker, "evolution")


def _marker(plane: dict[str, Any], surface: str) -> str:
    config = promote.surface_config(_config(), surface)
    probe = config.get("probe")
    if not probe:
        return ""
    status, body = probe_response(plane, probe["url"])
    if probe["kind"] == "status_only":
        return f"http:{status}"
    if probe["kind"] == "json_field":
        return f"field:{json.loads(body)[probe['field']]}" if status == 200 else ""
    if status == 200:
        return "sha256:" + hashlib.sha256(body.encode()).hexdigest()
    status, body = probe_response(plane, probe["fallback_url"])
    return "fallback-sha256:" + hashlib.sha256(body.encode()).hexdigest() if status == 200 else ""


def _view(plane: dict[str, Any], surface: str) -> dict[str, Any]:
    return _redacted_view(surface, plane, _marker(plane, surface))


# ------------------------------------------------------------------ política


class ConfigTest(unittest.TestCase):
    def _problems(self, mutate) -> list[str]:
        config = _config()
        mutate(config)
        return promote.config_problems(config)

    def test_versioned_config_follows_d13(self) -> None:
        config = _config()
        self.assertEqual(promote.config_problems(config), [])
        self.assertEqual([surface["id"] for surface in config["surfaces"]], list(ORDER))
        for surface in config["surfaces"]:
            self.assertEqual(surface["deploy"], DEPLOYS[surface["id"]])
            self.assertTrue((REPO_ROOT / surface["deploy"]).is_file())
            if surface["env_in_swarm_spec"]:
                self.assertEqual(surface["compensation"], ["swarm_rollback"])

    def test_refuses_what_would_break_the_transaction(self) -> None:
        def swap(config: dict[str, Any]) -> None:
            surfaces = config["surfaces"]
            surfaces[2], surfaces[3] = surfaces[3], surfaces[2]

        cases = {
            "viola a D-13": swap,
            "exige as superfícies android": lambda c: c["surfaces"].pop(),
            "perderia o env da spec": lambda c: c["surfaces"][0].update(
                compensation=["swarm_rollback", "easypanel_redeploy"]),
            "exige origem managed": lambda c: c["surfaces"][1].update(
                env_in_swarm_spec=False, compensation=["swarm_rollback", "easypanel_redeploy"]),
            "vem sempre primeiro": lambda c: c["surfaces"][3].update(
                compensation=["easypanel_redeploy", "swarm_rollback"]),
            "deploy não existe": lambda c: c["surfaces"][4].update(
                deploy="scripts/nao_existe.sh"),
            "deve ser HTTPS": lambda c: c["surfaces"][0]["probe"].update(
                url="http://evolution-cartinhas.2ta7qx.easypanel.host/health"),
            "all_or_nothing": lambda c: c["transaction"].update(all_or_nothing=False),
            "citar a D-13": lambda c: c.update(decisions=[]),
            "service repetido": lambda c: c["surfaces"][1].update(service="cartinhas"),
            "identity ausente": lambda c: c["surfaces"][0].pop("identity"),
            "identity_gate deve ser do BT-REL-002": lambda c: c.pop("identity_gate"),
        }
        for expected, mutate in cases.items():
            with self.subTest(expected=expected):
                problems = self._problems(mutate)
                self.assertTrue(any(expected in problem for problem in problems), problems)

    def test_subset_keeps_the_order(self) -> None:
        config = _config()
        chosen = promote.selected_surfaces(config, "android,backend,app")
        self.assertEqual([surface["id"] for surface in chosen], ["backend", "app", "android"])
        self.assertEqual(len(promote.selected_surfaces(config, "")), len(ORDER))
        for wanted in ("backend,backend", "nada"):
            with self.assertRaises(promote.InvalidInput):
                promote.selected_surfaces(config, wanted)


# ------------------------------------------------------------------ lógica


class LogicTest(unittest.TestCase):
    def setUp(self) -> None:
        self.plane = initial_plane()
        self.config = _config()
        self.baseline = {surface: _view(self.plane, surface) for surface in ORDER}
        self.sha = "2" * 40

    def surface(self, surface: str) -> dict[str, Any]:
        return promote.surface_config(self.config, surface)

    def deploy(self, surface: str, fault: str = "") -> dict[str, Any]:
        self.plane["faults"] = {surface: fault} if fault else {}
        state = Path(tempfile.mkdtemp(prefix="bt-rel-001-"))
        try:
            save_plane(state, self.plane)
            with mock.patch.dict(os.environ, {"MANALOOM_RELEASE_SOURCE_SHA": self.sha}), \
                    contextlib.redirect_stdout(io.StringIO()), \
                    contextlib.redirect_stderr(io.StringIO()):
                _fake_deploy(surface, state)
            self.plane = load_plane(state)
        finally:
            shutil.rmtree(state)
        return {"status": STATUS.get(surface, "deployed"),
                "image_digest_ref": new_image(surface, self.sha), "git_sha": self.sha}

    def test_every_baseline_is_rollback_safe(self) -> None:
        for surface in ORDER:
            with self.subTest(surface=surface):
                self.assertEqual(
                    promote.baseline_problems(self.surface(surface), self.baseline[surface]), [])
        self.assertTrue(self.baseline["app"]["marker"].startswith("fallback-sha256:"))
        self.assertEqual(self.baseline["backend"]["marker"], f"field:{OLD_SHA}")
        self.assertIsNone(self.baseline["ops"]["easypanel"])
        text = json.dumps(self.baseline)
        for marker in SECRET_MARKERS:
            self.assertNotIn(marker, text)

    def test_baseline_that_cannot_come_back_is_refused(self) -> None:
        name = swarm_name("app")
        tag = "localhost:5000/manaloom/app-web:latest"
        self.plane["swarm"][name]["Spec"]["TaskTemplate"]["ContainerSpec"]["Image"] = tag
        self.plane["tasks"][name] = [{"image": tag, "state": "Running 1 day ago"}]
        problems = promote.baseline_problems(self.surface("app"), _view(self.plane, "app"))
        self.assertTrue(any("não é um digest" in problem for problem in problems))
        self.setUp()
        self.plane["tasks"][swarm_name("site")] = []
        problems = promote.baseline_problems(self.surface("site"), _view(self.plane, "site"))
        self.assertTrue(any("tarefas no ar" in problem for problem in problems), problems)
        self.setUp()
        self.plane["easypanel"]["json"]["services"] = [
            entry for entry in self.plane["easypanel"]["json"]["services"]
            if entry["name"] != "cartinhas"]
        problems = promote.baseline_problems(self.surface("backend"),
                                             _view(self.plane, "backend"))
        self.assertTrue(any("o EasyPanel não tem o serviço" in problem for problem in problems))

    def test_view_refuses_the_spec_of_another_service(self) -> None:
        with self.assertRaises(promote.InvalidInput):
            promote.view(
                self.surface("backend"),
                resources.redact_inspect(json.dumps([self.plane["swarm"][swarm_name("ops")]])),
                resources.redact_easypanel(json.dumps(self.plane["easypanel"]), "evolution"),
                "", "", "evolution")

    def test_a_stale_public_probe_is_not_a_deploy(self) -> None:
        for surface in ("backend", "app", "android"):
            with self.subTest(surface=surface):
                self.setUp()
                result = self.deploy(surface, "stale_probe")
                check = promote.check_deployed(self.surface(surface), self.baseline[surface],
                                               _view(self.plane, surface), result, self.sha,
                                               "control_plane")
                self.assertEqual(check["status"], "FAIL")
                self.assertEqual(len(check["problems"]), 1, check["problems"])
                self.assertIn(f"a sonda de {surface}", check["problems"][0])

    def test_check_deployed_demands_spec_origin_probe_and_same_sha(self) -> None:
        for surface in ORDER:
            with self.subTest(surface=surface):
                self.setUp()
                result = self.deploy(surface)
                check = promote.check_deployed(self.surface(surface), self.baseline[surface],
                                               _view(self.plane, surface), result, self.sha,
                                               "control_plane")
                self.assertEqual(check["status"], "PASS", check["problems"])
        self.setUp()
        result = self.deploy("backend", "lie")
        check = promote.check_deployed(self.surface("backend"), self.baseline["backend"],
                                       _view(self.plane, "backend"), result, self.sha,
                                       "control_plane")
        self.assertEqual(check["status"], "FAIL")
        self.assertTrue(any("a spec está em" in problem for problem in check["problems"]))
        self.setUp()
        result = self.deploy("app")
        check = promote.check_deployed(self.surface("app"), self.baseline["app"],
                                       _view(self.plane, "app"), dict(result, git_sha="f" * 40),
                                       self.sha, "control_plane")
        self.assertTrue(any("outro SHA" in problem for problem in check["problems"]))
        check = promote.check_deployed(self.surface("app"), self.baseline["app"],
                                       _view(self.plane, "app"),
                                       dict(result, release_mode="product_open"),
                                       self.sha, "control_plane")
        self.assertTrue(any("não em control_plane" in problem for problem in check["problems"]))
        check = promote.check_deployed(self.surface("app"), self.baseline["app"],
                                       _view(self.plane, "app"), None, self.sha, "control_plane")
        self.assertEqual(check["status"], "FAIL")
        # O Swarm subiu, mas a origem do EasyPanel ficou na imagem velha: o próximo
        # deploy do EasyPanel desfaria a promoção.
        self.setUp()
        result = self.deploy("backend", "skip_easypanel")
        check = promote.check_deployed(self.surface("backend"), self.baseline["backend"],
                                       _view(self.plane, "backend"), result, self.sha,
                                       "control_plane")
        self.assertEqual(len(check["problems"]), 1, check["problems"])
        self.assertIn("a origem do EasyPanel está em", check["problems"][0])

    def _decide(self, surface: str) -> dict[str, Any]:
        return promote.compensation_decision(self.surface(surface), self.baseline[surface],
                                             _view(self.plane, surface))

    def test_compensation_decision_per_surface(self) -> None:
        self.deploy("backend")
        self.assertEqual(self._decide("backend"),
                         {"status": "PASS", "swarm": "swarm_rollback", "easypanel": "restore_image",
                          "image": self.baseline["backend"]["spec"]["image"]})
        self.deploy("ops")
        self.assertEqual(self._decide("ops")["easypanel"], "not_managed")
        self.deploy("app", "tweak_changes_config")
        self.assertEqual(self._decide("app")["swarm"], "easypanel_redeploy")
        self.setUp()
        self.deploy("backend", "fail_self_rollback")
        self.assertEqual(self._decide("backend")["swarm"], "already")
        self.setUp()
        self.deploy("backend", "concurrent_change")
        decision = self._decide("backend")
        self.assertEqual(decision["status"], "BLOCKED")
        self.assertTrue(any("não seria exato" in reason for reason in decision["reasons"]))

    def test_restore_is_proven_exact_or_by_identity(self) -> None:
        self.deploy("backend")
        swarm_rollback(self.plane, swarm_name("backend"))
        easypanel_entry(self.plane, "backend")["source"]["image"] = (
            self.baseline["backend"]["spec"]["image"])
        check = promote.check_restored(self.surface("backend"), self.baseline["backend"],
                                       _view(self.plane, "backend"))
        self.assertEqual((check["status"], check["level"]), ("PASS", "exact"))

        self.deploy("app", "tweak_changes_config")
        easypanel_entry(self.plane, "app")["source"]["image"] = self.baseline["app"]["spec"]["image"]
        easypanel_deploy(self.plane, "app")
        check = promote.check_restored(self.surface("app"), self.baseline["app"],
                                       _view(self.plane, "app"))
        self.assertEqual((check["status"], check["level"]), ("PASS", "identity"))

        # O backend redeployado pelo EasyPanel perde o env da spec: não voltou.
        self.setUp()
        self.deploy("backend")
        easypanel_entry(self.plane, "backend")["source"]["image"] = (
            self.baseline["backend"]["spec"]["image"])
        easypanel_deploy(self.plane, "backend")
        check = promote.check_restored(self.surface("backend"), self.baseline["backend"],
                                       _view(self.plane, "backend"))
        self.assertEqual(check["status"], "FAIL")
        self.assertIn("o env não voltou ao de antes", check["problems"])

    def test_restore_demands_origin_and_probe_back(self) -> None:
        self.deploy("app", "sticky_probe")
        swarm_rollback(self.plane, swarm_name("app"))
        check = promote.check_restored(self.surface("app"), self.baseline["app"],
                                       _view(self.plane, "app"))
        self.assertEqual(check["status"], "FAIL")
        self.assertTrue(any("origem do EasyPanel" in problem for problem in check["problems"]))
        self.assertTrue(any("a sonda de app não voltou" in problem
                            for problem in check["problems"]))
        easypanel_entry(self.plane, "app")["source"]["image"] = self.baseline["app"]["spec"]["image"]
        self.plane["frozen"] = {}
        check = promote.check_restored(self.surface("app"), self.baseline["app"],
                                       _view(self.plane, "app"))
        self.assertEqual(check["status"], "PASS", check["problems"])

    def test_check_converged_catches_a_later_change(self) -> None:
        result = self.deploy("site")
        committed = promote.check_deployed(self.surface("site"), self.baseline["site"],
                                           _view(self.plane, "site"), result,
                                           self.sha, "control_plane")["committed"]
        self.assertEqual(promote.check_converged(self.surface("site"), committed,
                                                 _view(self.plane, "site"))["status"], "PASS")
        swarm_rollback(self.plane, swarm_name("site"))
        self.assertEqual(promote.check_converged(self.surface("site"), committed,
                                                 _view(self.plane, "site"))["status"], "FAIL")


class JournalTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="bt-rel-001-journal-"))
        self.journal = self.tmp / "promocao-abc-20260928T000000Z.jsonl"

    def tearDown(self) -> None:
        shutil.rmtree(self.tmp)

    def test_chain_status_and_visibility(self) -> None:
        promote.journal_append(self.journal, "begin", {"sha": "2" * 40, "surfaces": ["backend"],
                                                       "release_mode": "control_plane"})
        self.assertEqual(stat.S_IMODE(self.journal.stat().st_mode), 0o600)
        promote.journal_append(self.journal, "surface_started", {"surface": "backend"})
        state = promote.journal_status(self.journal)
        self.assertEqual((state["status"], state["exit_code"]), ("incomplete", 4))
        self.assertEqual(promote.latest_open(self.tmp)["status"], "incomplete")
        promote.journal_append(self.journal, "surface_committed", {"surface": "backend"})
        promote.journal_append(self.journal, "end", {"status": "committed"})
        state = promote.journal_status(self.journal)
        self.assertEqual((state["status"], state["exit_code"]), ("committed", 0))
        self.assertEqual(state["surfaces"], {"backend": "committed"})
        self.assertEqual(promote.latest_open(self.tmp)["status"], "none")
        with self.assertRaises(promote.InvalidInput):
            promote.journal_append(self.journal, "surface_started", {"surface": "ops"})

    def test_rollback_failed_stays_open_until_resolved(self) -> None:
        promote.journal_append(self.journal, "begin", {"sha": "2" * 40, "surfaces": ["backend"]})
        promote.journal_append(self.journal, "end", {"status": "rollback_failed"})
        self.assertEqual(promote.journal_status(self.journal)["exit_code"], 1)
        self.assertEqual(promote.latest_open(self.tmp)["status"], "rollback_failed")
        promote.journal_append(self.journal, "resolved", {"reason": "conferido à mão"})
        self.assertEqual(promote.journal_status(self.journal)["status"], "resolved")
        self.assertEqual(promote.latest_open(self.tmp)["status"], "none")
        with self.assertRaises(promote.InvalidInput):
            promote.journal_append(self.journal, "resolved", {"reason": "de novo"})

    def test_tampered_or_truncated_journal_is_visible(self) -> None:
        promote.journal_append(self.journal, "begin", {"sha": "2" * 40, "surfaces": []})
        promote.journal_append(self.journal, "surface_started", {"surface": "backend"})
        promote.journal_append(self.journal, "end", {"status": "committed"})
        lines = self.journal.read_text(encoding="utf-8").splitlines()
        self.journal.write_text("\n".join([lines[0], lines[2]]) + "\n", encoding="utf-8")
        with self.assertRaises(promote.InvalidInput):
            promote.journal_status(self.journal)
        self.assertEqual(promote.latest_open(self.tmp)["status"], "corrupt")
        self.journal.write_text(lines[0].replace('"begin"', '"surface_started"') + "\n",
                                encoding="utf-8")
        with self.assertRaises(promote.InvalidInput):
            promote.journal_append(self.journal, "end", {"status": "committed"})

    def test_rewritten_line_or_renumbered_journal_is_refused(self) -> None:
        promote.journal_append(self.journal, "begin", {"sha": "2" * 40, "surfaces": []})
        promote.journal_append(self.journal, "surface_started", {"surface": "backend"})
        promote.journal_append(self.journal, "end", {"status": "committed"})
        lines = self.journal.read_text(encoding="utf-8").splitlines()
        # Mesma sequência, conteúdo trocado: só a corrente de hashes pega.
        self.journal.write_text("\n".join([lines[0], lines[1].replace("backend", "ops"),
                                           lines[2]]) + "\n", encoding="utf-8")
        with self.assertRaises(promote.InvalidInput):
            promote.parse_journal(self.journal)
        # Corrente íntegra, numeração pulada: só a sequência pega.
        first = json.loads(lines[0])
        second = json.loads(lines[1])
        second["seq"] = 3
        second_line = json.dumps(second, ensure_ascii=False, sort_keys=True)
        self.journal.write_text(lines[0] + "\n" + second_line + "\n", encoding="utf-8")
        self.assertEqual(first["seq"], 1)
        with self.assertRaises(promote.InvalidInput):
            promote.parse_journal(self.journal)

    def test_first_event_is_begin_and_end_status_is_known(self) -> None:
        with self.assertRaises(promote.InvalidInput):
            promote.journal_append(self.journal, "surface_started", {"surface": "backend"})
        promote.journal_append(self.journal, "begin", {"sha": "2" * 40, "surfaces": []})
        with self.assertRaises(promote.InvalidInput):
            promote.journal_append(self.journal, "end", {"status": "talvez"})
        with self.assertRaises(promote.InvalidInput):
            promote.journal_append(self.journal, "begin", {})


# ------------------------------------------------------------------ ferramenta


class ToolTest(unittest.TestCase):
    """A ferramenta de verdade num repositório descartável, contra o plano falso."""

    FILES = (
        "scripts/manaloom_promote_release.sh",
        "scripts/manaloom_promote_release.py",
        "scripts/manaloom_release_identity_gate.py",
        "scripts/manaloom_capacity_resources.py",
        "scripts/manaloom_capacity_policy.py",
        "scripts/manaloom_read_env.py",
        "scripts/lib/manaloom_mutation_guard.sh",
        "scripts/lib/manaloom_safe_env.sh",
        "scripts/lib/manaloom_release_runtime_contract.sh",
        "scripts/lib/manaloom_release_capabilities_contract.sh",
        "server/config/release_promotion.json",
        "server/config/release_capabilities.json",
        "server/config/capacity_policy.json",
        "docs/qa/execution/2026-09-23/host-xmage-e-reinicio.md",
    )

    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp(prefix="bt-rel-001-"))
        base = Path.home() / ".cache" / "manaloom-release-promotion-test"
        base.mkdir(parents=True, exist_ok=True)
        self.receipts = Path(tempfile.mkdtemp(prefix="receipts-", dir=base))
        self.state = self.tmp / "plane"
        self.state.mkdir()
        plane = initial_plane()
        plane["watch_dir"] = str(self.tmp)
        save_plane(self.state, plane)
        self.repo = self.tmp / "repo"
        for relative in self.FILES:
            target = self.repo / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO_ROOT / relative, target)
        for surface, deploy in DEPLOYS.items():
            stub = self.repo / deploy
            stub.write_text(f'#!/bin/bash\nexec "{sys.executable}" "{THIS_FILE}" --fake-deploy '
                            f'{surface} "{self.state}"\n', encoding="utf-8")
            stub.chmod(0o755)
        (self.repo / ".gitignore").write_text("__pycache__/\n", encoding="utf-8")
        self.sha = self._commit_and_push()
        bin_dir = self.tmp / "bin"
        bin_dir.mkdir()

        def shim(name: str, body: str) -> None:
            path = bin_dir / name
            path.write_text("#!/bin/bash\n" + body, encoding="utf-8")
            path.chmod(0o755)

        plane_cmd = f'exec "{sys.executable}" "{THIS_FILE}" --fake-plane'
        shim("ssh", f'{plane_cmd} ssh "{self.state}" "$@"\n')
        shim("curl", f'{plane_cmd} curl "{self.state}" "$@"\n')
        shim("ssh-keyscan", 'echo "evolution-cartinhas.2ta7qx.easypanel.host ssh-ed25519 AAAAC3Nza"\n')
        shim("ssh-keygen", f'cat >/dev/null\necho "256 {FAKE_HOST_KEY} host (ED25519)"\n')
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
            "GIT_CONFIG_NOSYSTEM": "1",
            "MANALOOM_NEW_SERVER_ENV": str(env_file),
            "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256": FAKE_HOST_KEY,
            "MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256":
                hashlib.sha256(EASYPANEL_URL.encode()).hexdigest(),
            "MANALOOM_CONFIRM_LIVE_MUTATIONS": "I_HAVE_EXPLICIT_APPROVAL",
            "MANALOOM_PROMOTE_WAIT_ATTEMPTS": "3",
            "MANALOOM_PROMOTE_WAIT_SECONDS": "0",
            "MANALOOM_PROMOTE_PROBE_ATTEMPTS": "1",
        }
        measured = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        fixture = _fixture()
        snapshot = capacity.build_snapshot(
            host_raw=fixture["snapshot_host_raw"].replace("{MEASURED_AT}", measured),
            postgres_raw=fixture["postgres_raw"],
            ssh_target=SSH_TARGET, host_key=FAKE_HOST_KEY, git_sha="0" * 40,
            tree_clean=True, collected_at=measured)
        self.snapshot = self.tmp / "snapshot.json"
        self.snapshot.write_text(json.dumps(snapshot), encoding="utf-8")
        self.outputs: list[str] = []

    def tearDown(self) -> None:
        shutil.rmtree(self.tmp, ignore_errors=True)
        shutil.rmtree(self.receipts, ignore_errors=True)

    def _git(self, *args: str) -> str:
        return subprocess.run(["git", "-C", str(self.repo), *args], capture_output=True,
                              text=True, check=True,
                              env={"PATH": "/usr/bin:/bin", "HOME": str(self.tmp),
                                   "GIT_CONFIG_NOSYSTEM": "1"}).stdout.strip()

    def _commit_and_push(self) -> str:
        origin = self.tmp / "origin.git"
        subprocess.run(["git", "init", "--bare", "--quiet", str(origin)], check=True,
                       env={"PATH": "/usr/bin:/bin", "HOME": str(self.tmp)})
        self._git("init", "--quiet")
        self._git("config", "user.name", "contract-test")
        self._git("config", "user.email", "contract-test@localhost")
        self._git("add", "-A")
        self._git("commit", "--quiet", "-m", "candidato")
        self._git("branch", "-M", "master")
        self._git("remote", "add", "origin", str(origin))
        self._git("push", "--quiet", "-u", "origin", "master")
        return self._git("rev-parse", "HEAD")

    # -- utilitários

    def run_tool(self, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
        result = subprocess.run(
            ["/bin/bash", str(self.repo / "scripts/manaloom_promote_release.sh"), *args],
            capture_output=True, text=True, env=env or self.env, check=False, timeout=300)
        self.outputs.append(result.stdout + result.stderr)
        return result

    def promote(self, surfaces: str = "", **env_overrides: str) -> subprocess.CompletedProcess:
        args = ["--execute", "--promote", "--sha", self.sha, "--receipt-dir", str(self.receipts),
                "--capacity-snapshot", str(self.snapshot)]
        if surfaces:
            args += ["--surfaces", surfaces]
        return self.run_tool(*args, env=dict(self.env, **env_overrides))

    def faults(self, **faults: str) -> None:
        plane = load_plane(self.state)
        plane["faults"] = faults
        save_plane(self.state, plane)

    def calls(self) -> list[dict[str, Any]]:
        log = self.state / "calls.jsonl"
        if not log.exists():
            return []
        return [json.loads(line) for line in log.read_text(encoding="utf-8").splitlines()]

    def deployed(self) -> list[str]:
        return [call["surface"] for call in self.calls() if call["program"] == "deploy"]

    def mutations(self) -> list[str]:
        found = []
        for call in self.calls():
            if call["program"] == "ssh" and call.get("kind") == "rollback":
                found.append("rollback:" + call["remote"].split("'")[1])
            if call["program"] == "curl" and call.get("procedure") in {
                    "services.app.updateSourceImage", "services.app.deployService"}:
                found.append(call["procedure"].rsplit(".", 1)[1] + ":"
                             + call["payload"]["serviceName"])
        return found

    def journal(self) -> tuple[Path, list[dict[str, Any]]]:
        journals = sorted(self.receipts.glob("promocao-*.jsonl"))
        self.assertEqual(len(journals), 1, journals)
        return journals[0], promote.parse_journal(journals[0])

    def events(self) -> list[str]:
        return [record["event"] for record in self.journal()[1]]

    def assert_at_baseline(self, surfaces=ORDER) -> None:
        plane = load_plane(self.state)
        original = initial_plane()
        for surface in surfaces:
            with self.subTest(baseline=surface):
                now = _view(plane, surface)
                before = _view(original, surface)
                self.assertEqual(now["identity_sha256"], before["identity_sha256"])
                self.assertEqual(now["marker"], before["marker"])
                if before["easypanel"] is not None:
                    self.assertEqual(now["easypanel"]["image"], before["spec"]["image"])

    def assert_contract_kept(self) -> None:
        calls = self.calls()
        self.assertEqual([call for call in calls if call["program"] == "leak"], [],
                         "valor de env gravado em arquivo de trabalho")
        for call in calls:
            if call["program"] == "ssh":
                self.assertNotIn("refused", call)
                self.assertIsNotNone(call["kind"], call)
            elif call["program"] == "curl":
                if "procedure" in call:
                    self.assertIn(call["procedure"], EASYPANEL_ALLOWED, call)
                else:
                    self.assertIn(call["probe"], PROBES, call)
                self.assertTrue(call["https_only"], call)
        texts = self.outputs + [path.read_text(encoding="utf-8")
                                for path in self.receipts.glob("promocao-*")]
        for text in texts:
            for marker in SECRET_MARKERS:
                self.assertNotIn(marker, text)
        for path in self.receipts.glob("promocao-*"):
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600, path)

    # -- casos

    def test_without_execute_it_only_describes(self) -> None:
        result = self.run_tool()
        self.assertEqual(result.returncode, 0, result.stderr)
        described = json.loads(result.stdout)
        self.assertEqual(described["order"], list(ORDER))
        self.assertEqual(set(described["easypanel"]), EASYPANEL_ALLOWED)
        self.assertEqual(self.calls(), [])

    def test_preflight_only_reads_and_sees_a_control_plane_release(self) -> None:
        result = self.run_tool("--execute", "--preflight", "--sha", self.sha,
                               "--capacity-snapshot", str(self.snapshot))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        summary = json.loads(result.stdout)
        self.assertEqual((summary["status"], summary["release_mode"], summary["capacity"]),
                         ("PASS", "control_plane", "PASS"))
        self.assertEqual(summary["surfaces"], list(ORDER))
        self.assertEqual(self.deployed(), [])
        self.assertEqual(self.mutations(), [])
        self.assertEqual(list(self.receipts.iterdir()), [])
        self.assert_contract_kept()

    def test_promotion_commits_every_surface_in_the_d13_order(self) -> None:
        result = self.promote()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1])["status"], "committed")
        self.assertEqual(self.deployed(), list(ORDER))
        self.assertEqual(self.mutations(), [])
        path, records = self.journal()
        events = [record["event"] for record in records]
        self.assertEqual(events[0], "begin")
        self.assertEqual(events[-2:], ["converged", "end"])
        self.assertEqual(records[-1]["data"]["status"], "committed")
        self.assertEqual(records[0]["data"]["release_mode"], "control_plane")
        state = promote.journal_status(path)
        self.assertEqual(state["surfaces"], {surface: "committed" for surface in ORDER})
        self.assertFalse((self.receipts / "EM_ANDAMENTO").exists())
        summary = json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))
        self.assertEqual(summary["status"], "committed")
        plane = load_plane(self.state)
        for surface in ORDER:
            self.assertEqual(_current_image(plane, surface), new_image(surface, self.sha))
        # BT-REL-002: o same-SHA leu cada superfície e todas mostram o release.
        identity = records[-2]["data"]["identity"]
        self.assertEqual(identity["scope"], list(ORDER))
        self.assertEqual(identity["expected"], {
            "git_sha": self.sha, "capabilities_digest": plane["policy_digest"],
            "release_mode": "control_plane"})
        for surface in ("backend", "site", "app", "android"):
            self.assertEqual(identity["surfaces"][surface]["git_sha"], self.sha, surface)
        for surface in ("backend", "app", "android"):
            self.assertEqual(identity["surfaces"][surface]["capabilities_digest"],
                             plane["policy_digest"], surface)
        self.assertEqual(identity["surfaces"]["ops"]["git_sha_hashed"],
                         identity_gate.hashed(self.sha))
        self.assertEqual(identity["surfaces"]["app"]["status"], "release")
        self.assert_contract_kept()

    def test_a_mixed_identity_after_the_deploys_undoes_the_promotion(self) -> None:
        cases = (
            ("site", "stale_identity", "site: mixed SHA"),
            ("ops", "stale_env", "ops: mixed SHA (GIT_SHA da spec é outro)"),
            ("backend", "wrong_digest", "backend: mixed digest"),
            ("app", "flag_on", "app: flag interactive_battle_enabled ligada"),
            ("app", "dev_identity", "app: identidade embarcada com status 'development_build'"),
        )
        for surface, fault, expected in cases:
            with self.subTest(fault=fault):
                self.tearDown()
                self.setUp()
                self.faults(**{surface: fault})
                result = self.promote()
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                self.assertIn("same-SHA falhou", result.stderr)
                self.assertEqual(self.deployed(), list(ORDER))
                _, records = self.journal()
                failed = next(record for record in records if record["event"] == "surface_failed")
                self.assertEqual(failed["data"]["surface"], "*")
                self.assertEqual(failed["data"]["identity"]["status"], "FAIL")
                self.assertTrue(any(problem.startswith(expected)
                                    for problem in failed["data"]["identity"]["problems"]),
                                failed["data"]["identity"]["problems"])
                self.assertNotIn("converged", [record["event"] for record in records])
                self.assertEqual(records[-1]["data"]["status"], "rolled_back")
                self.assert_at_baseline()
                self.assert_contract_kept()

    def test_android_can_follow_in_its_own_transaction(self) -> None:
        self.assertEqual(self.promote("backend,ops,site,app").returncode, 0)
        result = self.promote("android")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        journals = sorted(self.receipts.glob("promocao-*.jsonl"))
        self.assertEqual(len(journals), 2)
        records = promote.parse_journal(journals[-1])
        self.assertEqual(records[-2]["data"]["identity"]["scope"], list(ORDER))
        self.assertEqual(self.deployed(), list(ORDER))

    def test_a_failure_undoes_the_promoted_surfaces_in_reverse(self) -> None:
        self.faults(app="fail_after")
        result = self.promote()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.deployed(), ["backend", "ops", "site", "app"])
        path, records = self.journal()
        restored = [record["data"]["surface"] for record in records
                    if record["event"] == "surface_restored"]
        self.assertEqual(restored, ["app", "site", "ops", "backend"])
        # Falha de superfície não é aborto: a volta é a do fluxo, não a do trap.
        self.assertNotIn("aborted", [record["event"] for record in records])
        self.assertEqual(records[-1]["data"]["status"], "rolled_back")
        self.assertEqual(self.mutations(), [
            "updateSourceImage:manaloom-app", "rollback:evolution_manaloom-app",
            "updateSourceImage:manaloom-web-public", "rollback:evolution_manaloom-web-public",
            "rollback:evolution_manaloom-ops",
            "updateSourceImage:cartinhas", "rollback:evolution_cartinhas",
        ])
        self.assertFalse((self.receipts / "EM_ANDAMENTO").exists())
        self.assert_at_baseline()
        levels = promote.journal_status(path)["restore_levels"]
        self.assertEqual(levels, {"app": "exact", "site": "exact", "ops": "exact",
                                  "backend": "exact"})
        self.assert_contract_kept()

    def test_the_first_surface_failing_before_mutation_changes_nothing(self) -> None:
        self.faults(backend="fail_before")
        result = self.promote()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.deployed(), ["backend"])
        self.assertEqual(self.mutations(), [])
        _, records = self.journal()
        self.assertEqual(records[-1]["data"]["status"], "rolled_back")
        failed = next(record for record in records if record["event"] == "surface_failed")
        self.assertEqual(failed["data"]["deploy_exit"], 2)
        self.assertIn("BLOCKED", failed["data"]["log_tail"])
        self.assert_at_baseline()
        self.assert_contract_kept()

    def test_a_two_update_surface_comes_back_by_identity(self) -> None:
        # O Android troca a política de update e depois a imagem: a spec anterior não é
        # a de antes, e só o redeploy da imagem de antes pelo EasyPanel devolve a
        # identidade (imagem, env, réplicas e recursos).
        self.faults(android="tweak_changes_config,fail_after")
        result = self.promote()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        path, _ = self.journal()
        state = promote.journal_status(path)
        self.assertEqual(state["status"], "rolled_back")
        self.assertEqual(state["restore_levels"], {"android": "identity", "app": "exact",
                                                   "site": "exact", "ops": "exact",
                                                   "backend": "exact"})
        self.assertEqual(self.mutations()[:2], ["updateSourceImage:manaloom-releases",
                                                "deployService:manaloom-releases"])
        self.assert_at_baseline()
        self.assert_contract_kept()

    def test_a_lying_or_foreign_deploy_is_not_committed(self) -> None:
        for surface, fault in (("site", "lie"), ("site", "wrong_sha"), ("app", "product_open")):
            with self.subTest(fault=fault):
                self.tearDown()
                self.setUp()
                self.faults(**{surface: fault})
                result = self.promote()
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                _, records = self.journal()
                failed = next(record for record in records if record["event"] == "surface_failed")
                self.assertEqual(failed["data"]["surface"], surface)
                self.assertEqual(records[-1]["data"]["status"], "rolled_back")
                self.assert_at_baseline()
                self.assert_contract_kept()

    def test_a_script_that_rolled_itself_back_is_still_proven(self) -> None:
        self.faults(ops="fail_self_rollback")
        result = self.promote()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        path, records = self.journal()
        restored = {record["data"]["surface"]: record["data"] for record in records
                    if record["event"] == "surface_restored"}
        self.assertEqual(restored["ops"]["swarm"], "already")
        self.assertEqual(restored["backend"]["swarm"], "swarm_rollback")
        self.assertEqual(records[-1]["data"]["status"], "rolled_back")
        self.assert_at_baseline()
        self.assert_contract_kept()

    def test_an_inexact_rollback_is_critical_and_blocks_the_next_promotion(self) -> None:
        self.faults(backend="concurrent_change", site="fail_after")
        result = self.promote()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("CRITICAL", result.stderr)
        path, records = self.journal()
        self.assertEqual(records[-1]["data"]["status"], "rollback_failed")
        failed = [record["data"]["surface"] for record in records
                  if record["event"] == "surface_restore_failed"]
        self.assertEqual(failed, ["backend"])
        # O backend, que mudou por fora, não é tocado: nem Swarm nem EasyPanel.
        self.assertEqual(self.mutations(), [
            "updateSourceImage:manaloom-web-public", "rollback:evolution_manaloom-web-public",
            "rollback:evolution_manaloom-ops"])
        self.assertTrue((self.receipts / "EM_ANDAMENTO").exists())
        status = self.run_tool("--status", "--receipt-dir", str(self.receipts))
        self.assertEqual(status.returncode, 1, status.stdout + status.stderr)
        blocked = self.promote()
        self.assertEqual(blocked.returncode, 4, blocked.stdout + blocked.stderr)
        self.assertEqual(len(self.deployed()), 3)
        # A coordenação conserta à mão e resolve com o motivo: o marcador sai.
        plane = load_plane(self.state)
        original = initial_plane()
        plane["swarm"][swarm_name("backend")] = original["swarm"][swarm_name("backend")]
        plane["tasks"][swarm_name("backend")] = original["tasks"][swarm_name("backend")]
        easypanel_entry(plane, "backend")["source"]["image"] = (
            _view(original, "backend")["spec"]["image"])
        save_plane(self.state, plane)
        resolved = self.run_tool("--execute", "--resolve", str(path), "--receipt-dir",
                                 str(self.receipts), "--reason", "backend voltado à mão")
        self.assertEqual(resolved.returncode, 0, resolved.stdout + resolved.stderr)
        self.assertEqual(json.loads(resolved.stdout)["surfaces"],
                         {surface: "baseline" for surface in ("backend", "ops", "site", "app",
                                                              "android")})
        self.assertFalse((self.receipts / "EM_ANDAMENTO").exists())
        self.assertEqual(promote.journal_status(path)["status"], "resolved")
        self.assert_contract_kept()

    def test_every_open_mark_blocks_a_new_promotion(self) -> None:
        # O marcador sozinho (o diário nem chegou a começar) já bloqueia.
        (self.receipts / "EM_ANDAMENTO").write_text("promocao-perdida.jsonl\n", encoding="utf-8")
        result = self.promote()
        self.assertEqual(result.returncode, 4, result.stdout + result.stderr)
        (self.receipts / "EM_ANDAMENTO").unlink()
        # Um diário com rollback não provado bloqueia mesmo sem o marcador.
        journal = self.receipts / "promocao-antigo-20260927T000000Z.jsonl"
        promote.journal_append(journal, "begin", {"sha": self.sha, "surfaces": ["backend"]})
        promote.journal_append(journal, "end", {"status": "rollback_failed"})
        result = self.promote()
        self.assertEqual(result.returncode, 4, result.stdout + result.stderr)
        self.assertIn("rollback não provado", result.stderr)
        self.assertEqual(self.deployed(), [])

    def test_surfaces_that_change_after_promotion_undo_the_release(self) -> None:
        self.faults(app="revert_backend")
        result = self.promote()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.deployed(), list(ORDER))
        _, records = self.journal()
        self.assertNotIn("converged", [record["event"] for record in records])
        self.assertEqual(records[-1]["data"]["status"], "rolled_back")
        self.assert_at_baseline()
        self.assert_contract_kept()

    def test_resolve_refuses_an_inconsistent_production(self) -> None:
        self.faults(backend="concurrent_change", site="fail_after")
        self.assertEqual(self.promote().returncode, 1)
        path, _ = self.journal()
        # O backend não está nem na linha de base nem no promovido.
        plane = load_plane(self.state)
        swarm_update(plane, swarm_name("backend"), lambda spec: spec["TaskTemplate"][
            "ContainerSpec"].update(Image=new_image("backend", "3" * 40)))
        save_plane(self.state, plane)
        refused = self.run_tool("--execute", "--resolve", str(path), "--receipt-dir",
                                str(self.receipts), "--reason", "sem conferir")
        self.assertEqual(refused.returncode, 3, refused.stdout + refused.stderr)
        self.assertTrue((self.receipts / "EM_ANDAMENTO").exists())
        self.assertEqual(promote.journal_status(path)["status"], "rollback_failed")

    def test_sigterm_in_the_middle_is_undone_by_the_trap(self) -> None:
        self.faults(site="sigterm")
        result = self.promote()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        events = self.events()
        self.assertIn("aborted", events)
        _, records = self.journal()
        self.assertEqual(records[-1]["data"]["status"], "rolled_back")
        self.assertFalse((self.receipts / "EM_ANDAMENTO").exists())
        self.assert_at_baseline()
        self.assert_contract_kept()

    def test_a_killed_promotion_is_never_invisible(self) -> None:
        self.faults(app="sigkill")
        result = self.promote()
        self.assertEqual(result.returncode, -signal.SIGKILL, result.stdout + result.stderr)
        path, records = self.journal()
        self.assertNotIn("end", [record["event"] for record in records])
        self.assertTrue((self.receipts / "EM_ANDAMENTO").exists())
        status = self.run_tool("--status", "--receipt-dir", str(self.receipts))
        self.assertEqual(status.returncode, 4, status.stdout + status.stderr)
        self.assertEqual(json.loads(status.stdout.splitlines()[0])["status"], "incomplete")
        blocked = self.promote()
        self.assertEqual(blocked.returncode, 4)
        self.assertIn("em andamento ou interrompida", blocked.stderr)
        # O /app ficou no meio (mudou e não foi promovido): o resolve recusa até a
        # coordenação voltá-lo à mão; depois registra cada superfície no seu estado.
        refused = self.run_tool("--execute", "--resolve", str(path), "--receipt-dir",
                                str(self.receipts), "--reason", "sem conferir")
        self.assertEqual(refused.returncode, 3, refused.stdout + refused.stderr)
        plane = load_plane(self.state)
        original = initial_plane()
        plane["swarm"][swarm_name("app")] = original["swarm"][swarm_name("app")]
        plane["tasks"][swarm_name("app")] = original["tasks"][swarm_name("app")]
        easypanel_entry(plane, "app")["source"]["image"] = _view(original, "app")["spec"]["image"]
        save_plane(self.state, plane)
        resolved = self.run_tool("--execute", "--resolve", str(path), "--receipt-dir",
                                 str(self.receipts), "--reason", "conferido após o SIGKILL")
        self.assertEqual(resolved.returncode, 0, resolved.stdout + resolved.stderr)
        surfaces = json.loads(resolved.stdout)["surfaces"]
        self.assertEqual(surfaces, {"backend": "committed", "ops": "committed",
                                    "site": "committed", "app": "baseline",
                                    "android": "baseline"})
        self.assertFalse((self.receipts / "EM_ANDAMENTO").exists())

    def test_a_blocked_preflight_writes_the_journal_and_changes_nothing(self) -> None:
        plane = load_plane(self.state)
        name = swarm_name("app")
        tag = "localhost:5000/manaloom/app-web:latest"
        plane["swarm"][name]["Spec"]["TaskTemplate"]["ContainerSpec"]["Image"] = tag
        plane["tasks"][name] = [{"image": tag, "state": "Running 1 day ago"}]
        save_plane(self.state, plane)
        result = self.promote()
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertEqual(self.deployed(), [])
        self.assertEqual(self.mutations(), [])
        _, records = self.journal()
        self.assertEqual([record["event"] for record in records], ["begin", "end"])
        self.assertEqual(records[-1]["data"]["status"], "blocked")
        self.assertTrue(any("não é um digest" in reason
                            for reason in records[-1]["data"]["reasons"]))
        self.assertFalse((self.receipts / "EM_ANDAMENTO").exists())

    def test_an_old_capacity_snapshot_blocks(self) -> None:
        snapshot = json.loads(self.snapshot.read_text(encoding="utf-8"))
        snapshot["measured_at"] = "2026-09-01T00:00:00Z"
        self.snapshot.write_text(json.dumps(snapshot), encoding="utf-8")
        result = self.promote()
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertEqual(self.deployed(), [])

    def test_a_subset_follows_the_order_and_cannot_leave_the_stack_mixed(self) -> None:
        # O subconjunto sobe na ordem, mas o núcleo do same-SHA (ops e site ficaram no SHA
        # antigo) não mostra o release: a transação desfaz o que promoveu (BT-REL-002).
        result = self.promote("app,backend")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(self.deployed(), ["backend", "app"])
        _, records = self.journal()
        failed = next(record for record in records if record["event"] == "surface_failed")
        problems = failed["data"]["identity"]["problems"]
        self.assertTrue(any(problem.startswith("ops: mixed SHA") for problem in problems))
        self.assertTrue(any(problem.startswith("site: ") for problem in problems))
        self.assertEqual(records[-1]["data"]["status"], "rolled_back")
        self.assert_at_baseline()

    def test_refusals_before_anything_happens(self) -> None:
        env = dict(self.env)
        del env["MANALOOM_CONFIRM_LIVE_MUTATIONS"]
        self.assertEqual(self.run_tool("--execute", "--promote", "--sha", self.sha,
                                       "--receipt-dir", str(self.receipts),
                                       "--capacity-snapshot", str(self.snapshot),
                                       env=env).returncode, 2)
        temporary = self.tmp / "receipts"
        temporary.mkdir()
        self.assertEqual(self.run_tool("--execute", "--promote", "--sha", self.sha,
                                       "--receipt-dir", str(temporary),
                                       "--capacity-snapshot", str(self.snapshot)).returncode, 2)
        self.assertEqual(self.run_tool("--execute", "--promote", "--sha", self.sha,
                                       "--receipt-dir", str(self.receipts)).returncode, 2)
        self.assertEqual(self.run_tool("--execute", "--promote", "--sha", "9" * 40,
                                       "--receipt-dir", str(self.receipts),
                                       "--capacity-snapshot", str(self.snapshot)).returncode, 2)
        for key, value in (("MANALOOM_EXPECTED_EASYPANEL_BASE_URL_SHA256", "f" * 64),
                           ("MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256", "SHA256:" + "B" * 43)):
            with self.subTest(anchor=key):
                self.assertNotEqual(self.promote(**{key: value}).returncode, 0)
        (self.repo / "sujo.txt").write_text("x", encoding="utf-8")
        self.assertEqual(self.promote().returncode, 2)
        (self.repo / "sujo.txt").unlink()
        # Commit local fora do origin/master: os deploys recusariam, a promoção também.
        (self.repo / "novo.txt").write_text("x", encoding="utf-8")
        self._git("add", "novo.txt")
        self._git("commit", "--quiet", "-m", "local")
        local = self._git("rev-parse", "HEAD")
        self.assertEqual(self.run_tool("--execute", "--promote", "--sha", local,
                                       "--receipt-dir", str(self.receipts),
                                       "--capacity-snapshot", str(self.snapshot)).returncode, 2)
        self.assertEqual(self.calls(), [])
        self.assertEqual(list(self.receipts.glob("promocao-*")), [])

    def test_when_a_capability_opens_the_d13_gate_decides(self) -> None:
        # Um loader futuro que aceite abrir capability: a transação segue o resolvedor
        # da D-13 (on sem verificação live bloqueia; on verificada vira product_open).
        library = self.repo / "scripts/lib/manaloom_release_capabilities_contract.sh"
        text = library.read_text(encoding="utf-8")
        text = text.replace('      (.release_capability == "off") and\n'
                            '      (.allowed == false) and\n', "")
        library.write_text(text, encoding="utf-8")
        policy_path = self.repo / "server/config/release_capabilities.json"
        policy = json.loads(policy_path.read_text(encoding="utf-8"))
        policy["capabilities"]["catalog_private"].update(release_capability="on", allowed=True)
        policy_path.write_text(json.dumps(policy, indent=2) + "\n", encoding="utf-8")
        self._git("commit", "--quiet", "-am", "capability on sem verificação")
        self._git("push", "--quiet", "origin", "master")
        sha = self._git("rev-parse", "HEAD")
        blocked = self.run_tool("--execute", "--preflight", "--sha", sha)
        self.assertEqual(blocked.returncode, 2, blocked.stdout + blocked.stderr)
        self.assertIn("capability ON com verificacao live datada ausente", blocked.stderr)
        stamp = "2026-09-28T12:00:00Z"
        policy["live_verified_as_of"] = stamp
        policy["capabilities"]["catalog_private"]["live_verified_as_of"] = stamp
        policy_path.write_text(json.dumps(policy, indent=2) + "\n", encoding="utf-8")
        self._git("commit", "--quiet", "-am", "capability on verificada")
        self._git("push", "--quiet", "origin", "master")
        sha = self._git("rev-parse", "HEAD")
        opened = self.run_tool("--execute", "--preflight", "--sha", sha)
        self.assertEqual(opened.returncode, 0, opened.stdout + opened.stderr)
        self.assertEqual(json.loads(opened.stdout)["release_mode"], "product_open")
        self.assertEqual(self.deployed(), [])

    def test_a_matrix_with_a_capability_on_never_ships_as_control_plane(self) -> None:
        policy_path = self.repo / "server/config/release_capabilities.json"
        policy = json.loads(policy_path.read_text(encoding="utf-8"))
        policy["capabilities"]["ads"]["release_capability"] = "on"
        policy_path.write_text(json.dumps(policy, indent=2) + "\n", encoding="utf-8")
        self._git("commit", "--quiet", "-am", "capability on")
        self._git("push", "--quiet", "origin", "master")
        sha = self._git("rev-parse", "HEAD")
        result = self.run_tool("--execute", "--preflight", "--sha", sha)
        self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
        self.assertIn("BLOCKED: release capabilities", result.stderr)
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
