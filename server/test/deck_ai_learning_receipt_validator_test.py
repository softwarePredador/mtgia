#!/usr/bin/env python3
"""Behavioral tests for the Deck/AI/Learning v2 release receipt."""

from __future__ import annotations

import copy
import importlib.util
import json
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATOR_PATH = REPO_ROOT / "scripts" / "manaloom_deck_ai_learning_receipt_validator.py"
POLICY_PATH = REPO_ROOT / "server" / "config" / "deck_ai_learning_gate_policy.json"
SPEC = importlib.util.spec_from_file_location("deck_ai_receipt_validator", VALIDATOR_PATH)
assert SPEC is not None and SPEC.loader is not None
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)


class DeckAiLearningReceiptValidatorTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="manaloom-receipt-test-")
        self.root = Path(self.temp.name)
        self.evidence_root = self.root / "durable-evidence"
        self.evidence_root.mkdir()
        self.credential_file = self.root / "server.env"
        self.credential_file.write_text(
            "EASYPANEL_SERVER_IP=203.0.113.10\n"
            "DB_NAME=halder\n"
            "DB_USER=postgres\n"
            "DB_PASS=not-used-by-validator\n",
            encoding="utf-8",
        )
        self.expected_host_key = "SHA256:" + ("A" * 43)
        self.target_kwargs = {
            "expected_ssh_host_key_sha256": self.expected_host_key
        }
        self.policy = validator.load_json_strict(POLICY_PATH)
        policy_sha = validator.file_sha256(POLICY_PATH)
        self.current_source = {
            "git_sha": "a" * 40,
            "git_dirty": False,
            "worktree_digest_sha256": "b" * 64,
            "project_logic_source_digest": "c" * 64,
            "project_logic_manifest_sha256": "d" * 64,
            "migration_source_sha256": "e" * 64,
            "latest_migration": "058",
            "policy_sha256": policy_sha,
            "guarded_local_artifacts": {
                "docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db": {
                    "state": "missing"
                }
            },
        }
        self.receipt_path = self.evidence_root / "receipt.json"
        self.payload = self._valid_payload()
        self._write_receipt()

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _valid_payload(self) -> dict:
        now = datetime.now(timezone.utc).replace(microsecond=0)
        artifact_ids = self.policy["required_artifact_ids"]
        required_versions = self.policy["source"]["required_migration_versions"]
        applied_versions = [f"{version:03d}" for version in range(1, 59)]
        semantic_content = {
            "pg_hermes_sqlite_audit_json": json.dumps(
                {
                    "generated_at": now.isoformat(),
                    "status": "pass",
                    "postgres_target": "127.0.0.1:49152/halder",
                    "sqlite_db": "canonical-knowledge.db",
                    "mutations_performed": [],
                    "summary": {
                        "check_count": len(self.policy["release_check_ids"]) - 1,
                        "status_counts": {
                            "pass": len(self.policy["release_check_ids"]) - 1
                        },
                    },
                    "checks": [
                        {"name": check_id, "status": "pass", "detail": "ok"}
                        for check_id in self.policy["release_check_ids"]
                        if check_id != "pg_schema_migrations.038_058"
                    ],
                },
                sort_keys=True,
            )
            + "\n",
            "pg_hermes_sqlite_audit_log": "canonical audit completed\n",
            "migration_status_log": json.dumps(
                {
                    "generated_at": now.isoformat(),
                    "transaction_read_only": "on",
                    "database": "halder",
                    "required_range": "038-058",
                    "required_versions": required_versions,
                    "applied_versions": applied_versions,
                    "latest_applied": "058",
                    "pending_versions": [],
                    "applied_versions_sha256": validator.canonical_sha256(
                        applied_versions
                    ),
                },
                sort_keys=True,
            )
            + "\n",
            "read_only_preflight_log": json.dumps(
                {
                    "generated_at": now.isoformat(),
                    "transaction_read_only": "on",
                    "database": "halder",
                    "user": "postgres",
                    "pg_wrapper_mode": "read-only",
                    "expected_ssh_host_key_sha256": self.expected_host_key,
                    "write_authorization_used": False,
                },
                sort_keys=True,
            )
            + "\n",
        }
        artifacts = []
        for index, artifact_id in enumerate(artifact_ids):
            path = self.evidence_root / f"artifact-{index}.log"
            path.write_text(semantic_content[artifact_id], encoding="utf-8")
            artifacts.append(
                {
                    "id": artifact_id,
                    "path": path.relative_to(self.evidence_root).as_posix(),
                    "sha256": validator.file_sha256(path),
                    "size_bytes": path.stat().st_size,
                }
            )
        source: dict[str, object] = {}
        for field, value in self.current_source.items():
            source[f"{field}_start"] = copy.deepcopy(value)
            source[f"{field}_end"] = copy.deepcopy(value)
        target = validator.target_binding(self.credential_file, **self.target_kwargs)
        target["schema"] = {
            "required_range": self.policy["source"]["required_migration_range"],
            "required_versions": required_versions,
            "applied_versions": applied_versions,
            "latest_applied": "058",
            "pending_versions": [],
            "applied_versions_sha256": validator.canonical_sha256(applied_versions),
        }
        target["hermes"] = {
            "sqlite_sha256": "f" * 64,
            "sqlite_size_bytes": 1024,
        }
        checks = [
            {
                "id": check_id,
                "status": "PASS",
                "artifact_ids": artifact_ids,
            }
            for check_id in self.policy["release_check_ids"]
        ]
        return {
            "schema": self.policy["release_receipt_schema"],
            "producer": {
                "id": self.policy["canonical_producer"]["id"],
                "path": self.policy["canonical_producer"]["path"],
                "source_sha256": validator.file_sha256(
                    REPO_ROOT / self.policy["canonical_producer"]["path"]
                ),
            },
            "gate": {
                "id": self.policy["gate_id"],
                "profile": self.policy["release_profile"],
                "policy_sha256": validator.file_sha256(POLICY_PATH),
            },
            "status": "PASS",
            "generated_at": now.isoformat(),
            "started_at": (now - timedelta(minutes=2)).isoformat(),
            "completed_at": now.isoformat(),
            "evidence_root": str(self.evidence_root),
            "source": source,
            "target": target,
            "safety": {
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
            },
            "checks": checks,
            "artifacts": artifacts,
            "artifact_manifest_sha256": validator.canonical_sha256(
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

    def _write_receipt(self) -> None:
        self.receipt_path.write_text(
            json.dumps(self.payload, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    def _replace_artifact_json(self, artifact_id: str, value: dict) -> None:
        artifact = next(
            item for item in self.payload["artifacts"] if item["id"] == artifact_id
        )
        path = self.evidence_root / artifact["path"]
        path.write_text(json.dumps(value, sort_keys=True) + "\n", encoding="utf-8")
        artifact["sha256"] = validator.file_sha256(path)
        artifact["size_bytes"] = path.stat().st_size
        self.payload["artifact_manifest_sha256"] = validator.canonical_sha256(
            sorted(self.payload["artifacts"], key=lambda item: item["id"])
        )

    def _validate(self, *, durable: bool = False) -> dict:
        self._write_receipt()
        return validator.validate_release_receipt(
            self.receipt_path,
            POLICY_PATH,
            REPO_ROOT,
            self.credential_file,
            max_age_hours=24,
            require_durable=durable,
            current_source=self.current_source,
            expected_ssh_host_key_sha256=self.expected_host_key,
        )

    def assertBlocked(self, text: str) -> None:  # noqa: N802 - unittest convention
        with self.assertRaisesRegex(validator.ReceiptValidationError, text):
            self._validate()

    def test_valid_v2_receipt_is_bound_to_full_catalog_and_artifacts(self) -> None:
        result = self._validate()

        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["check_count"], len(self.policy["release_check_ids"]))
        self.assertEqual(result["git_sha"], self.current_source["git_sha"])
        self.assertEqual(result["mutations_performed"], [])

    def test_hand_written_one_check_receipt_is_rejected(self) -> None:
        self.payload["checks"] = self.payload["checks"][:1]
        self.payload["summary"]["check_count"] = 1
        self.payload["summary"]["passed_count"] = 1

        self.assertBlocked("release check catalog mismatch")

    def test_legacy_pg_audit_json_is_never_accepted_as_release_receipt(self) -> None:
        self.payload = {
            "status": "pass",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "postgres_target": "127.0.0.1:15432/halder",
            "mutations_performed": [],
            "summary": {"check_count": 1},
            "checks": [{"name": "pg_connection", "status": "pass"}],
        }

        self.assertBlocked("schema must be exactly")

    def test_hashed_artifact_with_one_semantic_check_is_rejected(self) -> None:
        audit_artifact = next(
            item
            for item in self.payload["artifacts"]
            if item["id"] == "pg_hermes_sqlite_audit_json"
        )
        audit = json.loads(
            (self.evidence_root / audit_artifact["path"]).read_text(encoding="utf-8")
        )
        audit["checks"] = audit["checks"][:1]
        audit["summary"] = {"check_count": 1, "status_counts": {"pass": 1}}
        self._replace_artifact_json("pg_hermes_sqlite_audit_json", audit)

        self.assertBlocked("PG audit semantic check catalog mismatch")

    def test_receipt_must_name_current_canonical_producer_hash(self) -> None:
        self.payload["producer"]["source_sha256"] = "0" * 64

        self.assertBlocked("producer.source_sha256")

    def test_duplicate_check_ids_are_rejected(self) -> None:
        self.payload["checks"][1]["id"] = self.payload["checks"][0]["id"]

        self.assertBlocked("duplicate release check ids")

    def test_every_source_identity_is_bound_at_start_and_end(self) -> None:
        for field in (
            "git_sha",
            "worktree_digest_sha256",
            "project_logic_source_digest",
            "project_logic_manifest_sha256",
            "migration_source_sha256",
            "latest_migration",
            "policy_sha256",
            "guarded_local_artifacts",
        ):
            with self.subTest(field=field):
                payload = copy.deepcopy(self.payload)
                payload["source"][f"{field}_end"] = "drift"
                self.payload = payload
                self.assertBlocked(f"source.{field}_end")
                self.payload = self._valid_payload()

    def test_release_rejects_dirty_current_source(self) -> None:
        self.current_source["git_dirty"] = True
        self.payload["source"]["git_dirty_start"] = True
        self.payload["source"]["git_dirty_end"] = True

        self.assertBlocked("clean worktree|current source git_dirty")

    def test_target_and_credential_config_are_exactly_bound(self) -> None:
        self.payload["target"]["identity_sha256"] = "0" * 64

        self.assertBlocked("target.identity_sha256")

    def test_expected_ssh_host_key_is_part_of_target_and_preflight(self) -> None:
        self.payload["target"]["expected_ssh_host_key_sha256"] = (
            "SHA256:" + ("B" * 43)
        )

        self.assertBlocked("target.(identity|expected_ssh_host_key_sha256)")

    def test_schema_058_must_be_applied_with_no_pending_versions(self) -> None:
        self.payload["target"]["schema"]["applied_versions"].remove("058")
        self.payload["target"]["schema"]["applied_versions_sha256"] = (
            validator.canonical_sha256(
                self.payload["target"]["schema"]["applied_versions"]
            )
        )

        self.assertBlocked("required migrations are not applied")

    def test_safety_claims_are_fail_closed(self) -> None:
        for field, unsafe in (
            ("transaction_read_only", False),
            ("mutations_performed", ["UPDATE decks"]),
            ("external_http_requests", ["https://example.invalid"]),
            ("write_authorization_used", True),
        ):
            with self.subTest(field=field):
                payload = copy.deepcopy(self.payload)
                payload["safety"][field] = unsafe
                self.payload = payload
                self.assertBlocked(f"safety.{field}")
                self.payload = self._valid_payload()

    def test_artifact_content_hash_is_recomputed(self) -> None:
        first = self.payload["artifacts"][0]
        (self.evidence_root / first["path"]).write_text(
            "tampered\n", encoding="utf-8"
        )

        self.assertBlocked("artifact (size|hash) drift")

    def test_summary_boolean_cannot_impersonate_check_count(self) -> None:
        self.payload["summary"]["check_count"] = True

        self.assertBlocked("summary.check_count")

    def test_temp_evidence_is_rejected_for_release(self) -> None:
        with self.assertRaisesRegex(
            validator.ReceiptValidationError, "cannot live under a temp root"
        ):
            self._validate(durable=True)

    def test_evidence_inside_worktree_is_explicitly_rejected(self) -> None:
        with self.assertRaisesRegex(
            validator.ReceiptValidationError, "outside the source worktree"
        ):
            validator.require_durable_evidence_path(
                REPO_ROOT / ".ignored-release-evidence",
                policy=self.policy,
                repo=REPO_ROOT,
            )

    def test_strict_json_loader_rejects_duplicate_keys(self) -> None:
        duplicate = self.root / "duplicate.json"
        duplicate.write_text('{"status":"PASS","status":"FAIL"}\n', encoding="utf-8")

        with self.assertRaisesRegex(validator.ReceiptValidationError, "duplicate JSON key"):
            validator.load_json_strict(duplicate)

    def test_source_toc_tou_guard_allows_dirty_local_but_not_release(self) -> None:
        dirty = copy.deepcopy(self.current_source)
        dirty["git_dirty"] = True

        self.assertEqual(
            validator.verify_source_stable(dirty, copy.deepcopy(dirty), require_clean=False),
            dirty,
        )
        with self.assertRaisesRegex(
            validator.ReceiptValidationError, "clean worktree"
        ):
            validator.verify_source_stable(dirty, copy.deepcopy(dirty), require_clean=True)
        changed = copy.deepcopy(dirty)
        changed["worktree_digest_sha256"] = "9" * 64
        with self.assertRaisesRegex(
            validator.ReceiptValidationError, "source state changed"
        ):
            validator.verify_source_stable(dirty, changed, require_clean=False)


if __name__ == "__main__":
    unittest.main()
