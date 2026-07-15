#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import sqlite3
import sys
import tempfile
import unittest
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
        with tempfile.TemporaryDirectory() as tmp:
            planned = module._collect_boot_jobs(
                {"DB_HOST": "example"},
                knowledge_db_path=Path(tmp) / "knowledge.db",
                knowledge_db_has_validator_tables=lambda _: True,
                pending_learning_events_count=lambda _: 2,
            )
        self.assertIn(("pull_learning_events", "pending_learning_events=2"), planned)

    def test_collect_boot_jobs_runs_preflight_for_missing_tables(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            planned = module._collect_boot_jobs(
                {},
                knowledge_db_path=Path(tmp) / "knowledge.db",
                knowledge_db_has_validator_tables=lambda _: False,
                pending_learning_events_count=lambda _: 0,
            )
        self.assertIn(("master_optimizer_preflight", "knowledge_db_missing_validator_tables"), planned)

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
