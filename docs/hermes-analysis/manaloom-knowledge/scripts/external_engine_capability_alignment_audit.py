#!/usr/bin/env python3
"""Audit how ManaLoom consumes pinned XMage and Forge capabilities.

The default mode is network-free and read-only. Optional pinned source roots
add source inventory proof without changing either checkout or any database.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_CONTRACT = REPO_ROOT / "docs/hermes-analysis/EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json"
SCHEMA_VERSION = "manaloom_external_engine_capability_audit_v1_2026-07-22"
CONTRACT_SCHEMA_VERSION = "manaloom_external_engine_capabilities_v1_2026-07-22"
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")

ALLOWED_DISPOSITIONS = {
    "adopted_runtime",
    "adopted_runtime_limited",
    "adopted_adapter",
    "adopted_adapter_limited",
    "adopted_governance",
    "adopted_diagnostic",
    "adopted_focused_reference",
    "adopted_reference_only",
    "evaluated_not_adopted",
    "evaluated_out_of_scope",
    "explicitly_rejected",
}
ADOPTED_DISPOSITIONS = {
    value for value in ALLOWED_DISPOSITIONS if value.startswith("adopted_")
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_contract(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("capability contract must be a JSON object")
    return payload


def _check(
    checks: list[dict[str, Any]],
    check_id: str,
    condition: bool,
    message: str,
    *,
    details: dict[str, Any] | None = None,
) -> None:
    checks.append(
        {
            "id": check_id,
            "status": "pass" if condition else "fail",
            "message": message,
            **({"details": details} if details else {}),
        }
    )


def _safe_repo_path(repo_root: Path, relative_path: str) -> Path | None:
    if not relative_path or Path(relative_path).is_absolute():
        return None
    candidate = (repo_root / relative_path).resolve()
    try:
        candidate.relative_to(repo_root.resolve())
    except ValueError:
        return None
    return candidate


def _validate_engine_contracts(
    contract: dict[str, Any],
    repo_root: Path,
    checks: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    raw_engines = contract.get("engines")
    engines = raw_engines if isinstance(raw_engines, list) else []
    engine_map = {
        str(engine.get("id")): engine
        for engine in engines
        if isinstance(engine, dict) and engine.get("id")
    }
    _check(
        checks,
        "engine_ids",
        set(engine_map) == {"xmage", "forge"} and len(engines) == 2,
        "Contract must define exactly the canonical XMage and Forge engines.",
        details={"observed": sorted(engine_map)},
    )

    expected = {
        "xmage": {
            "repository": "https://github.com/magefree/mage",
            "license": "MIT",
            "boundary": "isolated_sidecar_api",
        },
        "forge": {
            "repository": "https://github.com/Card-Forge/forge",
            "license": "GPL-3.0-only",
            "boundary": "isolated_process_api_only_no_backend_source_copy",
        },
    }
    for engine_id, expected_values in expected.items():
        engine = engine_map.get(engine_id, {})
        _check(
            checks,
            f"{engine_id}_repository_license_boundary",
            engine.get("official_repository") == expected_values["repository"]
            and engine.get("license") == expected_values["license"]
            and engine.get("integration_boundary") == expected_values["boundary"],
            f"{engine_id} repository, license and process boundary must remain explicit.",
            details={
                "repository": engine.get("official_repository"),
                "license": engine.get("license"),
                "integration_boundary": engine.get("integration_boundary"),
            },
        )
        pin_relative = str(engine.get("canonical_pin_file") or "")
        pin_path = _safe_repo_path(repo_root, pin_relative)
        try:
            pin = pin_path.read_text(encoding="utf-8").strip() if pin_path else ""
        except OSError:
            pin = ""
        engine["canonical_pin"] = pin or None
        _check(
            checks,
            f"{engine_id}_canonical_pin",
            bool(SHA_PATTERN.fullmatch(pin)),
            f"{engine_id} canonical pin file must contain one lowercase 40-character SHA.",
            details={"path": pin_relative, "pin": pin or None},
        )
    return engine_map


def _validate_capabilities(
    contract: dict[str, Any],
    repo_root: Path,
    engine_map: dict[str, dict[str, Any]],
    checks: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    raw_capabilities = contract.get("capabilities")
    capabilities = raw_capabilities if isinstance(raw_capabilities, list) else []
    capability_rows = [row for row in capabilities if isinstance(row, dict)]
    ids = [str(row.get("id") or "") for row in capability_rows]
    duplicates = sorted({value for value in ids if value and ids.count(value) > 1})
    _check(
        checks,
        "capability_ids_unique",
        len(capability_rows) == len(capabilities)
        and all(ids)
        and not duplicates,
        "Every capability must be an object with a unique non-empty id.",
        details={"duplicates": duplicates},
    )

    required = contract.get("required_capability_ids")
    required_ids = {
        str(value) for value in required if value
    } if isinstance(required, list) else set()
    observed_ids = set(ids)
    _check(
        checks,
        "required_capability_coverage",
        required_ids == observed_ids,
        "Every required engine capability must have exactly one disposition.",
        details={
            "missing": sorted(required_ids - observed_ids),
            "undeclared": sorted(observed_ids - required_ids),
        },
    )

    known_engines = set(engine_map)
    for row in capability_rows:
        capability_id = str(row.get("id") or "unknown")
        engines = row.get("engines")
        engine_ids = {
            str(value) for value in engines if value
        } if isinstance(engines, list) else set()
        disposition = str(row.get("disposition") or "")
        source_surfaces = row.get("source_surfaces")
        rationale = str(row.get("rationale") or "").strip()
        product_evidence = row.get("product_evidence")
        test_evidence = row.get("test_evidence")
        product_paths = product_evidence if isinstance(product_evidence, list) else []
        test_paths = test_evidence if isinstance(test_evidence, list) else []

        _check(
            checks,
            f"capability:{capability_id}:classification",
            bool(engine_ids)
            and engine_ids <= known_engines
            and disposition in ALLOWED_DISPOSITIONS
            and bool(str(row.get("relevance") or "").strip())
            and bool(source_surfaces)
            and bool(rationale),
            f"Capability {capability_id} must classify engines, relevance, disposition, source and rationale.",
            details={
                "engines": sorted(engine_ids),
                "disposition": disposition,
            },
        )

        adopted = disposition in ADOPTED_DISPOSITIONS
        _check(
            checks,
            f"capability:{capability_id}:evidence_shape",
            (adopted and bool(product_paths) and bool(test_paths))
            or (not adopted and not product_paths and not test_paths),
            (
                f"Adopted capability {capability_id} needs product and test evidence; "
                "non-adopted capabilities must not imply implementation evidence."
            ),
        )
        for evidence_kind, paths in (
            ("product", product_paths),
            ("test", test_paths),
        ):
            missing: list[str] = []
            unsafe: list[str] = []
            for relative_path in paths:
                candidate = _safe_repo_path(repo_root, str(relative_path))
                if candidate is None:
                    unsafe.append(str(relative_path))
                elif not candidate.exists():
                    missing.append(str(relative_path))
            _check(
                checks,
                f"capability:{capability_id}:{evidence_kind}_paths",
                not missing and not unsafe,
                f"Capability {capability_id} {evidence_kind} evidence must resolve inside the repository.",
                details={"missing": missing, "unsafe": unsafe},
            )
    return capability_rows


def _validate_import_boundaries(
    repo_root: Path,
    engine_map: dict[str, dict[str, Any]],
    checks: list[dict[str, Any]],
) -> None:
    import_pattern = re.compile(r"(?m)^\s*import\s+(mage|forge)\.")
    violations: dict[str, list[str]] = {"xmage": [], "forge": []}
    skipped_parts = {".git", ".dart_tool", "build", ".gradle"}
    for path in repo_root.rglob("*.java"):
        if any(part in skipped_parts for part in path.parts):
            continue
        try:
            source = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        imported = {match.group(1) for match in import_pattern.finditer(source)}
        if not imported:
            continue
        relative = path.relative_to(repo_root).as_posix()
        for package in imported:
            engine_id = "xmage" if package == "mage" else "forge"
            allowed_root = str(engine_map.get(engine_id, {}).get("allowed_java_root") or "")
            if not allowed_root or not (
                relative == allowed_root or relative.startswith(f"{allowed_root}/")
            ):
                violations[engine_id].append(relative)

    for engine_id in ("xmage", "forge"):
        _check(
            checks,
            f"{engine_id}_java_import_boundary",
            not violations[engine_id],
            f"{engine_id} Java dependencies must remain inside its isolated sidecar.",
            details={"violations": sorted(violations[engine_id])},
        )


def _validate_local_source_policy(
    contract: dict[str, Any],
    repo_root: Path,
    checks: list[dict[str, Any]],
) -> None:
    policy = contract.get("policy") if isinstance(contract.get("policy"), dict) else {}
    source_policy = (
        policy.get("local_source_checkout_policy")
        if isinstance(policy.get("local_source_checkout_policy"), dict)
        else {}
    )
    expected = {
        "root_argument": "--xmage-root",
        "environment_fallback": "MANALOOM_XMAGE_SOURCE_ROOT",
        "requires_canonical_pin": True,
        "requires_clean_checkout": True,
        "forbid_machine_specific_defaults": True,
        "shared_resolver": (
            "docs/hermes-analysis/manaloom-knowledge/scripts/"
            "external_engine_source_contract.py"
        ),
    }
    resolver = _safe_repo_path(repo_root, str(source_policy.get("shared_resolver") or ""))
    _check(
        checks,
        "local_source_checkout_policy",
        source_policy == expected and resolver is not None and resolver.is_file(),
        "Local engine source must use the shared explicit, clean, canonical-pin resolver.",
        details={"observed": source_policy},
    )

    roots = (
        repo_root / "scripts",
        repo_root / "server",
        repo_root / "services",
        repo_root / "docs/hermes-analysis/manaloom-knowledge/scripts",
    )
    suffixes = {".py", ".sh", ".dart", ".java"}
    machine_home_prefix = "/" + "Users/"
    legacy_xmage_path = "Downloads/" + "mage-master"
    violations: list[str] = []
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in suffixes:
                continue
            relative = path.relative_to(repo_root)
            if path.name.startswith("test_") or "test" in relative.parts:
                continue
            try:
                source = path.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            if machine_home_prefix in source or legacy_xmage_path in source:
                violations.append(relative.as_posix())
    _check(
        checks,
        "no_machine_specific_operational_defaults",
        not violations,
        "Operational scripts must not contain machine-specific source or artifact defaults.",
        details={"violations": sorted(violations)},
    )


def tracked_source_inventory(source_root: Path, engine_id: str) -> dict[str, Any]:
    try:
        revision = subprocess.run(
            ["git", "-C", str(source_root), "rev-parse", "HEAD"],
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
        tree = subprocess.run(
            ["git", "-C", str(source_root), "ls-tree", "-r", "--name-only", "HEAD"],
            check=False,
            capture_output=True,
            text=True,
            timeout=60,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return {
            "status": "fail",
            "error": f"git_source_inspection_failed:{exc.__class__.__name__}",
        }
    if revision.returncode != 0 or tree.returncode != 0:
        return {
            "status": "fail",
            "error": "source_root_is_not_a_readable_git_checkout",
            "stderr": (revision.stderr or tree.stderr).strip()[:500],
        }
    paths = [line.strip() for line in tree.stdout.splitlines() if line.strip()]
    java_tests = sum(
        path.endswith(".java") and "/src/test/" in path for path in paths
    )
    if engine_id == "xmage":
        metrics = {
            "card_implementations": sum(
                path.startswith("Mage.Sets/src/mage/cards/") and path.endswith(".java")
                for path in paths
            ),
            "java_tests": sum(
                path.startswith("Mage.Tests/src/test/") and path.endswith(".java")
                for path in paths
            ),
            "java_files": sum(path.endswith(".java") for path in paths),
        }
    else:
        metrics = {
            "card_scripts": sum(
                path.startswith("forge-gui/res/cardsfolder/") and path.endswith(".txt")
                for path in paths
            ),
            "java_tests": java_tests,
            "java_files": sum(path.endswith(".java") for path in paths),
        }
    return {
        "status": "pass",
        "source_root": str(source_root),
        "commit": revision.stdout.strip(),
        "metrics": metrics,
    }


def _validate_source_roots(
    source_roots: dict[str, Path | None],
    engine_map: dict[str, dict[str, Any]],
    checks: list[dict[str, Any]],
    *,
    require_sources: bool,
) -> dict[str, Any]:
    source_report: dict[str, Any] = {}
    for engine_id in ("xmage", "forge"):
        source_root = source_roots.get(engine_id)
        if source_root is None:
            source_report[engine_id] = {"status": "not_requested"}
            _check(
                checks,
                f"{engine_id}_source_inventory_requested",
                not require_sources,
                f"{engine_id} pinned source inventory is optional unless --require-sources is set.",
            )
            continue
        inventory = tracked_source_inventory(source_root.resolve(), engine_id)
        source_report[engine_id] = inventory
        expected_pin = str(engine_map.get(engine_id, {}).get("canonical_pin") or "")
        minimums = engine_map.get(engine_id, {}).get("source_inventory_minimums")
        minimums = minimums if isinstance(minimums, dict) else {}
        metrics = inventory.get("metrics") if isinstance(inventory.get("metrics"), dict) else {}
        minimums_pass = all(
            isinstance(metrics.get(key), int) and metrics.get(key, 0) >= int(value)
            for key, value in minimums.items()
        )
        _check(
            checks,
            f"{engine_id}_source_inventory",
            inventory.get("status") == "pass"
            and inventory.get("commit") == expected_pin
            and minimums_pass,
            f"{engine_id} source inventory must be at the runtime pin and meet the declared corpus floor.",
            details={
                "expected_pin": expected_pin,
                "observed_pin": inventory.get("commit"),
                "minimums": minimums,
                "metrics": metrics,
                "error": inventory.get("error"),
            },
        )
    return source_report


def build_report(
    contract: dict[str, Any],
    *,
    repo_root: Path = REPO_ROOT,
    xmage_root: Path | None = None,
    forge_root: Path | None = None,
    require_sources: bool = False,
) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    checks: list[dict[str, Any]] = []
    _check(
        checks,
        "contract_schema",
        contract.get("schema_version") == CONTRACT_SCHEMA_VERSION,
        f"Capability contract schema must be {CONTRACT_SCHEMA_VERSION}.",
        details={"observed": contract.get("schema_version")},
    )
    policy = contract.get("policy") if isinstance(contract.get("policy"), dict) else {}
    _check(
        checks,
        "frozen_product_policy",
        policy.get("product_source_of_truth") == "postgresql_backend"
        and policy.get("rules_execution_order")
        == ["xmage", "forge", "native_explicit_residual"]
        and policy.get("card_level_learning_requires_typed_natural_event") is True
        and policy.get("external_source_code_is_never_direct_postgresql_truth") is True
        and policy.get("unclassified_capabilities_allowed") is False,
        "The frozen PostgreSQL, execution-order and learning boundaries must not drift.",
    )
    engine_map = _validate_engine_contracts(contract, repo_root, checks)
    capabilities = _validate_capabilities(contract, repo_root, engine_map, checks)
    _validate_import_boundaries(repo_root, engine_map, checks)
    _validate_local_source_policy(contract, repo_root, checks)
    sources = _validate_source_roots(
        {"xmage": xmage_root, "forge": forge_root},
        engine_map,
        checks,
        require_sources=require_sources,
    )

    failed = [row for row in checks if row["status"] == "fail"]
    dispositions: dict[str, int] = {}
    for row in capabilities:
        disposition = str(row.get("disposition") or "unknown")
        dispositions[disposition] = dispositions.get(disposition, 0) + 1
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at_utc": utc_now(),
        "status": "pass" if not failed else "fail",
        "safety": {
            "read_only": True,
            "network_used": False,
            "postgres_writes": False,
            "sqlite_writes": False,
            "source_mutations": False,
        },
        "summary": {
            "check_count": len(checks),
            "passed_check_count": len(checks) - len(failed),
            "failed_check_count": len(failed),
            "engine_count": len(engine_map),
            "capability_count": len(capabilities),
            "adopted_capability_count": sum(
                row.get("disposition") in ADOPTED_DISPOSITIONS
                for row in capabilities
            ),
            "dispositions": dict(sorted(dispositions.items())),
        },
        "engines": list(engine_map.values()),
        "source_inventory": sources,
        "capabilities": capabilities,
        "checks": checks,
        "failures": failed,
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report.get("summary") or {}
    lines = [
        "# External Engine Capability Alignment Audit",
        "",
        f"- Generated UTC: `{report.get('generated_at_utc')}`",
        f"- Status: `{report.get('status')}`",
        f"- Checks: `{summary.get('passed_check_count')}/{summary.get('check_count')}`",
        f"- Capabilities: `{summary.get('capability_count')}`",
        f"- Adopted: `{summary.get('adopted_capability_count')}`",
        "",
        "## Engines",
        "",
        "| Engine | Pin | License | Runtime role | Source inspection |",
        "| --- | --- | --- | --- | --- |",
    ]
    source_inventory = report.get("source_inventory") or {}
    for engine in report.get("engines") or []:
        engine_id = engine.get("id")
        source = source_inventory.get(engine_id) or {}
        lines.append(
            f"| `{engine_id}` | `{engine.get('canonical_pin')}` | `{engine.get('license')}` | "
            f"`{engine.get('runtime_role')}` | `{source.get('status')}` |"
        )
    lines.extend(
        [
            "",
            "## Capability Decisions",
            "",
            "| Capability | Relevance | Disposition | Engines |",
            "| --- | --- | --- | --- |",
        ]
    )
    for row in report.get("capabilities") or []:
        lines.append(
            f"| `{row.get('id')}` | `{row.get('relevance')}` | `{row.get('disposition')}` | "
            f"`{','.join(row.get('engines') or [])}` |"
        )
    if report.get("failures"):
        lines.extend(["", "## Failures", ""])
        for failure in report["failures"]:
            lines.append(f"- `{failure.get('id')}`: {failure.get('message')}")
    lines.append("")
    return "\n".join(lines)


def write_outputs(report: dict[str, Any], output_prefix: Path) -> None:
    output_prefix.parent.mkdir(parents=True, exist_ok=True)
    output_prefix.with_suffix(".json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    output_prefix.with_suffix(".md").write_text(
        render_markdown(report),
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--xmage-root", type=Path)
    parser.add_argument("--forge-root", type=Path)
    parser.add_argument("--require-sources", action="store_true")
    parser.add_argument("--output-prefix", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        contract = load_contract(args.contract)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"external_engine_capability_contract_error={exc}")
        return 2
    report = build_report(
        contract,
        repo_root=args.repo_root,
        xmage_root=args.xmage_root,
        forge_root=args.forge_root,
        require_sources=args.require_sources,
    )
    if args.output_prefix:
        write_outputs(report, args.output_prefix)
        print(f"json_output={args.output_prefix.with_suffix('.json')}")
        print(f"markdown_output={args.output_prefix.with_suffix('.md')}")
    print(f"status={report['status']}")
    print(
        "checks="
        f"{report['summary']['passed_check_count']}/{report['summary']['check_count']}"
    )
    print(f"capabilities={report['summary']['capability_count']}")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
