#!/usr/bin/env python3
"""Contracts for release-only Gradle SBOM and fail-closed OSV classification."""

from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]


def _load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


SBOM = _load_module(
    "manaloom_generate_release_sbom",
    ROOT / "scripts" / "manaloom_generate_release_sbom.py",
)
OSV = _load_module(
    "manaloom_osv_scan_sbom",
    ROOT / "scripts" / "manaloom_osv_scan_sbom.py",
)


def _property(component: dict, name: str) -> str:
    return next(
        item["value"]
        for item in component["properties"]
        if item["name"] == name
    )


def _encode_varint(value: int) -> bytes:
    encoded = bytearray()
    while value >= 0x80:
        encoded.append((value & 0x7F) | 0x80)
        value >>= 7
    encoded.append(value)
    return bytes(encoded)


def _message_field(number: int, value: bytes) -> bytes:
    return _encode_varint((number << 3) | 2) + _encode_varint(len(value)) + value


def _dependency_metadata(coordinates: list[tuple[str, str, str]]) -> bytes:
    payload = bytearray()
    for group, name, version in coordinates:
        maven_library = b"".join(
            (
                _message_field(1, group.encode()),
                _message_field(2, name.encode()),
                _message_field(5, version.encode()),
            )
        )
        library = _message_field(1, maven_library)
        payload.extend(_message_field(1, library))
    return bytes(payload)


class ReleaseSbomScopeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary_directory.cleanup)
        self.temp = Path(self.temporary_directory.name)

    def _components(self, lines: list[str]) -> list[dict]:
        lock = self.temp / "gradle.lockfile"
        lock.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return SBOM._gradle_components(lock)

    def _aab(self, coordinates: list[tuple[str, str, str]]) -> Path:
        aab = self.temp / "app-release.aab"
        with zipfile.ZipFile(aab, "w") as archive:
            archive.writestr(
                SBOM._AAB_DEPENDENCY_METADATA,
                _dependency_metadata(coordinates),
            )
        return aab

    def test_only_exact_release_runtime_token_is_required(self) -> None:
        components = self._components(
            [
                "com.example:runtime:1.0=releaseRuntimeClasspath",
                "com.example:unit-test:1.0=releaseUnitTestRuntimeClasspath",
                "com.example:debug:1.0=debugRuntimeClasspath",
                "com.example:profile:1.0=profileRuntimeClasspath",
                "com.example:tooling:1.0=myreleaseRuntimeClasspath",
            ]
        )
        by_name = {component["name"]: component for component in components}

        self.assertEqual(by_name["runtime"]["scope"], "required")
        for name in ("unit-test", "debug", "profile", "tooling"):
            self.assertEqual(by_name[name]["scope"], "excluded")
            self.assertNotIn(
                "releaseRuntimeClasspath",
                _property(by_name[name], "manaloom:gradle-configurations").split(","),
            )
        self.assertEqual(SBOM._gradle_scope_counts(components), (1, 4))

    def test_gradle_inventory_without_release_runtime_fails_closed(self) -> None:
        components = self._components(
            ["com.example:test-only:1.0=releaseUnitTestRuntimeClasspath"]
        )
        with self.assertRaisesRegex(ValueError, "releaseRuntimeClasspath"):
            SBOM._gradle_scope_counts(components)

    def test_battle_sidecar_supply_chain_is_source_proven(self) -> None:
        git_sha = "f" * 40
        components, inventory = SBOM._battle_sidecar_components(
            ROOT / "services", git_sha=git_sha
        )
        repeated, repeated_inventory = SBOM._battle_sidecar_components(
            ROOT / "services", git_sha=git_sha
        )
        self.assertEqual(components, repeated)
        self.assertEqual(inventory, repeated_inventory)
        self.assertTrue(inventory["included"])
        self.assertEqual(inventory["sidecar_count"], 2)
        self.assertEqual(
            inventory["apt_versions"],
            "unresolved-until-built-image-inspection",
        )

        by_name = {component["name"]: component for component in components}
        xmage_pin = (ROOT / "services/xmage-sidecar/XMAGE_COMMIT").read_text(
            encoding="utf-8"
        ).strip()
        forge_pin = (ROOT / "services/forge-sidecar/FORGE_COMMIT").read_text(
            encoding="utf-8"
        ).strip()
        self.assertEqual(by_name["xmage"]["version"], xmage_pin)
        self.assertEqual(by_name["forge"]["version"], forge_pin)
        self.assertEqual(by_name["xmage"]["licenses"][0]["license"]["id"], "MIT")
        self.assertEqual(
            by_name["forge"]["licenses"][0]["license"]["id"],
            "GPL-3.0-only",
        )
        self.assertIn(xmage_pin, by_name["xmage"]["externalReferences"][0]["url"])
        self.assertIn(forge_pin, by_name["forge"]["externalReferences"][0]["url"])

        xmage_sidecar = by_name["manaloom-xmage-sidecar"]
        forge_sidecar = by_name["manaloom-forge-sidecar"]
        self.assertEqual(
            json.loads(
                _property(xmage_sidecar, "manaloom:apt-package-declarations")
            ),
            {"build": ["git", "unzip"], "runtime": ["unzip"]},
        )
        self.assertEqual(
            json.loads(
                _property(forge_sidecar, "manaloom:apt-package-declarations")
            ),
            {
                "forge-build": ["git"],
                "runtime": [
                    "fontconfig",
                    "libfreetype6",
                    "libx11-6",
                    "libxext6",
                    "libxi6",
                    "libxrender1",
                    "libxtst6",
                    "python3",
                    "xauth",
                    "xvfb",
                ],
            },
        )
        self.assertEqual(
            _property(xmage_sidecar, "manaloom:apt-version-evidence"),
            "unresolved-until-built-image-inspection",
        )

        containers = [
            component for component in components if component["type"] == "container"
        ]
        self.assertEqual(len(containers), 2)
        self.assertTrue(
            all(
                component["hashes"][0]["alg"] == "SHA-256"
                and len(component["hashes"][0]["content"]) == 64
                for component in containers
            )
        )
        self.assertTrue(
            all(
                _property(component, "manaloom:runtime-family") == "java"
                for component in containers
            )
        )

        direct_maven = {
            component["name"]
            for component in components
            if any(
                item.get("name") == "manaloom:dependency-scope"
                and item.get("value") == "xmage-sidecar-direct-runtime"
                for item in component.get("properties", [])
            )
        }
        self.assertEqual(
            direct_maven,
            {"mage-common", "mage-sets", "gson", "sqlite-jdbc", "jsoup"},
        )
        self.assertNotIn("junit-jupiter", direct_maven)

    def test_battle_sidecar_pin_mismatch_fails_closed(self) -> None:
        services = self.temp / "services"
        required = (
            "xmage-sidecar/Dockerfile",
            "xmage-sidecar/XMAGE_COMMIT",
            "xmage-sidecar/pom.xml",
            "forge-sidecar/Dockerfile",
            "forge-sidecar/FORGE_COMMIT",
            "forge-sidecar/SeededForgeMain.java",
            "forge-sidecar/sidecar.py",
        )
        for relative in required:
            destination = services / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / "services" / relative, destination)
        (services / "xmage-sidecar/XMAGE_COMMIT").write_text(
            "0" * 40 + "\n", encoding="utf-8"
        )

        with self.assertRaisesRegex(ValueError, "diverge"):
            SBOM._battle_sidecar_components(services, git_sha="f" * 40)

    def test_duplicate_gradle_coordinate_cannot_override_release_scope(self) -> None:
        with self.assertRaisesRegex(ValueError, "coordenada Gradle duplicada"):
            self._components(
                [
                    "com.example:vulnerable:1.0=releaseRuntimeClasspath",
                    "com.example:vulnerable:1.0=debugRuntimeClasspath",
                ]
            )
        required = {
            "bom-ref": "pkg:maven/com.example/vulnerable@1.0",
            "scope": "required",
        }
        excluded = {**required, "scope": "excluded"}
        with self.assertRaisesRegex(ValueError, "mesmo bom-ref"):
            SBOM._deduplicate([required, excluded])

    def test_aab_dependency_metadata_matches_gradle_bidirectionally(self) -> None:
        components = self._components(
            [
                "com.example:one:1.0=releaseRuntimeClasspath",
                "com.example:two:2.0=debugRuntimeClasspath,releaseRuntimeClasspath",
                "com.example:debug-only:3.0=debugRuntimeClasspath",
            ]
        )
        aab = self._aab(
            [("com.example", "one", "1.0"), ("com.example", "two", "2.0")]
        )
        self.assertEqual(SBOM._validate_gradle_aab_parity(components, aab), 2)

        missing = self._aab([("com.example", "one", "1.0")])
        with self.assertRaisesRegex(ValueError, "diverge"):
            SBOM._validate_gradle_aab_parity(components, missing)

        unexpected = self._aab(
            [
                ("com.example", "one", "1.0"),
                ("com.example", "two", "2.0"),
                ("com.example", "unexpected", "9.0"),
            ]
        )
        with self.assertRaisesRegex(ValueError, "diverge"):
            SBOM._validate_gradle_aab_parity(components, unexpected)

    def test_non_release_vulnerabilities_are_reported_but_do_not_block(self) -> None:
        components = self._components(
            [
                "com.example:runtime:1.0=releaseRuntimeClasspath",
                "com.example:debug-only:1.0=debugRuntimeClasspath",
                "com.example:unit-test:1.0=releaseUnitTestRuntimeClasspath",
            ]
        )

        def query(_url: str, queries: list[dict]) -> list[dict]:
            return [
                {
                    "vulns": (
                        [{"id": f"OSV-{item['package']['name']}"}]
                        if item["package"]["name"] != "com.example:runtime"
                        else []
                    )
                }
                for item in queries
            ]

        with mock.patch.object(OSV, "_query_batch", side_effect=query):
            scan = OSV._scan_components(components, "https://osv.invalid")
        report = OSV._build_report(
            components=components,
            scan=scan,
            sbom_name="fixture.cdx.json",
            sbom_sha256="0" * 64,
        )

        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["vulnerability_count"], 0)
        self.assertEqual(report["blocking_vulnerability_count"], 0)
        self.assertEqual(report["excluded_vulnerability_count"], 2)
        self.assertEqual(report["total_vulnerability_count"], 2)
        self.assertEqual(report["release_vulnerability_count"], 0)
        self.assertEqual(report["non_release_vulnerability_count"], 2)
        self.assertEqual(report["observed_vulnerability_count"], 2)
        self.assertEqual(len(report["non_release_vulnerabilities"]), 2)
        self.assertTrue(
            all(
                finding["exclusion_evidence"]["kind"]
                == "gradle-lock-configuration-membership"
                for finding in report["non_release_vulnerabilities"]
            )
        )

    def test_mutating_excluded_component_into_release_makes_finding_blocking(self) -> None:
        excluded = self._components(
            ["com.example:vulnerable:1.0=debugRuntimeClasspath"]
        )[0]
        promoted = copy.deepcopy(excluded)
        promoted["scope"] = "required"
        for item in promoted["properties"]:
            if item["name"] == "manaloom:dependency-scope":
                item["value"] = "android-release-runtime"
            if item["name"] == "manaloom:gradle-configurations":
                item["value"] = "debugRuntimeClasspath,releaseRuntimeClasspath"

        with mock.patch.object(
            OSV,
            "_query_batch",
            return_value=[[{"vulns": [{"id": "OSV-BLOCK"}]}][0]],
        ):
            scan = OSV._scan_components([promoted], "https://osv.invalid")
        report = OSV._build_report(
            components=[promoted],
            scan=scan,
            sbom_name="fixture.cdx.json",
            sbom_sha256="0" * 64,
        )
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["blocking_vulnerability_count"], 1)
        self.assertEqual(report["total_vulnerability_count"], 1)
        self.assertEqual(report["release_vulnerability_count"], 1)
        self.assertEqual(report["non_release_vulnerability_count"], 0)

    def test_exclusions_and_unqueryable_components_fail_closed(self) -> None:
        excluded = self._components(
            ["com.example:debug-only:1.0=debugRuntimeClasspath"]
        )[0]
        tampered = copy.deepcopy(excluded)
        tampered["properties"] = [
            item
            for item in tampered["properties"]
            if item["name"] != "manaloom:release-membership-evidence"
        ]
        with self.assertRaisesRegex(ValueError, "prova completa"):
            OSV._scan_components([tampered], "https://osv.invalid")

        required = self._components(
            ["com.example:runtime:1.0=releaseRuntimeClasspath"]
        )[0]
        for mutation in (
            {**required, "purl": ""},
            {**required, "purl": "pkg:generic/runtime@1.0"},
            {**required, "version": ""},
        ):
            with self.subTest(mutation=mutation):
                with self.assertRaises(ValueError):
                    OSV._scan_components([mutation], "https://osv.invalid")

        with self.assertRaisesRegex(ValueError, "nao e objeto"):
            OSV._scan_components(["not-an-object"], "https://osv.invalid")

    def test_malformed_osv_responses_fail_closed(self) -> None:
        component = self._components(
            ["com.example:runtime:1.0=releaseRuntimeClasspath"]
        )[0]
        invalid_results = (
            ["not-an-object"],
            [{"vulns": "not-a-list"}],
            [{"vulns": ["not-an-object"]}],
            [{"vulns": [{}]}],
            [{"vulns": [{"id": "OSV-1", "aliases": "not-a-list"}]}],
        )
        for response in invalid_results:
            with self.subTest(response=response):
                with mock.patch.object(OSV, "_query_batch", return_value=response):
                    with self.assertRaises(ValueError):
                        OSV._scan_components([component], "https://osv.invalid")


if __name__ == "__main__":
    unittest.main()
