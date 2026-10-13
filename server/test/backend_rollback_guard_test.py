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
- o bloco da guarda do deploy, recortado do script e rodado com `ssh` falso e um
  wrapper do PostgreSQL que roda a consulta de verdade num `schema_migrations` em
  SQLite: o lado do banco é o MAX(version) do ledger (trocar a consulta por um valor
  fixo derruba o teste); com a imagem anterior na 058 e o banco na 077, o Swarm pausa;
  com a mesma migration, volta;
- o trap `rollback_backend_deploy`, recortado do script e rodado com `ssh`,
  `trpc_post` e `curl` falsos: com a política `restore` (ou sem política) ele
  recusa sem chamar nada e imprime o caminho de restore com o estado verdadeiro do
  Swarm (paused quando o update não convergiu; completed, sem pausa, quando a falha
  veio depois; desconhecido quando não se sabe se o update chegou ao Swarm) e como
  sair dele antes de um deploy de correção: a imagem anterior volta por
  `docker service update --image <digest> --env-add GIT_SHA=<sha>`, explícito e
  idempotente, nunca por `docker service rollback` (depois de um `--force`, ele
  voltaria para a imagem nova); com `rollback`, volta;
- o bloco do update do Swarm, recortado do deploy e rodado com um `ssh` falso que
  executa o lado remoto com `docker`, `base64` e `sleep` falsos: o deploy só diz que
  o Swarm foi tocado quando o `docker service update` foi mandado; parado antes dele,
  o trap não age; sem saber, a mensagem diz que não sabe;
- o runbook `docs/runbooks/BACKUP_E_RESTAURACAO.md` tem os dois caminhos que a
  mensagem cita, e nenhum passo dele manda usar `docker service rollback`.
"""

from __future__ import annotations

import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LIB = REPO_ROOT / "scripts" / "lib" / "manaloom_backend_rollback_guard.sh"
DEPLOY = REPO_ROOT / "scripts" / "manaloom_deploy_backend_image.sh"
RUNBOOK = REPO_ROOT / "docs" / "runbooks" / "BACKUP_E_RESTAURACAO.md"
READINESS = "server/lib/health_readiness_support.dart"
BASH = "/bin/bash"
PREVIOUS_SHA = "b" * 40
GUARD_START = "# >>> guarda do rollback automatico"
GUARD_END = "# <<< guarda do rollback automatico"
# O wrapper do PostgreSQL falso: roda a consulta do deploy (psql -c) num
# public.schema_migrations em SQLite com as versões de FAKE_DB_VERSIONS (na ordem dada).
FAKE_WRAPPER = f"""#!{sys.executable} -I
import os
import sqlite3
import sys

arguments = sys.argv[1:]
if arguments[:2] != ["--read-only", "psql"] or "-c" not in arguments:
    sys.exit(9)
database = sqlite3.connect(":memory:")
database.execute("ATTACH DATABASE ':memory:' AS public")
database.execute("CREATE TABLE public.schema_migrations (version TEXT PRIMARY KEY, name TEXT)")
for version in filter(None, os.environ.get("FAKE_DB_VERSIONS", "").split(",")):
    database.execute("INSERT INTO public.schema_migrations VALUES (?, ?)", (version, "m" + version))
for row in database.execute(arguments[arguments.index("-c") + 1]):
    print("|".join("" if value is None else str(value) for value in row))
