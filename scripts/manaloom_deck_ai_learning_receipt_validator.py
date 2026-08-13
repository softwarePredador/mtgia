#!/usr/bin/env python3
"""Create and validate source-bound Deck/AI/Learning gate evidence.

The release validator deliberately accepts only the v2 envelope.  Historical
PG/Hermes audit JSON is useful input evidence, but cannot by itself authorize a
release because it has no checkout, target, migration-catalog or artifact
binding.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
GIT_SHA_RE = re.compile(r"^[0-9a-f]{40}$")
MIGRATION_RE = re.compile(r"version:\s*'([0-9]{3})'")


class ReceiptValidationError(ValueError):
    """A release receipt failed a fail-closed contract check."""


def _reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ReceiptValidationError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_json_strict(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=_reject_duplicate_keys,
        )
    except ReceiptValidationError:
        raise
    except Exception as exc:  # pragma: no cover - exact parser text is unstable
        raise ReceiptValidationError(f"invalid JSON {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ReceiptValidationError(f"JSON root must be an object: {path}")
    return value


def canonical_sha256(value: Any) -> str:
    encoded = json.dumps(
        value,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def _git_bytes(repo: Path, *args: str) -> bytes:
    return subprocess.check_output(
        ["git", "-C", str(repo), *args],
        stderr=subprocess.DEVNULL,
    )


def worktree_digest_sha256(repo: Path) -> str:
    """Hash HEAD-relative tracked changes plus every non-ignored untracked file."""
    digest = hashlib.sha256()
    digest.update(b"manaloom-worktree-v2\0")
    digest.update(b"tracked-diff\0")
    digest.update(
        _git_bytes(
            repo,
            "diff",
            "--no-ext-diff",
            "--no-textconv",
            "--binary",
            "HEAD",
            "--",
        )
    )
    untracked = _git_bytes(
        repo,
        "ls-files",
        "--others",
        "--exclude-standard",
        "-z",
    ).split(b"\0")
    for raw_path in sorted(path for path in untracked if path):
        path = repo / os.fsdecode(raw_path)
        digest.update(b"untracked\0")
        digest.update(raw_path)
        digest.update(b"\0")
        if path.is_symlink():
            digest.update(b"symlink\0")
            digest.update(os.fsencode(os.readlink(path)))
        elif path.is_file():
            digest.update(b"file\0")
            digest.update(file_sha256(path).encode("ascii"))
        else:
            digest.update(b"unsupported\0")
    return digest.hexdigest()


def _guarded_artifact_state(repo: Path, relative_path: str) -> dict[str, Any]:
    path = repo / relative_path
    if not path.exists():
        return {"state": "missing"}
    if path.is_symlink() or not path.is_file():
        return {"state": "unsupported"}
    return {
        "state": "present",
        "sha256": file_sha256(path),
        "size_bytes": path.stat().st_size,
    }


def capture_source_state(repo: Path, policy_path: Path) -> dict[str, Any]:
    repo = repo.resolve()
    policy_path = policy_path.resolve()
    policy = load_json_strict(policy_path)
    manifest_path = repo / "project_logic_manifest.json"
    migration_path = repo / "server" / "bin" / "migrate.dart"
    manifest = load_json_strict(manifest_path)
    migrations = MIGRATION_RE.findall(migration_path.read_text(encoding="utf-8"))
    if not migrations:
        raise ReceiptValidationError("no versioned migrations found in migrate.dart")
    git_sha = _git_bytes(repo, "rev-parse", "HEAD").decode().strip()
    if not GIT_SHA_RE.fullmatch(git_sha):
        raise ReceiptValidationError("source checkout has no full Git SHA")
    git_dirty = bool(
        _git_bytes(repo, "status", "--porcelain", "--untracked-files=normal").strip()
    )
    source_digest = manifest.get("source_digest_sha256")
    if not isinstance(source_digest, str) or not SHA256_RE.fullmatch(source_digest):
        raise ReceiptValidationError("project logic source digest is invalid")
    guarded_paths = policy.get("source", {}).get("guarded_local_artifacts")
    if not isinstance(guarded_paths, list) or not all(
        isinstance(item, str) and item for item in guarded_paths
    ):
        raise ReceiptValidationError("policy guarded_local_artifacts is invalid")
    return {
        "git_sha": git_sha,
        "git_dirty": git_dirty,
        "worktree_digest_sha256": worktree_digest_sha256(repo),
        "project_logic_source_digest": source_digest,
        "project_logic_manifest_sha256": file_sha256(manifest_path),
        "migration_source_sha256": file_sha256(migration_path),
        "latest_migration": max(migrations),
        "policy_sha256": file_sha256(policy_path),
        "guarded_local_artifacts": {
            item: _guarded_artifact_state(repo, item) for item in guarded_paths
        },
    }


def verify_source_stable(
    start: dict[str, Any],
    end: dict[str, Any],
    *,
    require_clean: bool,
) -> dict[str, Any]:
    if start != end:
        changed = sorted(
            key for key in set(start) | set(end) if start.get(key) != end.get(key)
        )
        raise ReceiptValidationError(
            "source state changed while gate executed: " + ", ".join(changed)
        )
    if require_clean and start.get("git_dirty") is not False:
        raise ReceiptValidationError("release evidence requires a clean worktree")
    return start


def _read_env_data(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
            raise ReceiptValidationError(
                f"invalid credential key at line {line_number}"
            )
        if key in result:
            raise ReceiptValidationError(f"duplicate credential key: {key}")
        result[key] = value.strip().strip('"').strip("'")
    return result


def target_binding(
    credential_file: Path,
    *,
    remote_host: str = "127.0.0.1",
    remote_port: str = "15432",
    expected_ssh_host_key_sha256: str | None = None,
) -> dict[str, str]:
    credential_file = credential_file.resolve()
    values = _read_env_data(credential_file)
    required = ("EASYPANEL_SERVER_IP", "DB_NAME", "DB_USER")
    missing = [key for key in required if not values.get(key)]
    if missing:
        raise ReceiptValidationError(
            "credential config cannot identify target: " + ", ".join(missing)
        )
    expected_ssh_host_key_sha256 = (
        expected_ssh_host_key_sha256
        if expected_ssh_host_key_sha256 is not None
        else os.environ.get("MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256", "")
    )
    if not re.fullmatch(r"SHA256:[A-Za-z0-9+/]{43}", expected_ssh_host_key_sha256):
        raise ReceiptValidationError(
            "MANALOOM_EXPECTED_SSH_HOST_KEY_SHA256 is required and invalid"
        )
    material = {
        "ssh_server": values["EASYPANEL_SERVER_IP"],
        "expected_ssh_host_key_sha256": expected_ssh_host_key_sha256,
        "postgres_remote_host": remote_host,
        "postgres_remote_port": str(remote_port),
        "database": values["DB_NAME"],
        "user": values["DB_USER"],
    }
    return {
        "credential_config_sha256": file_sha256(credential_file),
        "expected_ssh_host_key_sha256": expected_ssh_host_key_sha256,
        "identity_sha256": canonical_sha256(material),
    }


def _parse_timestamp(value: Any, field: str) -> datetime:
    if not isinstance(value, str) or not value:
        raise ReceiptValidationError(f"{field} is required")
    try:
        timestamp = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ReceiptValidationError(f"{field} is not ISO-8601") from exc
    if timestamp.tzinfo is None:
        raise ReceiptValidationError(f"{field} must include a timezone")
    return timestamp.astimezone(timezone.utc)


def _require_object(value: Any, field: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ReceiptValidationError(f"{field} must be an object")
    return value


def _require_list(value: Any, field: str) -> list[Any]:
    if not isinstance(value, list):
        raise ReceiptValidationError(f"{field} must be a list")
    return value


def _require_exact(value: Any, expected: Any, field: str) -> None:
    if value != expected:
        raise ReceiptValidationError(f"{field} must be exactly {expected!r}")


def _require_sha256(value: Any, field: str) -> str:
    if not isinstance(value, str) or not SHA256_RE.fullmatch(value):
        raise ReceiptValidationError(f"{field} must be a lowercase SHA-256")
    return value


def _require_positive_int(value: Any, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ReceiptValidationError(f"{field} must be a positive integer")
    return value


def _is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def is_temporary_path(path: Path, policy: dict[str, Any]) -> bool:
    resolved = path.resolve()
    prefixes = _require_list(
        policy.get("temporary_path_prefixes"), "policy.temporary_path_prefixes"
    )
    for raw_prefix in prefixes:
        if not isinstance(raw_prefix, str) or not raw_prefix.startswith("/"):
            raise ReceiptValidationError("temporary path prefixes must be absolute")
        if _is_relative_to(resolved, Path(raw_prefix).resolve()):
            return True
    return False


def require_durable_evidence_path(
    path: Path,
    *,
    policy: dict[str, Any],
    repo: Path,
) -> None:
    resolved = path.resolve()
    if is_temporary_path(resolved, policy):
        raise ReceiptValidationError("release evidence cannot live under a temp root")
    if _is_relative_to(resolved, repo.resolve()):
        raise ReceiptValidationError(
            "release evidence must live outside the source worktree"
        )


def _validate_artifacts(
    receipt: dict[str, Any],
    *,
    receipt_path: Path,
    policy: dict[str, Any],
    repo: Path,
    require_durable: bool,
) -> dict[str, dict[str, Any]]:
    raw_root = receipt.get("evidence_root")
    if not isinstance(raw_root, str) or not raw_root.startswith("/"):
        raise ReceiptValidationError("evidence_root must be an absolute path")
    raw_evidence_root = Path(raw_root)
    if raw_evidence_root.is_symlink():
        raise ReceiptValidationError("evidence_root cannot be a symlink")
    evidence_root = raw_evidence_root.resolve()
    if require_durable:
        require_durable_evidence_path(receipt_path, policy=policy, repo=repo)
        require_durable_evidence_path(evidence_root, policy=policy, repo=repo)
    if not _is_relative_to(receipt_path.resolve(), evidence_root):
        raise ReceiptValidationError("receipt must live under evidence_root")
    artifacts = _require_list(receipt.get("artifacts"), "artifacts")
    indexed: dict[str, dict[str, Any]] = {}
    canonical_artifacts: list[dict[str, Any]] = []
    for index, raw_artifact in enumerate(artifacts):
        artifact = _require_object(raw_artifact, f"artifacts[{index}]")
        artifact_id = artifact.get("id")
        if not isinstance(artifact_id, str) or not re.fullmatch(
            r"[a-z0-9][a-z0-9_.-]*", artifact_id
        ):
            raise ReceiptValidationError(f"artifacts[{index}].id is invalid")
        if artifact_id in indexed:
            raise ReceiptValidationError(f"duplicate artifact id: {artifact_id}")
        relative_path = artifact.get("path")
        if (
            not isinstance(relative_path, str)
            or not relative_path
            or Path(relative_path).is_absolute()
        ):
            raise ReceiptValidationError(
                f"artifact {artifact_id} path must be relative to evidence_root"
            )
        artifact_candidate = evidence_root / relative_path
        if artifact_candidate.is_symlink():
            raise ReceiptValidationError(f"artifact cannot be a symlink: {artifact_id}")
        artifact_path = artifact_candidate.resolve()
        if not _is_relative_to(artifact_path, evidence_root):
            raise ReceiptValidationError(f"artifact escapes evidence_root: {artifact_id}")
        if artifact_path.is_symlink() or not artifact_path.is_file():
            raise ReceiptValidationError(f"artifact is missing or a symlink: {artifact_id}")
        expected_sha = _require_sha256(
            artifact.get("sha256"), f"artifact {artifact_id}.sha256"
        )
        expected_size = _require_positive_int(
            artifact.get("size_bytes"), f"artifact {artifact_id}.size_bytes"
        )
        if artifact_path.stat().st_size != expected_size:
            raise ReceiptValidationError(f"artifact size drift: {artifact_id}")
        if file_sha256(artifact_path) != expected_sha:
            raise ReceiptValidationError(f"artifact hash drift: {artifact_id}")
        normalized = {
            "id": artifact_id,
            "path": relative_path,
            "sha256": expected_sha,
            "size_bytes": expected_size,
        }
        indexed[artifact_id] = {
            **normalized,
            "_resolved_path": artifact_path,
        }
        canonical_artifacts.append(normalized)
    required_artifacts = _require_list(
        policy.get("required_artifact_ids"), "policy.required_artifact_ids"
    )
    missing = [item for item in required_artifacts if item not in indexed]
    if missing:
        raise ReceiptValidationError(
            "receipt is missing required artifacts: " + ", ".join(missing)
        )
    expected_manifest_sha = canonical_sha256(
        sorted(canonical_artifacts, key=lambda item: item["id"])
    )
    _require_exact(
        receipt.get("artifact_manifest_sha256"),
        expected_manifest_sha,
        "artifact_manifest_sha256",
    )
    return indexed


def _validate_canonical_producer(
    receipt: dict[str, Any],
    *,
    policy: dict[str, Any],
    repo: Path,
) -> None:
    producer = _require_object(receipt.get("producer"), "producer")
    expected = _require_object(
        policy.get("canonical_producer"), "policy.canonical_producer"
    )
    _require_exact(producer.get("id"), expected.get("id"), "producer.id")
    _require_exact(producer.get("path"), expected.get("path"), "producer.path")
    producer_path = (repo / str(expected.get("path"))).resolve()
    if not _is_relative_to(producer_path, repo) or not producer_path.is_file():
        raise ReceiptValidationError("canonical producer path is invalid")
    _require_exact(
        producer.get("source_sha256"),
        file_sha256(producer_path),
        "producer.source_sha256",
    )


def _artifact_path(
    artifacts: dict[str, dict[str, Any]], artifact_id: str
) -> Path:
    artifact = artifacts.get(artifact_id)
    if artifact is None:
        raise ReceiptValidationError(f"required semantic artifact missing: {artifact_id}")
    path = artifact.get("_resolved_path")
    if not isinstance(path, Path):
        raise ReceiptValidationError(f"artifact has no resolved path: {artifact_id}")
    return path


def _validate_artifact_semantics(
    receipt: dict[str, Any],
    *,
    policy: dict[str, Any],
    artifacts: dict[str, dict[str, Any]],
    credential_file: Path,
) -> None:
    """Cross-check the v2 envelope against canonical producer outputs."""
    audit = load_json_strict(
        _artifact_path(artifacts, "pg_hermes_sqlite_audit_json")
    )
    migration = load_json_strict(_artifact_path(artifacts, "migration_status_log"))
    preflight = load_json_strict(_artifact_path(artifacts, "read_only_preflight_log"))
    receipt_started = _parse_timestamp(receipt.get("started_at"), "started_at")
    receipt_completed = _parse_timestamp(receipt.get("completed_at"), "completed_at")
    for label, artifact_payload in (
        ("PG audit", audit),
        ("migration", migration),
        ("read-only preflight", preflight),
    ):
        artifact_time = _parse_timestamp(
            artifact_payload.get("generated_at"), f"{label} generated_at"
        )
        if not receipt_started <= artifact_time <= receipt_completed:
            raise ReceiptValidationError(
                f"{label} artifact timestamp is outside producer run"
            )
    _require_exact(audit.get("status"), "pass", "PG audit status")
    _require_exact(
        audit.get("mutations_performed"), [], "PG audit mutations_performed"
    )
    audit_target = audit.get("postgres_target")
    if not isinstance(audit_target, str) or audit_target.lower() in {
        "",
        "none",
        "skipped",
        "unknown",
    }:
        raise ReceiptValidationError("PG audit target is missing")
    expected_checks = [
        check_id
        for check_id in policy["release_check_ids"]
        if check_id != "pg_schema_migrations.038_058"
    ]
    raw_checks = _require_list(audit.get("checks"), "PG audit checks")
    actual_checks: list[str] = []
    for index, raw_check in enumerate(raw_checks):
        check = _require_object(raw_check, f"PG audit checks[{index}]")
        name = check.get("name")
        if not isinstance(name, str):
            raise ReceiptValidationError("PG audit check name is invalid")
        actual_checks.append(name)
        _require_exact(check.get("status"), "pass", f"PG audit check {name}")
    if actual_checks != expected_checks:
        raise ReceiptValidationError("PG audit semantic check catalog mismatch")
    audit_summary = _require_object(audit.get("summary"), "PG audit summary")
    _require_exact(
        audit_summary.get("check_count"), len(expected_checks), "PG audit check_count"
    )
    _require_exact(
        audit_summary.get("status_counts"),
        {"pass": len(expected_checks)},
        "PG audit status_counts",
    )

    credential_values = _read_env_data(credential_file)
    _require_exact(
        preflight.get("transaction_read_only"),
        "on",
        "read-only preflight transaction_read_only",
    )
    _require_exact(
        preflight.get("database"),
        credential_values.get("DB_NAME"),
        "read-only preflight database",
    )
    _require_exact(
        preflight.get("user"),
        credential_values.get("DB_USER"),
        "read-only preflight user",
    )
    _require_exact(
        preflight.get("pg_wrapper_mode"),
        "read-only",
        "read-only preflight wrapper mode",
    )
    _require_exact(
        preflight.get("expected_ssh_host_key_sha256"),
        receipt["target"].get("expected_ssh_host_key_sha256"),
        "read-only preflight SSH host key",
    )
    _require_exact(
        preflight.get("write_authorization_used"),
        False,
        "read-only preflight write authorization",
    )

    target_schema = _require_object(receipt["target"].get("schema"), "target.schema")
    source_policy = policy["source"]
    for field, expected in (
        ("required_range", source_policy["required_migration_range"]),
        ("required_versions", source_policy["required_migration_versions"]),
        ("latest_applied", source_policy["required_latest_migration"]),
        ("pending_versions", []),
    ):
        _require_exact(migration.get(field), expected, f"migration artifact {field}")
        _require_exact(
            target_schema.get(field), expected, f"target.schema semantic {field}"
        )
    _require_exact(
        migration.get("transaction_read_only"),
        "on",
        "migration artifact transaction_read_only",
    )
    _require_exact(
        migration.get("database"),
        credential_values.get("DB_NAME"),
        "migration artifact database",
    )
    _require_exact(
        migration.get("applied_versions"),
        target_schema.get("applied_versions"),
        "migration artifact applied_versions",
    )
    _require_exact(
        migration.get("applied_versions_sha256"),
        target_schema.get("applied_versions_sha256"),
        "migration artifact applied_versions_sha256",
    )


def _validate_source_binding(
    source: dict[str, Any],
    *,
    current_source: dict[str, Any],
    policy: dict[str, Any],
) -> None:
    field_map = {
        "git_sha": "git_sha",
        "git_dirty": "git_dirty",
        "worktree_digest_sha256": "worktree_digest_sha256",
        "project_logic_source_digest": "project_logic_source_digest",
        "project_logic_manifest_sha256": "project_logic_manifest_sha256",
        "migration_source_sha256": "migration_source_sha256",
        "latest_migration": "latest_migration",
        "policy_sha256": "policy_sha256",
        "guarded_local_artifacts": "guarded_local_artifacts",
    }
    for receipt_prefix, current_key in field_map.items():
        expected = current_source.get(current_key)
        _require_exact(
            source.get(f"{receipt_prefix}_start"),
            expected,
            f"source.{receipt_prefix}_start",
        )
        _require_exact(
            source.get(f"{receipt_prefix}_end"),
            expected,
            f"source.{receipt_prefix}_end",
        )
    _require_exact(
        current_source.get("git_dirty"),
        False,
        "current source git_dirty",
    )
    required_latest = policy.get("source", {}).get("required_latest_migration")
    _require_exact(
        current_source.get("latest_migration"),
        required_latest,
        "current source latest_migration",
    )


def _validate_target(
    target: dict[str, Any],
    *,
    expected_target: dict[str, str],
    policy: dict[str, Any],
) -> None:
    _require_exact(
        target.get("credential_config_sha256"),
        expected_target["credential_config_sha256"],
        "target.credential_config_sha256",
    )
    _require_exact(
        target.get("identity_sha256"),
        expected_target["identity_sha256"],
        "target.identity_sha256",
    )
    _require_exact(
        target.get("expected_ssh_host_key_sha256"),
        expected_target["expected_ssh_host_key_sha256"],
        "target.expected_ssh_host_key_sha256",
    )
    schema = _require_object(target.get("schema"), "target.schema")
    source_policy = _require_object(policy.get("source"), "policy.source")
    required_versions = _require_list(
        source_policy.get("required_migration_versions"),
        "policy.source.required_migration_versions",
    )
    _require_exact(
        schema.get("required_range"),
        source_policy.get("required_migration_range"),
        "target.schema.required_range",
    )
    _require_exact(
        schema.get("required_versions"),
        required_versions,
        "target.schema.required_versions",
    )
    applied = _require_list(schema.get("applied_versions"), "target.schema.applied_versions")
    if len(applied) != len(set(applied)) or not all(
        isinstance(item, str) and re.fullmatch(r"[0-9]{3}", item)
        for item in applied
    ):
        raise ReceiptValidationError("target.schema.applied_versions is invalid")
    missing = [item for item in required_versions if item not in applied]
    if missing:
        raise ReceiptValidationError(
            "required migrations are not applied: " + ", ".join(missing)
        )
    latest = source_policy.get("required_latest_migration")
    _require_exact(schema.get("latest_applied"), latest, "target.schema.latest_applied")
    _require_exact(schema.get("pending_versions"), [], "target.schema.pending_versions")
    _require_exact(
        schema.get("applied_versions_sha256"),
        canonical_sha256(applied),
        "target.schema.applied_versions_sha256",
    )
    hermes = _require_object(target.get("hermes"), "target.hermes")
    _require_sha256(hermes.get("sqlite_sha256"), "target.hermes.sqlite_sha256")
    _require_positive_int(
        hermes.get("sqlite_size_bytes"), "target.hermes.sqlite_size_bytes"
    )


def _validate_safety(safety: dict[str, Any]) -> None:
    exact = {
        "pg_wrapper_mode": "read-only",
        "transaction_read_only": True,
        "sqlite_open_mode": "ro",
        "network_scope": "postgres_read_only_tunnel_only",
        "external_http_requests": [],
        "live_api_requests": [],
        "mutations_performed": [],
        "ddl_statements": [],
        "dml_statements": [],
        "write_authorization_used": False,
    }
    for key, expected in exact.items():
        _require_exact(safety.get(key), expected, f"safety.{key}")


def _validate_checks(
    receipt: dict[str, Any],
    *,
    policy: dict[str, Any],
    artifacts: dict[str, dict[str, Any]],
) -> None:
    checks = _require_list(receipt.get("checks"), "checks")
    expected_ids = _require_list(policy.get("release_check_ids"), "policy.release_check_ids")
    actual_ids: list[str] = []
    referenced_artifacts: set[str] = set()
    for index, raw_check in enumerate(checks):
        check = _require_object(raw_check, f"checks[{index}]")
        check_id = check.get("id")
        if not isinstance(check_id, str):
            raise ReceiptValidationError(f"checks[{index}].id is invalid")
        actual_ids.append(check_id)
        _require_exact(check.get("status"), "PASS", f"check {check_id}.status")
        artifact_ids = _require_list(
            check.get("artifact_ids"), f"check {check_id}.artifact_ids"
        )
        if not artifact_ids or len(artifact_ids) != len(set(artifact_ids)):
            raise ReceiptValidationError(
                f"check {check_id} must reference unique evidence artifacts"
            )
        unknown = [item for item in artifact_ids if item not in artifacts]
        if unknown:
            raise ReceiptValidationError(
                f"check {check_id} references unknown artifacts: {unknown}"
            )
        referenced_artifacts.update(artifact_ids)
    if len(actual_ids) != len(set(actual_ids)):
        raise ReceiptValidationError("duplicate release check ids")
    if actual_ids != expected_ids:
        missing = [item for item in expected_ids if item not in actual_ids]
        extra = [item for item in actual_ids if item not in expected_ids]
        raise ReceiptValidationError(
            "release check catalog mismatch: "
            f"expected={len(expected_ids)} actual={len(actual_ids)} "
            f"missing={missing} extra={extra}"
        )
    required_artifacts = set(
        _require_list(policy.get("required_artifact_ids"), "policy.required_artifact_ids")
    )
    if not required_artifacts.issubset(referenced_artifacts):
        raise ReceiptValidationError("required artifacts are not referenced by checks")
    summary = _require_object(receipt.get("summary"), "summary")
    exact_summary = {
        "check_count": len(expected_ids),
        "passed_count": len(expected_ids),
        "failed_count": 0,
        "blocked_count": 0,
        "skipped_count": 0,
    }
    for key, expected in exact_summary.items():
        _require_exact(summary.get(key), expected, f"summary.{key}")
        if isinstance(summary.get(key), bool):
            raise ReceiptValidationError(f"summary.{key} cannot be boolean")


def validate_release_receipt(
    receipt_path: Path,
    policy_path: Path,
    repo: Path,
    credential_file: Path,
    *,
    max_age_hours: int,
    require_durable: bool = True,
    now: datetime | None = None,
    current_source: dict[str, Any] | None = None,
    expected_ssh_host_key_sha256: str | None = None,
) -> dict[str, Any]:
    if isinstance(max_age_hours, bool) or max_age_hours <= 0:
        raise ReceiptValidationError("max_age_hours must be positive")
    if receipt_path.is_symlink():
        raise ReceiptValidationError("release receipt cannot be a symlink")
    receipt_path = receipt_path.resolve()
    policy_path = policy_path.resolve()
    repo = repo.resolve()
    credential_file = credential_file.resolve()
    if not receipt_path.is_file():
        raise ReceiptValidationError("release receipt is missing")
    if not credential_file.is_file():
        raise ReceiptValidationError("credential configuration is not readable")
    policy = load_json_strict(policy_path)
    receipt = load_json_strict(receipt_path)
    _require_exact(
        receipt.get("schema"),
        policy.get("release_receipt_schema"),
        "schema",
    )
    gate = _require_object(receipt.get("gate"), "gate")
    _require_exact(gate.get("id"), policy.get("gate_id"), "gate.id")
    _require_exact(gate.get("profile"), policy.get("release_profile"), "gate.profile")
    _require_exact(
        gate.get("policy_sha256"), file_sha256(policy_path), "gate.policy_sha256"
    )
    _require_exact(receipt.get("status"), "PASS", "status")
    _validate_canonical_producer(receipt, policy=policy, repo=repo)
    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    generated_at = _parse_timestamp(receipt.get("generated_at"), "generated_at")
    started_at = _parse_timestamp(receipt.get("started_at"), "started_at")
    completed_at = _parse_timestamp(receipt.get("completed_at"), "completed_at")
    if not started_at <= completed_at <= generated_at:
        raise ReceiptValidationError("receipt timestamps are out of order")
    age_seconds = (now - generated_at).total_seconds()
    if age_seconds < -300:
        raise ReceiptValidationError("receipt timestamp is in the future")
    if age_seconds > max_age_hours * 3600:
        raise ReceiptValidationError(f"receipt is stale: age_seconds={int(age_seconds)}")
    current_source = current_source or capture_source_state(repo, policy_path)
    source = _require_object(receipt.get("source"), "source")
    _validate_source_binding(
        source,
        current_source=current_source,
        policy=policy,
    )
    target = _require_object(receipt.get("target"), "target")
    _validate_target(
        target,
        expected_target=target_binding(
            credential_file,
            expected_ssh_host_key_sha256=expected_ssh_host_key_sha256,
        ),
        policy=policy,
    )
    _validate_safety(_require_object(receipt.get("safety"), "safety"))
    artifacts = _validate_artifacts(
        receipt,
        receipt_path=receipt_path,
        policy=policy,
        repo=repo,
        require_durable=require_durable,
    )
    _validate_artifact_semantics(
        receipt,
        policy=policy,
        artifacts=artifacts,
        credential_file=credential_file,
    )
    _validate_checks(receipt, policy=policy, artifacts=artifacts)
    return {
        "status": "PASS",
        "schema": policy.get("release_receipt_schema"),
        "gate": policy.get("gate_id"),
        "git_sha": current_source["git_sha"],
        "project_logic_source_digest": current_source[
            "project_logic_source_digest"
        ],
        "target_identity_sha256": target["identity_sha256"],
        "receipt_sha256": file_sha256(receipt_path),
        "age_seconds": int(age_seconds),
        "check_count": len(policy["release_check_ids"]),
        "artifact_count": len(artifacts),
        "mutations_performed": [],
    }


def _relative_evidence_artifact(
    evidence_root: Path,
    artifact_id: str,
    path: Path,
) -> dict[str, Any]:
    if path.is_symlink():
        raise ReceiptValidationError(f"producer artifact is a symlink: {artifact_id}")
    resolved = path.resolve()
    if not _is_relative_to(resolved, evidence_root) or not resolved.is_file():
        raise ReceiptValidationError(
            f"producer artifact is outside evidence root or missing: {artifact_id}"
        )
    if resolved.stat().st_size <= 0:
        raise ReceiptValidationError(f"producer artifact is invalid: {artifact_id}")
    return {
        "id": artifact_id,
        "path": resolved.relative_to(evidence_root).as_posix(),
        "sha256": file_sha256(resolved),
        "size_bytes": resolved.stat().st_size,
    }


def assemble_release_receipt(
    *,
    repo: Path,
    policy_path: Path,
    credential_file: Path,
    evidence_root: Path,
    output_path: Path,
    source_start_path: Path,
    source_end_path: Path,
    pg_audit_json_path: Path,
    pg_audit_log_path: Path,
    migration_status_path: Path,
    read_only_preflight_path: Path,
    knowledge_db_path: Path,
    started_at: str,
) -> dict[str, Any]:
    """Assemble only from outputs emitted by the canonical read-only runner."""
    repo = repo.resolve()
    policy_path = policy_path.resolve()
    credential_file = credential_file.resolve()
    if evidence_root.is_symlink():
        raise ReceiptValidationError("evidence root cannot be a symlink")
    evidence_root = evidence_root.resolve()
    output_path = output_path.resolve()
    policy = load_json_strict(policy_path)
    require_durable_evidence_path(evidence_root, policy=policy, repo=repo)
    if not _is_relative_to(output_path, evidence_root):
        raise ReceiptValidationError("release receipt output must be under evidence root")
    if output_path.exists():
        raise ReceiptValidationError("release receipt output already exists")
    source_start = load_json_strict(source_start_path)
    source_end = load_json_strict(source_end_path)
    verify_source_stable(source_start, source_end, require_clean=True)
    guarded_paths = policy["source"]["guarded_local_artifacts"]
    if len(guarded_paths) != 1:
        raise ReceiptValidationError("producer expects one canonical Hermes cache")
    expected_knowledge_db = (repo / guarded_paths[0]).resolve()
    if knowledge_db_path.resolve() != expected_knowledge_db:
        raise ReceiptValidationError("producer must audit the canonical Hermes cache")
    guarded_state = source_end["guarded_local_artifacts"].get(guarded_paths[0])
    if not isinstance(guarded_state, dict) or guarded_state.get("state") != "present":
        raise ReceiptValidationError("canonical Hermes cache is missing")
    if guarded_state.get("sha256") != file_sha256(expected_knowledge_db):
        raise ReceiptValidationError("Hermes cache changed outside source snapshots")

    audit = load_json_strict(pg_audit_json_path)
    migration = load_json_strict(migration_status_path)
    preflight = load_json_strict(read_only_preflight_path)
    if Path(str(audit.get("sqlite_db") or "")).resolve() != expected_knowledge_db:
        raise ReceiptValidationError("PG audit used a different Hermes cache")
    applied_versions = migration.get("applied_versions")
    if not isinstance(applied_versions, list):
        raise ReceiptValidationError("migration producer output has no applied_versions")
    migration["applied_versions_sha256"] = canonical_sha256(applied_versions)
    _write_json(migration_status_path, migration)

    artifacts = [
        _relative_evidence_artifact(
            evidence_root,
            "pg_hermes_sqlite_audit_json",
            pg_audit_json_path,
        ),
        _relative_evidence_artifact(
            evidence_root,
            "pg_hermes_sqlite_audit_log",
            pg_audit_log_path,
        ),
        _relative_evidence_artifact(
            evidence_root,
            "migration_status_log",
            migration_status_path,
        ),
        _relative_evidence_artifact(
            evidence_root,
            "read_only_preflight_log",
            read_only_preflight_path,
        ),
    ]
    artifact_ids = {item["id"] for item in artifacts}
    checks = []
    for check_id in policy["release_check_ids"]:
        evidence_ids = (
            ["migration_status_log", "read_only_preflight_log"]
            if check_id == "pg_schema_migrations.038_058"
            else ["pg_hermes_sqlite_audit_json", "pg_hermes_sqlite_audit_log"]
        )
        if not set(evidence_ids).issubset(artifact_ids):
            raise ReceiptValidationError("producer artifact mapping is incomplete")
        checks.append(
            {"id": check_id, "status": "PASS", "artifact_ids": evidence_ids}
        )

    source: dict[str, Any] = {}
    for field, value in source_start.items():
        source[f"{field}_start"] = value
        source[f"{field}_end"] = source_end.get(field)
    now = datetime.now(timezone.utc).replace(microsecond=0)
    target = target_binding(credential_file)
    target["schema"] = {
        "required_range": migration.get("required_range"),
        "required_versions": migration.get("required_versions"),
        "applied_versions": applied_versions,
        "latest_applied": migration.get("latest_applied"),
        "pending_versions": migration.get("pending_versions"),
        "applied_versions_sha256": migration["applied_versions_sha256"],
    }
    target["hermes"] = {
        "sqlite_sha256": file_sha256(expected_knowledge_db),
        "sqlite_size_bytes": expected_knowledge_db.stat().st_size,
    }
    producer_policy = policy["canonical_producer"]
    producer_path = repo / producer_policy["path"]
    payload = {
        "schema": policy["release_receipt_schema"],
        "producer": {
            "id": producer_policy["id"],
            "path": producer_policy["path"],
            "source_sha256": file_sha256(producer_path),
        },
        "gate": {
            "id": policy["gate_id"],
            "profile": policy["release_profile"],
            "policy_sha256": file_sha256(policy_path),
        },
        "status": "PASS",
        "started_at": _parse_timestamp(started_at, "started_at").isoformat(),
        "completed_at": now.isoformat(),
        "generated_at": now.isoformat(),
        "evidence_root": str(evidence_root),
        "source": source,
        "target": target,
        "safety": {
            "pg_wrapper_mode": preflight.get("pg_wrapper_mode"),
            "transaction_read_only": preflight.get("transaction_read_only") == "on",
            "sqlite_open_mode": "ro",
            "network_scope": "postgres_read_only_tunnel_only",
            "external_http_requests": [],
            "live_api_requests": [],
            "mutations_performed": [],
            "ddl_statements": [],
            "dml_statements": [],
            "write_authorization_used": preflight.get("write_authorization_used"),
        },
        "checks": checks,
        "artifacts": artifacts,
        "artifact_manifest_sha256": canonical_sha256(
            sorted(artifacts, key=lambda item: item["id"])
        ),
        "summary": {
            "check_count": len(checks),
            "passed_count": len(checks),
            "failed_count": 0,
            "blocked_count": 0,
            "skipped_count": 0,
        },
    }
    _write_json(output_path, payload)
    validate_release_receipt(
        output_path,
        policy_path,
        repo,
        credential_file,
        max_age_hours=1,
        require_durable=True,
    )
    return payload


def _write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, indent=2, ensure_ascii=True, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    snapshot = subparsers.add_parser("snapshot-source")
    snapshot.add_argument("--repo", type=Path, required=True)
    snapshot.add_argument("--policy", type=Path, required=True)
    snapshot.add_argument("--out", type=Path, required=True)

    stable = subparsers.add_parser("verify-source-stable")
    stable.add_argument("--start", type=Path, required=True)
    stable.add_argument("--end", type=Path, required=True)
    stable.add_argument("--require-clean", action="store_true")

    durable = subparsers.add_parser("check-durable-path")
    durable.add_argument("--path", type=Path, required=True)
    durable.add_argument("--policy", type=Path, required=True)
    durable.add_argument("--repo", type=Path, required=True)

    validate = subparsers.add_parser("validate-release")
    validate.add_argument("--receipt", type=Path, required=True)
    validate.add_argument("--policy", type=Path, required=True)
    validate.add_argument("--repo", type=Path, required=True)
    validate.add_argument("--credential-file", type=Path, required=True)
    validate.add_argument("--max-age-hours", type=int, required=True)

    assemble = subparsers.add_parser("assemble-release")
    assemble.add_argument("--repo", type=Path, required=True)
    assemble.add_argument("--policy", type=Path, required=True)
    assemble.add_argument("--credential-file", type=Path, required=True)
    assemble.add_argument("--evidence-root", type=Path, required=True)
    assemble.add_argument("--out", type=Path, required=True)
    assemble.add_argument("--source-start", type=Path, required=True)
    assemble.add_argument("--source-end", type=Path, required=True)
    assemble.add_argument("--pg-audit-json", type=Path, required=True)
    assemble.add_argument("--pg-audit-log", type=Path, required=True)
    assemble.add_argument("--migration-status", type=Path, required=True)
    assemble.add_argument("--read-only-preflight", type=Path, required=True)
    assemble.add_argument("--knowledge-db", type=Path, required=True)
    assemble.add_argument("--started-at", required=True)
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = _build_parser().parse_args(list(argv) if argv is not None else None)
    try:
        if args.command == "snapshot-source":
            _write_json(args.out, capture_source_state(args.repo, args.policy))
            return 0
        if args.command == "verify-source-stable":
            result = verify_source_stable(
                load_json_strict(args.start),
                load_json_strict(args.end),
                require_clean=args.require_clean,
            )
            print(json.dumps({"status": "PASS", "source": result}, sort_keys=True))
            return 0
        if args.command == "check-durable-path":
            policy = load_json_strict(args.policy)
            require_durable_evidence_path(
                args.path,
                policy=policy,
                repo=args.repo,
            )
            print(
                json.dumps(
                    {"status": "PASS", "durable_path": str(args.path.resolve())},
                    sort_keys=True,
                )
            )
            return 0
        if args.command == "assemble-release":
            payload = assemble_release_receipt(
                repo=args.repo,
                policy_path=args.policy,
                credential_file=args.credential_file,
                evidence_root=args.evidence_root,
                output_path=args.out,
                source_start_path=args.source_start,
                source_end_path=args.source_end,
                pg_audit_json_path=args.pg_audit_json,
                pg_audit_log_path=args.pg_audit_log,
                migration_status_path=args.migration_status,
                read_only_preflight_path=args.read_only_preflight,
                knowledge_db_path=args.knowledge_db,
                started_at=args.started_at,
            )
            print(
                json.dumps(
                    {
                        "status": payload["status"],
                        "receipt": str(args.out.resolve()),
                        "check_count": payload["summary"]["check_count"],
                    },
                    sort_keys=True,
                )
            )
            return 0
        result = validate_release_receipt(
            args.receipt,
            args.policy,
            args.repo,
            args.credential_file,
            max_age_hours=args.max_age_hours,
        )
        print(json.dumps(result, sort_keys=True))
        return 0
    except ReceiptValidationError as exc:
        print(f"BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
