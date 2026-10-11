#!/usr/bin/env python3
"""Revisão da promoção, item 2 (D-104, item 12): sem volta automática do backend
para uma imagem que não aceita o banco migrado.

O readiness do backend exige MAX(version) igual à última migration que a imagem
conhece; 41bab49c9 exige a 058, e depois do lote o banco está na 077. O Swarm
(`--update-failure-action rollback`) e o trap do deploy (`rollback_backend_deploy`)
voltavam para ela mesmo assim, e a API ficava em 503. Provas, sem servidor real,
sob o /bin/bash de verdade:

- a biblioteca `scripts/lib/manaloom_backend_rollback_guard.sh`: a migration que a
  imagem de um commit exige (as duas formas do readiness têm de concordar), a
  política (`rollback` só com a mesma migration do banco) e a ação do Swarm;
- o bloco da guarda do deploy, recortado do script e rodado com `ssh` e o wrapper
  do PostgreSQL falsos: com a imagem anterior na 058 e o banco na 077, o Swarm
  pausa; com a mesma migration, volta;
- o trap `rollback_backend_deploy`, recortado do script e rodado com `ssh`,
  `trpc_post` e `curl` falsos: com a política `restore` (ou sem política) ele
  recusa sem chamar nada e imprime o caminho de restore; com `rollback`, volta.
"""

from __future__ import annotations

import os
import re
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LIB = REPO_ROOT / "scripts" / "lib" / "manaloom_backend_rollback_guard.sh"
DEPLOY = REPO_ROOT / "scripts" / "manaloom_deploy_backend_image.sh"
RUNBOOK = REPO_ROOT / "docs" / "runbooks" / "BACKUP_E_RESTAURACAO.md"
READINESS = "server/lib/health_readiness_support.dart"
BASH = "/bin/bash"
GUARD_START = "# >>> guarda do rollback automatico"
GUARD_END = "# <<< guarda do rollback automatico"


def _readiness(sql: str, declared: str) -> str:
    return (
        "const releaseSchemaReadinessSql = '''\n"
        f"    ) = '{sql}' AS latest_migration_ready,\n"
        "''';\n"
        f"        'required_range': '038-{declared}',\n"
        f"        'latest_migration': '{declared}',\n"
        f"        'latest_migration': '{declared}',\n"
    )


def _git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, text=True, check=True,
        env={**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.invalid",
             "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.invalid"},
    ).stdout.strip()


class _Repo:
    """Repositório git temporário com um commit por forma do readiness."""

    def __init__(self) -> None:
        self.root = Path(tempfile.mkdtemp(prefix="manaloom-rollback-guard."))
        _git(self.root, "init", "-q")
        self.commits: dict[str, str] = {}
        for label, content in (
            ("058", _readiness("058", "058")),
            ("077", _readiness("077", "077")),
            ("divergente", _readiness("077", "076")),
            ("sem_check", "const nada = 1;\n"),
        ):
            target = self.root / READINESS
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
            _git(self.root, "add", "-A")
            _git(self.root, "commit", "-q", "-m", label)
            self.commits[label] = _git(self.root, "rev-parse", "HEAD")
        (self.root / READINESS).unlink()
        _git(self.root, "commit", "-q", "-a", "-m", "sem_arquivo")
        self.commits["sem_arquivo"] = _git(self.root, "rev-parse", "HEAD")
        # O wrapper do PostgreSQL falso: devolve o MAX(version) que o teste manda.
        wrapper = self.root / "server" / "bin" / "with_new_server_pg.sh"
        wrapper.parent.mkdir(parents=True, exist_ok=True)
        wrapper.write_text('#!/bin/bash\n[[ "$1" == "--read-only" ]] || exit 9\n'
                           'printf "%s\\n" "$FAKE_DB_LATEST"\n', encoding="utf-8")
        wrapper.chmod(wrapper.stat().st_mode | stat.S_IXUSR)

    def close(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)


def _bash(script: str, *args: str, env: dict[str, str] | None = None
          ) -> subprocess.CompletedProcess:
    return subprocess.run([BASH, "-c", script, "_", *args], capture_output=True, text=True,
                          timeout=60, env={**os.environ, **(env or {})})


def _deploy_section(start: str, end_pattern: str) -> str:
    source = DEPLOY.read_text(encoding="utf-8")
    first = source.index(start)
    match = re.compile(end_pattern, re.MULTILINE).search(source, first)
    assert match is not None, end_pattern
    return source[first:match.end()]


class LibraryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = _Repo()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.repo.close()

    def required(self, sha: str) -> subprocess.CompletedProcess:
        return _bash('set -euo pipefail; source "$1"; '
                     'manaloom_readiness_required_migration "$2" "$3"',
                     str(LIB), str(self.repo.root), sha)

    def test_reads_the_migration_the_image_of_a_commit_requires(self) -> None:
        for label, expected in (("058", "058"), ("077", "077")):
            with self.subTest(commit=label):
                result = self.required(self.repo.commits[label])
                self.assertEqual((result.returncode, result.stdout), (0, expected + "\n"))

    def test_fails_when_it_cannot_tell(self) -> None:
        for label, sha in (
            ("formas divergentes", self.repo.commits["divergente"]),
            ("sem o check", self.repo.commits["sem_check"]),
            ("sem o arquivo", self.repo.commits["sem_arquivo"]),
            ("SHA curto", self.repo.commits["077"][:12]),
            ("SHA desconhecido", "0" * 40),
            ("vazio", ""),
        ):
            with self.subTest(caso=label):
                result = self.required(sha)
                self.assertEqual((result.returncode, result.stdout), (1, ""))

    def test_the_real_production_baseline_requires_058_and_head_follows_the_code(self) -> None:
        baseline = subprocess.run(["git", "-C", str(REPO_ROOT), "rev-parse", "--verify", "-q",
                                   "41bab49c9^{commit}"], capture_output=True, text=True)
        if baseline.returncode != 0:
            self.skipTest("41bab49c9 fora deste clone")
        result = _bash('set -euo pipefail; source "$1"; '
                       'manaloom_readiness_required_migration "$2" "$3"',
                       str(LIB), str(REPO_ROOT), baseline.stdout.strip())
        self.assertEqual(result.stdout.strip(), "058", result.stderr)
        head = subprocess.run(["git", "-C", str(REPO_ROOT), "rev-parse", "HEAD"],
                              capture_output=True, text=True, check=True).stdout.strip()
        text = subprocess.run(["git", "-C", str(REPO_ROOT), "show", f"HEAD:{READINESS}"],
                              capture_output=True, text=True, check=True).stdout
        expected = re.search(r"=\s*'([0-9]{3})'\s+AS\s+latest_migration_ready", text).group(1)
        result = _bash('set -euo pipefail; source "$1"; '
                       'manaloom_readiness_required_migration "$2" "$3"',
                       str(LIB), str(REPO_ROOT), head)
        self.assertEqual(result.stdout.strip(), expected)

    def test_rollback_only_when_the_image_accepts_the_database(self) -> None:
        for previous, database, policy, action in (
            ("077", "077", "rollback", "rollback"),
            ("058", "077", "restore", "pause"),
            ("077", "078", "restore", "pause"),
            ("", "077", "restore", "pause"),
            ("077", "", "restore", "pause"),
            ("77", "77", "restore", "pause"),
            ("abc", "abc", "restore", "pause"),
        ):
            with self.subTest(anterior=previous, banco=database):
                result = _bash('set -euo pipefail; source "$1"; '
                               'policy="$(manaloom_backend_rollback_policy "$2" "$3")"; '
                               'printf "%s %s" "$policy" '
                               '"$(manaloom_swarm_update_failure_action "$policy")"',
                               str(LIB), previous, database)
                self.assertEqual(result.stdout, f"{policy} {action}", result.stderr)

    def test_the_restore_path_points_to_the_runbook(self) -> None:
        result = _bash('source "$1"; manaloom_backend_restore_path 058 077', str(LIB))
        self.assertIn("rollback automatico do backend recusado", result.stderr)
        self.assertIn("exige a migration 058; o banco esta na 077", result.stderr)
        self.assertIn("docs/runbooks/BACKUP_E_RESTAURACAO.md", result.stderr)
        self.assertIn("Restauração da produção (RTO de 4 h)", RUNBOOK.read_text(encoding="utf-8"))


