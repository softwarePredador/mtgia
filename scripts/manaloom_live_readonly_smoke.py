#!/usr/bin/env python3
"""Smoke live somente leitura (BT-QA-001, BT-COH-001): só GET, sem credencial.

Lê do próprio SHA, pelo Git, a política de promoção
(`server/config/release_promotion.json`) e a matriz de capabilities
(`server/config/release_capabilities.json`). Depois:
- faz GET em cada fonte `http_json` da identidade das superfícies pedidas e no
  `/ready` do backend;
- grava cada corpo, com status e sha256, no diretório de evidência;
- roda o portão same-SHA do BT-REL-002 (`manaloom_release_identity_gate.py`)
  só com as fontes HTTP (as da spec do Swarm pedem SSH e ficam de fora);
- confere a prontidão (`/ready` 200 com `status` `ready`) e a lista de
  capabilities permitidas no `/capabilities` contra a matriz do SHA, ou contra
  `--expect-allowed` quando dada.

Nunca manda POST, cookie, token ou cabeçalho de autorização, e só aceita URL
`https://` (ou loopback, para o teste). Não grava nada fora de `--out`.

Uso:
  scripts/manaloom_live_readonly_smoke.py --sha SHA --out DIR
      [--surfaces backend,site,app,android] [--expect-allowed a,b,...]
      [--repo DIR] [--config-file F --policy-file F] [--timeout S]

Saída: 0 PASS; 1 FAIL (identidade, prontidão ou matriz); 2 entrada inválida.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

SCHEMA = "manaloom.live_readonly_smoke.v1"
CONFIG_PATH = "server/config/release_promotion.json"
POLICY_PATH = "server/config/release_capabilities.json"
DEFAULT_SURFACES = "backend,site,app,android"
FULL_SHA = re.compile(r"^[0-9a-f]{40}$")
LOOPBACK_HOSTS = {"127.0.0.1", "localhost", "::1"}
SCRIPTS_DIR = Path(__file__).resolve().parent


class InvalidInput(Exception):
    pass


def _load_gate() -> Any:
    path = SCRIPTS_DIR / "manaloom_release_identity_gate.py"
    spec = importlib.util.spec_from_file_location("manaloom_release_identity_gate", path)
    if spec is None or spec.loader is None:  # pragma: no cover - checkout quebrado
        raise RuntimeError(f"não carreguei {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _git_show(repo: Path, sha: str, path: str) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(repo), "show", f"{sha}:{path}"], capture_output=True,
    )
    if result.returncode != 0:
        raise InvalidInput(f"{path} não existe no SHA {sha[:12]}")
    return result.stdout


def _resolve_sha(repo: Path, sha: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--verify", "--quiet", f"{sha}^{{commit}}"],
        capture_output=True, text=True,
    )
    resolved = result.stdout.strip()
    if result.returncode != 0 or not FULL_SHA.match(resolved):
        raise InvalidInput(f"SHA desconhecido: {sha}")
    return resolved


def _check_url(url: Any) -> str:
    if not isinstance(url, str):
        raise InvalidInput("URL ausente na política de promoção")
    parsed = urllib.parse.urlsplit(url)
    loopback = parsed.scheme == "http" and parsed.hostname in LOOPBACK_HOSTS
    if (parsed.scheme != "https" and not loopback) or not parsed.hostname \
            or parsed.username or parsed.password:
        raise InvalidInput(f"URL fora do contrato (só https ou loopback): {url}")
    return url


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args: Any, **kwargs: Any) -> None:
        return None


def fetch(url: str, timeout: float) -> tuple[int | None, bytes, str | None]:
    """Um GET sem credencial e sem seguir redirecionamento."""
    request = urllib.request.Request(
        url, method="GET",
        headers={"Accept": "application/json",
                 "User-Agent": "manaloom-live-readonly-smoke/1"},
    )
    handlers: list[Any] = [_NoRedirect()]
    if urllib.parse.urlsplit(url).hostname in LOOPBACK_HOSTS:
        handlers.append(urllib.request.ProxyHandler({}))
    opener = urllib.request.build_opener(*handlers)
    try:
        with opener.open(request, timeout=timeout) as response:
            return response.status, response.read(), None
    except urllib.error.HTTPError as error:
        return error.code, error.read() or b"", None
    except (urllib.error.URLError, OSError, ValueError) as error:
        return None, b"", type(error).__name__


def _json(body: bytes) -> Any:
    try:
        return json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None


def run(args: argparse.Namespace) -> tuple[int, dict[str, Any]]:
    gate_module = _load_gate()
    repo = args.repo.resolve()
    if args.config_file and args.policy_file:
        if not FULL_SHA.match(args.sha):
            raise InvalidInput("com --config-file e --policy-file, --sha é o SHA completo")
        sha = args.sha
        config_bytes = args.config_file.read_bytes()
        policy_bytes = args.policy_file.read_bytes()
        sources = {"config": str(args.config_file), "policy": str(args.policy_file)}
    elif args.config_file or args.policy_file:
        raise InvalidInput("--config-file e --policy-file andam juntos")
    else:
        sha = _resolve_sha(repo, args.sha)
        config_bytes = _git_show(repo, sha, CONFIG_PATH)
        policy_bytes = _git_show(repo, sha, POLICY_PATH)
        sources = {"config": f"git:{sha}:{CONFIG_PATH}",
                   "policy": f"git:{sha}:{POLICY_PATH}"}
    config = _json(config_bytes)
    if not isinstance(config, dict) or not isinstance(config.get("surfaces"), list):
        raise InvalidInput("política de promoção ilegível")
    surfaces = {item["id"]: item for item in config["surfaces"]
                if isinstance(item, dict) and isinstance(item.get("id"), str)}
    scope = [item for item in args.surfaces.split(",") if item]
    unknown = [item for item in scope if item not in surfaces]
    if not scope or unknown:
        raise InvalidInput(f"superfície desconhecida: {', '.join(unknown) or 'nenhuma'}")
    try:
        expected = gate_module.expected_identity(sha, policy_bytes)
    except gate_module.InvalidInput as error:
        raise InvalidInput(str(error)) from error

    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    fetched: list[dict[str, Any]] = []

    def get(url: str, name: str) -> tuple[int | None, Any]:
        status, body, error = fetch(_check_url(url), args.timeout)
        (out / name).write_bytes(body)
        fetched.append({
            "url": url, "file": name, "status": status, "error": error,
            "bytes": len(body), "sha256": hashlib.sha256(body).hexdigest(),
        })
        return status, _json(body)

    readings: dict[str, list[dict[str, Any]]] = {}
    backend_base: str | None = None
    for surface_id in scope:
        identity = surfaces[surface_id].get("identity") or {}
        for index, source in enumerate(identity.get("sources") or []):
            if not isinstance(source, dict) or source.get("kind") != "http_json":
                continue
            status, body = get(source.get("url"), f"{surface_id}-{index}.json")
            readings.setdefault(surface_id, []).append({
                "kind": "http_json", "index": index, "status": status, "body": body,
            })
            if surface_id == "backend" and backend_base is None:
                parts = urllib.parse.urlsplit(source["url"])
                backend_base = f"{parts.scheme}://{parts.netloc}"
    identities = {
        surface_id: gate_module.surface_identity(
            surface_id, surfaces[surface_id]["identity"], readings.get(surface_id, []),
            {"http_json"})
        for surface_id in scope
    }
    identity_result = gate_module.gate(expected, identities, scope)

    problems = list(identity_result["problems"])
    ready: dict[str, Any] = {"checked": False}
    allowed: dict[str, Any] = {"checked": False}
    if backend_base is not None:
        status, body = get(f"{backend_base}/ready", "backend-ready.json")
        checks = body.get("checks") if isinstance(body, dict) else None
        ready = {
            "checked": True, "status_code": status,
            "status": body.get("status") if isinstance(body, dict) else None,
            "latest_migration": (
                checks.get("release_schema", {}).get("latest_migration")
                if isinstance(checks, dict) else None),
            "unhealthy_checks": sorted(
                key for key, value in (checks or {}).items()
                if isinstance(value, dict)
                and value.get("status") not in ("healthy", "disabled")),
        }
        if status != 200 or ready["status"] != "ready":
            problems.append(f"backend: /ready respondeu {status} {ready['status']!r}")
        status, body = get(f"{backend_base}/capabilities", "backend-capabilities.json")
        live = body.get("capabilities") if isinstance(body, dict) else None
        live_allowed = sorted(
            key for key, value in (live or {}).items()
            if isinstance(value, dict) and value.get("allowed") is True)
        wanted = (sorted(item for item in args.expect_allowed.split(",") if item)
                  if args.expect_allowed is not None else expected["allowed"])
        allowed = {
            "checked": True, "status_code": status,
            "policy_version": body.get("policy_version") if isinstance(body, dict) else None,
            "live": live_allowed, "expected": wanted,
        }
        if status != 200 or live is None:
            problems.append(f"backend: /capabilities respondeu {status}")
        elif live_allowed != wanted:
            problems.append(
                f"backend: capabilities permitidas {live_allowed} em vez de {wanted}")

    summary = {
        "schema": SCHEMA,
        "status": "PASS" if not problems else "FAIL",
        "sha": sha,
        "sources": sources,
        "scope": scope,
        "kinds": ["http_json"],
        "expected": identity_result["expected"],
        "identity": identity_result,
        "ready": ready,
        "capabilities": allowed,
        "fetched": fetched,
        "problems": problems,
    }
    (out / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    return (0 if not problems else 1), summary


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--sha", required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--surfaces", default=DEFAULT_SURFACES)
    parser.add_argument("--expect-allowed")
    parser.add_argument("--repo", type=Path, default=SCRIPTS_DIR.parent)
    parser.add_argument("--config-file", type=Path)
    parser.add_argument("--policy-file", type=Path)
    parser.add_argument("--timeout", type=float, default=20.0)
    args = parser.parse_args(argv)
    try:
        code, summary = run(args)
    except (InvalidInput, OSError) as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2
    print(json.dumps({key: summary[key] for key in
                      ("status", "sha", "scope", "problems")}, ensure_ascii=False))
    return code


if __name__ == "__main__":
    sys.exit(main())
