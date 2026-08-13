#!/usr/bin/env python3
"""Fail-closed tests for the Markdown/Hermes knowledge import auditor."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
WRAPPER = REPO_ROOT / "server" / "bin" / "manaloom_knowledge_import.sh"
RUNNER = (
    REPO_ROOT
    / "docs"
    / "hermes-analysis"
    / "manaloom-knowledge"
    / "scripts"
    / "run_import.py"
)


class ManaLoomKnowledgeImportTest(unittest.TestCase):
    def test_wrapper_default_is_report_only_without_secrets_or_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            temp_root = Path(tmp)
            runner = temp_root / "fake_runner.py"
            runner.write_text(
                textwrap.dedent(
                    """
                    import json
                    import os
                    import sys

                    print(json.dumps({
                        "argv": sys.argv[1:],
                        "secret_loaded": os.environ.get("KNOWLEDGE_TEST_SECRET"),
                        "database_environment_present": any(
                            os.environ.get(name)
                            for name in (
                                "PGHOST", "PGPORT", "PGDATABASE", "PGUSER",
                                "PGPASSWORD", "DB_HOST", "DB_PORT", "DB_NAME",
                                "DB_USER", "DB_PASS",
                            )
                        ),
                    }, sort_keys=True))
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            secret_file = temp_root / "secrets.env"
            secret_file.write_text(
                "KNOWLEDGE_TEST_SECRET=must_not_be_loaded\n",
                encoding="utf-8",
            )
            artifact_dir = temp_root / "must-not-be-created"
            env = os.environ.copy()
            env.update(
                {
                    "MANALOOM_REPO": str(REPO_ROOT),
                    "MANALOOM_KNOWLEDGE_IMPORT_RUNNER": str(runner),
                    "MANALOOM_KNOWLEDGE_IMPORT_ARTIFACT_DIR": str(artifact_dir),
                    "MANALOOM_POSTGRES_ENV": str(secret_file),
                    "PYTHON_BIN": sys.executable,
                    "PGPASSWORD": "must-not-reach-runner",
                    "DB_PASS": "must-not-reach-runner",
                }
            )

            result = subprocess.run(
                [str(WRAPPER)],
                cwd=REPO_ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            report = json.loads(result.stdout.splitlines()[0])
            self.assertEqual(report["argv"], ["--report-only"])
            self.assertIsNone(report["secret_loaded"])
            self.assertFalse(report["database_environment_present"])
            self.assertIn("knowledge_import_mode=report_only", result.stdout)
            self.assertIn("knowledge_import_postgresql=not_contacted", result.stdout)
            self.assertFalse(artifact_dir.exists())

    def test_wrapper_apply_requests_fail_before_invoking_runner(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            temp_root = Path(tmp)
            marker = temp_root / "runner-was-invoked"
            runner = temp_root / "fake_runner.py"
            runner.write_text(
                "from pathlib import Path\n"
                f"Path({str(marker)!r}).write_text('unexpected', encoding='utf-8')\n",
                encoding="utf-8",
            )
            base_env = os.environ.copy()
            base_env.update(
                {
                    "MANALOOM_REPO": str(REPO_ROOT),
                    "MANALOOM_KNOWLEDGE_IMPORT_RUNNER": str(runner),
                    "PYTHON_BIN": sys.executable,
                }
            )

            for command, extra_env in (
                ([str(WRAPPER), "--apply"], {}),
                ([str(WRAPPER)], {"MANALOOM_IMPORT_APPLY": "1"}),
            ):
                with self.subTest(command=command, extra_env=extra_env):
                    env = base_env | extra_env
                    result = subprocess.run(
                        command,
                        cwd=REPO_ROOT,
                        env=env,
                        text=True,
                        capture_output=True,
                        check=False,
                    )
                    self.assertEqual(result.returncode, 2)
                    self.assertIn("BLOCKED_BT_AI_014", result.stderr)
                    self.assertFalse(marker.exists())

    def test_runner_builds_local_report_without_postgresql(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            knowledge_root = Path(tmp) / "knowledge"
            deck_dir = knowledge_root / "decks" / "talrand"
            deck_dir.mkdir(parents=True)
            (knowledge_root / "THEMES.md").write_text(
                textwrap.dedent(
                    """
                    ### Ramp por Tema
                    | Tema | Faixa | Notas |
                    |---|---|---|
                    | Spellslinger | 10-12 | Priorizar pedras eficientes |
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            (deck_dir / "optimized.md").write_text(
                textwrap.dedent(
                    """
                    Comandante: Talrand, Sky Summoner
                    Lands: 35
                    Ramp: 10

                    | Card | Tag | Function |
                    |---|---|---|
                    | Arcane Signet | Ramp | Mana |

                    **Sol Ring** (80%)
                    """
                ).strip()
                + "\n",
                encoding="utf-8",
            )
            env = os.environ.copy()
            env.update(
                {
                    "MANALOOM_KNOWLEDGE_ROOT": str(knowledge_root),
                    "MANALOOM_IMPORT_APPLY": "0",
                    "PGHOST": "must-not-connect.invalid",
                    "PGPASSWORD": "must-not-be-used",
                }
            )

            result = subprocess.run(
                [sys.executable, str(RUNNER), "--report-only"],
                cwd=REPO_ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            report = json.loads(result.stdout)
            self.assertEqual(report["status"], "report_only")
            self.assertEqual(
                report["candidate_counts"],
                {
                    "theme_contextual_rules": 1,
                    "commander_reference_profiles": 1,
                    "card_deck_profiles": 2,
                    "total": 4,
                },
            )
            self.assertEqual(
                report["postgresql"],
                {
                    "credentials_loaded": False,
                    "connected": False,
                    "queried": False,
                    "mutated": False,
                },
            )
            self.assertFalse(report["apply"]["allowed"])
            self.assertEqual(report["apply"]["blocked_by"], "BT-AI-014")

    def test_runner_apply_request_is_blocked_before_source_scan(self) -> None:
        env = os.environ.copy()
        env.update(
            {
                "MANALOOM_KNOWLEDGE_ROOT": "/path/that/does/not/exist",
                "MANALOOM_IMPORT_APPLY": "1",
            }
        )
        result = subprocess.run(
            [sys.executable, str(RUNNER)],
            cwd=REPO_ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 2)
        report = json.loads(result.stderr)
        self.assertEqual(report["status"], "blocked")
        self.assertEqual(report["blocked_by"], "BT-AI-014")
        self.assertFalse(report["postgresql"]["connected"])
        self.assertFalse(report["postgresql"]["mutated"])

    def test_runner_has_no_database_driver_or_secret_loader(self) -> None:
        source = RUNNER.read_text(encoding="utf-8")
        wrapper_source = WRAPPER.read_text(encoding="utf-8")
        self.assertNotIn("import psycopg2", source)
        self.assertNotIn("from db_helper import", source)
        self.assertNotIn("SECRET_ENV=", wrapper_source)
        self.assertNotIn("source \"$SECRET_ENV\"", wrapper_source)
        self.assertNotIn("mkdir -p", wrapper_source)
        self.assertNotIn("tee \"$log_path\"", wrapper_source)


if __name__ == "__main__":
    unittest.main()