class DeployGuardBlockTest(unittest.TestCase):
    """O bloco da guarda, como está no deploy, com `ssh` e o wrapper falsos."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = _Repo()
        cls.block = _deploy_section(GUARD_START, re.escape(GUARD_END) + r"\n")

    @classmethod
    def tearDownClass(cls) -> None:
        cls.repo.close()

    def run_block(self, git_sha: str, database: str, ssh_fails: bool = False):
        script = (
            'set -euo pipefail\n'
            'source "$LIB"\n'
            'ssh() { [[ "$FAKE_SSH_FAILS" == 1 ]] && return 255; printf "%s" "$FAKE_GIT_SHA"; }\n'
            f'{self.block}'
            'printf "%s|%s|%s|%s|%s" "$PREVIOUS_GIT_SHA" "$PREVIOUS_REQUIRED_MIGRATION" '
            '"$DATABASE_LATEST_MIGRATION" "$BACKEND_ROLLBACK_POLICY" '
            '"$SWARM_UPDATE_FAILURE_ACTION"\n'
        )
        return _bash(script, env={
            "LIB": str(LIB), "ROOT_DIR": str(self.repo.root), "SSH_KEY": "/dev/null",
            "SSH_HOST": "deploy@example.invalid", "SERVICE": "manaloom_api",
            "FAKE_GIT_SHA": git_sha, "FAKE_DB_LATEST": database,
            "FAKE_SSH_FAILS": "1" if ssh_fails else "0",
        })

    def test_an_image_behind_the_migrated_database_pauses_the_swarm(self) -> None:
        sha = self.repo.commits["058"]
        result = self.run_block(sha, "077")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f"{sha}|058|077|restore|pause")
        self.assertIn("sem volta automatica do backend", result.stderr)

    def test_an_image_that_accepts_the_database_keeps_the_automatic_rollback(self) -> None:
        sha = self.repo.commits["077"]
        result = self.run_block(sha, "077")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f"{sha}|077|077|rollback|rollback")
        self.assertNotIn("sem volta automatica", result.stderr)

    def test_unknown_previous_image_pauses(self) -> None:
        for label, sha, ssh_fails in (
            ("ssh falhou", self.repo.commits["077"], True),
            ("sem GIT_SHA na spec", "", False),
            ("readiness ilegível", self.repo.commits["divergente"], False),
            ("commit fora do repositório", "f" * 40, False),
        ):
            with self.subTest(caso=label):
                result = self.run_block(sha, "077", ssh_fails=ssh_fails)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(result.stdout.endswith("|077|restore|pause"), result.stdout)


class RollbackTrapTest(unittest.TestCase):
    """O `rollback_backend_deploy` do deploy, com as chamadas remotas falsas."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.function = _deploy_section("rollback_backend_deploy() {", r"^}\n")

    def run_trap(self, policy: str | None) -> tuple[subprocess.CompletedProcess, list[str]]:
        with tempfile.TemporaryDirectory() as folder:
            calls = Path(folder) / "chamadas"
            calls.touch()
            script = (
                'set -euo pipefail\n'
                'source "$LIB"\n'
                'trpc_post() { echo "trpc $1" >>"$CALLS"; printf "%s" "$FAKE_SERVICES"; }\n'
                'ssh() { echo ssh >>"$CALLS"; return 0; }\n'
                'curl() { echo curl >>"$CALLS"; '
                'printf "%s" \'{"status":"ready","environment":"production"}\'; }\n'
                'sleep() { :; }\n'
                + (f'BACKEND_ROLLBACK_POLICY={policy}\n' if policy is not None
                   else 'BACKEND_ROLLBACK_POLICY=""\n')
                + 'PREVIOUS_REQUIRED_MIGRATION=058\nDATABASE_LATEST_MIGRATION=077\n'
                'SOURCE_MUTATED=0\nROLLBACK_SOURCE_IMAGE=registry/api@sha256:aa\n'
                'PREVIOUS_SPEC_IMAGE=registry/api@sha256:aa\nSERVICE=manaloom_api\n'
                'SSH_KEY=/dev/null\nSSH_HOST=deploy@example.invalid\n'
                'API_BASE_URL=http://api.example.invalid\n'
                'EASYPANEL_PROJECT=p\nEASYPANEL_SERVICE=s\n'
                f'{self.function}'
                'rollback_backend_deploy\n'
            )
            result = _bash(script, env={"LIB": str(LIB), "CALLS": str(calls),
                                        "FAKE_SERVICES": "{}"})
            return result, calls.read_text(encoding="utf-8").split()

    def test_restore_policy_refuses_without_touching_anything(self) -> None:
        for policy in ("restore", None):
            with self.subTest(politica=policy):
                result, calls = self.run_trap(policy)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertEqual(calls, [])
                self.assertIn("rollback automatico do backend recusado", result.stderr)
                self.assertIn("docs/runbooks/BACKUP_E_RESTAURACAO.md", result.stderr)
                self.assertNotIn("restaurando spec e origem anteriores", result.stderr)

    def test_rollback_policy_still_restores_the_previous_image(self) -> None:
        result, calls = self.run_trap("rollback")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["ssh", "curl"])
        self.assertIn("rollback backend comprovado", result.stderr)


if __name__ == "__main__":
    unittest.main()