"""


def _ledger(latest: str) -> str:
    """As versões de um ledger da 001 até [latest], fora de ordem (vazio sem latest)."""
    if not latest:
        return ""
    versions = [f"{number:03d}" for number in range(1, int(latest) + 1)]
    return ",".join(versions[-2:] + versions[:-2])


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
        # O wrapper do PostgreSQL falso: roda a consulta num ledger em SQLite.
        wrapper = self.root / "server" / "bin" / "with_new_server_pg.sh"
        wrapper.parent.mkdir(parents=True, exist_ok=True)
        wrapper.write_text(FAKE_WRAPPER, encoding="utf-8")
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


def _flat(text: str) -> str:
    """O texto com cada sequência de espaços e quebras de linha como um espaço só."""
    return " ".join(text.split())


def _rollback_mentions_are_warnings(text: str) -> list[str]:
    """Cada menção a `docker service rollback` que não é um aviso para não usar."""
    flat = _flat(text)
    return [flat[max(0, match.start() - 40):match.end() + 20]
            for match in re.finditer(r"docker service rollback", flat)
            if not re.search(r"(?i)n[ãa]o use `?$", flat[max(0, match.start() - 12):match.start()])]


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
        # Sem saber onde o deploy parou, a mensagem não afirma que o Swarm pausou: diz
        # que não sabe se o update chegou ao Swarm e manda conferir.
        self.assertIn("estado do Swarm: desconhecido; nao se sabe se o docker service "
                      "update chegou ao Swarm", result.stderr)
        self.assertIn("Confira com docker service inspect antes de agir", result.stderr)
        self.assertNotIn("Swarm para o update em paused", result.stderr)
        # Sem a imagem e o GIT_SHA, o comando mostra o que falta, não um valor inventado.
        self.assertIn("docker service update --image '<imagem anterior repo@sha256>' "
                      "--env-add GIT_SHA=<GIT_SHA da imagem anterior> '<servico>'",
                      result.stderr)
        runbook = RUNBOOK.read_text(encoding="utf-8")
        self.assertIn("## Restauração da produção (RTO de 4 h)", runbook)
        self.assertIn("## Deploy do backend que falhou depois do lote", runbook)
        # O passo 7 volta o backend para a imagem que aceita o dump, só depois do banco,
        # pelo digest e com o GIT_SHA dela, e a seção nova diz como sair de paused,
        # rollback_paused ou updating antes de um deploy de correção.
        explicit = ("docker service update --image <imagem anterior> --env-add "
                    "GIT_SHA=<GIT_SHA anterior> <serviço>")
        step7 = _flat(runbook[runbook.index("\n7. "):runbook.index("\n8. ")])
        self.assertIn("só com o banco já restaurado", step7)
        self.assertIn(explicit, step7)
        self.assertIn("idempotente", step7)
        self.assertIn("não use `docker service rollback`", step7)
        section = _flat(runbook[runbook.index("## Deploy do backend que falhou depois do lote"):])
        for text in ("`paused`", "`rollback_paused`", "docker service update --force <serviço>",
                     explicit, "Não use `docker service rollback`",
                     "baseline backend nao e rollback-safe", "nada foi mandado ao Swarm"):
            self.assertIn(text, section)
        # Nenhum passo do runbook manda usar o rollback: toda menção é um aviso.
        self.assertEqual(_rollback_mentions_are_warnings(runbook), [])

    def test_a_repeated_apply_redoes_the_preview_first(self) -> None:
        # Depois de o dedupe gravar e o migrate falhar com o banco na 058, as contagens da
        # prévia antiga são recusadas: o runbook manda refazer a prévia antes.
        runbook = RUNBOOK.read_text(encoding="utf-8")
        lot = _flat(runbook[runbook.index("de migrations (`scripts/manaloom_lot_apply_migrations.sh`)"):
                            runbook.index("## Receipt")])
        for text in ("3. Para repetir o `--apply` depois de uma falha, refaça antes o "
                     "`--execute --preview`.",
                     "Se o dedupe já gravou e o migrate falhou com o banco ainda na 058",
                     "as contagens da prévia nova (em geral 0) são as que vão no `--esperado`",
                     "Com as contagens antigas, o script recusa sem gravar (código 3)",
                     "Com o banco além da 058"):
            self.assertIn(text, lot)


class DeployGuardBlockTest(unittest.TestCase):
    """O bloco da guarda, como está no deploy, com `ssh` e o wrapper falsos."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.repo = _Repo()
        cls.block = _deploy_section(GUARD_START, re.escape(GUARD_END) + r"\n")

    @classmethod
    def tearDownClass(cls) -> None:
        cls.repo.close()

    def run_block(self, git_sha: str, database: str, ssh_fails: bool = False,
                  versions: str | None = None):
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
            "FAKE_GIT_SHA": git_sha,
            "FAKE_DB_VERSIONS": _ledger(database) if versions is None else versions,
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

    def test_the_database_side_is_the_max_version_of_the_ledger(self) -> None:
        # A consulta de verdade do deploy num ledger em SQLite: o lado do banco é o
        # MAX(version), não a primeira nem a última linha, e um ledger vazio não é migration.
        sha = self.repo.commits["058"]
        for label, versions, latest, policy in (
            ("banco na 058", "057,058,056", "058", "rollback"),
            ("banco na 077", "058,077,059", "077", "restore"),
            ("ledger vazio", "", "", "restore"),
        ):
            with self.subTest(caso=label):
                result = self.run_block(sha, "", versions=versions)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.split("|")[2:4], [latest, policy], result.stdout)

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

    def run_trap(self, policy: str | None, converged: str = "0", source_mutated: str = "0",
                 previous_git_sha: str = PREVIOUS_SHA
                 ) -> tuple[subprocess.CompletedProcess, list[str]]:
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
                f'SWARM_UPDATE_CONVERGED={converged}\nSOURCE_MUTATED={source_mutated}\n'
                f'PREVIOUS_GIT_SHA={previous_git_sha}\n'
                'ROLLBACK_SOURCE_IMAGE=registry/api@sha256:aa\n'
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

    def test_the_refusal_tells_the_true_swarm_state_and_the_way_out(self) -> None:
        # O update não convergiu: o Swarm está em paused (ou updating), o deploy seguinte
        # recusa, e a mensagem diz como sair antes de um deploy de correção.
        result, calls = self.run_trap("restore", converged="0")
        self.assertEqual((result.returncode, calls), (1, []))
        for text in ("o update nao convergiu", "Swarm para o update em paused",
                     "O proximo deploy recusa esse servico",
                     "docker service inspect 'manaloom_api'",
                     "com o update em paused, rollback_paused ou updating",
                     "docker service update --force 'manaloom_api'",
                     # A volta é explícita: o digest anterior e o GIT_SHA dele, que a
                     # guarda do deploy seguinte lê da spec; repetir não muda nada.
                     "docker service update --image 'registry/api@sha256:aa' "
                     f"--env-add GIT_SHA={PREVIOUS_SHA} 'manaloom_api'",
                     "repetir o comando nao muda nada",
                     "nao use docker service rollback: todo update, o --force inclusive, "
                     "grava a spec atual como a anterior, e o rollback volta para a imagem nova",
                     "/health/ready segue 503",
                     "rode o deploy de uma imagem que exige a migration 077",
                     "o passo 7 volta o backend para registry/api@sha256:aa com o mesmo "
                     "docker service update --image",
                     "Deploy do backend que falhou depois do lote",
                     "Restauracao da producao (RTO de 4 h)"):
            self.assertIn(text, result.stderr)
        # Nenhuma linha manda rodar o rollback do Swarm.
        self.assertNotIn("docker service rollback '", result.stderr)
        self.assertEqual([line for line in result.stderr.splitlines()
                          if "docker service rollback" in line
                          and "nao use docker service rollback" not in line], [])
        self.assertNotIn("o update terminou (completed)", result.stderr)
        self.assertNotIn("a origem no EasyPanel ja aponta", result.stderr)
        # Sem o GIT_SHA anterior, o comando mostra o que falta.
        result, _ = self.run_trap("restore", previous_git_sha="")
        self.assertIn("--env-add GIT_SHA=<GIT_SHA da imagem anterior> 'manaloom_api'",
                      result.stderr)
        # A falha veio depois do update que convergiu: nada pausou, a imagem nova roda e
        # o deploy seguinte aceita o serviço.
        result, calls = self.run_trap("restore", converged="1", source_mutated="1")
        self.assertEqual((result.returncode, calls), (1, []))
        self.assertIn("o update terminou (completed) e a imagem nova esta rodando",
                      result.stderr)
        self.assertIn("O Swarm nao pausou nada", result.stderr)
        self.assertIn("a origem no EasyPanel ja aponta para a imagem nova", result.stderr)
        self.assertNotIn("Swarm para o update em paused", result.stderr)

    def test_rollback_policy_still_restores_the_previous_image(self) -> None:
        result, calls = self.run_trap("rollback")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ["ssh", "curl"])
        self.assertIn("rollback backend comprovado", result.stderr)


