#!/usr/bin/env python3
"""BT-REL-002 (D-13): identidade de release por superfície e o portão same-SHA.

Lógica sem conexão. Quem lê as fontes passa os corpos para cá:
- a promoção do BT-REL-001 (`scripts/manaloom_promote_release.sh`), pelas URLs públicas
  e pela spec do Swarm;
- o avaliador do BT-OBS-003 (`server/bin/manaloom_slo_alerts.py`), de dentro do ops.

Cada superfície declara em `server/config/release_promotion.json` de onde vem a
identidade (`identity.sources`) e se entra no same-SHA (`identity.same_sha`). A
identidade normalizada tem produto, superfície, SHA completo, digest da matriz de
capabilities, modo do /app (D-13) e flags de build. O portão compara com a identidade
esperada, a do SHA do release e da matriz commitada nele, e falha fechado:
- SHA diferente numa superfície do escopo: mixed SHA;
- digest, modo ou produto diferente do esperado, flag de build ligada com a capability
  desligada no SHA, ou duas fontes da mesma superfície que discordam: mixed digest;
- fonte ilegível, sem o campo pedido ou com SHA que não é o completo: sem identidade.

Subcomandos:
  expected --sha SHA --policy ARQUIVO                 identidade esperada (JSON)
  gate --config C --expected E --readings R --scope a,b   PASS (0) ou FAIL (1)

`readings` é um JSON {superfície: [leitura por fonte]}; cada leitura é
{"kind": "http_json", "index": i, "status": 200, "body": {...}} ou
{"kind": "spec_env", "index": i, "env": {"GIT_SHA": "sha256:<hex>"}} ou
{"kind": "self", "index": i, "git_sha": ..., "capabilities_digest": ...}.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

PRODUCT = "brewtact"
GIT_SHA = re.compile(r"^[0-9a-f]{40}$")
SHA256_HEX = re.compile(r"^[0-9a-f]{64}$")
HASHED = re.compile(r"^sha256:[0-9a-f]{64}$")
SOURCE_KINDS = {"http_json", "spec_env", "self"}
IDENTITY_FIELDS = {
    "git_sha", "product", "surface", "capabilities_digest", "release_mode", "flags", "status",
}
RELEASE_MODES = {"control_plane", "product_open"}
# Suporte técnico compilado no artefato (nunca autorização): só pode estar ligado com a
# capability dele liberada na matriz do SHA; os deploys já recusam flag ligada com a
# matriz toda off.
FLAG_CAPABILITIES = {
    "scanner_release_enabled": "scanner",
    "battle_live_spectator_enabled": "battle_live",
    "interactive_battle_enabled": "battle_coach",
}
TIMESTAMP = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$")


class InvalidInput(ValueError):
    """Entrada fora do contrato: código 2."""


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def hashed(value: str) -> str:
    """O formato do redator do BT-CAP-002 para um valor de env."""
    return "sha256:" + _sha256(value.encode("utf-8"))


# ------------------------------------------------------------ configuração


def identity_problems(surface_id: str, identity: Any) -> list[str]:
    """Valida o bloco `identity` de uma superfície da política de promoção."""
    label = f"surfaces.{surface_id}.identity"
    if not isinstance(identity, dict):
        return [f"{label} ausente"]
    problems: list[str] = []
    if not isinstance(identity.get("same_sha"), bool):
        problems.append(f"{label}.same_sha deve ser booleano")
    sources = identity.get("sources")
    if not isinstance(sources, list) or not sources:
        return problems + [f"{label}.sources vazio"]
    for index, source in enumerate(sources):
        where = f"{label}.sources[{index}]"
        if not isinstance(source, dict) or source.get("kind") not in SOURCE_KINDS:
            problems.append(f"{where}.kind desconhecido")
            continue
        kind = source["kind"]
        if kind == "http_json":
            url = source.get("url")
            if not (isinstance(url, str) and url.startswith("https://")):
                problems.append(f"{where}.url deve ser HTTPS")
            fields = source.get("fields")
            if not isinstance(fields, dict) or not fields:
                problems.append(f"{where}.fields vazio")
            else:
                for name, path in fields.items():
                    if name not in IDENTITY_FIELDS:
                        problems.append(f"{where}.fields.{name} desconhecido")
                    if not (isinstance(path, str)
                            and re.fullmatch(r"[a-z_][a-z_0-9]*(\.[a-z_][a-z_0-9]*)*", path)):
                        problems.append(f"{where}.fields.{name} com caminho inválido")
        elif kind == "spec_env":
            if source.get("key") != "GIT_SHA" or source.get("field") != "git_sha":
                problems.append(f"{where}: spec_env só lê GIT_SHA como git_sha")
    if not any(isinstance(item, dict) and item.get("kind") != "self" for item in sources):
        problems.append(f"{label}: a promoção precisa de uma fonte que não seja self")
    if not any(isinstance(item, dict) and (
            item.get("kind") == "spec_env"
            or (item.get("kind") == "http_json" and isinstance(item.get("fields"), dict)
                and "git_sha" in item["fields"])) for item in sources):
        problems.append(f"{label}: nenhuma fonte dá o SHA da superfície")
    return problems


# ------------------------------------------------------------ esperado


def resolve_release_mode(policy: dict[str, Any]) -> str | None:
    """O resolvedor da D-13 (scripts/lib/manaloom_release_capabilities_contract.sh).

    control_plane com todas as capabilities off e sem permissão; product_open com
    verificação live datada e ao menos uma capability on, permitida e verificada;
    None (BLOCKED) em qualquer outra matriz.
    """
    capabilities = policy.get("capabilities")
    if not isinstance(capabilities, dict) or not capabilities:
        return None
    entries = list(capabilities.values())
    if not all(isinstance(entry, dict) for entry in entries):
        return None
    if all(entry.get("release_capability") == "off" and entry.get("allowed") is False
           for entry in entries):
        return "control_plane"

    def verified(value: Any) -> bool:
        return isinstance(value, str) and bool(TIMESTAMP.match(value))

    if verified(policy.get("live_verified_as_of")) and any(
            entry.get("release_capability") == "on" and entry.get("allowed") is True
            and verified(entry.get("live_verified_as_of")) for entry in entries):
        return "product_open"
    return None


def expected_identity(sha: str, policy_bytes: bytes) -> dict[str, Any]:
    """O SHA do release e a matriz commitada nele: digest, modo e permitidas."""
    if not GIT_SHA.match(sha):
        raise InvalidInput("o SHA esperado deve ser o completo (40 hex)")
    try:
        policy = json.loads(policy_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise InvalidInput(f"matriz de capabilities ilegível: {error}") from error
    if not isinstance(policy, dict) or policy.get("product") != PRODUCT:
        raise InvalidInput("matriz de capabilities de outro produto")
    capabilities = policy.get("capabilities") if isinstance(policy.get("capabilities"), dict) else {}
    return {
        "product": PRODUCT,
        "git_sha": sha,
        "capabilities_digest": _sha256(policy_bytes),
        "release_mode": resolve_release_mode(policy),
        "allowed": sorted(key for key, entry in capabilities.items()
                          if isinstance(entry, dict) and entry.get("allowed") is True),
    }


# ------------------------------------------------------------ leitura


def field(data: Any, path: str) -> Any:
    """Valor do caminho pontilhado; ausente vira None."""
    current = data
    for part in path.split("."):
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def surface_identity(
    surface_id: str, identity_config: dict[str, Any], readings: list[dict[str, Any]],
    kinds: set[str],
) -> dict[str, Any]:
    """Identidade normalizada de uma superfície, a partir das leituras das fontes.

    Só as fontes dos tipos em [kinds] contam (a promoção não lê `self`; o avaliador,
    de dentro do ops, não lê `spec_env`). Fonte pedida sem leitura, ilegível ou sem o
    campo é problema; duas fontes que discordam no mesmo campo também.
    """
    values: dict[str, list[Any]] = {}
    problems: list[str] = []
    by_index = {reading.get("index"): reading for reading in readings
                if isinstance(reading, dict)}
    counted = 0
    for index, source in enumerate(identity_config["sources"]):
        if source["kind"] not in kinds:
            continue
        counted += 1
        reading = by_index.get(index)
        where = f"{surface_id}[{index}]"
        if reading is None or reading.get("kind") != source["kind"]:
            problems.append(f"{where}: fonte sem leitura")
            continue
        if source["kind"] == "http_json":
            body = reading.get("body")
            if reading.get("status") != 200 or not isinstance(body, dict):
                problems.append(f"{where}: {source['url']} respondeu {reading.get('status')}")
                continue
            for name, path in source["fields"].items():
                value = field(body, path)
                if value is None:
                    problems.append(f"{where}: sem {path}")
                    continue
                values.setdefault(name, []).append(value)
        elif source["kind"] == "spec_env":
            value = (reading.get("env") or {}).get(source["key"])
            if not isinstance(value, str) or not HASHED.match(value):
                problems.append(f"{where}: a spec não tem {source['key']}")
                continue
            values.setdefault("git_sha_hashed", []).append(value)
        else:
            for name in ("git_sha", "capabilities_digest"):
                value = reading.get(name)
                if value is None:
                    problems.append(f"{where}: sem {name} próprio")
                    continue
                values.setdefault(name, []).append(value)
    if counted == 0:
        problems.append(f"{surface_id}: nenhuma fonte legível por este leitor")
    merged: dict[str, Any] = {}
    for name, found in values.items():
        distinct = {json.dumps(item, sort_keys=True) for item in found}
        if len(distinct) > 1:
            problems.append(f"{surface_id}: as fontes discordam em {name}")
        merged[name] = found[0]
    return {"surface": surface_id, "fields": merged, "problems": problems}


# ------------------------------------------------------------ portão


def gate(
    expected: dict[str, Any], identities: dict[str, dict[str, Any]], scope: list[str],
) -> dict[str, Any]:
    """Compara cada superfície do escopo com a identidade esperada. Falha fechado."""
    results: dict[str, Any] = {}
    failures: list[str] = []
    allowed = set(expected.get("allowed") or [])
    for surface_id in scope:
        identity = identities.get(surface_id)
        if identity is None:
            problems = [f"{surface_id}: identidade não lida"]
            results[surface_id] = {"status": "FAIL", "problems": problems}
            failures += problems
            continue
        found = identity["fields"]
        problems = list(identity["problems"])
        sha = found.get("git_sha")
        if sha is not None and (not isinstance(sha, str) or not GIT_SHA.match(sha)):
            problems.append(f"{surface_id}: git_sha não é o SHA completo")
        elif sha is not None and sha != expected["git_sha"]:
            problems.append(f"{surface_id}: mixed SHA ({str(sha)[:12]} em vez de "
                            f"{expected['git_sha'][:12]})")
        hashed_sha = found.get("git_sha_hashed")
        if hashed_sha is not None and hashed_sha != hashed(expected["git_sha"]):
            problems.append(f"{surface_id}: mixed SHA (GIT_SHA da spec é outro)")
        if sha is None and hashed_sha is None:
            problems.append(f"{surface_id}: sem SHA")
        if "product" in found and found["product"] != PRODUCT:
            problems.append(f"{surface_id}: produto {found['product']!r}")
        if "surface" in found and found["surface"] != surface_id:
            problems.append(f"{surface_id}: a identidade diz superfície {found['surface']!r}")
        if "status" in found and found["status"] != "release":
            problems.append(f"{surface_id}: identidade embarcada com status "
                            f"{found['status']!r}, não release")
        digest = found.get("capabilities_digest")
        if digest is not None and (not isinstance(digest, str) or not SHA256_HEX.match(digest)):
            problems.append(f"{surface_id}: digest da matriz inválido")
        elif digest is not None and digest != expected["capabilities_digest"]:
            problems.append(f"{surface_id}: mixed digest ({str(digest)[:12]} em vez de "
                            f"{expected['capabilities_digest'][:12]})")
        if "release_mode" in found and found["release_mode"] != expected["release_mode"]:
            problems.append(f"{surface_id}: modo {found['release_mode']!r} em vez de "
                            f"{expected['release_mode']!r}")
        flags = found.get("flags")
        if flags is not None:
            if not isinstance(flags, dict):
                problems.append(f"{surface_id}: flags ilegíveis")
            else:
                for flag, value in sorted(flags.items()):
                    if not isinstance(value, bool):
                        problems.append(f"{surface_id}: flag {flag} não é booleana")
                    elif value and FLAG_CAPABILITIES.get(flag) not in allowed:
                        problems.append(f"{surface_id}: flag {flag} ligada com a capability "
                                        f"{FLAG_CAPABILITIES.get(flag, 'desconhecida')} "
                                        "desligada no SHA")
        results[surface_id] = {"status": "PASS" if not problems else "FAIL",
                               "fields": dict(found), "problems": problems}
        failures += problems
    return {"status": "PASS" if not failures else "FAIL",
            "expected": {key: expected[key] for key in
                         ("git_sha", "capabilities_digest", "release_mode")},
            "surfaces": results, "problems": failures}


# ------------------------------------------------------------ CLI


def _read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise InvalidInput(f"não li {path}: {error}") from error


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    commands = parser.add_subparsers(dest="command", required=True)
    wanted = commands.add_parser("expected")
    wanted.add_argument("--sha", required=True)
    wanted.add_argument("--policy", type=Path, required=True)
    checked = commands.add_parser("gate")
    checked.add_argument("--config", type=Path, required=True)
    checked.add_argument("--expected", type=Path, required=True)
    checked.add_argument("--readings", type=Path, required=True)
    checked.add_argument("--scope", required=True)
    checked.add_argument("--kinds", default="http_json,spec_env")
    args = parser.parse_args(argv)
    try:
        if args.command == "expected":
            try:
                policy_bytes = args.policy.read_bytes()
            except OSError as error:
                raise InvalidInput(f"não li {args.policy}: {error}") from error
            print(json.dumps(expected_identity(args.sha, policy_bytes), ensure_ascii=False))
            return 0
        config = _read_json(args.config)
        expected = _read_json(args.expected)
        readings = _read_json(args.readings)
        scope = [item for item in args.scope.split(",") if item]
        kinds = set(args.kinds.split(","))
        if not scope or not kinds <= SOURCE_KINDS:
            raise InvalidInput("escopo ou tipos de fonte inválidos")
        surfaces = {surface["id"]: surface for surface in config["surfaces"]}
        identities = {}
        for surface_id in scope:
            if surface_id not in surfaces:
                raise InvalidInput(f"superfície desconhecida: {surface_id}")
            identities[surface_id] = surface_identity(
                surface_id, surfaces[surface_id]["identity"],
                readings.get(surface_id) or [], kinds)
        result = gate(expected, identities, scope)
        print(json.dumps(result, ensure_ascii=False))
        return 0 if result["status"] == "PASS" else 1
    except (InvalidInput, KeyError, TypeError) as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    sys.exit(main())
