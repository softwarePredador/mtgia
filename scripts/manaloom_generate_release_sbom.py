#!/usr/bin/env python3
"""Generate a deterministic CycloneDX inventory from locked app dependencies."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys
import urllib.parse
import uuid
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _app_version(pubspec: Path) -> str:
    for raw_line in pubspec.read_text(encoding="utf-8").splitlines():
        if raw_line.startswith("version:"):
            value = raw_line.split(":", 1)[1].strip().strip("'\"")
            if value:
                return value
    raise ValueError(f"version ausente em {pubspec}")


def _dart_components(
    app_dir: Path, *, dart_bin: Path, include_dev: bool
) -> list[dict[str, Any]]:
    result = subprocess.run(
        [str(dart_bin), "pub", "deps", "--json"],
        cwd=app_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    payload = json.loads(result.stdout)
    packages = payload.get("packages")
    if not isinstance(packages, list):
        raise ValueError("dart pub deps --json nao retornou packages")

    package_by_name = {
        str(package.get("name")): package
        for package in packages
        if isinstance(package, dict) and package.get("name")
    }
    root = next(
        (
            package
            for package in packages
            if isinstance(package, dict) and package.get("kind") == "root"
        ),
        None,
    )
    if root is None:
        raise ValueError("dart pub deps --json nao retornou o pacote root")

    runtime_direct = {
        str(name) for name in root.get("directDependencies", []) if name
    }
    direct_names = set(runtime_direct)
    selected_names: set[str]
    if include_dev:
        direct_names.update(
            str(name) for name in root.get("devDependencies", []) if name
        )
        selected_names = {
            name
            for name, package in package_by_name.items()
            if package.get("kind") != "root"
        }
    else:
        # Walk only the production dependency graph rooted at
        # `directDependencies`. This keeps test/lint tooling out of an SBOM
        # that describes the shipped Flutter artifact.
        selected_names = set(runtime_direct)
        pending = list(runtime_direct)
        while pending:
            current = pending.pop()
            package = package_by_name.get(current)
            if not isinstance(package, dict):
                continue
            for dependency in package.get("dependencies", []):
                dependency_name = str(dependency)
                if dependency_name and dependency_name not in selected_names:
                    selected_names.add(dependency_name)
                    pending.append(dependency_name)

    components: list[dict[str, Any]] = []
    for name in sorted(selected_names):
        package = package_by_name.get(name)
        if not isinstance(package, dict):
            continue
        version = str(package.get("version") or "").strip()
        if not name or not version:
            continue
        dependency_kind = "direct" if name in direct_names else "transitive"
        encoded_name = urllib.parse.quote(name, safe="")
        components.append(
            {
                "type": "library",
                "group": "pub.dev",
                "name": name,
                "version": version,
                "bom-ref": f"pkg:pub/{encoded_name}@{version}",
                "purl": f"pkg:pub/{encoded_name}@{version}",
                "properties": [
                    {
                        "name": "manaloom:dependency-kind",
                        "value": dependency_kind,
                    }
                ],
            }
        )
    return components


def _locked_pub_versions(pubspec_lock: Path) -> dict[str, str]:
    versions: dict[str, str] = {}
    current_package: str | None = None
    inside_packages = False
    package_pattern = re.compile(r"^  ([a-zA-Z0-9_]+):$")
    version_pattern = re.compile(r"^    version:\s+(.+?)\s*$")

    for line in pubspec_lock.read_text(encoding="utf-8").splitlines():
        if line == "packages:":
            inside_packages = True
            continue
        if inside_packages and line and not line.startswith(" "):
            break
        if not inside_packages:
            continue
        package_match = package_pattern.match(line)
        if package_match:
            current_package = package_match.group(1)
            continue
        version_match = version_pattern.match(line)
        if version_match and current_package:
            versions[current_package] = version_match.group(1).strip("'\"")

    if not versions:
        raise ValueError(f"nenhuma versao encontrada em {pubspec_lock}")
    return versions


def _validate_dart_components_against_lock(
    components: list[dict[str, Any]], pubspec_lock: Path
) -> None:
    locked_versions = _locked_pub_versions(pubspec_lock)
    mismatches: list[str] = []
    for component in components:
        if component.get("group") != "pub.dev":
            continue
        name = str(component.get("name") or "")
        actual = str(component.get("version") or "")
        expected = locked_versions.get(name)
        if expected != actual:
            mismatches.append(
                f"{name}: lock={expected or 'ausente'} deps={actual or 'ausente'}"
            )
    if mismatches:
        raise ValueError(
            "grafo Dart do SBOM diverge do pubspec.lock: " + "; ".join(mismatches)
        )


def _npm_components(package_lock: Path | None) -> list[dict[str, Any]]:
    if package_lock is None or not package_lock.is_file():
        return []
    payload = json.loads(package_lock.read_text(encoding="utf-8"))
    packages = payload.get("packages")
    if not isinstance(packages, dict):
        raise ValueError("package-lock.json nao possui mapa packages")

    components: list[dict[str, Any]] = []
    for package_path, package in packages.items():
        if not package_path or not isinstance(package, dict):
            continue
        name = str(package.get("name") or "").strip()
        if not name and "node_modules/" in package_path:
            # package-lock v3 commonly omits `name` from nested package
            # records. Derive it from the final node_modules segment so the
            # SBOM does not silently drop the JavaScript dependency graph.
            name = package_path.rsplit("node_modules/", 1)[-1].strip()
        version = str(package.get("version") or "").strip()
        if not name or not version:
            continue
        encoded_name = urllib.parse.quote(name, safe="/")
        scope = "development" if package.get("dev") is True else "runtime"
        component: dict[str, Any] = {
            "type": "library",
            "group": "npmjs.com",
            "name": name,
            "version": version,
            "bom-ref": f"pkg:npm/{encoded_name}@{version}",
            "purl": f"pkg:npm/{encoded_name}@{version}",
            "properties": [
                {"name": "manaloom:dependency-scope", "value": scope}
            ],
        }
        integrity = str(package.get("integrity") or "").strip()
        if integrity:
            component["properties"].append(
                {"name": "manaloom:npm-integrity", "value": integrity}
            )
        components.append(component)
    return components


_ENGINE_SPECS = {
    "xmage": {
        "directory": "xmage-sidecar",
        "pin_file": "XMAGE_COMMIT",
        "docker_arg": "XMAGE_COMMIT",
        "organization": "magefree",
        "repository": "mage",
        "license": "MIT",
        "license_path": "LICENSE.txt",
    },
    "forge": {
        "directory": "forge-sidecar",
        "pin_file": "FORGE_COMMIT",
        "docker_arg": "FORGE_COMMIT",
        "organization": "Card-Forge",
        "repository": "forge",
        "license": "GPL-3.0-only",
        "license_path": "LICENSE",
    },
}


def _read_engine_pin(path: Path, engine: str) -> str:
    if not path.is_file():
        raise ValueError(f"pin {engine} ausente: {path}")
    value = path.read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[0-9a-f]{40}", value):
        raise ValueError(f"pin {engine} deve ser um commit SHA-1 completo: {path}")
    return value


def _docker_logical_lines(dockerfile: Path) -> list[str]:
    lines: list[str] = []
    buffer = ""
    for raw_line in dockerfile.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        continuation = stripped.endswith("\\")
        part = stripped[:-1].rstrip() if continuation else stripped
        buffer = f"{buffer} {part}".strip()
        if not continuation:
            lines.append(buffer)
            buffer = ""
    if buffer:
        raise ValueError(f"Dockerfile termina com continuacao incompleta: {dockerfile}")
    return lines


def _docker_supply_chain(dockerfile: Path) -> dict[str, Any]:
    if not dockerfile.is_file():
        raise ValueError(f"Dockerfile de sidecar ausente: {dockerfile}")
    stages: list[dict[str, Any]] = []
    current_stage: dict[str, Any] | None = None
    for line in _docker_logical_lines(dockerfile):
        from_match = re.fullmatch(
            r"FROM\s+(\S+)(?:\s+AS\s+(\S+))?", line, flags=re.IGNORECASE
        )
        if from_match:
            current_stage = {
                "name": from_match.group(2) or "runtime",
                "image": from_match.group(1),
                "apt_packages": [],
            }
            stages.append(current_stage)
            continue

        install_count = len(re.findall(r"\bapt-get\s+install\b", line))
        if install_count == 0:
            continue
        if current_stage is None:
            raise ValueError(f"apt-get anterior ao primeiro FROM em {dockerfile}")
        matches = list(
            re.finditer(
                r"\bapt-get\s+install\s+-y\s+--no-install-recommends\s+"
                r"(.+?)(?=\s+&&|$)",
                line,
            )
        )
        if len(matches) != install_count:
            raise ValueError(
                f"declaracao apt nao reconhecida integralmente em {dockerfile}: {line}"
            )
        for match in matches:
            packages = shlex.split(match.group(1))
            if not packages or any(package.startswith("-") for package in packages):
                raise ValueError(f"lista apt invalida em {dockerfile}: {line}")
            current_stage["apt_packages"].extend(packages)

    if not stages:
        raise ValueError(f"Dockerfile sem FROM: {dockerfile}")
    for stage in stages:
        image = str(stage["image"])
        if not re.fullmatch(r"\S+@sha256:[0-9a-f]{64}", image):
            raise ValueError(
                f"imagem base sem digest SHA-256 imutavel em {dockerfile}: {image}"
            )
        stage["apt_packages"] = sorted(set(stage["apt_packages"]))
    return {"stages": stages}


def _docker_arg(dockerfile: Path, name: str) -> str:
    matches = re.findall(
        rf"^ARG\s+{re.escape(name)}=([^\s]+)\s*$",
        dockerfile.read_text(encoding="utf-8"),
        flags=re.MULTILINE,
    )
    if len(matches) != 1:
        raise ValueError(f"Dockerfile deve declarar exatamente um ARG {name}")
    return matches[0]


def _oci_components(
    supplies: list[tuple[str, dict[str, Any]]],
) -> list[dict[str, Any]]:
    usages: dict[str, dict[str, set[str]]] = {}
    for sidecar, supply in supplies:
        for stage in supply["stages"]:
            image = str(stage["image"])
            usage = usages.setdefault(image, {"sidecars": set(), "stages": set()})
            usage["sidecars"].add(sidecar)
            usage["stages"].add(f"{sidecar}:{stage['name']}")

    components: list[dict[str, Any]] = []
    for image in sorted(usages):
        image_name, digest = image.rsplit("@sha256:", 1)
        repository, tag = image_name.rsplit(":", 1)
        encoded_repository = urllib.parse.quote(repository, safe="./")
        encoded_tag = urllib.parse.quote(tag, safe=".+_-")
        usage = usages[image]
        components.append(
            {
                "type": "container",
                "name": repository,
                "version": tag,
                "bom-ref": (
                    f"pkg:oci/{encoded_repository}@{encoded_tag}"
                    f"?digest=sha256%3A{digest}"
                ),
                "purl": (
                    f"pkg:oci/{encoded_repository}@{encoded_tag}"
                    f"?digest=sha256%3A{digest}"
                ),
                "hashes": [{"alg": "SHA-256", "content": digest}],
                "properties": [
                    {
                        "name": "manaloom:deployment-units",
                        "value": ",".join(sorted(usage["sidecars"])),
                    },
                    {
                        "name": "manaloom:docker-stages",
                        "value": ",".join(sorted(usage["stages"])),
                    },
                    {
                        "name": "manaloom:runtime-family",
                        "value": (
                            "java"
                            if "temurin" in repository or repository == "maven"
                            else "container"
                        ),
                    },
                ],
            }
        )
    return components


def _resolve_maven_value(value: str, properties: dict[str, str]) -> str:
    resolved = value.strip()
    for _ in range(10):
        placeholders = re.findall(r"\$\{([^}]+)\}", resolved)
        if not placeholders:
            return resolved
        for placeholder in placeholders:
            replacement = properties.get(placeholder)
            if replacement is None:
                raise ValueError(f"propriedade Maven nao resolvida: {placeholder}")
            resolved = resolved.replace(f"${{{placeholder}}}", replacement)
    raise ValueError(f"resolucao Maven excedeu o limite: {value}")


def _direct_maven_runtime_components(pom: Path) -> list[dict[str, Any]]:
    if not pom.is_file():
        raise ValueError(f"pom.xml do XMage sidecar ausente: {pom}")
    root = ET.parse(pom).getroot()
    namespace = {"m": "http://maven.apache.org/POM/4.0.0"}
    properties: dict[str, str] = {}
    properties_node = root.find("m:properties", namespace)
    if properties_node is not None:
        for child in properties_node:
            key = child.tag.rsplit("}", 1)[-1]
            properties[key] = (child.text or "").strip()

    components: list[dict[str, Any]] = []
    dependencies = root.findall("m:dependencies/m:dependency", namespace)
    for dependency in dependencies:
        text = lambda name: (dependency.findtext(f"m:{name}", "", namespace)).strip()
        scope = text("scope") or "compile"
        optional = text("optional").lower() == "true"
        if scope not in {"compile", "runtime"} or optional:
            continue
        group = _resolve_maven_value(text("groupId"), properties)
        name = _resolve_maven_value(text("artifactId"), properties)
        version = _resolve_maven_value(text("version"), properties)
        if not group or not name or not version:
            raise ValueError(f"dependencia Maven direta incompleta em {pom}")
        encoded_group = urllib.parse.quote(group, safe=".")
        encoded_name = urllib.parse.quote(name, safe="")
        encoded_version = urllib.parse.quote(version, safe=".+_-")
        purl = f"pkg:maven/{encoded_group}/{encoded_name}@{encoded_version}"
        components.append(
            {
                "type": "library",
                "group": group,
                "name": name,
                "version": version,
                "scope": "required",
                "bom-ref": f"{purl}#manaloom-xmage-sidecar",
                "purl": purl,
                "properties": [
                    {
                        "name": "manaloom:dependency-scope",
                        "value": "xmage-sidecar-direct-runtime",
                    },
                    {
                        "name": "manaloom:dependency-evidence",
                        "value": "services/xmage-sidecar/pom.xml",
                    },
                ],
            }
        )
    if not components:
        raise ValueError(f"pom.xml sem dependencias diretas de runtime: {pom}")
    return components


def _battle_sidecar_components(
    services_root: Path, *, git_sha: str
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    present = {
        engine: (services_root / str(spec["directory"])).is_dir()
        for engine, spec in _ENGINE_SPECS.items()
    }
    if not any(present.values()):
        return [], {"included": False}
    if not all(present.values()):
        raise ValueError(
            "inventario de sidecars exige xmage-sidecar e forge-sidecar juntos"
        )

    components: list[dict[str, Any]] = []
    supplies: list[tuple[str, dict[str, Any]]] = []
    total_apt_declarations = 0
    for engine, spec in _ENGINE_SPECS.items():
        sidecar_name = f"{engine}-sidecar"
        sidecar_dir = services_root / str(spec["directory"])
        dockerfile = sidecar_dir / "Dockerfile"
        pin_file = sidecar_dir / str(spec["pin_file"])
        pin = _read_engine_pin(pin_file, engine)
        docker_pin = _docker_arg(dockerfile, str(spec["docker_arg"]))
        if docker_pin != pin:
            raise ValueError(
                f"pin {engine} diverge entre {pin_file.name} e Dockerfile"
            )
        supply = _docker_supply_chain(dockerfile)
        supplies.append((sidecar_name, supply))
        apt_by_stage = {
            str(stage["name"]): stage["apt_packages"]
            for stage in supply["stages"]
            if stage["apt_packages"]
        }
        total_apt_declarations += sum(len(items) for items in apt_by_stage.values())
        source_hashes = {
            "Dockerfile": _sha256(dockerfile),
            pin_file.name: _sha256(pin_file),
        }
        if engine == "xmage":
            source_hashes["pom.xml"] = _sha256(sidecar_dir / "pom.xml")
        else:
            source_hashes["SeededForgeMain.java"] = _sha256(
                sidecar_dir / "SeededForgeMain.java"
            )
            source_hashes["sidecar.py"] = _sha256(sidecar_dir / "sidecar.py")

        components.append(
            {
                "type": "application",
                "name": f"manaloom-{sidecar_name}",
                "version": git_sha,
                "bom-ref": f"urn:manaloom:sidecar:{engine}:{git_sha}",
                "properties": [
                    {
                        "name": "manaloom:engine-commit",
                        "value": pin,
                    },
                    {
                        "name": "manaloom:source-file-sha256",
                        "value": json.dumps(
                            source_hashes, sort_keys=True, separators=(",", ":")
                        ),
                    },
                    {
                        "name": "manaloom:apt-package-declarations",
                        "value": json.dumps(
                            apt_by_stage, sort_keys=True, separators=(",", ":")
                        ),
                    },
                    {
                        "name": "manaloom:apt-version-evidence",
                        "value": "unresolved-until-built-image-inspection",
                    },
                    {
                        "name": "manaloom:maven-transitive-evidence",
                        "value": (
                            "direct-runtime-only-from-local-pom"
                            if engine == "xmage"
                            else "unavailable-upstream-pom-not-vendored"
                        ),
                    },
                ],
            }
        )

        organization = str(spec["organization"])
        repository = str(spec["repository"])
        commit_url = f"https://github.com/{organization}/{repository}/commit/{pin}"
        license_url = (
            f"https://github.com/{organization}/{repository}/blob/{pin}/"
            f"{spec['license_path']}"
        )
        components.append(
            {
                "type": "application",
                "group": organization,
                "name": engine,
                "version": pin,
                "bom-ref": f"urn:manaloom:engine:{engine}:{pin}",
                "licenses": [
                    {
                        "license": {
                            "id": str(spec["license"]),
                            "url": license_url,
                        }
                    }
                ],
                "externalReferences": [
                    {"type": "vcs", "url": commit_url},
                    {"type": "license", "url": license_url},
                ],
                "properties": [
                    {
                        "name": "manaloom:pin-file",
                        "value": f"services/{spec['directory']}/{spec['pin_file']}",
                    },
                    {
                        "name": "manaloom:pin-file-sha256",
                        "value": _sha256(pin_file),
                    },
                    {
                        "name": "manaloom:execution-boundary",
                        "value": "isolated-http-sidecar",
                    },
                ],
            }
        )

    components.extend(_oci_components(supplies))
    components.extend(
        _direct_maven_runtime_components(services_root / "xmage-sidecar" / "pom.xml")
    )
    return components, {
        "included": True,
        "sidecar_count": 2,
        "apt_declaration_count": total_apt_declarations,
        "apt_versions": "unresolved-until-built-image-inspection",
        "xmage_maven": "direct-runtime-only-from-local-pom",
        "forge_maven": "unavailable-upstream-pom-not-vendored",
    }


_GRADLE_RELEASE_RUNTIME_CONFIGURATION = "releaseRuntimeClasspath"
_AAB_DEPENDENCY_METADATA = (
    "BUNDLE-METADATA/com.android.tools.build.libraries/dependencies.pb"
)


def _gradle_components(gradle_lock: Path | None) -> list[dict[str, Any]]:
    """Inventory every locked Gradle component with exact release membership.

    A Gradle lock produced by ``lockAllConfigurations`` contains build tooling,
    Android tests, unit tests, debug and profile dependencies alongside the
    shipped release graph.  The right-hand side of every lock entry is the
    authoritative set of configurations that resolved that coordinate.  Keep
    non-release entries visible in CycloneDX with ``scope=excluded`` so the OSV
    report can disclose their findings, while only exact membership in
    ``releaseRuntimeClasspath`` is allowed to block a shipped release.
    """
    if gradle_lock is None or not gradle_lock.is_file():
        return []

    components: list[dict[str, Any]] = []
    seen_coordinates: set[tuple[str, str, str]] = set()
    for raw_line in gradle_lock.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("empty="):
            continue
        if "=" not in line:
            raise ValueError(
                f"entrada Gradle sem configuracoes em {gradle_lock}: {line}"
            )
        coordinate, raw_configurations = line.split("=", 1)
        parts = coordinate.rsplit(":", 2)
        if len(parts) != 3 or not all(parts):
            raise ValueError(f"coordenada Gradle invalida em {gradle_lock}: {line}")
        configurations = sorted(
            {
                configuration.strip()
                for configuration in raw_configurations.split(",")
                if configuration.strip()
            }
        )
        if not configurations:
            raise ValueError(
                f"entrada Gradle sem configuracoes em {gradle_lock}: {line}"
            )
        group, name, version = parts
        coordinate_key = (group, name, version)
        if coordinate_key in seen_coordinates:
            raise ValueError(
                f"coordenada Gradle duplicada em {gradle_lock}: {coordinate}"
            )
        seen_coordinates.add(coordinate_key)
        is_release_runtime = _GRADLE_RELEASE_RUNTIME_CONFIGURATION in configurations
        encoded_group = urllib.parse.quote(group, safe=".")
        encoded_name = urllib.parse.quote(name, safe="")
        components.append(
            {
                "type": "library",
                "group": group,
                "name": name,
                "version": version,
                "scope": "required" if is_release_runtime else "excluded",
                "bom-ref": (
                    f"pkg:maven/{encoded_group}/{encoded_name}@"
                    f"{urllib.parse.quote(version, safe='.+_-')}"
                ),
                "purl": (
                    f"pkg:maven/{encoded_group}/{encoded_name}@"
                    f"{urllib.parse.quote(version, safe='.+_-')}"
                ),
                "properties": [
                    {
                        "name": "manaloom:dependency-scope",
                        "value": (
                            "android-release-runtime"
                            if is_release_runtime
                            else "android-non-release-only"
                        ),
                    },
                    {
                        "name": "manaloom:dependency-lock",
                        "value": "gradle.lockfile",
                    },
                    {
                        "name": "manaloom:gradle-configurations",
                        "value": ",".join(configurations),
                    },
                    {
                        "name": "manaloom:release-runtime-configuration",
                        "value": _GRADLE_RELEASE_RUNTIME_CONFIGURATION,
                    },
                    {
                        "name": "manaloom:release-membership-evidence",
                        "value": "gradle-lock-configuration-membership",
                    },
                ],
            }
        )
    if not components:
        raise ValueError(f"gradle lock sem componentes: {gradle_lock}")
    return components


def _protobuf_varint(data: bytes, index: int, *, context: str) -> tuple[int, int]:
    value = 0
    shift = 0
    while index < len(data) and shift < 70:
        byte = data[index]
        index += 1
        value |= (byte & 0x7F) << shift
        if byte < 0x80:
            return value, index
        shift += 7
    raise ValueError(f"protobuf truncado ou varint invalido em {context}")


def _protobuf_fields(
    data: bytes, *, context: str
) -> list[tuple[int, int, int | bytes]]:
    fields: list[tuple[int, int, int | bytes]] = []
    index = 0
    while index < len(data):
        key, index = _protobuf_varint(data, index, context=context)
        field_number = key >> 3
        wire_type = key & 0x07
        if field_number == 0:
            raise ValueError(f"protobuf possui field zero em {context}")
        if wire_type == 0:
            value, index = _protobuf_varint(data, index, context=context)
        elif wire_type == 1:
            end = index + 8
            if end > len(data):
                raise ValueError(f"protobuf fixed64 truncado em {context}")
            value = data[index:end]
            index = end
        elif wire_type == 2:
            length, index = _protobuf_varint(data, index, context=context)
            end = index + length
            if end > len(data):
                raise ValueError(f"protobuf length-delimited truncado em {context}")
            value = data[index:end]
            index = end
        elif wire_type == 5:
            end = index + 4
            if end > len(data):
                raise ValueError(f"protobuf fixed32 truncado em {context}")
            value = data[index:end]
            index = end
        else:
            raise ValueError(
                f"protobuf wire type nao suportado ({wire_type}) em {context}"
            )
        fields.append((field_number, wire_type, value))
    return fields


def _aab_maven_coordinates(aab: Path) -> set[tuple[str, str, str]]:
    if not aab.is_file():
        raise ValueError(f"artefato Android de release ausente: {aab}")
    try:
        with zipfile.ZipFile(aab) as archive:
            dependency_metadata = archive.read(_AAB_DEPENDENCY_METADATA)
    except KeyError as exc:
        raise ValueError(
            f"AAB sem metadata de dependencias: {_AAB_DEPENDENCY_METADATA}"
        ) from exc
    except zipfile.BadZipFile as exc:
        raise ValueError(f"artefato Android nao e um AAB ZIP valido: {aab}") from exc

    coordinates: set[tuple[str, str, str]] = set()
    library_index = 0
    for field_number, wire_type, raw_library in _protobuf_fields(
        dependency_metadata, context="AppDependencies"
    ):
        if field_number != 1:
            continue
        if wire_type != 2 or not isinstance(raw_library, bytes):
            raise ValueError("AppDependencies.library possui wire type invalido")
        library_index += 1
        identities = [
            value
            for number, child_wire, value in _protobuf_fields(
                raw_library, context=f"Library[{library_index}]"
            )
            if number == 1 and child_wire == 2 and isinstance(value, bytes)
        ]
        if len(identities) != 1:
            raise ValueError(
                f"Library[{library_index}] deve possuir uma identidade Maven"
            )

        identity_fields: dict[int, str] = {}
        for number, child_wire, raw_value in _protobuf_fields(
            identities[0], context=f"MavenLibrary[{library_index}]"
        ):
            if number not in (1, 2, 5):
                continue
            if child_wire != 2 or not isinstance(raw_value, bytes):
                raise ValueError(
                    f"MavenLibrary[{library_index}] possui campo textual invalido"
                )
            if number in identity_fields:
                raise ValueError(
                    f"MavenLibrary[{library_index}] possui campo duplicado {number}"
                )
            try:
                decoded = raw_value.decode("utf-8")
            except UnicodeDecodeError as exc:
                raise ValueError(
                    f"MavenLibrary[{library_index}] possui UTF-8 invalido"
                ) from exc
            if not decoded:
                raise ValueError(
                    f"MavenLibrary[{library_index}] possui campo textual vazio"
                )
            identity_fields[number] = decoded
        if set(identity_fields) != {1, 2, 5}:
            raise ValueError(
                f"MavenLibrary[{library_index}] sem group/artifact/version completos"
            )
        coordinate = (
            identity_fields[1],
            identity_fields[2],
            identity_fields[5],
        )
        if coordinate in coordinates:
            raise ValueError(f"AAB possui dependencia Maven duplicada: {coordinate}")
        coordinates.add(coordinate)

    if not coordinates:
        raise ValueError("AAB nao declarou dependencias Maven em dependencies.pb")
    return coordinates


def _validate_gradle_aab_parity(
    gradle_components: list[dict[str, Any]], aab: Path
) -> int:
    gradle_release_coordinates = {
        (
            str(component.get("group") or ""),
            str(component.get("name") or ""),
            str(component.get("version") or ""),
        )
        for component in gradle_components
        if component.get("scope") == "required"
    }
    aab_coordinates = _aab_maven_coordinates(aab)
    missing_from_aab = sorted(gradle_release_coordinates - aab_coordinates)
    unexpected_in_aab = sorted(aab_coordinates - gradle_release_coordinates)
    if missing_from_aab or unexpected_in_aab:
        details: list[str] = []
        if missing_from_aab:
            details.append(f"ausentes_no_aab={missing_from_aab}")
        if unexpected_in_aab:
            details.append(f"inesperadas_no_aab={unexpected_in_aab}")
        raise ValueError(
            "releaseRuntimeClasspath diverge do dependencies.pb do AAB: "
            + "; ".join(details)
        )
    return len(aab_coordinates)


def _gradle_scope_counts(
    gradle_components: list[dict[str, Any]],
) -> tuple[int, int]:
    release_count = sum(
        component.get("scope") == "required" for component in gradle_components
    )
    excluded_count = sum(
        component.get("scope") == "excluded" for component in gradle_components
    )
    if gradle_components and release_count == 0:
        raise ValueError(
            "gradle lock nao possui componentes no releaseRuntimeClasspath"
        )
    return release_count, excluded_count


def _deduplicate(components: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_ref: dict[str, dict[str, Any]] = {}
    for component in components:
        bom_ref = str(component["bom-ref"])
        existing = by_ref.get(bom_ref)
        if existing is not None and existing != component:
            raise ValueError(
                f"componentes divergentes possuem o mesmo bom-ref: {bom_ref}"
            )
        by_ref[bom_ref] = component
    return [by_ref[key] for key in sorted(by_ref)]


def _timestamp(raw: str | None) -> str:
    if raw:
        parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    else:
        epoch = os.environ.get("SOURCE_DATE_EPOCH")
        parsed = (
            datetime.fromtimestamp(int(epoch), tz=timezone.utc)
            if epoch
            else datetime.now(timezone.utc)
        )
    return parsed.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-dir", type=Path, required=True)
    parser.add_argument("--dart-bin", type=Path, required=True)
    parser.add_argument("--package-lock", type=Path)
    parser.add_argument("--gradle-lock", type=Path)
    parser.add_argument("--android-release-artifact", type=Path)
    parser.add_argument("--battle-sidecars-root", type=Path)
    parser.add_argument("--include-dev", action="store_true")
    parser.add_argument("--git-sha", required=True)
    parser.add_argument("--source-committed-at")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    app_dir = args.app_dir.resolve()
    pubspec = app_dir / "pubspec.yaml"
    pubspec_lock = app_dir / "pubspec.lock"
    if not pubspec.is_file() or not pubspec_lock.is_file():
        parser.error("app-dir deve conter pubspec.yaml e pubspec.lock")

    dart_bin = args.dart_bin.resolve()
    if not dart_bin.is_file() or not os.access(dart_bin, os.X_OK):
        parser.error("dart-bin deve apontar para um executavel Dart")

    dart_components = _dart_components(
        app_dir, dart_bin=dart_bin, include_dev=args.include_dev
    )
    _validate_dart_components_against_lock(dart_components, pubspec_lock)
    services_root = (
        args.battle_sidecars_root.resolve()
        if args.battle_sidecars_root
        else app_dir.parent / "services"
    )
    sidecar_components, sidecar_inventory = _battle_sidecar_components(
        services_root, git_sha=args.git_sha
    )
    if args.battle_sidecars_root and not sidecar_inventory["included"]:
        parser.error("battle-sidecars-root nao contem os dois sidecars obrigatorios")
    if sidecar_inventory["included"] and not re.fullmatch(
        r"[0-9a-f]{40}", args.git_sha
    ):
        parser.error("git-sha deve ser completo quando sidecars entram no SBOM")
    gradle_components = _gradle_components(args.gradle_lock)
    gradle_release_components, gradle_excluded_components = _gradle_scope_counts(
        gradle_components
    )
    aab_dependency_count: int | None = None
    if args.android_release_artifact:
        if not gradle_components:
            parser.error("android-release-artifact exige gradle-lock")
        aab_dependency_count = _validate_gradle_aab_parity(
            gradle_components, args.android_release_artifact
        )
    components = _deduplicate(
        dart_components
        + _npm_components(args.package_lock)
        + gradle_components
        + sidecar_components
    )
    version = _app_version(pubspec)
    serial_seed = f"manaloom:{version}:{args.git_sha}"
    properties = [
        {"name": "manaloom:git-sha", "value": args.git_sha},
        {
            "name": "manaloom:pubspec-lock-sha256",
            "value": _sha256(pubspec_lock),
        },
        {
            "name": "manaloom:sbom-scope",
            "value": (
                (
                    "flutter-dart-runtime+android-gradle-release-runtime"
                    if gradle_components
                    else "flutter-dart-runtime"
                )
                + (
                    "+battle-sidecar-source-supply-chain"
                    if sidecar_inventory["included"]
                    else ""
                )
            ),
        },
    ]
    if sidecar_inventory["included"]:
        properties.extend(
            [
                {
                    "name": "manaloom:battle-sidecar-component-count",
                    "value": str(len(sidecar_components)),
                },
                {
                    "name": "manaloom:battle-sidecar-apt-declaration-count",
                    "value": str(sidecar_inventory["apt_declaration_count"]),
                },
                {
                    "name": "manaloom:battle-sidecar-apt-version-evidence",
                    "value": str(sidecar_inventory["apt_versions"]),
                },
                {
                    "name": "manaloom:xmage-maven-evidence",
                    "value": str(sidecar_inventory["xmage_maven"]),
                },
                {
                    "name": "manaloom:forge-maven-evidence",
                    "value": str(sidecar_inventory["forge_maven"]),
                },
            ]
        )
    if args.package_lock and args.package_lock.is_file():
        properties.append(
            {
                "name": "manaloom:package-lock-sha256",
                "value": _sha256(args.package_lock),
            }
        )
    if args.gradle_lock and args.gradle_lock.is_file():
        properties.extend(
            [
                {
                    "name": "manaloom:gradle-lock-sha256",
                    "value": _sha256(args.gradle_lock),
                },
                {
                    "name": "manaloom:gradle-release-runtime-configuration",
                    "value": _GRADLE_RELEASE_RUNTIME_CONFIGURATION,
                },
                {
                    "name": "manaloom:gradle-release-runtime-component-count",
                    "value": str(gradle_release_components),
                },
                {
                    "name": "manaloom:gradle-excluded-component-count",
                    "value": str(gradle_excluded_components),
                },
                {
                    "name": "manaloom:gradle-exclusion-proof",
                    "value": "gradle-lock-configuration-membership",
                },
            ]
        )
    if args.android_release_artifact:
        properties.extend(
            [
                {
                    "name": "manaloom:android-release-artifact-sha256",
                    "value": _sha256(args.android_release_artifact),
                },
                {
                    "name": "manaloom:android-release-artifact-dependency-count",
                    "value": str(aab_dependency_count),
                },
                {
                    "name": "manaloom:gradle-aab-dependency-parity",
                    "value": "exact-bidirectional-match",
                },
            ]
        )

    bom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{uuid.uuid5(uuid.NAMESPACE_URL, serial_seed)}",
        "version": 1,
        "metadata": {
            "timestamp": _timestamp(args.source_committed_at),
            "tools": {
                "components": [
                    {
                        "type": "application",
                        "name": "manaloom_generate_release_sbom.py",
                        "version": "1",
                    }
                ]
            },
            "component": {
                "type": "application",
                "name": "manaloom",
                "version": version,
                "bom-ref": f"pkg:generic/manaloom@{version}?vcs_ref={args.git_sha}",
                "properties": properties,
            },
        },
        "components": components,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(args.output.suffix + ".tmp")
    temporary.write_text(
        json.dumps(bom, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(args.output)
    print(
        json.dumps(
            {
                "status": "generated",
                "output": str(args.output),
                "components": len(components),
                "battle_sidecars_included": sidecar_inventory["included"],
                "git_sha": args.git_sha,
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as exc:
        print(f"sbom generation failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
