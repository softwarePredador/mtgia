#!/usr/bin/env python3
"""Generate a deterministic CycloneDX inventory from locked app dependencies."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.parse
import uuid
import zipfile
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
                "flutter-dart-runtime+android-gradle-release-runtime"
                if gradle_components
                else "flutter-dart-runtime"
            ),
        },
    ]
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