UPDATE_START = "# >>> update do Swarm"
UPDATE_END = "# <<< update do Swarm"
IMAGE = "registry/api@sha256:" + "c" * 64
# O docker falso do lado remoto: anota cada chamada e responde pelo estado de FAKE_*.
FAKE_DOCKER = """#!/bin/bash
echo "docker $*" >>"$CALLS"
case "$1 $2" in
  "service update") [[ "$FAKE_UPDATE" == fail ]] && exit 1; exit 0 ;;
  "service ls") [[ -n "$FAKE_LS_EXIT" ]] && exit "$FAKE_LS_EXIT"; echo "$FAKE_REPLICAS" ;;
  "service ps") echo "$FAKE_RUNNING" ;;
  "service inspect")
    case "$*" in
      *UpdateStatus.Message*) echo "image=$FAKE_SPEC update=$FAKE_STATE" ;;
      *UpdateStatus*) echo "$FAKE_STATE" ;;
      *) echo "$FAKE_SPEC" ;;
    esac ;;
  *) exit 64 ;;
esac
"""
FAKE_BASE64 = """#!/bin/bash
[[ "$FAKE_BASE64_FAILS" == 1 ]] && exit 1
exec /usr/bin/base64 "$@"
"""


class SwarmUpdateBlockTest(unittest.TestCase):
    """O bloco do update do Swarm, como está no deploy, com o lado remoto de verdade
    rodando sob `docker`, `base64` e `sleep` falsos (o `ssh` falso executa o heredoc)."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.block = _deploy_section(UPDATE_START, re.escape(UPDATE_END) + r"\n")
        # Toda variável que o bloco expande localmente nasce vazia (o deploy roda com -u).
        cls.names = sorted(set(re.findall(r"(?<!\\)\$\{?([A-Za-z_][A-Za-z0-9_]*)", cls.block)))

    def run_block(self, *, ssh_exit: int | None = None, base64_fails: bool = False,
                  update: str = "ok", ls_exit: str = "", replicas: str = "1/1",
                  state: str = "completed") -> tuple[subprocess.CompletedProcess, str, list[str]]:
        with tempfile.TemporaryDirectory() as folder:
            folder_path = Path(folder)
            fake_bin = folder_path / "bin"
            fake_bin.mkdir()
            for name, body in (("docker", FAKE_DOCKER), ("base64", FAKE_BASE64),
                               ("sleep", "#!/bin/bash\nexit 0\n")):
                target = fake_bin / name
                target.write_text(body, encoding="utf-8")
                target.chmod(0o755)
            calls = folder_path / "chamadas"
            calls.touch()
            outcome = folder_path / "resultado"
            script = (
                "set -euo pipefail\n"
                + "".join(f"{name}=\"\"\n" for name in self.names)
                + "SERVICE=manaloom_api\nSSH_KEY=/dev/null\nSSH_HOST=deploy@example.invalid\n"
                f"image_digest_ref='{IMAGE}'\nsha={'d' * 40}\nshort_sha={'d' * 12}\n"
                "SWARM_UPDATE_FAILURE_ACTION=pause\n"
                "DEPLOY_MUTATION_STARTED=0\nSWARM_UPDATE_CONVERGED=0\n"
                "trap 'printf \"%s|%s|%s\" \"$?\" \"$DEPLOY_MUTATION_STARTED\" "
                "\"$SWARM_UPDATE_CONVERGED\" >\"$OUTCOME\"' EXIT\n"
                'ssh() { echo ssh >>"$CALLS"; if [[ -n "$FAKE_SSH_EXIT" ]]; then '
                'return "$FAKE_SSH_EXIT"; fi; PATH="$FAKE_BIN:$PATH" /bin/bash -s; }\n'
                + self.block
            )
            result = _bash(script, env={
                "CALLS": str(calls), "OUTCOME": str(outcome), "FAKE_BIN": str(fake_bin),
                "FAKE_SSH_EXIT": "" if ssh_exit is None else str(ssh_exit),
                "FAKE_BASE64_FAILS": "1" if base64_fails else "0",
                "FAKE_UPDATE": update, "FAKE_LS_EXIT": ls_exit, "FAKE_REPLICAS": replicas,
                "FAKE_SPEC": IMAGE, "FAKE_RUNNING": IMAGE, "FAKE_STATE": state,
            })
            return (result, outcome.read_text(encoding="utf-8"),
                    calls.read_text(encoding="utf-8").splitlines())

    def assert_update_sent(self, calls: list[str], sent: bool) -> None:
        updates = [call for call in calls if call.startswith("docker service update ")]
        self.assertEqual(len(updates), 1 if sent else 0, calls)
        if sent:
            self.assertIn(f"--image {IMAGE}", updates[0])

    def test_converged_update_marks_the_swarm_as_touched_and_converged(self) -> None:
        result, outcome, calls = self.run_block()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(outcome, "0|1|1")
        self.assert_update_sent(calls, True)

    def test_an_update_that_does_not_converge_leaves_the_swarm_paused(self) -> None:
        result, outcome, calls = self.run_block(replicas="0/1", state="paused")
        self.assertEqual(outcome, "1|1|0", result.stderr)
        self.assertIn("foi mandado e nao convergiu", result.stderr)
        self.assert_update_sent(calls, True)

    def test_any_failure_after_the_update_was_sent_counts_as_sent(self) -> None:
        # Um docker que falha com 3 depois do update não pode passar por "nada mandado".
        result, outcome, calls = self.run_block(ls_exit="3")
        self.assertEqual(outcome, "1|1|0", result.stderr)
        self.assertNotIn("nada foi mandado", result.stderr)
        self.assert_update_sent(calls, True)

    def test_a_failure_before_the_update_does_not_touch_the_swarm(self) -> None:
        # O decode do lado remoto falhou antes do docker service update: o trap não age
        # (nada a voltar) e a mensagem diz que nada foi mandado.
        result, outcome, calls = self.run_block(base64_fails=True)
        self.assertEqual(outcome.split("|")[:2], ["1", "0"], result.stderr)
        self.assertIn("antes do docker service update: nada foi mandado ao Swarm", result.stderr)
        self.assertNotIn("docker service update foi mandado", result.stderr)
        self.assert_update_sent(calls, False)

    def test_unknown_when_it_cannot_tell_if_the_update_reached_the_swarm(self) -> None:
        for label, kwargs, sent in (
            ("o ssh caiu", {"ssh_exit": 255}, False),
            ("o docker service update falhou", {"update": "fail"}, True),
        ):
            with self.subTest(caso=label):
                result, outcome, calls = self.run_block(**kwargs)
                self.assertEqual(outcome, "1|1|", result.stderr)
                self.assertIn("nao se sabe se o docker service update chegou ao Swarm; "
                              "confira com docker service inspect 'manaloom_api'",
                              result.stderr)
                self.assert_update_sent(calls, sent)


if __name__ == "__main__":
    unittest.main()
