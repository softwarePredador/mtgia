#!/usr/bin/env python3
"""Fail closed when a release SBOM contains known OSV vulnerabilities."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import urllib.parse
from pathlib import Path
from typing import Any


_GRADLE_RELEASE_RUNTIME_CONFIGURATION = "releaseRuntimeClasspath"
_GRADLE_EXCLUSION_EVIDENCE = "gradle-lock-configuration-membership"


def _osv_package(component: dict[str, Any]) -> tuple[str, str] | None:
    purl = str(component.get("purl") or "")
    name = str(component.get("name") or "")
    group = str(component.get("group") or "")
    version = str(component.get("version") or "")
    if "@" not in purl:
        return None
    package_path, encoded_version = purl.rsplit("@", 1)
    purl_version = urllib.parse.unquote(encoded_version)
    if purl.startswith("pkg:pub/"):
        purl_name = urllib.parse.unquote(package_path.removeprefix("pkg:pub/"))
        if purl_name != name or purl_version != version:
            raise ValueError("purl Pub diverge de name/version do componente")
        return "Pub", name
    if purl.startswith("pkg:maven/"):
        maven_path = package_path.removeprefix("pkg:maven/")
        parts = maven_path.split("/")
        if len(parts) != 2:
            raise ValueError("purl Maven nao possui group/artifact exatos")
        purl_group, purl_name = map(urllib.parse.unquote, parts)
        if (purl_group, purl_name, purl_version) != (group, name, version):
            raise ValueError(
                "purl Maven diverge de group/name/version do componente"
            )
        return "Maven", f"{group}:{name}"
    if purl.startswith("pkg:npm/"):
        purl_name = urllib.parse.unquote(package_path.removeprefix("pkg:npm/"))
        if purl_name != name or purl_version != version:
            raise ValueError("purl npm diverge de name/version do componente")
        return "npm", name
    return None


def _query_batch(
    api_url: str, queries: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    result = subprocess.run(
        [
            "curl",
            "-fsS",
            "--retry",
            "3",
            "--connect-timeout",
            "15",
            "-H",
            "Content-Type: application/json",
            "--data-binary",
            "@-",
            api_url,
        ],
        input=json.dumps({"queries": queries}),
        check=True,
        capture_output=True,
        text=True,
    )
    payload = json.loads(result.stdout)
    results = payload.get("results")
    if not isinstance(results, list) or len(results) != len(queries):
        raise ValueError("OSV querybatch retornou cardinalidade invalida")
    return results


def _component_properties(component: dict[str, Any]) -> dict[str, str]:
    raw_properties = component.get("properties") or []
    if not isinstance(raw_properties, list):
        raise ValueError("componente SBOM possui properties invalidas")
    properties: dict[str, str] = {}
    for raw_property in raw_properties:
        if not isinstance(raw_property, dict):
            raise ValueError("componente SBOM possui property invalida")
        name = str(raw_property.get("name") or "")
        value = str(raw_property.get("value") or "")
        if not name:
            raise ValueError("componente SBOM possui property sem nome")
        if name in properties:
            raise ValueError(f"componente SBOM possui property duplicada: {name}")
        properties[name] = value
    return properties


def _release_relevance(
    component: dict[str, Any],
) -> tuple[bool, dict[str, Any] | None]:
    """Return whether a component is shipped, validating exclusions fail-closed."""
    properties = _component_properties(component)
    is_gradle_locked = properties.get("manaloom:dependency-lock") == "gradle.lockfile"
    scope = str(component.get("scope") or "required")

    if not is_gradle_locked:
        if scope == "excluded":
            raise ValueError(
                "componente excluido sem prova Gradle de ausencia no release runtime"
            )
        return True, None

    if component.get("type") != "library":
        raise ValueError("componente Gradle deve possuir type=library")

    configurations = sorted(
        {
            configuration.strip()
            for configuration in properties.get(
                "manaloom:gradle-configurations", ""
            ).split(",")
            if configuration.strip()
        }
    )
    target_configuration = properties.get(
        "manaloom:release-runtime-configuration"
    )
    evidence = properties.get("manaloom:release-membership-evidence")
    if (
        not configurations
        or target_configuration != _GRADLE_RELEASE_RUNTIME_CONFIGURATION
        or evidence != _GRADLE_EXCLUSION_EVIDENCE
    ):
        raise ValueError(
            "componente Gradle sem prova completa de membership no release runtime"
        )

    is_release_runtime = target_configuration in configurations
    expected_scope = "required" if is_release_runtime else "excluded"
    expected_dependency_scope = (
        "android-release-runtime"
        if is_release_runtime
        else "android-non-release-only"
    )
    if scope != expected_scope:
        raise ValueError(
            "scope CycloneDX diverge das configuracoes registradas no Gradle lock"
        )
    if properties.get("manaloom:dependency-scope") != expected_dependency_scope:
        raise ValueError(
            "dependency-scope diverge das configuracoes registradas no Gradle lock"
        )

    if is_release_runtime:
        return True, None
    return False, {
        "kind": _GRADLE_EXCLUSION_EVIDENCE,
        "target_configuration": target_configuration,
        "resolved_configurations": configurations,
    }


def _scan_components(
    components: list[Any], api_url: str
) -> dict[str, Any]:
    query_records: list[
        tuple[dict[str, Any], dict[str, Any], bool, dict[str, Any] | None]
    ] = []
    excluded_component_count = 0
    for component in components:
        if not isinstance(component, dict):
            raise ValueError("SBOM possui componente que nao e objeto")
        release_relevant, exclusion_evidence = _release_relevance(component)
        if not release_relevant:
            excluded_component_count += 1
        osv_package = _osv_package(component)
        version = str(component.get("version") or "")
        if component.get("type") == "library" and (
            osv_package is None or not version
        ):
            raise ValueError(
                "componente library nao pode ser consultado no OSV"
            )
        if osv_package is None:
            continue
        ecosystem, package_name = osv_package
        query_records.append(
            (
                component,
                {
                    "package": {
                        "ecosystem": ecosystem,
                        "name": package_name,
                    },
                    "version": version,
                },
                release_relevant,
                exclusion_evidence,
            )
        )

    release_findings: list[dict[str, Any]] = []
    non_release_findings: list[dict[str, Any]] = []
    for offset in range(0, len(query_records), 500):
        batch = query_records[offset : offset + 500]
        results = _query_batch(api_url, [record[1] for record in batch])
        for (
            component,
            query,
            release_relevant,
            exclusion_evidence,
        ), result in zip(batch, results, strict=True):
            if not isinstance(result, dict):
                raise ValueError("OSV querybatch retornou resultado que nao e objeto")
            vulnerabilities = result.get("vulns", [])
            if not isinstance(vulnerabilities, list):
                raise ValueError("OSV querybatch retornou vulns que nao e lista")
            for vulnerability in vulnerabilities:
                if not isinstance(vulnerability, dict):
                    raise ValueError("OSV querybatch retornou vulnerabilidade invalida")
                vulnerability_id = vulnerability.get("id")
                if not isinstance(vulnerability_id, str) or not vulnerability_id:
                    raise ValueError("OSV querybatch retornou vulnerabilidade sem id")
                aliases = vulnerability.get("aliases", [])
                if not isinstance(aliases, list) or not all(
                    isinstance(alias, str) and alias for alias in aliases
                ):
                    raise ValueError("OSV querybatch retornou aliases invalidos")
                finding = {
                    "component": {
                        "bom_ref": component.get("bom-ref"),
                        "name": query["package"]["name"],
                        "ecosystem": query["package"]["ecosystem"],
                        "version": query["version"],
                        "scope": component.get("scope", "required"),
                    },
                    "release_relevant": release_relevant,
                    "id": vulnerability_id,
                    "aliases": sorted(aliases),
                    "summary": vulnerability.get("summary"),
                }
                if exclusion_evidence is not None:
                    finding["exclusion_evidence"] = exclusion_evidence
                if release_relevant:
                    release_findings.append(finding)
                else:
                    non_release_findings.append(finding)

    def finding_key(finding: dict[str, Any]) -> tuple[str, str, str]:
        return (
            str(finding["component"]["ecosystem"]),
            str(finding["component"]["name"]),
            str(finding["id"]),
        )

    release_findings.sort(key=finding_key)
    non_release_findings.sort(key=finding_key)
    return {
        "queried_component_count": len(query_records),
        "queried_excluded_component_count": sum(
            not record[2] for record in query_records
        ),
        "excluded_component_count": excluded_component_count,
        "release_findings": release_findings,
        "non_release_findings": non_release_findings,
    }


def _build_report(
    *,
    components: list[Any],
    scan: dict[str, Any],
    sbom_name: str,
    sbom_sha256: str,
) -> dict[str, Any]:
    release_findings = scan["release_findings"]
    non_release_findings = scan["non_release_findings"]
    return {
        "schema_version": 2,
        "status": "passed" if not release_findings else "failed",
        "scanner": "OSV querybatch",
        "sbom": sbom_name,
        "sbom_sha256": sbom_sha256,
        "component_count": len(components),
        "queried_component_count": scan["queried_component_count"],
        "excluded_component_count": scan["excluded_component_count"],
        "queried_excluded_component_count": scan[
            "queried_excluded_component_count"
        ],
        # Kept as the blocking release count for existing fail-closed callers.
        "vulnerability_count": len(release_findings),
        "blocking_vulnerability_count": len(release_findings),
        "excluded_vulnerability_count": len(non_release_findings),
        "total_vulnerability_count": (
            len(release_findings) + len(non_release_findings)
        ),
        "release_vulnerability_count": len(release_findings),
        "non_release_vulnerability_count": len(non_release_findings),
        "observed_vulnerability_count": (
            len(release_findings) + len(non_release_findings)
        ),
        "vulnerabilities": release_findings,
        "non_release_vulnerabilities": non_release_findings,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sbom", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--api-url", default="https://api.osv.dev/v1/querybatch"
    )
    args = parser.parse_args()

    payload = json.loads(args.sbom.read_text(encoding="utf-8"))
    components = payload.get("components")
    if not isinstance(components, list):
        parser.error("SBOM sem components")

    scan = _scan_components(components, args.api_url)
    release_findings = scan["release_findings"]
    non_release_findings = scan["non_release_findings"]
    report = _build_report(
        components=components,
        scan=scan,
        sbom_name=str(args.sbom.name),
        sbom_sha256=hashlib.sha256(args.sbom.read_bytes()).hexdigest(),
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "status": report["status"],
                "queried_component_count": scan["queried_component_count"],
                "vulnerability_count": len(release_findings),
                "non_release_vulnerability_count": len(non_release_findings),
                "output": str(args.output),
            },
            sort_keys=True,
        )
    )
    return 0 if not release_findings else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (
        OSError,
        ValueError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as exc:
        print(f"OSV scan failed: {exc}", file=sys.stderr)
        raise SystemExit(2) from exc
