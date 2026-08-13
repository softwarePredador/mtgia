#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import sqlite3
import sys
import tempfile
import unittest
import urllib.error
import urllib.request
from copy import deepcopy
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "manaloom_ops_daemon.py"
    spec = importlib.util.spec_from_file_location("manaloom_ops_daemon", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ManaLoomOpsDaemonTest(unittest.TestCase):
    def test_base_env_loads_database_values_from_env_file(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / ".env"
            env_file.write_text("DB_HOST=db.example\nDB_NAME=mana\n", encoding="utf-8")
            original_env_file = module.ENV_FILE
            original_db_host = os.environ.pop("DB_HOST", None)
            original_db_name = os.environ.pop("DB_NAME", None)
            try:
                module.ENV_FILE = env_file
                env = module._base_env()
            finally:
                module.ENV_FILE = original_env_file
                if original_db_host is not None:
                    os.environ["DB_HOST"] = original_db_host
                if original_db_name is not None:
                    os.environ["DB_NAME"] = original_db_name
        self.assertEqual(env["DB_HOST"], "db.example")
        self.assertEqual(env["DB_NAME"], "mana")
        self.assertEqual(
            env["MANALOOM_CANONICAL_KNOWN_CARDS_JSON"],
            str(module.CANONICAL_SNAPSHOT),
        )
        self.assertEqual(
            env["MANALOOM_BATTLE_STRATEGY_ARTIFACT_ROOT"],
            str(module.ARTIFACT_DIR / "battle-strategy-audit"),
        )
        self.assertEqual(env["MANALOOM_REPO_DIR"], str(module.REPO_ROOT))

    def test_collect_boot_jobs_runs_pull_for_pending_events(self) -> None:
        module = _load_module()
        original_pull = module.BOOT_PULL_PENDING_EVENTS
        try:
            module.BOOT_PULL_PENDING_EVENTS = True
            with tempfile.TemporaryDirectory() as tmp:
                planned = module._collect_boot_jobs(
                    {"DB_HOST": "example"},
                    knowledge_db_path=Path(tmp) / "knowledge.db",
                    knowledge_db_has_validator_tables=lambda _: True,
                    pending_learning_events_count=lambda _: 2,
                    learning_writes_allowed=True,
                )
        finally:
            module.BOOT_PULL_PENDING_EVENTS = original_pull
        self.assertIn(("pull_learning_events", "pending_learning_events=2"), planned)

    def test_collect_boot_jobs_runs_preflight_for_missing_tables(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            planned = module._collect_boot_jobs(
                {},
                knowledge_db_path=Path(tmp) / "knowledge.db",
                knowledge_db_has_validator_tables=lambda _: False,
                pending_learning_events_count=lambda _: 0,
                preflight_allowed=True,
            )
        self.assertIn(("master_optimizer_preflight", "knowledge_db_missing_validator_tables"), planned)

    def test_collect_boot_jobs_suppresses_legacy_triggers_when_capabilities_are_off(
        self,
    ) -> None:
        module = _load_module()
        original_pull = module.BOOT_PULL_PENDING_EVENTS
        original_preflight = module.RUN_PREFLIGHT_ON_BOOT
        try:
            module.BOOT_PULL_PENDING_EVENTS = True
            module.RUN_PREFLIGHT_ON_BOOT = True
            planned = module._collect_boot_jobs(
                {"DB_HOST": "must-not-be-used"},
                knowledge_db_path=Path("/definitely/missing/knowledge.db"),
                knowledge_db_has_validator_tables=lambda _: False,
                pending_learning_events_count=lambda _: 99,
                learning_writes_allowed=False,
                preflight_allowed=False,
            )
        finally:
            module.BOOT_PULL_PENDING_EVENTS = original_pull
            module.RUN_PREFLIGHT_ON_BOOT = original_preflight

        self.assertEqual(planned, [])

    def test_release_policy_requires_exact_schema_and_fails_closed(self) -> None:
        module = _load_module()
        source = module.REPO_ROOT / "server/config/release_capabilities.json"
        payload = json.loads(source.read_text(encoding="utf-8"))

        with tempfile.TemporaryDirectory() as tmp:
            candidate = Path(tmp) / "release_capabilities.json"
            candidate.write_text(json.dumps(payload), encoding="utf-8")
            valid = module._load_release_policy(candidate)
            self.assertTrue(valid.valid)
            self.assertEqual(set(valid.capabilities), module.EXPECTED_RELEASE_CAPABILITIES)
            self.assertFalse(any(valid.capabilities.values()))

            malformed = deepcopy(payload)
            malformed["unexpected"] = True
            candidate.write_text(json.dumps(malformed), encoding="utf-8")
            self.assertFalse(module._load_release_policy(candidate).valid)

            malformed = deepcopy(payload)
            malformed["capabilities"]["learning_writes"]["unexpected"] = True
            candidate.write_text(json.dumps(malformed), encoding="utf-8")
            self.assertFalse(module._load_release_policy(candidate).valid)

            malformed = deepcopy(payload)
            malformed["capabilities"]["learning_writes"].update(
                {"release_capability": "on", "allowed": False}
            )
            candidate.write_text(json.dumps(malformed), encoding="utf-8")
            self.assertFalse(module._load_release_policy(candidate).valid)

        missing = module._load_release_policy(Path(tmp) / "missing.json")
        self.assertFalse(missing.valid)
        self.assertFalse(missing.allowed("learning_writes"))
        self.assertFalse(missing.allowed("battle_batch"))

    def test_all_off_or_invalid_policy_schedules_only_safe_governor(self) -> None:
        module = _load_module()
        all_off = module._load_release_policy(
            module.REPO_ROOT / "server/config/release_capabilities.json"
        )
        invalid = module.ReleasePolicy(False, "invalid", {})

        for policy in (all_off, invalid):
            self.assertEqual(
                [job.name for job in module._jobs_for_release_policy(policy)],
                ["hermes_cron_governor_report"],
            )

        self.assertEqual(
            {job.name for job in module.JOBS},
            set(module.JOB_REQUIRED_CAPABILITIES),
        )

    def test_unclassified_future_job_is_fail_closed(self) -> None:
        module = _load_module()
        policy = module._load_release_policy(
            module.REPO_ROOT / "server/config/release_capabilities.json"
        )
        unexpected = module.Job(
            name="future_unclassified_job",
            schedule="* * * * *",
            lockfile=Path("/tmp/future-unclassified.lock"),
            command="false",
            script_name="future_unclassified.sh",
        )
        original_jobs = module.JOBS
        try:
            module.JOBS = [*original_jobs, unexpected]
            names = [job.name for job in module._jobs_for_release_policy(policy)]
        finally:
            module.JOBS = original_jobs

        self.assertNotIn(unexpected.name, names)

    def test_base_env_neutralizes_legacy_true_flags(self) -> None:
        module = _load_module()
        legacy_flags = {
            "HERMES_AUTO_PROMOTE_APPLY",
            "HERMES_AUTO_SYNC_APPLY",
            "MANALOOM_BATTLE_RULES_APPLY_PG",
            "MANALOOM_BOOT_PULL_PENDING_EVENTS",
            "MANALOOM_ENABLE_LEARNED_DECK_WRITES",
            "MANALOOM_ENABLE_LEARNING_WRITES",
            "MANALOOM_IMPORT_APPLY",
            "MANALOOM_LEARNING_WRITES",
            "MANALOOM_NATIVE_BATTLE_HTTP_ENABLED",
            "MANALOOM_NATIVE_BATTLE_SYNC_ON_BOOT",
            "MANALOOM_RUN_PREFLIGHT_ON_BOOT",
            "MANALOOM_SYNC_CARD_LEGALITIES_APPLY",
            "MTGIA_SYNC_GIT_PULL",
        }
        previous = {key: os.environ.get(key) for key in legacy_flags}
        try:
            os.environ.update({key: "1" for key in legacy_flags})
            env = module._base_env(module.ReleasePolicy(False, "invalid", {}))
        finally:
            for key, value in previous.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

        for key in legacy_flags:
            self.assertEqual(env[key], "0", key)

    def test_native_sync_and_server_do_not_start_when_battle_batch_is_off(
        self,
    ) -> None:
        module = _load_module()
        original_sync = module.NATIVE_BATTLE_SYNC_ON_BOOT
        original_http = module.NATIVE_BATTLE_HTTP_ENABLED
        original_run = module.subprocess.run
        try:
            module.NATIVE_BATTLE_SYNC_ON_BOOT = True
            module.NATIVE_BATTLE_HTTP_ENABLED = True
            module.subprocess.run = lambda *args, **kwargs: self.fail(
                "native sync subprocess must not execute"
            )
            module._sync_native_battle_rules({}, battle_batch_allowed=False)
            self.assertIsNone(
                module._start_native_battle_http(battle_batch_allowed=False)
            )
        finally:
            module.NATIVE_BATTLE_SYNC_ON_BOOT = original_sync
            module.NATIVE_BATTLE_HTTP_ENABLED = original_http
            module.subprocess.run = original_run

    def test_disabled_runtime_exposes_health_without_battle_surface(self) -> None:
        module = _load_module()
        policy = module._load_release_policy(
            module.REPO_ROOT / "server/config/release_capabilities.json"
        )
        server = module._start_disabled_ops_health(
            policy,
            enabled_jobs=("hermes_cron_governor_report",),
            host="127.0.0.1",
            port=0,
        )
        try:
            host, port = server.server_address
            with urllib.request.urlopen(
                f"http://{host}:{port}/health", timeout=2
            ) as response:
                payload = json.loads(response.read().decode("utf-8"))
                self.assertEqual(response.headers["Cache-Control"], "no-store")
            self.assertEqual(payload["status"], "ok")
            self.assertEqual(
                payload["engine_contract"], "disabled_by_release_capability"
            )
            self.assertEqual(payload["operational_mode"], "safe_housekeeping_only")
            self.assertEqual(
                payload["enabled_jobs"], ["hermes_cron_governor_report"]
            )
            self.assertEqual(
                payload["release_capabilities"]["battle_batch"], "off"
            )
            self.assertEqual(
                payload["release_capabilities"]["learning_writes"], "off"
            )

            with self.assertRaises(urllib.error.HTTPError) as blocked:
                urllib.request.urlopen(f"http://{host}:{port}/simulate", timeout=2)
            self.assertEqual(blocked.exception.code, 404)
        finally:
            server.shutdown()
            server.server_close()

    def test_knowledge_db_has_validator_tables_checks_required_tables(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            conn = sqlite3.connect(db_path)
            try:
                conn.execute("CREATE TABLE decks (id INTEGER PRIMARY KEY)")
                self.assertFalse(module._knowledge_db_has_validator_tables(db_path))
                conn.execute("CREATE TABLE deck_cards (id INTEGER PRIMARY KEY)")
            finally:
                conn.close()
            self.assertTrue(module._knowledge_db_has_validator_tables(db_path))

    def test_load_existing_state_reuses_last_job_status_from_jobs_json(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            jobs_json = Path(tmp) / "jobs.json"
            jobs_json.write_text(
                json.dumps(
                    [
                        {
                            "id": "manaloom_knowledge_import",
                            "name": "manaloom_knowledge_import",
                            "last_status": "ok",
                            "last_started_at": "2026-06-18T07:36:27",
                            "last_finished_at": "2026-06-18T07:36:28",
                            "last_exit_code": 0,
                            "latest_output": "/data/manaloom-ops/cron/output/manaloom_knowledge_import/20260618_073627.log",
                        },
                        {
                            "id": "unknown_job",
                            "name": "unknown_job",
                            "last_status": "error",
                        },
                    ]
                ),
                encoding="utf-8",
            )
            original_jobs_json = module.JOBS_JSON
            try:
                module.JOBS_JSON = jobs_json
                state = module._load_existing_state(module.JOBS)
            finally:
                module.JOBS_JSON = original_jobs_json
        self.assertEqual(state["manaloom_knowledge_import"]["last_status"], "ok")
        self.assertEqual(state["manaloom_knowledge_import"]["last_exit_code"], 0)
        self.assertNotIn("unknown_job", state)

    def test_load_existing_state_recovers_from_latest_log_when_manifest_is_empty(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            jobs_json = Path(tmp) / "jobs.json"
            jobs_json.write_text("[]\n", encoding="utf-8")
            cron_output_dir = Path(tmp) / "cron" / "output" / "manaloom_knowledge_import"
            cron_output_dir.mkdir(parents=True, exist_ok=True)
            log_path = cron_output_dir / "20260618_073627.log"
            log_path.write_text(
                "=== Importando conhecimento Hermes → PostgreSQL ===\n"
                "✔ Houve mudanças nos dados.\n"
                "manaloom_knowledge_import=ok\n",
                encoding="utf-8",
            )
            original_jobs_json = module.JOBS_JSON
            original_output_dir = module.CRON_OUTPUT_DIR
            try:
                module.JOBS_JSON = jobs_json
                module.CRON_OUTPUT_DIR = Path(tmp) / "cron" / "output"
                state = module._load_existing_state(module.JOBS)
            finally:
                module.JOBS_JSON = original_jobs_json
                module.CRON_OUTPUT_DIR = original_output_dir
        self.assertEqual(state["manaloom_knowledge_import"]["last_status"], "ok")
        self.assertEqual(
            state["manaloom_knowledge_import"]["latest_output"],
            str(log_path),
        )
        self.assertEqual(
            state["manaloom_knowledge_import"]["last_started_at"],
            "2026-06-18T07:36:27",
        )

    def test_load_existing_state_marks_running_job_interrupted_after_restart(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            jobs_json = Path(tmp) / "jobs.json"
            jobs_json.write_text(
                json.dumps(
                    [
                        {
                            "id": "manaloom_battle_strategy_audit",
                            "name": "manaloom_battle_strategy_audit",
                            "last_status": "running",
                            "last_started_at": "2026-07-15T12:05:02",
                            "last_exit_code": None,
                        }
                    ]
                ),
                encoding="utf-8",
            )
            original_jobs_json = module.JOBS_JSON
            original_output_dir = module.CRON_OUTPUT_DIR
            try:
                module.JOBS_JSON = jobs_json
                module.CRON_OUTPUT_DIR = Path(tmp) / "cron" / "output"
                state = module._load_existing_state(module.JOBS)
            finally:
                module.JOBS_JSON = original_jobs_json
                module.CRON_OUTPUT_DIR = original_output_dir

        recovered = state["manaloom_battle_strategy_audit"]
        self.assertEqual(recovered["last_status"], "error")
        self.assertEqual(recovered["last_error"], "interrupted_by_process_restart")
        self.assertEqual(recovered["last_started_at"], "2026-07-15T12:05:02")

    def test_load_existing_state_prefers_newer_log_over_stale_manifest_error(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            jobs_json = Path(tmp) / "jobs.json"
            stale_log = (
                "/data/manaloom-ops/cron/output/manaloom_knowledge_import/"
                "20260618_122001.log"
            )
            jobs_json.write_text(
                json.dumps(
                    [
                        {
                            "id": "manaloom_knowledge_import",
                            "name": "manaloom_knowledge_import",
                            "last_status": "error",
                            "last_started_at": "2026-06-18T12:20:01",
                            "last_finished_at": "2026-06-18T12:20:01",
                            "last_exit_code": 1,
                            "latest_output": stale_log,
                        }
                    ]
                ),
                encoding="utf-8",
            )
            cron_output_dir = Path(tmp) / "cron" / "output" / "manaloom_knowledge_import"
            cron_output_dir.mkdir(parents=True, exist_ok=True)
            fresh_log = cron_output_dir / "20260618_171404.log"
            fresh_log.write_text(
                "=== Importando conhecimento Hermes → PostgreSQL ===\n"
                "manaloom_knowledge_import=ok\n",
                encoding="utf-8",
            )
            original_jobs_json = module.JOBS_JSON
            original_output_dir = module.CRON_OUTPUT_DIR
            try:
                module.JOBS_JSON = jobs_json
                module.CRON_OUTPUT_DIR = Path(tmp) / "cron" / "output"
                state = module._load_existing_state(module.JOBS)
            finally:
                module.JOBS_JSON = original_jobs_json
                module.CRON_OUTPUT_DIR = original_output_dir

        self.assertEqual(state["manaloom_knowledge_import"]["last_status"], "ok")
        self.assertEqual(state["manaloom_knowledge_import"]["last_exit_code"], 0)
        self.assertEqual(
            state["manaloom_knowledge_import"]["last_started_at"],
            "2026-06-18T17:14:04",
        )
        self.assertEqual(
            state["manaloom_knowledge_import"]["latest_output"],
            str(fresh_log),
        )

    def test_sync_legalities_job_runs_before_candidate_review(self) -> None:
        module = _load_module()
        names = [job.name for job in module.JOBS]
        self.assertIn("manaloom_sync_card_legalities_from_scryfall", names)
        self.assertLess(
            names.index("manaloom_sync_card_legalities_from_scryfall"),
            names.index("manaloom_new_card_candidate_review"),
        )
        job = module.JOBS[names.index("manaloom_sync_card_legalities_from_scryfall")]
        self.assertEqual(job.schedule, "30 */6 * * *")
        self.assertIn("sync_card_legalities_from_scryfall.sh", job.command)

    def test_ai_runtime_cleanup_is_scheduled_with_reservation_ttl(self) -> None:
        module = _load_module()
        jobs = {job.name: job for job in module.JOBS}

        job = jobs["manaloom_ai_runtime_cleanup"]
        self.assertEqual(job.schedule, "10 4 * * *")
        self.assertIn("cron_cleanup_optimize_telemetry.sh", job.command)
        self.assertIn("--ai-log-retention-days=", job.command)
        self.assertIn("AI_LOG_RETENTION_DAYS", job.command)
        self.assertIn("--job-retention-minutes=", job.command)
        self.assertIn("AI_JOB_RETENTION_MINUTES", job.command)
        self.assertIn("--reservation-ttl-minutes=", job.command)
        self.assertIn("AI_PLAN_RESERVATION_TTL_MINUTES", job.command)
        self.assertIn("--rate-limit-retention-hours=", job.command)
        self.assertIn("RATE_LIMIT_EVENT_RETENTION_HOURS", job.command)
        self.assertFalse(job.background)

    def test_battle_strategy_jobs_produce_gate_evidence_in_background(self) -> None:
        module = _load_module()
        jobs = {job.name: job for job in module.JOBS}
        hourly = jobs["manaloom_battle_strategy_audit"]
        nightly = jobs["manaloom_battle_strategy_nightly"]

        self.assertTrue(hourly.background)
        self.assertTrue(nightly.background)
        self.assertIn("${MANALOOM_BATTLE_STRATEGY_SEEDS:-16}", hourly.command)
        self.assertIn("${MANALOOM_BATTLE_STRATEGY_NIGHTLY_SEEDS:-64}", nightly.command)
        self.assertTrue(module._matches_schedule(hourly.schedule, module.datetime(2026, 7, 15, 5, 5)))
        self.assertFalse(module._matches_schedule(hourly.schedule, module.datetime(2026, 7, 15, 6, 5)))
        self.assertTrue(module._matches_schedule(nightly.schedule, module.datetime(2026, 7, 15, 6, 5)))


if __name__ == "__main__":
    unittest.main()
