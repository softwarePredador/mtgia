#!/usr/bin/env python3
"""BT-REL-002 (D-13): identidade de release por superfície e o portão same-SHA.

A lógica do portão (`scripts/manaloom_release_identity_gate.py`), sem conexão: a
identidade esperada sai do SHA e da matriz commitada nele; cada superfície é lida das
fontes que a política de promoção declara; SHA, digest, produto, superfície, modo da
D-13 ou flag divergente, fonte ilegível ou fontes que discordam falham fechado. O
resolvedor em Python (que o BT-OBS-003 usa de dentro do ops) é conferido contra o
resolvedor em shell da biblioteca de capabilities, matriz a matriz.
"""

from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "scripts" / "manaloom_release_identity_gate.py"
CONFIG_PATH = REPO_ROOT / "server" / "config" / "release_promotion.json"
POLICY_PATH = REPO_ROOT / "server" / "config" / "release_capabilities.json"
LIBRARY = REPO_ROOT / "scripts" / "lib" / "manaloom_release_capabilities_contract.sh"
SHA = "2" * 40


def _load():
    spec = importlib.util.spec_from_file_location("bt_rel_002_identity_test", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


gate = _load()


def _config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def _surfaces() -> dict[str, dict[str, Any]]:
    return {surface["id"]: surface for surface in _config()["surfaces"]}


def _policy_bytes() -> bytes:
    return POLICY_PATH.read_bytes()


def _expected() -> dict[str, Any]:
    return gate.expected_identity(SHA, _policy_bytes())


def _readings(sha: str = SHA, digest: str | None = None) -> dict[str, list[dict[str, Any]]]:
    """Leituras coerentes de todas as superfícies, como a promoção as grava."""
    digest = digest or hashlib.sha256(_policy_bytes()).hexdigest()
    flags = {"battle_live_spectator_enabled": False, "interactive_battle_enabled": False}
    return {
        "backend": [
            {"kind": "http_json", "index": 0, "status": 200,
             "body": {"git_sha": sha, "release_capabilities": {"policy_digest_sha256": digest}}},
            {"kind": "http_json", "index": 1, "status": 200,
             "body": {"product": "brewtact", "policy_digest_sha256": digest}},
        ],
        "ops": [{"kind": "spec_env", "index": 0, "env": {"GIT_SHA": gate.hashed(sha)}}],
        "site": [
            {"kind": "http_json", "index": 0, "status": 200,
             "body": {"product": "brewtact", "surface": "site", "git_sha": sha}},
            {"kind": "spec_env", "index": 1, "env": {"GIT_SHA": gate.hashed(sha)}},
        ],
        "app": [
            {"kind": "http_json", "index": index, "status": 200,
             "body": {"status": "release", "product": "brewtact", "surface": "app",
                      "git_sha": sha, "release_mode": "control_plane", "features": flags,
                      "release_capabilities": {"policy_digest_sha256": digest}}}
            for index in (0, 1)
        ],
        "android": [
            {"kind": "http_json", "index": 0, "status": 200,
             "body": {"product": "brewtact", "surface": "android", "git_sha": sha,
                      "release_mode": "control_plane",
                      "release_capabilities": {"policy_digest_sha256": digest}}},
        ],
    }


def _check(readings: dict[str, list[dict[str, Any]]], scope=("backend", "ops", "site", "app"),
           kinds=frozenset({"http_json", "spec_env"})) -> dict[str, Any]:
    surfaces = _surfaces()
    identities = {
        surface: gate.surface_identity(surface, surfaces[surface]["identity"],
                                       readings.get(surface, []), set(kinds))
        for surface in scope
    }
    return gate.gate(_expected(), identities, list(scope))


class ExpectedTest(unittest.TestCase):
    def test_expected_identity_comes_from_the_sha_and_the_committed_matrix(self) -> None:
        expected = _expected()
        self.assertEqual(expected["git_sha"], SHA)
        self.assertEqual(expected["capabilities_digest"],
                         hashlib.sha256(_policy_bytes()).hexdigest())
        self.assertEqual(expected["release_mode"], "control_plane")
        self.assertEqual(expected["allowed"], [])
        for bad in ("2" * 39, "short", "G" * 40):
            with self.assertRaises(gate.InvalidInput):
                gate.expected_identity(bad, _policy_bytes())
        with self.assertRaises(gate.InvalidInput):
            gate.expected_identity(SHA, b"not json")
        other = json.loads(_policy_bytes())
        other["product"] = "manaloom"
        with self.assertRaises(gate.InvalidInput):
            gate.expected_identity(SHA, json.dumps(other).encode())

    def test_python_resolver_matches_the_shell_resolver(self) -> None:
        base = json.loads(_policy_bytes())
        stamp = "2026-09-28T12:00:00Z"

        def opened(verified_top: bool, verified_entry: bool, allowed: bool) -> dict[str, Any]:
            policy = copy.deepcopy(base)
            policy["live_verified_as_of"] = stamp if verified_top else None
            entry = policy["capabilities"]["catalog_private"]
            entry.update(release_capability="on", allowed=allowed,
                         live_verified_as_of=stamp if verified_entry else None)
            return policy

        incoherent = copy.deepcopy(base)
        incoherent["capabilities"]["ads"]["allowed"] = True
        matrices = {
            "all_off": base,
            "verified_open": opened(True, True, True),
            "unverified_top": opened(False, True, True),
            "unverified_entry": opened(True, False, True),
            "on_without_permission": opened(True, True, False),
            "off_but_allowed": incoherent,
            "empty": {**base, "capabilities": {}},
        }
        for name, matrix in matrices.items():
            with self.subTest(matrix=name):
                shell = subprocess.run(
                    ["/bin/bash", "-c",
                     'source "$1"; manaloom_resolve_public_app_release_mode "$2" >/dev/null 2>&1 '
                     '|| exit 3; printf "%s" "$MANALOOM_PUBLIC_APP_RELEASE_MODE"',
                     "_", str(LIBRARY), json.dumps(matrix)],
                    capture_output=True, text=True, check=False)
                shell_mode = shell.stdout if shell.returncode == 0 else None
                self.assertEqual(gate.resolve_release_mode(matrix), shell_mode)


class ConfigTest(unittest.TestCase):
    def test_every_surface_declares_where_its_identity_comes_from(self) -> None:
        surfaces = _surfaces()
        for surface_id, surface in surfaces.items():
            with self.subTest(surface=surface_id):
                self.assertEqual(gate.identity_problems(surface_id, surface["identity"]), [])
        core = {surface_id for surface_id, surface in surfaces.items()
                if surface["identity"]["same_sha"]}
        self.assertEqual(core, {"backend", "ops", "site", "app"})

    def test_refuses_identity_blocks_that_cannot_be_checked(self) -> None:
        backend = _surfaces()["backend"]["identity"]
        cases = {
            "same_sha deve ser booleano": lambda block: block.update(same_sha="sim"),
            "sources vazio": lambda block: block.update(sources=[]),
            "kind desconhecido": lambda block: block["sources"][0].update(kind="ftp"),
            "deve ser HTTPS": lambda block: block["sources"][0].update(
                url="http://evolution-cartinhas.2ta7qx.easypanel.host/health"),
            "fields vazio": lambda block: block["sources"][0].update(fields={}),
            "desconhecido": lambda block: block["sources"][0]["fields"].update(senha="x"),
            "caminho inválido": lambda block: block["sources"][0]["fields"].update(
                git_sha="../git_sha"),
            "spec_env só lê GIT_SHA": lambda block: block["sources"].append(
                {"kind": "spec_env", "key": "JWT_SECRET", "field": "git_sha"}),
            "precisa de uma fonte que não seja self": lambda block: block.update(
                sources=[{"kind": "self"}]),
            "nenhuma fonte dá o SHA": lambda block: block.update(sources=[
                {"kind": "http_json", "url": "https://evolution-cartinhas.2ta7qx.easypanel.host/capabilities",
                 "fields": {"product": "product"}}]),
        }
        for expected, mutate in cases.items():
            with self.subTest(expected=expected):
                block = copy.deepcopy(backend)
                mutate(block)
                problems = gate.identity_problems("backend", block)
                self.assertTrue(any(expected in problem for problem in problems), problems)


class GateTest(unittest.TestCase):
    def test_a_coherent_release_passes(self) -> None:
        result = _check(_readings(), scope=("backend", "ops", "site", "app", "android"))
        self.assertEqual(result["status"], "PASS", result["problems"])
        self.assertEqual(result["expected"]["git_sha"], SHA)
        self.assertEqual(set(result["surfaces"]), {"backend", "ops", "site", "app", "android"})

    def _fails(self, readings: dict[str, Any], expected: str,
               scope=("backend", "ops", "site", "app")) -> None:
        result = _check(readings, scope=scope)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any(expected in problem for problem in result["problems"]),
                        result["problems"])

    def test_mixed_sha_fails_closed(self) -> None:
        readings = _readings()
        readings["site"][0]["body"]["git_sha"] = "3" * 40
        self._fails(readings, "site: mixed SHA")
        readings = _readings()
        readings["ops"][0]["env"]["GIT_SHA"] = gate.hashed("3" * 40)
        self._fails(readings, "ops: mixed SHA (GIT_SHA da spec é outro)")
        readings = _readings()
        readings["backend"][0]["body"]["git_sha"] = SHA[:12]
        self._fails(readings, "backend: git_sha não é o SHA completo")
        readings = _readings()
        readings["android"][0]["body"]["git_sha"] = "3" * 40
        self._fails(readings, "android: mixed SHA", scope=("backend", "android"))

    def test_mixed_digest_mode_product_or_surface_fails_closed(self) -> None:
        readings = _readings()
        readings["backend"][1]["body"]["policy_digest_sha256"] = "e" * 64
        self._fails(readings, "backend: as fontes discordam em capabilities_digest")
        self._fails(_readings(digest="e" * 64), "app: mixed digest")
        readings = _readings()
        for reading in readings["app"]:
            reading["body"]["release_mode"] = "product_open"
        self._fails(readings, "app: modo 'product_open' em vez de 'control_plane'")
        readings = _readings()
        readings["site"][0]["body"]["product"] = "manaloom"
        self._fails(readings, "site: produto 'manaloom'")
        readings = _readings()
        readings["site"][0]["body"]["surface"] = "app"
        self._fails(readings, "site: a identidade diz superfície 'app'")

    def test_the_embedded_identity_must_be_a_release_build(self) -> None:
        readings = _readings()
        readings["app"][1]["body"] = {"schema_version": 1, "status": "development_build",
                                      "release_identity_embedded": False}
        result = _check(readings)
        self.assertEqual(result["status"], "FAIL")
        problems = result["surfaces"]["app"]["problems"]
        self.assertTrue(any("sem git_sha" in problem for problem in problems), problems)
        self.assertTrue(any("status 'development_build'" in problem
                            or "as fontes discordam em status" in problem
                            for problem in problems), problems)

    def test_a_build_flag_needs_its_capability_on_at_the_sha(self) -> None:
        readings = _readings()
        for reading in readings["app"]:
            reading["body"]["features"]["interactive_battle_enabled"] = True
        self._fails(readings, "app: flag interactive_battle_enabled ligada com a capability "
                              "battle_coach desligada no SHA")
        readings = _readings()
        for reading in readings["app"]:
            reading["body"]["features"]["scanner_release_enabled"] = "false"
        self._fails(readings, "app: flag scanner_release_enabled não é booleana")

    def test_unreadable_sources_fail_closed(self) -> None:
        readings = _readings()
        readings["site"][0].update(status=404, body=None)
        self._fails(readings, "site[0]: https://")
        readings = _readings()
        del readings["backend"][1]
        self._fails(readings, "backend[1]: fonte sem leitura")
        readings = _readings()
        readings["ops"][0]["env"] = {}
        self._fails(readings, "ops[0]: a spec não tem GIT_SHA")
        readings = _readings()
        del readings["app"][0]["body"]["release_capabilities"]
        self._fails(readings, "app[0]: sem release_capabilities.policy_digest_sha256")
        result = gate.gate(_expected(), {}, ["backend"])
        self.assertEqual(result["problems"], ["backend: identidade não lida"])
        # Uma identidade sem SHA nenhum (nem da fonte, nem da spec) não passa.
        result = gate.gate(_expected(), {"site": {"surface": "site", "problems": [],
                                                  "fields": {"product": "brewtact"}}}, ["site"])
        self.assertEqual(result["problems"], ["site: sem SHA"])

    def test_the_ops_evaluator_reads_itself_instead_of_the_spec(self) -> None:
        ops = _surfaces()["ops"]["identity"]
        digest = hashlib.sha256(_policy_bytes()).hexdigest()
        own = gate.surface_identity(
            "ops", ops, [{"kind": "self", "index": 1, "git_sha": SHA,
                          "capabilities_digest": digest}], {"http_json", "self"})
        result = gate.gate(_expected(), {"ops": own}, ["ops"])
        self.assertEqual(result["status"], "PASS", result["problems"])
        stale = gate.surface_identity(
            "ops", ops, [{"kind": "self", "index": 1, "git_sha": SHA,
                          "capabilities_digest": "e" * 64}], {"http_json", "self"})
        self.assertEqual(gate.gate(_expected(), {"ops": stale}, ["ops"])["status"], "FAIL")
        blind = gate.surface_identity("ops", ops, [], {"http_json"})
        self.assertIn("ops: nenhuma fonte legível por este leitor", blind["problems"])

    def test_cli_exit_codes(self) -> None:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_text:
            tmp = Path(tmp_text)
            expected = tmp / "expected.json"
            readings = tmp / "readings.json"
            done = subprocess.run(
                [sys.executable, str(MODULE_PATH), "expected", "--sha", SHA,
                 "--policy", str(POLICY_PATH)], capture_output=True, text=True, check=False)
            self.assertEqual(done.returncode, 0, done.stdout)
            expected.write_text(done.stdout, encoding="utf-8")
            readings.write_text(json.dumps(_readings()), encoding="utf-8")
            base = [sys.executable, str(MODULE_PATH), "gate", "--config", str(CONFIG_PATH),
                    "--expected", str(expected), "--readings", str(readings)]
            self.assertEqual(subprocess.run(base + ["--scope", "backend,ops,site,app"],
                                            capture_output=True, check=False).returncode, 0)
            mixed = _readings()
            mixed["backend"][0]["body"]["git_sha"] = "3" * 40
            readings.write_text(json.dumps(mixed), encoding="utf-8")
            self.assertEqual(subprocess.run(base + ["--scope", "backend"],
                                            capture_output=True, check=False).returncode, 1)
            self.assertEqual(subprocess.run(base + ["--scope", "nada"],
                                            capture_output=True, check=False).returncode, 2)


if __name__ == "__main__":
    unittest.main()
