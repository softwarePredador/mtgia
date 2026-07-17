#!/usr/bin/env python3
"""Generate a deterministic CycloneDX inventory from locked app dependencies."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import urllib.parse
import uuid
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
    app_dir: Path, *, include_dev: bool
) -> list[dict[str, Any]]:
    result = subprocess.run(
        ["dart", "pub", "deps", "--json"],
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


def _deduplicate(components: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_ref: dict[str, dict[str, Any]] = {}
    for component in components:
        by_ref[str(component["bom-ref"])] = component
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
    parser.add_argument("--package-lock", type=Path)
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

    components = _deduplicate(
        _dart_components(app_dir, include_dev=args.include_dev)
        + _npm_components(args.package_lock)
    )
    version = _app_version(pubspec)
    serial_seed = f"manaloom:{version}:{args.git_sha}"
    properties = [
        {"name": "manaloom:git-sha", "value": args.git_sha},
        {
            "name": "manaloom:pubspec-lock-sha256",
            "value": _sha256(pubspec_lock),
        },
    ]
    if args.package_lock and args.package_lock.is_file():
        properties.append(
            {
                "name": "manaloom:package-lock-sha256",
                "value": _sha256(args.package_lock),
            }
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
