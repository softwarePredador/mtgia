#!/usr/bin/env python3
"""Audit retained ManaLoom report data artifacts.

The product truth is PostgreSQL/backend plus executable runtime code. The
`master_optimizer_reports` tree is not a durable data lake. This audit keeps
that boundary explicit by flagging raw report artifacts that are tracked but not
referenced by current scripts/contracts, and by surfacing ignored local
artifacts left on disk.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DOCS_DIR = REPO_ROOT / "docs" / "hermes-analysis"
REPORT_DIR = DOCS_DIR / "master_optimizer_reports"
DEDUPLICATED_REPORT_DIR = DOCS_DIR / "deduplicated-report-content"
DEDUPLICATED_REPORT_MANIFEST_FILE = DOCS_DIR / "DEDUPLICATED_REPORTS_2026-07-23.json"
ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE = DOCS_DIR / "ARCHIVED_LARGE_ARTIFACTS.md"

REPORT_PATH_PREFIX = "docs/hermes-analysis/master_optimizer_reports/"
DEDUPLICATED_REPORT_PATH_PREFIX = "docs/hermes-analysis/deduplicated-report-content/"

RAW_REPORT_SUFFIXES = {".json", ".jsonl", ".sql", ".out", ".txt", ".db", ".log", ".tsv", ".err"}
TRACKED_EVIDENCE_SUFFIXES = RAW_REPORT_SUFFIXES.union({".md"})
REFERENCE_SUFFIXES = TRACKED_EVIDENCE_SUFFIXES.union({".csv"})

SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
RECOVERY_COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
ARCHIVED_ARTIFACT_ROW_RE = re.compile(
    r"^\| `(?P<path>[^`]+)` \| (?P<bytes>[\d,]+) \| "
    r"`(?P<sha256>[0-9a-f]{64})` \| (?P<replacement>.+) \|$",
    re.MULTILINE,
)

SQL_PACKAGE_ROLES = frozenset({"precheck", "apply", "postcheck", "rollback"})
SQL_PACKAGE_ROLE_RE = re.compile(
    r"^(?P<prefix>.+)_(?P<role>precheck|apply|postcheck|rollback)\.sql$"
)

ACTIVE_REFERENCE_ROOTS = (
    DOCS_DIR / "manaloom-knowledge" / "scripts",
    REPO_ROOT / "scripts",
    REPO_ROOT / "server" / "bin",
    REPO_ROOT / "server" / "lib",
    REPO_ROOT / "server" / "routes",
    REPO_ROOT / "server" / "test",
    REPO_ROOT / "app" / "lib",
    REPO_ROOT / "app" / "test",
    REPO_ROOT / "app" / "integration_test",
    REPO_ROOT / ".github",
)

RETENTION_MANIFEST_FILE = REPORT_DIR / "README.md"
RETENTION_JUSTIFICATION_PREFIX = "Retention justification:"
PENDING_LOCAL_HASH_LABEL = "pending-local-sha256:"

CURRENT_CONTRACT_FILES = (
    DOCS_DIR / "README.md",
    DOCS_DIR / "MANALOOM_OPERATIONAL_LOOKUP_GUIDE_2026-06-30.md",
    DOCS_DIR / "MANALOOM_FAILURE_MODE_VALIDATION_MATRIX_2026-06-30.md",
    DOCS_DIR / "APP_AI_KNOWLEDGE_BRIDGE_CONTRACT_2026-07-06.md",
    DOCS_DIR / "NEW_SERVER_POSTGRES_WORKFLOW_2026-07-06.md",
    DOCS_DIR / "DATA_FIELD_ALIAS_CONTRACT_2026-06-30.md",
    DOCS_DIR / "BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md",
    DOCS_DIR / "GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md",
    DOCS_DIR / "EXTERNAL_BATTLE_EXECUTION_CONTRACT.md",
    DOCS_DIR / "EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json",
    DOCS_DIR / "COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md",
    DOCS_DIR / "MANALOOM_DEEP_AI_DATA_COHERENCE_VALIDATION_2026-07-06.md",
    DOCS_DIR / "RULE_COMPETING_SCOPE_CLEANUP_EVIDENCE_2026-07-14.md",
    DOCS_DIR / "PROJECT_REVALIDATION_AND_GLOBAL_QUEUE_2026-07-14.md",
)

HISTORICAL_REFERENCE_FILES = (
    DOCS_DIR / "XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md",
)

ARCHIVED_EVIDENCE_REFERENCE_FILES = (
    DOCS_DIR / "archive" / "HERMES_ANALYSIS_README_SNAPSHOT_2026-07-23.md",
    DOCS_DIR
    / "archive"
    / "COMMANDER_DECKBUILDING_EVIDENCE_LOG_2026-06-29_TO_2026-07-15.md",
    DOCS_DIR
    / "archive"
    / "XMAGE_NATIVE_ADAPTATION_EVIDENCE_LOG_2026-06-29_TO_2026-07-15.md",
)


@dataclass(frozen=True)
class Check:
    name: str
    status: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return {"name": self.name, "status": self.status, "detail": self.detail}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def git_ls_files(path: Path) -> list[Path]:
    output = subprocess.check_output(
        ["git", "-C", str(REPO_ROOT), "ls-files", str(path.relative_to(REPO_ROOT))],
        text=True,
    )
    return [REPO_ROOT / line for line in output.splitlines() if line.strip()]


def git_tree_blobs(
    commit: str,
    pathspecs: list[str],
) -> tuple[dict[str, str], str | None]:
    """Return repository-path to blob-id mappings from a historical tree."""

    try:
        output = subprocess.check_output(
            [
                "git",
                "-C",
                str(REPO_ROOT),
                "ls-tree",
                "-r",
                "-z",
                "--full-tree",
                commit,
                "--",
                *pathspecs,
            ],
            stderr=subprocess.STDOUT,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        detail = getattr(error, "output", b"")
        if isinstance(detail, bytes):
            detail = detail.decode("utf-8", errors="replace")
        return {}, f"cannot read recovery tree {commit}: {str(detail).strip() or error}"

    result: dict[str, str] = {}
    for entry in output.split(b"\0"):
        if not entry:
            continue
        metadata, separator, encoded_path = entry.partition(b"\t")
        fields = metadata.split()
        if not separator or len(fields) != 3 or fields[1] != b"blob":
            continue
        result[encoded_path.decode("utf-8", errors="surrogateescape")] = fields[
            2
        ].decode("ascii")
    return result, None


def git_blob_payload(blob_id: str) -> tuple[bytes | None, str | None]:
    try:
        return (
            subprocess.check_output(
                ["git", "-C", str(REPO_ROOT), "cat-file", "blob", blob_id],
                stderr=subprocess.STDOUT,
            ),
            None,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        detail = getattr(error, "output", b"")
        if isinstance(detail, bytes):
            detail = detail.decode("utf-8", errors="replace")
        return None, f"cannot read recovery blob {blob_id}: {str(detail).strip() or error}"


def sha256_payload(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def tracked_relative_paths(path: Path) -> set[str]:
    return {rel(item) for item in git_ls_files(path)}


def manifest_tracking_status(path: Path) -> str:
    return (
        "tracked"
        if rel(path) in tracked_relative_paths(path)
        else "validated_untracked_index"
    )


def _append_error(bucket: list[str], message: str) -> None:
    if message not in bucket:
        bucket.append(message)


def validate_deduplicated_report_retention() -> dict[str, Any]:
    """Validate the deduplication index, canonical bytes, and recovery tree.

    The canonical directory is allowed to be untracked during local Sprint 9
    work only because every file is independently sealed by the manifest. An
    extra, missing, renamed, or modified file therefore fails this audit.
    """

    manifest_errors: list[str] = []
    canonical_errors: list[str] = []
    recovery_errors: list[str] = []
    result: dict[str, Any] = {
        "path": rel(DEDUPLICATED_REPORT_MANIFEST_FILE),
        "canonical_directory": rel(DEDUPLICATED_REPORT_DIR),
        "manifest_tracking_status": manifest_tracking_status(
            DEDUPLICATED_REPORT_MANIFEST_FILE
        ),
        "schema_version": None,
        "policy": None,
        "recovery_commit": None,
        "group_count": 0,
        "canonical_file_count": 0,
        "tracked_canonical_file_count": 0,
        "content_sealed_untracked_canonical_file_count": 0,
        "removed_file_count": 0,
        "recovered_removed_file_count": 0,
        "reclaimed_checkout_bytes": 0,
        "canonical_files": [],
        "manifest_errors": manifest_errors,
        "canonical_errors": canonical_errors,
        "recovery_errors": recovery_errors,
    }

    if not DEDUPLICATED_REPORT_MANIFEST_FILE.is_file():
        manifest_errors.append(
            f"missing manifest {rel(DEDUPLICATED_REPORT_MANIFEST_FILE)}"
        )
        result["status"] = "fail"
        return result

    try:
        document = json.loads(
            DEDUPLICATED_REPORT_MANIFEST_FILE.read_text(encoding="utf-8")
        )
    except (OSError, json.JSONDecodeError) as error:
        manifest_errors.append(f"cannot parse deduplication manifest: {error}")
        result["status"] = "fail"
        return result

    if not isinstance(document, dict):
        manifest_errors.append("deduplication manifest root must be an object")
        result["status"] = "fail"
        return result

    schema_version = document.get("schema_version")
    policy = document.get("policy")
    recovery_commit = document.get("recovery_commit")
    groups = document.get("groups")
    result.update(
        {
            "schema_version": schema_version,
            "policy": policy,
            "recovery_commit": recovery_commit,
        }
    )

    if schema_version != 1:
        manifest_errors.append(f"schema_version must be 1, found {schema_version!r}")
    if (
        policy
        != "exact_sha256_duplicates_only; runtime assets and cross-platform consumers excluded"
    ):
        manifest_errors.append(f"unexpected deduplication policy {policy!r}")
    if not isinstance(groups, list):
        manifest_errors.append("groups must be an array")
        groups = []

    canonical_paths: list[str] = []
    removed_paths: list[str] = []
    valid_group_specs: list[dict[str, Any]] = []
    tracked_canonical = tracked_relative_paths(DEDUPLICATED_REPORT_DIR)
    canonical_metadata: list[dict[str, Any]] = []
    calculated_reclaimed_bytes = 0

    for index, group in enumerate(groups):
        label = f"group[{index}]"
        if not isinstance(group, dict):
            manifest_errors.append(f"{label} must be an object")
            continue
        canonical_path = group.get("canonical_path")
        digest = group.get("sha256")
        size = group.get("bytes")
        declared_removed_count = group.get("removed_count")
        group_removed_paths = group.get("removed_paths")

        if not isinstance(canonical_path, str):
            manifest_errors.append(f"{label}.canonical_path must be a string")
            continue
        if not isinstance(digest, str) or SHA256_RE.fullmatch(digest) is None:
            manifest_errors.append(f"{label}.sha256 must be lowercase SHA-256")
            continue
        if not isinstance(size, int) or isinstance(size, bool) or size < 0:
            manifest_errors.append(f"{label}.bytes must be a non-negative integer")
            continue
        if not isinstance(group_removed_paths, list) or not all(
            isinstance(path, str) for path in group_removed_paths
        ):
            manifest_errors.append(f"{label}.removed_paths must be a string array")
            continue

        canonical_paths.append(canonical_path)
        removed_paths.extend(group_removed_paths)
        calculated_reclaimed_bytes += size * max(0, len(group_removed_paths) - 1)

        if declared_removed_count != len(group_removed_paths):
            manifest_errors.append(
                f"{label}.removed_count={declared_removed_count!r} "
                f"does not match removed_paths={len(group_removed_paths)}"
            )
        if not group_removed_paths:
            manifest_errors.append(f"{label} must contain at least one removed path")
        if len(set(group_removed_paths)) != len(group_removed_paths):
            manifest_errors.append(f"{label} contains duplicate removed paths")
        for removed_path in group_removed_paths:
            if not removed_path.startswith(REPORT_PATH_PREFIX):
                manifest_errors.append(
                    f"{label} removed path escapes report directory: {removed_path}"
                )
            current_path = REPO_ROOT / removed_path
            if current_path.exists():
                recovery_errors.append(
                    f"removed path is still present in checkout: {removed_path}"
                )

        if not canonical_path.startswith(DEDUPLICATED_REPORT_PATH_PREFIX):
            canonical_errors.append(
                f"{label} canonical path escapes canonical directory: {canonical_path}"
            )
        canonical_file = REPO_ROOT / canonical_path
        try:
            canonical_file.resolve().relative_to(DEDUPLICATED_REPORT_DIR.resolve())
        except ValueError:
            canonical_errors.append(
                f"{label} canonical path does not resolve under canonical directory: "
                f"{canonical_path}"
            )
        if canonical_file.stem != digest:
            canonical_errors.append(
                f"{label} canonical filename does not equal SHA-256: {canonical_path}"
            )
        if canonical_file.suffix not in TRACKED_EVIDENCE_SUFFIXES:
            canonical_errors.append(
                f"{label} canonical suffix is not governed: {canonical_path}"
            )

        metadata: dict[str, Any] = {
            "path": canonical_path,
            "bytes": size,
            "sha256": digest,
            "tracking_status": (
                "tracked"
                if canonical_path in tracked_canonical
                else "content_sealed_untracked"
            ),
            "seal_status": "fail",
        }
        try:
            payload = canonical_file.read_bytes()
        except OSError as error:
            canonical_errors.append(
                f"cannot read canonical file {canonical_path}: {error}"
            )
        else:
            actual_digest = sha256_payload(payload)
            if len(payload) != size:
                canonical_errors.append(
                    f"canonical size mismatch for {canonical_path}: "
                    f"expected={size} actual={len(payload)}"
                )
            if actual_digest != digest:
                canonical_errors.append(
                    f"canonical SHA-256 mismatch for {canonical_path}: "
                    f"expected={digest} actual={actual_digest}"
                )
            if len(payload) == size and actual_digest == digest:
                metadata["seal_status"] = "pass"
        canonical_metadata.append(metadata)
        valid_group_specs.append(
            {
                "label": label,
                "bytes": size,
                "sha256": digest,
                "removed_paths": group_removed_paths,
            }
        )

    if len(set(canonical_paths)) != len(canonical_paths):
        manifest_errors.append("canonical paths must be unique across groups")
    if len(set(removed_paths)) != len(removed_paths):
        manifest_errors.append("removed paths must be unique across groups")

    physical_canonical_paths = (
        {
            rel(path)
            for path in DEDUPLICATED_REPORT_DIR.rglob("*")
            if path.is_file()
        }
        if DEDUPLICATED_REPORT_DIR.exists()
        else set()
    )
    expected_canonical_paths = set(canonical_paths)
    for path in sorted(expected_canonical_paths - physical_canonical_paths):
        _append_error(canonical_errors, f"missing canonical file: {path}")
    for path in sorted(physical_canonical_paths - expected_canonical_paths):
        _append_error(canonical_errors, f"unmanifested canonical file: {path}")

    declared_counts = {
        "group_count": len(groups),
        "canonical_file_count": len(canonical_paths),
        "removed_file_count": len(removed_paths),
        "reclaimed_checkout_bytes": calculated_reclaimed_bytes,
    }
    for field, calculated in declared_counts.items():
        if document.get(field) != calculated:
            manifest_errors.append(
                f"{field}={document.get(field)!r} does not match calculated={calculated}"
            )

    result.update(declared_counts)
    result["canonical_files"] = canonical_metadata
    result["tracked_canonical_file_count"] = sum(
        item["tracking_status"] == "tracked" for item in canonical_metadata
    )
    result["content_sealed_untracked_canonical_file_count"] = sum(
        item["tracking_status"] == "content_sealed_untracked"
        and item["seal_status"] == "pass"
        for item in canonical_metadata
    )

    if not isinstance(recovery_commit, str) or RECOVERY_COMMIT_RE.fullmatch(
        recovery_commit
    ) is None:
        recovery_errors.append(
            f"recovery_commit must be a full lowercase Git SHA: {recovery_commit!r}"
        )
    else:
        tree, tree_error = git_tree_blobs(recovery_commit, [REPORT_PATH_PREFIX])
        if tree_error:
            recovery_errors.append(tree_error)
        else:
            blob_seal_cache: dict[str, tuple[int, str] | None] = {}
            recovered_removed_count = 0
            for group in valid_group_specs:
                group_paths = group["removed_paths"]
                missing = [path for path in group_paths if path not in tree]
                recovered_removed_count += len(group_paths) - len(missing)
                for path in missing:
                    recovery_errors.append(
                        f"removed path is absent from recovery tree: {path}"
                    )
                blob_ids = {tree[path] for path in group_paths if path in tree}
                if len(blob_ids) != 1:
                    recovery_errors.append(
                        f"{group['label']} recovery paths do not share one exact blob"
                    )
                    continue
                blob_id = next(iter(blob_ids))
                if blob_id not in blob_seal_cache:
                    payload, blob_error = git_blob_payload(blob_id)
                    if blob_error:
                        recovery_errors.append(blob_error)
                    blob_seal_cache[blob_id] = (
                        (len(payload), sha256_payload(payload))
                        if payload is not None
                        else None
                    )
                blob_seal = blob_seal_cache[blob_id]
                if blob_seal is None:
                    continue
                actual_size, actual_digest = blob_seal
                if actual_size != group["bytes"]:
                    recovery_errors.append(
                        f"{group['label']} recovery size mismatch: "
                        f"expected={group['bytes']} actual={actual_size}"
                    )
                if actual_digest != group["sha256"]:
                    recovery_errors.append(
                        f"{group['label']} recovery SHA-256 mismatch: "
                        f"expected={group['sha256']} actual={actual_digest}"
                    )
            result["recovered_removed_file_count"] = recovered_removed_count

    errors = [*manifest_errors, *canonical_errors, *recovery_errors]
    result["errors"] = errors
    result["status"] = "pass" if not errors else "fail"
    return result


def parse_archived_large_artifact_entries(text: str) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for match in ARCHIVED_ARTIFACT_ROW_RE.finditer(text):
        listed_path = match.group("path")
        if "/" in listed_path:
            repository_path = f"docs/hermes-analysis/{listed_path}"
        else:
            repository_path = f"{REPORT_PATH_PREFIX}{listed_path}"
        entries.append(
            {
                "listed_path": listed_path,
                "repository_path": repository_path,
                "bytes": int(match.group("bytes").replace(",", "")),
                "sha256": match.group("sha256"),
                "replacement": match.group("replacement").strip(),
            }
        )
    return entries


def validate_archived_large_artifact_retention() -> dict[str, Any]:
    manifest_errors: list[str] = []
    recovery_errors: list[str] = []
    replacement_errors: list[str] = []
    result: dict[str, Any] = {
        "path": rel(ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE),
        "manifest_tracking_status": manifest_tracking_status(
            ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE
        ),
        "recovery_commit": None,
        "artifact_count": 0,
        "recovered_artifact_count": 0,
        "replacement_count": 0,
        "archived_bytes": 0,
        "entries": [],
        "manifest_errors": manifest_errors,
        "recovery_errors": recovery_errors,
        "replacement_errors": replacement_errors,
    }

    if not ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE.is_file():
        manifest_errors.append(
            f"missing manifest {rel(ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE)}"
        )
        result["status"] = "fail"
        return result
    try:
        text = ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE.read_text(encoding="utf-8")
    except OSError as error:
        manifest_errors.append(f"cannot read archived artifact manifest: {error}")
        result["status"] = "fail"
        return result

    commit_matches = set(re.findall(r"`([0-9a-f]{40})`", text))
    if len(commit_matches) != 1:
        manifest_errors.append(
            "archived artifact manifest must name exactly one recovery commit"
        )
        recovery_commit = None
    else:
        recovery_commit = next(iter(commit_matches))
    result["recovery_commit"] = recovery_commit

    entries = parse_archived_large_artifact_entries(text)
    result["artifact_count"] = len(entries)
    result["archived_bytes"] = sum(entry["bytes"] for entry in entries)
    result["entries"] = entries
    repository_paths = [entry["repository_path"] for entry in entries]
    if not entries:
        manifest_errors.append("archived artifact manifest contains no artifact rows")
    if len(set(repository_paths)) != len(repository_paths):
        manifest_errors.append("archived artifact paths must be unique")

    tracked_docs = tracked_relative_paths(DOCS_DIR)
    replacement_count = 0
    for entry in entries:
        repository_path = entry["repository_path"]
        current_path = REPO_ROOT / repository_path
        is_pointer_replacement = entry["listed_path"].endswith("/BATTLE_LOG.md")
        if is_pointer_replacement:
            replacement_path = current_path
            try:
                pointer_text = replacement_path.read_text(encoding="utf-8")
            except OSError as error:
                replacement_errors.append(
                    f"cannot read compact replacement {repository_path}: {error}"
                )
                continue
            required_pointer_tokens = (
                entry["sha256"],
                str(entry["bytes"]),
                recovery_commit or "",
                rel(ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE),
                "/tmp/manaloom-battle-logs",
            )
            normalized_pointer_text = pointer_text.replace(",", "")
            missing_tokens = [
                token
                for token in required_pointer_tokens
                if token and token not in normalized_pointer_text
            ]
            if missing_tokens:
                replacement_errors.append(
                    f"compact replacement {repository_path} is missing archive metadata"
                )
                continue
            if repository_path not in tracked_docs:
                replacement_errors.append(
                    f"compact replacement is not tracked: {repository_path}"
                )
                continue
            if current_path.stat().st_size >= entry["bytes"]:
                replacement_errors.append(
                    f"compact replacement is not smaller than archived bytes: "
                    f"{repository_path}"
                )
                continue
            entry["replacement_path"] = repository_path
            entry["replacement_status"] = "pass"
            replacement_count += 1
        else:
            if current_path.exists():
                replacement_errors.append(
                    f"archived raw artifact is still present: {repository_path}"
                )
            replacement_path = current_path.with_suffix(".md")
            replacement_repository_path = rel(replacement_path)
            entry["replacement_path"] = replacement_repository_path
            if not replacement_path.is_file():
                replacement_errors.append(
                    f"missing sibling Markdown replacement: "
                    f"{replacement_repository_path}"
                )
                entry["replacement_status"] = "fail"
            elif replacement_repository_path not in tracked_docs:
                replacement_errors.append(
                    f"sibling Markdown replacement is not tracked: "
                    f"{replacement_repository_path}"
                )
                entry["replacement_status"] = "fail"
            else:
                entry["replacement_status"] = "pass"
                replacement_count += 1
    result["replacement_count"] = replacement_count

    if recovery_commit is not None:
        tree, tree_error = git_tree_blobs(recovery_commit, repository_paths)
        if tree_error:
            recovery_errors.append(tree_error)
        else:
            blob_seal_cache: dict[str, tuple[int, str] | None] = {}
            recovered_count = 0
            for entry in entries:
                repository_path = entry["repository_path"]
                blob_id = tree.get(repository_path)
                if blob_id is None:
                    recovery_errors.append(
                        f"archived path is absent from recovery tree: {repository_path}"
                    )
                    continue
                if blob_id not in blob_seal_cache:
                    payload, blob_error = git_blob_payload(blob_id)
                    if blob_error:
                        recovery_errors.append(blob_error)
                    blob_seal_cache[blob_id] = (
                        (len(payload), sha256_payload(payload))
                        if payload is not None
                        else None
                    )
                blob_seal = blob_seal_cache[blob_id]
                if blob_seal is None:
                    continue
                actual_size, actual_digest = blob_seal
                if actual_size != entry["bytes"]:
                    recovery_errors.append(
                        f"archived size mismatch for {repository_path}: "
                        f"expected={entry['bytes']} actual={actual_size}"
                    )
                    continue
                if actual_digest != entry["sha256"]:
                    recovery_errors.append(
                        f"archived SHA-256 mismatch for {repository_path}: "
                        f"expected={entry['sha256']} actual={actual_digest}"
                    )
                    continue
                recovered_count += 1
                entry["recovery_status"] = "pass"
            result["recovered_artifact_count"] = recovered_count

    errors = [*manifest_errors, *recovery_errors, *replacement_errors]
    result["errors"] = errors
    result["status"] = "pass" if not errors else "fail"
    return result


def retention_reference_tokens(text: str) -> set[str]:
    suffixes = "|".join(
        re.escape(suffix.removeprefix("."))
        for suffix in sorted(REFERENCE_SUFFIXES, key=len, reverse=True)
    )
    return set(re.findall(rf"[\w./-]+\.(?:{suffixes})(?![\w])", text))


def reference_aliases(repository_paths: set[str]) -> set[str]:
    aliases: set[str] = set()
    docs_prefix = "docs/hermes-analysis/"
    for path in repository_paths:
        aliases.add(path)
        aliases.add(Path(path).name)
        if path.startswith(docs_prefix):
            aliases.add(path.removeprefix(docs_prefix))
    return aliases


def audit_retention_reference_text(
    *,
    source: str,
    text: str,
    canonical_paths: set[str],
    removed_paths: set[str],
    archived_removed_paths: set[str],
) -> tuple[list[dict[str, str]], int]:
    issues: list[dict[str, str]] = []
    canonical_reference_count = 0
    removed_aliases = reference_aliases(removed_paths)
    archived_aliases = reference_aliases(archived_removed_paths)
    tokens = retention_reference_tokens(text)
    canonical_candidates = {
        token for token in tokens if "deduplicated-report-content/" in token
    }
    for candidate in sorted(canonical_candidates):
        canonical_reference_count += 1
        if candidate not in canonical_paths:
            issues.append(
                {
                    "source": source,
                    "reference": candidate,
                    "kind": "unknown_or_malformed_canonical_reference",
                }
            )

    for token in sorted(tokens):
        if token in removed_aliases:
            issues.append(
                {
                    "source": source,
                    "reference": token,
                    "kind": "removed_duplicate_reference",
                }
            )
        if token in archived_aliases:
            issues.append(
                {
                    "source": source,
                    "reference": token,
                    "kind": "archived_raw_reference",
                }
            )
    return issues, canonical_reference_count


def validate_retention_references(
    deduplicated: dict[str, Any],
    archived: dict[str, Any],
) -> dict[str, Any]:
    canonical_paths = {
        item["path"]
        for item in deduplicated.get("canonical_files", [])
        if isinstance(item, dict) and isinstance(item.get("path"), str)
    }
    try:
        deduplication_document = json.loads(
            DEDUPLICATED_REPORT_MANIFEST_FILE.read_text(encoding="utf-8")
        )
    except (OSError, json.JSONDecodeError):
        deduplication_document = {}
    removed_paths = {
        path
        for group in deduplication_document.get("groups", [])
        if isinstance(group, dict)
        for path in group.get("removed_paths", [])
        if isinstance(path, str)
    }
    # BATTLE_LOG.md remains a valid compact pointer at the same path. Only raw
    # artifacts that disappeared from the checkout are stale references.
    archived_removed_paths = {
        entry["repository_path"]
        for entry in archived.get("entries", [])
        if isinstance(entry, dict)
        and isinstance(entry.get("repository_path"), str)
        and not entry["listed_path"].endswith("/BATTLE_LOG.md")
    }

    reference_files = {
        path
        for path in git_ls_files(DOCS_DIR)
        if path.exists() and path.is_file() and path.suffix == ".md"
    }
    reference_files.update(active_reference_files())
    if RETENTION_MANIFEST_FILE.is_file():
        reference_files.add(RETENTION_MANIFEST_FILE)
    # The archive manifest intentionally names the removed raw artifacts and is
    # therefore an index, not a consumer reference surface.
    reference_files.discard(ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE)

    issues: list[dict[str, str]] = []
    canonical_reference_count = 0
    for path in sorted(reference_files):
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError as error:
            issues.append(
                {
                    "source": rel(path),
                    "reference": str(error),
                    "kind": "unreadable_reference_surface",
                }
            )
            continue
        file_issues, file_reference_count = audit_retention_reference_text(
            source=rel(path),
            text=text,
            canonical_paths=canonical_paths,
            removed_paths=removed_paths,
            archived_removed_paths=archived_removed_paths,
        )
        issues.extend(file_issues)
        canonical_reference_count += file_reference_count

    required_index_mentions = {
        rel(DEDUPLICATED_REPORT_MANIFEST_FILE),
        DEDUPLICATED_REPORT_PATH_PREFIX,
        rel(ARCHIVED_LARGE_ARTIFACTS_MANIFEST_FILE),
    }
    try:
        retention_manifest_text = RETENTION_MANIFEST_FILE.read_text(
            encoding="utf-8"
        )
    except OSError:
        retention_manifest_text = ""
    missing_index_mentions = sorted(
        token
        for token in required_index_mentions
        if token not in retention_manifest_text
    )
    return {
        "status": "pass" if not issues and not missing_index_mentions else "fail",
        "scanned_file_count": len(reference_files),
        "canonical_reference_count": canonical_reference_count,
        "issue_count": len(issues),
        "issues": issues,
        "required_index_mentions": sorted(required_index_mentions),
        "missing_index_mentions": missing_index_mentions,
    }


def tracked_report_raw_files() -> list[Path]:
    return [
        path
        for path in git_ls_files(REPORT_DIR)
        if path.is_file() and path.suffix in RAW_REPORT_SUFFIXES
    ]


def exact_duplicate_report_groups(
    paths: list[Path] | None = None,
) -> list[dict[str, Any]]:
    candidates = paths
    if candidates is None:
        candidates = [
            path
            for path in git_ls_files(REPORT_DIR)
            if path.is_file() and path.suffix in TRACKED_EVIDENCE_SUFFIXES
        ]

    grouped: dict[tuple[int, str], list[Path]] = {}
    for path in candidates:
        try:
            payload = path.read_bytes()
        except OSError:
            continue
        key = (len(payload), hashlib.sha256(payload).hexdigest())
        grouped.setdefault(key, []).append(path)

    return [
        {
            "bytes": size,
            "sha256": digest,
            "paths": sorted(rel(path) for path in group),
        }
        for (size, digest), group in sorted(grouped.items())
        if len(group) > 1
    ]


def active_reference_files() -> list[Path]:
    files: set[Path] = set()
    for root in ACTIVE_REFERENCE_ROOTS:
        if not root.exists():
            continue
        for path in git_ls_files(root):
            if path.exists() and path.is_file() and not str(path).startswith(str(REPORT_DIR) + "/"):
                files.add(path)
    # Historical evidence remains a retention-reference surface without being
    # promoted back into the set of current operational contracts.
    for path in (
        *CURRENT_CONTRACT_FILES,
        *HISTORICAL_REFERENCE_FILES,
        *ARCHIVED_EVIDENCE_REFERENCE_FILES,
    ):
        if path.exists() and path.is_file():
            files.add(path)
    return sorted(files)


def read_active_reference_text() -> str:
    chunks: list[str] = []
    for path in active_reference_files():
        try:
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            continue
    return "\n".join(chunks)


def extract_raw_reference_tokens(text: str) -> set[str]:
    referenced_tokens = set(
        re.findall(
            r"[\w./-]+\.(?:json|jsonl|sql|out|txt|db|log|tsv|err)",
            text,
        )
    )
    referenced_tokens.update(Path(token).name for token in list(referenced_tokens))
    return referenced_tokens


def retention_manifest_justification() -> str | None:
    if not RETENTION_MANIFEST_FILE.exists():
        return None
    for line in RETENTION_MANIFEST_FILE.read_text(
        encoding="utf-8", errors="ignore"
    ).splitlines():
        if line.startswith(RETENTION_JUSTIFICATION_PREFIX):
            justification = line.removeprefix(RETENTION_JUSTIFICATION_PREFIX).strip()
            return justification or None
    return None


def retention_manifest_paths() -> set[str]:
    if not RETENTION_MANIFEST_FILE.exists():
        return set()
    text = RETENTION_MANIFEST_FILE.read_text(encoding="utf-8", errors="ignore")
    suffixes = "|".join(
        sorted(
            suffix.removeprefix(".")
            for suffix in RAW_REPORT_SUFFIXES.union({".md"})
        )
    )
    pattern = rf"`(docs/hermes-analysis/master_optimizer_reports/[^`]+\.(?:{suffixes}))`"
    return set(re.findall(pattern, text))


def retention_manifest_pending_hashes() -> dict[str, str]:
    """Return content seals for reviewed evidence that is not tracked yet.

    Ordinary manifest membership is intentionally insufficient for local
    JSON/Markdown output. A pending evidence file is governed only when the
    README records its exact repository path and SHA-256. This lets a reviewed
    apply/sync/audit bundle survive until it is added to Git without turning
    the manifest into a blanket escape hatch for generated output.
    """

    if not RETENTION_MANIFEST_FILE.exists():
        return {}
    text = RETENTION_MANIFEST_FILE.read_text(encoding="utf-8", errors="ignore")
    suffixes = "|".join(
        sorted(
            suffix.removeprefix(".")
            for suffix in RAW_REPORT_SUFFIXES.union({".md"})
        )
    )
    pattern = re.compile(
        rf"`(?P<path>docs/hermes-analysis/master_optimizer_reports/[^`]+\.(?:{suffixes}))`"
        rf"\s+[—-]\s+{re.escape(PENDING_LOCAL_HASH_LABEL)}\s+"
        r"`(?P<sha256>[0-9a-f]{64})`"
    )
    result: dict[str, str] = {}
    for match in pattern.finditer(text):
        path = match.group("path")
        digest = match.group("sha256")
        prior = result.get(path)
        if prior is not None and prior != digest:
            raise ValueError(f"conflicting pending-local SHA-256 seals for {path}")
        result[path] = digest
    return result


def classify_paths(
    paths: list[Path],
    *,
    active_tokens: set[str],
    manifest_paths: set[str],
    manifest_has_justification: bool,
) -> dict[str, list[Path]]:
    classified: dict[str, list[Path]] = {
        "active_consumer": [],
        "manifest_only": [],
        "ungoverned": [],
    }
    for path in paths:
        relative_path = rel(path)
        if path.name in active_tokens or relative_path in active_tokens:
            classified["active_consumer"].append(path)
        elif manifest_has_justification and relative_path in manifest_paths:
            classified["manifest_only"].append(path)
        else:
            classified["ungoverned"].append(path)
    return classified


def classify_raw_files() -> dict[str, list[Path]]:
    return classify_paths(
        tracked_report_raw_files(),
        active_tokens=extract_raw_reference_tokens(read_active_reference_text()),
        manifest_paths=retention_manifest_paths(),
        manifest_has_justification=retention_manifest_justification() is not None,
    )


def local_untracked_report_files() -> list[Path]:
    if not REPORT_DIR.exists():
        return []
    tracked = {path.resolve() for path in git_ls_files(REPORT_DIR)}
    return sorted(
        path
        for path in REPORT_DIR.rglob("*")
        if path.is_file()
        and path.resolve() not in tracked
        and path.suffix in RAW_REPORT_SUFFIXES.union({".md"})
    )


def classify_local_report_files(
    paths: list[Path], *, manifest_paths: set[str], pending_hashes: dict[str, str] | None = None
) -> dict[str, list[Path]]:
    """Split local raw files into reviewed SQL quartets and actual residue.

    A newly prepared PostgreSQL operator package necessarily exists before it
    can be tracked. Treating every such file as disposable residue made the
    local closure gate impossible to run without mutating the Git index.

    The exceptions are deliberately narrow: SQL must be explicitly listed and
    form a complete precheck/apply/postcheck/rollback quartet; reviewed JSON or
    Markdown evidence must be explicitly listed and match an exact SHA-256 seal
    in the manifest. Missing/tampered files, arbitrary generated output, and
    incomplete SQL packages still fail. In CI, omitted files remain stale
    manifest entries.
    """

    pending_hashes = pending_hashes or {}

    package_members: dict[str, dict[str, Path]] = {}
    for path in paths:
        if path.suffix != ".sql" or rel(path) not in manifest_paths:
            continue
        match = SQL_PACKAGE_ROLE_RE.fullmatch(path.name)
        if match is None:
            continue
        package_members.setdefault(match.group("prefix"), {})[
            match.group("role")
        ] = path

    pending_manifest: set[Path] = set()
    for members in package_members.values():
        if set(members) == SQL_PACKAGE_ROLES:
            pending_manifest.update(members.values())

    for path in paths:
        relative_path = rel(path)
        expected_hash = pending_hashes.get(relative_path)
        if (
            relative_path not in manifest_paths
            or expected_hash is None
            or path.suffix not in {".json", ".md"}
        ):
            continue
        try:
            actual_hash = hashlib.sha256(path.read_bytes()).hexdigest()
        except OSError:
            continue
        if actual_hash == expected_hash:
            pending_manifest.add(path)

    return {
        "pending_manifest": sorted(pending_manifest),
        "ignored": sorted(path for path in paths if path not in pending_manifest),
    }


def ignored_local_report_files() -> list[Path]:
    """Compatibility helper returning only ungoverned local residue."""

    return classify_local_report_files(
        local_untracked_report_files(),
        manifest_paths=retention_manifest_paths(),
        pending_hashes=retention_manifest_pending_hashes(),
    )["ignored"]


def byte_size(paths: list[Path]) -> int:
    total = 0
    for path in paths:
        try:
            total += path.stat().st_size
        except OSError:
            continue
    return total


def artifact_metadata(
    path: Path,
    *,
    classification: str,
    justification: str | None = None,
    now: datetime | None = None,
) -> dict[str, Any]:
    now = now or datetime.now(timezone.utc)
    try:
        stat = path.stat()
        modified_at = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc)
        size_bytes = stat.st_size
        age_days = max(0.0, (now - modified_at).total_seconds() / 86400)
    except OSError:
        modified_at = None
        size_bytes = 0
        age_days = None
    return {
        "path": rel(path),
        "classification": classification,
        "justification": justification,
        "size_bytes": size_bytes,
        "modified_at": modified_at.isoformat() if modified_at else None,
        "age_days": round(age_days, 2) if age_days is not None else None,
    }


def build_report(*, fail_on_ignored_local: bool) -> dict[str, Any]:
    classified = classify_raw_files()
    active_consumer = classified["active_consumer"]
    manifest_only = classified["manifest_only"]
    ungoverned = classified["ungoverned"]
    manifest_paths = retention_manifest_paths()
    manifest_justification = retention_manifest_justification()
    pending_hashes = retention_manifest_pending_hashes()
    local_classified = classify_local_report_files(
        local_untracked_report_files(),
        manifest_paths=manifest_paths,
        pending_hashes=pending_hashes,
    )
    pending_manifest_local = local_classified["pending_manifest"]
    ignored = local_classified["ignored"]
    duplicate_groups = exact_duplicate_report_groups()
    duplicate_file_count = sum(len(group["paths"]) for group in duplicate_groups)
    duplicate_reclaimable_bytes = sum(
        int(group["bytes"]) * (len(group["paths"]) - 1)
        for group in duplicate_groups
    )
    deduplicated_retention = validate_deduplicated_report_retention()
    archived_retention = validate_archived_large_artifact_retention()
    retention_reference_audit = validate_retention_references(
        deduplicated_retention,
        archived_retention,
    )
    # Markdown summaries are not part of the tracked-raw classification, but a
    # content-sealed pending summary must stop being "stale" once it is tracked.
    tracked_relative_paths = {
        rel(path)
        for path in git_ls_files(REPORT_DIR)
        if path.exists() and path.is_file()
    }
    pending_manifest_relative_paths = {
        rel(path) for path in pending_manifest_local
    }
    stale_manifest_entries = sorted(
        manifest_paths
        - tracked_relative_paths
        - pending_manifest_relative_paths
    )
    checks = [
        Check(
            "retention_manifest_has_explicit_justification",
            "pass" if manifest_justification else "fail",
            f"manifest={rel(RETENTION_MANIFEST_FILE)} justification_present={manifest_justification is not None}",
        ),
        Check(
            "tracked_raw_report_files_have_consumer_or_retention_justification",
            "pass" if not ungoverned else "fail",
            " ".join(
                [
                    f"active_consumer={len(active_consumer)}",
                    f"manifest_only={len(manifest_only)}",
                    f"ungoverned={len(ungoverned)}",
                ]
            ),
        ),
        Check(
            "retention_manifest_has_no_stale_raw_entries",
            "pass" if not stale_manifest_entries else "fail",
            f"manifest_entries={len(manifest_paths)} stale_entries={len(stale_manifest_entries)}",
        ),
        Check(
            "ignored_local_report_artifacts_absent",
            "pass" if (not fail_on_ignored_local or not ignored) else "fail",
            f"ignored_local_count={len(ignored)} ignored_local_bytes={byte_size(ignored)}",
        ),
        Check(
            "tracked_report_artifacts_have_no_exact_duplicates",
            "pass" if not duplicate_groups else "fail",
            " ".join(
                [
                    f"duplicate_groups={len(duplicate_groups)}",
                    f"duplicate_files={duplicate_file_count}",
                    f"reclaimable_bytes={duplicate_reclaimable_bytes}",
                ]
            ),
        ),
        Check(
            "deduplicated_report_manifest_is_valid",
            "pass"
            if not deduplicated_retention["manifest_errors"]
            else "fail",
            " ".join(
                [
                    f"manifest={deduplicated_retention['path']}",
                    f"tracking={deduplicated_retention['manifest_tracking_status']}",
                    f"groups={deduplicated_retention['group_count']}",
                    f"errors={len(deduplicated_retention['manifest_errors'])}",
                ]
            ),
        ),
        Check(
            "deduplicated_report_canonical_files_are_content_sealed",
            "pass"
            if not deduplicated_retention["canonical_errors"]
            else "fail",
            " ".join(
                [
                    f"canonical_files={deduplicated_retention['canonical_file_count']}",
                    (
                        "tracked="
                        f"{deduplicated_retention['tracked_canonical_file_count']}"
                    ),
                    (
                        "content_sealed_untracked="
                        f"{deduplicated_retention['content_sealed_untracked_canonical_file_count']}"
                    ),
                    f"errors={len(deduplicated_retention['canonical_errors'])}",
                ]
            ),
        ),
        Check(
            "deduplicated_report_removed_paths_are_recoverable",
            "pass"
            if not deduplicated_retention["recovery_errors"]
            else "fail",
            " ".join(
                [
                    f"removed={deduplicated_retention['removed_file_count']}",
                    (
                        "recovered="
                        f"{deduplicated_retention['recovered_removed_file_count']}"
                    ),
                    f"commit={deduplicated_retention['recovery_commit']}",
                    f"errors={len(deduplicated_retention['recovery_errors'])}",
                ]
            ),
        ),
        Check(
            "archived_large_artifact_manifest_is_valid",
            "pass" if not archived_retention["manifest_errors"] else "fail",
            " ".join(
                [
                    f"manifest={archived_retention['path']}",
                    f"tracking={archived_retention['manifest_tracking_status']}",
                    f"artifacts={archived_retention['artifact_count']}",
                    f"errors={len(archived_retention['manifest_errors'])}",
                ]
            ),
        ),
        Check(
            "archived_large_artifacts_are_recoverable_and_replaced",
            "pass"
            if not archived_retention["recovery_errors"]
            and not archived_retention["replacement_errors"]
            else "fail",
            " ".join(
                [
                    f"recovered={archived_retention['recovered_artifact_count']}",
                    f"replacements={archived_retention['replacement_count']}",
                    f"commit={archived_retention['recovery_commit']}",
                    (
                        "errors="
                        f"{len(archived_retention['recovery_errors']) + len(archived_retention['replacement_errors'])}"
                    ),
                ]
            ),
        ),
        Check(
            "retention_governance_references_resolve",
            "pass"
            if not retention_reference_audit["issues"]
            else "fail",
            " ".join(
                [
                    f"scanned_files={retention_reference_audit['scanned_file_count']}",
                    (
                        "canonical_references="
                        f"{retention_reference_audit['canonical_reference_count']}"
                    ),
                    f"issues={retention_reference_audit['issue_count']}",
                ]
            ),
        ),
        Check(
            "retention_governance_indexes_are_explicit",
            "pass"
            if not retention_reference_audit["missing_index_mentions"]
            else "fail",
            " ".join(
                [
                    (
                        "required_mentions="
                        f"{len(retention_reference_audit['required_index_mentions'])}"
                    ),
                    (
                        "missing_mentions="
                        f"{len(retention_reference_audit['missing_index_mentions'])}"
                    ),
                ]
            ),
        ),
    ]
    status_counts: dict[str, int] = {}
    for check in checks:
        status_counts[check.status] = status_counts.get(check.status, 0) + 1
    now = datetime.now(timezone.utc)
    tracked_artifacts = [
        artifact_metadata(path, classification="active_consumer", now=now)
        for path in active_consumer
    ] + [
        artifact_metadata(
            path,
            classification="manifest_only",
            justification=manifest_justification,
            now=now,
        )
        for path in manifest_only
    ] + [
        artifact_metadata(path, classification="ungoverned", now=now)
        for path in ungoverned
    ]
    ignored_artifacts = [
        artifact_metadata(path, classification="ignored_local", now=now)
        for path in ignored
    ]
    known_ages = [
        float(item["age_days"])
        for item in tracked_artifacts
        if item["age_days"] is not None
    ]
    return {
        "generated_at": utc_now(),
        "status": "pass" if status_counts.get("fail", 0) == 0 else "fail",
        "summary": {
            "check_count": len(checks),
            "status_counts": status_counts,
            "tracked_raw_count": len(active_consumer) + len(manifest_only) + len(ungoverned),
            "active_consumer_tracked_raw_count": len(active_consumer),
            "active_consumer_tracked_raw_bytes": byte_size(active_consumer),
            "manifest_only_tracked_raw_count": len(manifest_only),
            "manifest_only_tracked_raw_bytes": byte_size(manifest_only),
            "ungoverned_tracked_raw_count": len(ungoverned),
            "ungoverned_tracked_raw_bytes": byte_size(ungoverned),
            "tracked_raw_oldest_age_days": max(known_ages) if known_ages else None,
            "retention_manifest_entry_count": len(manifest_paths),
            "retention_manifest_stale_entry_count": len(stale_manifest_entries),
            "pending_manifest_local_count": len(pending_manifest_local),
            "pending_manifest_local_bytes": byte_size(pending_manifest_local),
            "ignored_local_count": len(ignored),
            "ignored_local_bytes": byte_size(ignored),
            "exact_duplicate_group_count": len(duplicate_groups),
            "exact_duplicate_file_count": duplicate_file_count,
            "exact_duplicate_reclaimable_bytes": duplicate_reclaimable_bytes,
            "deduplicated_group_count": deduplicated_retention["group_count"],
            "deduplicated_canonical_file_count": deduplicated_retention[
                "canonical_file_count"
            ],
            "deduplicated_content_sealed_untracked_count": deduplicated_retention[
                "content_sealed_untracked_canonical_file_count"
            ],
            "deduplicated_removed_file_count": deduplicated_retention[
                "removed_file_count"
            ],
            "deduplicated_recovered_removed_file_count": deduplicated_retention[
                "recovered_removed_file_count"
            ],
            "deduplicated_reclaimed_checkout_bytes": deduplicated_retention[
                "reclaimed_checkout_bytes"
            ],
            "archived_large_artifact_count": archived_retention["artifact_count"],
            "archived_large_artifact_recovered_count": archived_retention[
                "recovered_artifact_count"
            ],
            "archived_large_artifact_replacement_count": archived_retention[
                "replacement_count"
            ],
            "archived_large_artifact_bytes": archived_retention["archived_bytes"],
            "retention_reference_issue_count": retention_reference_audit[
                "issue_count"
            ],
        },
        "checks": [check.as_dict() for check in checks],
        "retention_manifest": {
            "path": rel(RETENTION_MANIFEST_FILE),
            "justification": manifest_justification,
            "entries": sorted(manifest_paths),
            "pending_local_sha256": dict(sorted(pending_hashes.items())),
            "pending_local_entries": sorted(pending_manifest_relative_paths),
            "stale_entries": stale_manifest_entries,
        },
        "active_consumer_tracked_raw": [rel(path) for path in active_consumer],
        "manifest_only_tracked_raw": [rel(path) for path in manifest_only],
        "ungoverned_tracked_raw": [rel(path) for path in ungoverned],
        "tracked_raw_artifacts": sorted(tracked_artifacts, key=lambda item: item["path"]),
        "ignored_local_artifact_metadata": ignored_artifacts,
        # Compatibility aliases. "referenced" now means a real active surface;
        # manifest-only retention is reported separately instead of inflating it.
        "referenced_tracked_raw": [rel(path) for path in active_consumer],
        "unreferenced_tracked_raw": [rel(path) for path in ungoverned],
        "pending_manifest_local_raw": [rel(path) for path in pending_manifest_local],
        "ignored_local_report_artifacts": [rel(path) for path in ignored],
        "exact_duplicate_report_groups": duplicate_groups,
        "deduplicated_report_retention": deduplicated_retention,
        "archived_large_artifact_retention": archived_retention,
        "retention_reference_audit": retention_reference_audit,
        "mutations_performed": [],
    }


def write_markdown(report: dict[str, Any], path: Path) -> None:
    lines = [
        "# Report Retention Audit",
        "",
        f"- Generated at: `{report['generated_at']}`",
        f"- Status: `{report['status']}`",
        f"- Summary: `{json.dumps(report['summary'], sort_keys=True)}`",
        "",
        "| Check | Status | Detail |",
        "| --- | --- | --- |",
    ]
    for check in report["checks"]:
        detail = str(check.get("detail") or "").replace("|", "\\|")
        lines.append(f"| `{check['name']}` | `{check['status']}` | {detail} |")
    if report["ungoverned_tracked_raw"]:
        lines.extend(["", "## Ungoverned Tracked Raw Files", ""])
        for item in report["ungoverned_tracked_raw"][:200]:
            lines.append(f"- `{item}`")
        if len(report["ungoverned_tracked_raw"]) > 200:
            lines.append(f"- ... {len(report['ungoverned_tracked_raw']) - 200} more")
    if report["manifest_only_tracked_raw"]:
        lines.extend(
            [
                "",
                "## Manifest-only Retained Raw Files",
                "",
                (
                    f"Count: `{len(report['manifest_only_tracked_raw'])}`. "
                    "These files have retention justification but no active consumer reference."
                ),
            ]
        )
        metadata_by_path = {
            item["path"]: item for item in report["tracked_raw_artifacts"]
        }
        for item in report["manifest_only_tracked_raw"][:200]:
            metadata = metadata_by_path.get(item, {})
            lines.append(
                f"- `{item}` - bytes={metadata.get('size_bytes', 0)} "
                f"age_days={metadata.get('age_days')}"
            )
        if len(report["manifest_only_tracked_raw"]) > 200:
            lines.append(f"- ... {len(report['manifest_only_tracked_raw']) - 200} more")
    if report["ignored_local_report_artifacts"]:
        lines.extend(["", "## Ignored Local Report Artifacts", ""])
        for item in report["ignored_local_report_artifacts"][:200]:
            lines.append(f"- `{item}`")
        if len(report["ignored_local_report_artifacts"]) > 200:
            lines.append(f"- ... {len(report['ignored_local_report_artifacts']) - 200} more")
    if report["pending_manifest_local_raw"]:
        lines.extend(["", "## Pending Manifest SQL Package Files", ""])
        lines.append(
            "Complete reviewed SQL quartets present locally and listed in the "
            "retention manifest; they must be tracked with the related evidence "
            "before merge."
        )
        for item in report["pending_manifest_local_raw"][:200]:
            lines.append(f"- `{item}`")
    if report["exact_duplicate_report_groups"]:
        lines.extend(["", "## Exact Duplicate Report Artifacts", ""])
        for group in report["exact_duplicate_report_groups"][:100]:
            lines.append(
                f"- `{group['sha256']}` - bytes={group['bytes']} "
                f"copies={len(group['paths'])}"
            )
            for item in group["paths"][:20]:
                lines.append(f"  - `{item}`")
    retention_error_sections = (
        (
            "Deduplicated Report Retention Errors",
            report["deduplicated_report_retention"]["errors"],
        ),
        (
            "Archived Large Artifact Retention Errors",
            report["archived_large_artifact_retention"]["errors"],
        ),
    )
    for title, errors in retention_error_sections:
        if not errors:
            continue
        lines.extend(["", f"## {title}", ""])
        for error in errors[:200]:
            lines.append(f"- {error}")
        if len(errors) > 200:
            lines.append(f"- ... {len(errors) - 200} more")
    if report["retention_reference_audit"]["issues"]:
        lines.extend(["", "## Retention Reference Issues", ""])
        for issue in report["retention_reference_audit"]["issues"][:200]:
            lines.append(
                f"- `{issue['source']}`: `{issue['reference']}` "
                f"({issue['kind']})"
            )
    if report["retention_reference_audit"]["missing_index_mentions"]:
        lines.extend(["", "## Missing Retention Index Mentions", ""])
        for item in report["retention_reference_audit"][
            "missing_index_mentions"
        ]:
            lines.append(f"- `{item}`")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=Path("/tmp/manaloom_report_retention_audit"),
    )
    parser.add_argument(
        "--fail-on-ignored-local",
        action="store_true",
        help="Fail when ignored local report artifacts are present on disk.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(fail_on_ignored_local=args.fail_on_ignored_local)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_markdown(report, md_path)
    print(json.dumps({"status": report["status"], "json": str(json_path), "markdown": str(md_path)}))
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
