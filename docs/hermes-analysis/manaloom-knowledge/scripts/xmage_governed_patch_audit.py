#!/usr/bin/env python3
"""Audit the fetchable, versioned XMage runtime patch without network access."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_CONTRACT = (
    REPO_ROOT
    / "docs/hermes-analysis/XMAGE_GOVERNED_RUNTIME_PATCH_CONTRACT.json"
)
CONTRACT_SCHEMA = "manaloom_xmage_governed_patch_contract_v1_2026-07-30"
EVIDENCE_SCHEMA = "manaloom_xmage_governed_patch_evidence_v1_2026-07-30"
AUDIT_SCHEMA = "manaloom_xmage_governed_patch_audit_v1_2026-07-30"
SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
PATCH_DIFF_HEADER = re.compile(r"^diff --git a/(.+) b/(.+)$")
EXPECTED_POLICY = {
    "upstream_pin_remains_canonical": True,
    "governed_patch_must_be_fetchable": True,
    "governed_patch_parent_must_equal_upstream_pin": True,
    "versioned_patch_must_reproduce_commit_tree": True,
    "complete_git_diff_required": True,
    "every_added_card_must_be_classified": True,
    "catalog_resolution_is_semantic_proof": False,
    "postgresql_is_product_source_of_truth": True,
    "postgresql_reconciliation_must_be_read_only": True,
    "focused_runtime_tests_required": True,
    "runtime_must_publish_patch_identity": True,
    "user_facing_copy_must_be_engine_neutral": True,
}
EXPECTED_PATHS = {
    "Mage.Server/src/main/java/mage/server/TableController.java",
    "Mage.Sets/src/mage/cards/l/LoreholdTheHistorian.java",
    "Mage.Sets/src/mage/sets/SecretsOfStrixhaven.java",
    "Mage.Tests/src/test/java/org/mage/test/cards/abilities/keywords/MiracleTest.java",
    "Mage.Tests/src/test/java/org/mage/test/game/MatchOptionsRuntimeBoundaryTest.java",
    "Mage/src/main/java/mage/abilities/common/MiracleGrantedAbility.java",
    "Mage/src/main/java/mage/abilities/effects/common/cost/MiracleCostModifier.java",
    "Mage/src/main/java/mage/abilities/effects/common/cost/MiracleCostModifierFlat.java",
    "Mage/src/main/java/mage/abilities/keyword/MiracleAbility.java",
    "Mage/src/main/java/mage/game/match/MatchOptions.java",
    "Mage/src/main/java/mage/game/permanent/PermanentCard.java",
    "Mage/src/main/java/mage/game/permanent/PermanentImpl.java",
    "Mage/src/main/java/mage/util/CardUtil.java",
    "Mage/src/main/java/mage/util/functions/MiracleCostModifierCreator.java",
    "Mage/src/main/java/mage/watchers/Watcher.java",
    "Mage/src/main/java/mage/watchers/Watchers.java",
    "Mage/src/main/java/mage/watchers/common/MiracleGrantedWatcher.java",
}


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return value


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def versioned_patch_name_status(path: Path) -> list[tuple[str, str]]:
    """Derive the exact Git name-status surface from a versioned text patch."""

    entries: list[tuple[str, str]] = []
    current_path: str | None = None
    current_status = "M"

    def finish_entry() -> None:
        if current_path is not None:
            entries.append((current_status, current_path))

    for line in path.read_text(encoding="utf-8").splitlines():
        header = PATCH_DIFF_HEADER.fullmatch(line)
        if header is not None:
            finish_entry()
            before_path, after_path = header.groups()
            if before_path != after_path:
                raise ValueError("renamed or mismatched patch paths are forbidden")
            current_path = after_path
            current_status = "M"
            continue
        if current_path is None:
            if line:
                raise ValueError("patch content appeared before the first diff header")
            continue
        if line.startswith(("rename from ", "rename to ", "copy from ", "copy to ")):
            raise ValueError("renames and copies are forbidden in governed patches")
        if line.startswith("deleted file mode "):
            current_status = "D"
        elif line.startswith("new file mode "):
            current_status = "A"

    finish_entry()
    if not entries:
        raise ValueError("versioned patch has no changed paths")
    return entries


def canonical_name_status_sha256(entries: list[tuple[str, str]]) -> str:
    encoded = "".join(
        f"{status}\t{path}\n"
        for status, path in sorted(entries, key=lambda row: row[1])
    )
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def canonical_sorted_paths_sha256(entries: list[tuple[str, str]]) -> str:
    encoded = "".join(
        f"{path}\n" for _, path in sorted(entries, key=lambda row: row[1])
    )
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def safe_repo_path(root: Path, value: object) -> Path | None:
    if not isinstance(value, str) or not value or Path(value).is_absolute():
        return None
    candidate = (root / value).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def _check(
    checks: list[dict[str, Any]],
    check_id: str,
    condition: bool,
    message: str,
    **details: Any,
) -> None:
    checks.append(
        {
            "id": check_id,
            "status": "pass" if condition else "fail",
            "message": message,
            **({"details": details} if details else {}),
        }
    )


def build_report(
    contract: dict[str, Any],
    evidence: dict[str, Any],
    *,
    repo_root: Path = REPO_ROOT,
    evidence_sha256: str,
    require_deployable: bool = False,
) -> dict[str, Any]:
    root = repo_root.resolve()
    checks: list[dict[str, Any]] = []
    active = (
        contract.get("active_patch")
        if isinstance(contract.get("active_patch"), dict)
        else {}
    )
    expected = (
        active.get("expected")
        if isinstance(active.get("expected"), dict)
        else {}
    )
    patch_id = str(active.get("id") or "")
    upstream_pin = str(active.get("upstream_pin") or "")
    patch_commit = str(active.get("patch_commit") or "")

    _check(
        checks,
        "contract_schema",
        contract.get("schema_version") == CONTRACT_SCHEMA,
        "The governed patch contract schema must be exact.",
    )
    _check(
        checks,
        "policy",
        contract.get("policy") == EXPECTED_POLICY,
        "The governed patch policy must preserve every proof boundary.",
    )
    _check(
        checks,
        "identity",
        bool(patch_id)
        and SHA_PATTERN.fullmatch(upstream_pin) is not None
        and SHA_PATTERN.fullmatch(patch_commit) is not None
        and upstream_pin != patch_commit,
        "The patch must identify distinct exact Git commits.",
    )

    upstream_file = safe_repo_path(root, active.get("upstream_pin_file"))
    patch_file = safe_repo_path(root, active.get("patch_commit_file"))
    observed_upstream = ""
    observed_patch = ""
    try:
        observed_upstream = upstream_file.read_text().strip() if upstream_file else ""
        observed_patch = patch_file.read_text().strip() if patch_file else ""
    except OSError:
        pass
    _check(
        checks,
        "source_identity_files",
        observed_upstream == upstream_pin and observed_patch == patch_commit,
        "Runtime identity files must match the governed patch contract.",
        observed_upstream=observed_upstream,
        observed_patch=observed_patch,
    )

    runtime_surface_requirements = {
        "services/xmage-sidecar/src/main/java/com/manaloom/xmage/SidecarMain.java": (
            patch_commit,
            "engine_patch_commit",
            "+patch.",
        ),
        "server/lib/ai/battle_engine_config.dart": (
            patch_commit,
            "XMAGE_EXPECTED_PATCH_COMMIT",
            "engine_patch_commit",
        ),
        "services/xmage-sidecar/Dockerfile": (
            patch_commit,
            "XMAGE_PATCH_TREE",
            "git rev-parse FETCH_HEAD^",
        ),
        "services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh": (
            "XMAGE_PATCH_COMMIT",
            "XMAGE_PATCH_TREE",
            "rev-parse FETCH_HEAD^)",
        ),
        "scripts/manaloom_deploy_battle_sidecars.sh": (
            "xmage_governed_patch_audit.py",
            "--require-deployable",
            "XMAGE_EXPECTED_PATCH_COMMIT",
        ),
        "scripts/manaloom_deploy_backend_image.sh": (
            "XMAGE_EXPECTED_PATCH_COMMIT",
            "engine_patch_commit",
            "+patch.",
        ),
    }
    runtime_surface_failures: list[str] = []
    for relative_path, markers in runtime_surface_requirements.items():
        surface_path = safe_repo_path(root, relative_path)
        try:
            surface_source = (
                surface_path.read_text(encoding="utf-8") if surface_path else ""
            )
        except OSError:
            surface_source = ""
        missing = [marker for marker in markers if marker not in surface_source]
        if missing:
            runtime_surface_failures.append(
                f"{relative_path}:{','.join(missing)}"
            )
    _check(
        checks,
        "runtime_identity_surfaces",
        not runtime_surface_failures,
        "Runtime, backend and deploy surfaces must enforce the exact patch identity.",
        failures=runtime_surface_failures,
    )

    declared_digest = str(active.get("evidence_sha256") or "")
    _check(
        checks,
        "evidence_digest",
        SHA256_PATTERN.fullmatch(declared_digest) is not None
        and declared_digest == evidence_sha256,
        "Evidence must be pinned by an exact SHA-256 digest.",
        expected=declared_digest,
        observed=evidence_sha256,
    )
    _check(
        checks,
        "evidence_identity",
        evidence.get("schema_version") == EVIDENCE_SCHEMA
        and evidence.get("patch_id") == patch_id
        and evidence.get("status") == "pass",
        "Evidence schema, patch id and result must match.",
    )

    source = evidence.get("source") if isinstance(evidence.get("source"), dict) else {}
    _check(
        checks,
        "fetchable_governed_commit",
        source.get("upstream_base_commit") == upstream_pin
        and source.get("governed_repository") == active.get("governed_repository")
        and source.get("patch_commit") == patch_commit
        and source.get("patch_parent") == upstream_pin
        and SHA_PATTERN.fullmatch(str(source.get("patch_tree") or "")) is not None
        and source.get("fetchable") is True
        and source.get("verified_via")
        == "github_git_commit_api_and_fresh_git_fetch",
        "The runtime patch must be fetchable and have the canonical pin as direct parent.",
    )

    delta = (
        evidence.get("exact_delta")
        if isinstance(evidence.get("exact_delta"), dict)
        else {}
    )
    changed_paths = delta.get("changed_paths")
    changed_path_set = (
        {str(value) for value in changed_paths}
        if isinstance(changed_paths, list)
        else set()
    )
    _check(
        checks,
        "complete_git_delta",
        delta.get("audit_mode") == "read_only_local_git_object_diff"
        and delta.get("old_is_direct_parent") is True
        and delta.get("changed_path_count") == expected.get("changed_path_count")
        and delta.get("changed_card_implementation_count")
        == expected.get("changed_card_implementation_count")
        and changed_path_set == EXPECTED_PATHS
        and len(changed_paths or []) == len(EXPECTED_PATHS)
        and all(
            SHA256_PATTERN.fullmatch(str(delta.get(key) or "")) is not None
            for key in (
                "raw_diff_sha256",
                "name_status_sha256",
                "sorted_paths_sha256",
            )
        )
        and delta.get("raw_diff_sha256") == expected.get("raw_diff_sha256")
        and delta.get("name_status_sha256")
        == expected.get("name_status_sha256")
        and delta.get("sorted_paths_sha256")
        == expected.get("sorted_paths_sha256"),
        "The full parent-to-patch Git delta must be digest-pinned and exact.",
    )
    _check(
        checks,
        "added_card_classification",
        delta.get("added_card_implementations") == ["Lorehold, the Historian"]
        and delta.get("unrelated_card_implementations") == [],
        "Every added card must be classified and unrelated cards are forbidden.",
    )

    versioned = (
        evidence.get("versioned_patch")
        if isinstance(evidence.get("versioned_patch"), dict)
        else {}
    )
    versioned_path = safe_repo_path(root, versioned.get("path"))
    versioned_digest = ""
    versioned_entries: list[tuple[str, str]] = []
    versioned_delta_error = ""
    if versioned_path is not None:
        try:
            versioned_digest = file_sha256(versioned_path)
            versioned_entries = versioned_patch_name_status(versioned_path)
        except (OSError, UnicodeError, ValueError) as error:
            versioned_delta_error = str(error)
    _check(
        checks,
        "versioned_patch",
        SHA256_PATTERN.fullmatch(str(versioned.get("sha256") or "")) is not None
        and versioned_digest == versioned.get("sha256")
        and versioned_digest == expected.get("versioned_patch_sha256")
        and versioned.get("applies_to_upstream_base") is True
        and versioned.get("result_tree_matches_governed_commit") is True
        and isinstance(versioned.get("source_commits"), list)
        and len(versioned.get("source_commits")) == 2,
        "The committed runtime tree must be reproduced by the versioned patch.",
        observed_sha256=versioned_digest,
    )
    versioned_path_set = {path for _, path in versioned_entries}
    versioned_name_status_sha256 = (
        canonical_name_status_sha256(versioned_entries)
        if versioned_entries
        else ""
    )
    versioned_sorted_paths_sha256 = (
        canonical_sorted_paths_sha256(versioned_entries)
        if versioned_entries
        else ""
    )
    added_card_paths = {
        path
        for status, path in versioned_entries
        if status == "A"
        and path.startswith("Mage.Sets/src/mage/cards/")
        and path.endswith(".java")
    }
    _check(
        checks,
        "versioned_patch_delta",
        not versioned_delta_error
        and len(versioned_entries) == len(EXPECTED_PATHS)
        and len(versioned_path_set) == len(versioned_entries)
        and versioned_path_set == EXPECTED_PATHS
        and versioned_name_status_sha256 == delta.get("name_status_sha256")
        and versioned_name_status_sha256 == expected.get("name_status_sha256")
        and versioned_sorted_paths_sha256 == delta.get("sorted_paths_sha256")
        and versioned_sorted_paths_sha256 == expected.get("sorted_paths_sha256")
        and added_card_paths
        == {"Mage.Sets/src/mage/cards/l/LoreholdTheHistorian.java"},
        "The committed patch itself must reproduce the classified path and "
        "name-status digests used to authorize deployment.",
        error=versioned_delta_error,
        observed_name_status_sha256=versioned_name_status_sha256,
        observed_sorted_paths_sha256=versioned_sorted_paths_sha256,
        observed_paths=sorted(versioned_path_set),
        observed_added_card_paths=sorted(added_card_paths),
    )

    focused = (
        evidence.get("focused_verification")
        if isinstance(evidence.get("focused_verification"), dict)
        else {}
    )
    focused_path = safe_repo_path(root, focused.get("artifact_path"))
    focused_digest = ""
    focused_artifact: dict[str, Any] = {}
    if focused_path is not None:
        try:
            focused_digest = file_sha256(focused_path)
            focused_artifact = load_json(focused_path)
        except (OSError, ValueError, json.JSONDecodeError):
            pass
    _check(
        checks,
        "focused_runtime_tests",
        focused_digest == focused.get("artifact_sha256")
        and focused_artifact.get("status") == "pass_local_reproduction"
        and focused.get("java_major") == 17
        and focused.get("focused_tests") == expected.get("focused_test_count")
        and focused.get("failures") == 0
        and focused.get("errors") == 0
        and focused.get("skipped") == 0
        and focused.get("result") == "pass",
        "The focused Miracle, Lorehold and runtime-boundary scenarios must pass without skips.",
    )

    postgres = (
        evidence.get("postgresql_product_scope")
        if isinstance(evidence.get("postgresql_product_scope"), dict)
        else {}
    )
    _check(
        checks,
        "postgresql_read_only_scope",
        postgres.get("canonical_wrapper") == "server/bin/with_new_server_pg.sh"
        and postgres.get("transaction_mode") == "read_only"
        and postgres.get("transaction_read_only") is True
        and postgres.get("writes_performed") is False
        and postgres.get("queries_executed") == 1
        and postgres.get("card_name") == "Lorehold, the Historian"
        and postgres.get("printing_match_count")
        == expected.get("postgresql_printing_match_count")
        and postgres.get("distinct_oracle_ids")
        == expected.get("postgresql_distinct_oracle_ids")
        and postgres.get("commander_statuses") == ["legal"]
        and postgres.get("legendary_creature_rows")
        == expected.get("postgresql_legendary_creature_rows")
        and postgres.get("product_scope_status") == "product_in_scope",
        "Product scope must be reconciled through PostgreSQL read-only evidence.",
    )

    runtime_policy = (
        evidence.get("runtime_policy")
        if isinstance(evidence.get("runtime_policy"), dict)
        else {}
    )
    _check(
        checks,
        "runtime_policy",
        runtime_policy
        == {
            "catalog_resolution_is_semantic_proof": False,
            "focused_tests_are_required": True,
            "patch_identity_is_public_in_health_and_replays": True,
            "user_facing_copy_is_engine_neutral": True,
            "fallback_or_card_removal_allowed": False,
        },
        "Runtime provenance and user-facing boundaries must remain exact.",
    )

    qualification = (
        evidence.get("qualification")
        if isinstance(evidence.get("qualification"), dict)
        else {}
    )
    deployment_allowed = (
        qualification.get("status") == "pass"
        and qualification.get("deployment_allowed") is True
        and qualification.get("blocking_reasons") == []
        and qualification.get("remaining_review_required") == 0
        and all(row["status"] == "pass" for row in checks)
    )
    _check(
        checks,
        "qualification",
        deployment_allowed,
        "Deployment permission must be derived from all governed patch checks.",
    )
    if require_deployable:
        _check(
            checks,
            "deployment_qualification",
            deployment_allowed,
            "Strict deployment is blocked until every patch check passes.",
        )

    failures = [row for row in checks if row["status"] == "fail"]
    return {
        "schema_version": AUDIT_SCHEMA,
        "generated_at_utc": datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat(),
        "status": "pass" if not failures else "fail",
        "qualification_status": qualification.get("status"),
        "deployment_allowed": deployment_allowed and not failures,
        "strict_deployment_check_requested": require_deployable,
        "patch": {
            "id": patch_id,
            "upstream_pin": upstream_pin,
            "patch_commit": patch_commit,
            "governed_repository": active.get("governed_repository"),
            "changed_path_count": delta.get("changed_path_count"),
            "focused_test_count": focused.get("focused_tests"),
        },
        "safety": {
            "read_only": True,
            "network_used": False,
            "postgres_queries": 0,
            "postgres_writes": False,
            "source_mutations": False,
        },
        "checks": checks,
        "failures": failures,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--evidence", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--require-deployable", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    contract = load_json(args.contract.resolve())
    active = contract.get("active_patch") or {}
    evidence_path = (
        args.evidence.resolve()
        if args.evidence
        else safe_repo_path(args.repo_root.resolve(), active.get("evidence_path"))
    )
    if evidence_path is None:
        raise SystemExit("Invalid governed patch evidence path.")
    evidence = load_json(evidence_path)
    report = build_report(
        contract,
        evidence,
        repo_root=args.repo_root,
        evidence_sha256=file_sha256(evidence_path),
        require_deployable=args.require_deployable,
    )
    encoded = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
