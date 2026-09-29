#!/usr/bin/env python3
"""Checagens de shell que barram sob `set -e` no `/bin/bash` 3.2.

No bash anterior ao 4.1 (o `/bin/bash` do macOS, onde a coordenação roda deploy,
promoção, ops e backup), um `[[ ... ]]` ou `(( ... ))` solto que falha não encerra o
script com `set -e`; um `!` solto não encerra em versão nenhuma. As checagens
pós-deploy do `/app` e do site eram assim: um `/app` fora do ar passava.

Duas provas:
- o lint `scripts/manaloom_errexit_lint.py` acha o padrão e não acha falso positivo
  nos casos que o repositório usa; a varredura do repositório fica limpa, e o que é raiz
  do digest de UI (em rascunho) fica numa lista fechada que só pode encolher;
- os trechos pós-deploy do `/app` e do site rodam sob o `/bin/bash` de verdade, contra um
  curl falso: coerentes passam; cada divergência injetada barra.
"""

from __future__ import annotations

import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LINT_PATH = REPO_ROOT / "scripts" / "manaloom_errexit_lint.py"
PENDING_PATH = REPO_ROOT / "scripts" / "manaloom_errexit_lint_pending.json"
WEB_DEPLOY = REPO_ROOT / "scripts" / "manaloom_deploy_flutter_web.sh"
SITE_DEPLOY = REPO_ROOT / "scripts" / "manaloom_deploy_public_web.sh"
BASH = "/bin/bash"
SHA = "2" * 40


def _load():
    spec = importlib.util.spec_from_file_location("errexit_lint", LINT_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


lint = _load()


def _findings(script: str) -> list[int]:
    return [number for number, _ in lint.findings(textwrap.dedent(script))]


class LintTest(unittest.TestCase):
    def test_flags_what_does_not_stop_under_bash_3_2(self) -> None:
        script = """\
            set -euo pipefail
            [[ "$a" == "b" ]]
            (( count > 3 ))
            ! grep -Fq x arquivo
            if x; then [[ -n "$y" ]]; fi
            [[ "$a" == \\
              "b" ]]
            [[ "$a" == "b" &&
               "$c" == "d" ]]
            {
              [[ -f "$lock" ]]
            } >/dev/null
            """
        self.assertEqual(_findings(script), [2, 3, 4, 5, 6, 8, 11])

    def test_accepts_the_forms_that_stop_or_are_conditions(self) -> None:
        script = """\
            set -euo pipefail
            [[ "$a" == "b" ]] || fail "x"
            [[ "$a" == "b" ]] && echo sim
            if [[ "$a" == "b" ]]; then :; fi
            while [[ "$n" -lt 3 ]]; do n=$((n + 1)); done
            if release="$(algo)" &&
               [[ "$release" == "x" ]]; then :; fi
            (( count++ ))
            is_ready() {
              [[ -f "$1" ]]
            }
            is_gone() {
              ! kill -0 "$1" >/dev/null 2>&1
            }
            function has_lock {
              echo "${lock}" {a,b}
              [[ -f "$lock" ]]
            }
            if ! grep -Fq x arquivo; then exit 1; fi
            echo "[[ texto ]] entre aspas"
            ssh host "
            [[ -n \\"\\$x\\" ]]
            "
            cat <<'EOF'
            [[ heredoc ]]
            EOF
            x="$( [[ 1 == 1 ]] && echo sim )"
            # [[ comentario ]]
            """
        self.assertEqual(_findings(script), [])

    def test_the_repository_is_clean_and_digest_roots_only_shrink(self) -> None:
        targets, digest = lint.scan_targets(REPO_ROOT)
        scanned = {path.relative_to(REPO_ROOT).as_posix() for path in targets}
        # Os scripts que a coordenação roda deste Mac estão na varredura.
        for required in ("scripts/manaloom_deploy_flutter_web.sh",
                         "scripts/manaloom_deploy_public_web.sh",
                         "scripts/manaloom_deploy_backend_image.sh",
                         "scripts/manaloom_deploy_ops_image.sh",
                         "scripts/manaloom_promote_release.sh",
                         "scripts/manaloom_capacity_resources.sh",
                         "scripts/manaloom_backup_cycle.sh",
                         "scripts/manaloom_full_restore_drill.sh",
                         "scripts/lib/manaloom_release_capabilities_contract.sh"):
            self.assertIn(required, scanned)
        dirty = {}
        for path in targets:
            found = lint.findings(path.read_text(encoding="utf-8", errors="replace"))
            if found:
                dirty[path.relative_to(REPO_ROOT).as_posix()] = found
        self.assertEqual(dirty, {}, "checagem solta fora das raízes do digest de UI")
        new, stale = lint.pending_drift(REPO_ROOT, digest, lint.load_pending(PENDING_PATH))
        self.assertEqual(new, [], "checagem solta nova numa raiz do digest de UI")
        self.assertEqual(stale, [], "entrada da lista pendente que já não existe")

    def test_pending_drift_catches_new_and_stale_entries(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            script = root / "scripts" / "raiz.sh"
            script.parent.mkdir()
            script.write_text("set -e\n[[ -f a ]]\n[[ -f b ]]\n", encoding="utf-8")
            pending = lint.Counter({("scripts/raiz.sh", "[[ -f a ]]"): 1,
                                    ("scripts/raiz.sh", "[[ -f c ]]"): 1})
            new, stale = lint.pending_drift(root, [script], pending)
        self.assertEqual(new, [("scripts/raiz.sh", "[[ -f b ]]")])
        self.assertEqual(stale, [("scripts/raiz.sh", "[[ -f c ]]")])

    def test_the_contract_negative_checks_really_stop(self) -> None:
        # forbid_text é o que substituiu os `! grep` soltos do contrato de release.
        source = (REPO_ROOT / "scripts" / "manaloom_release_ops_contract_test.sh").read_text(
            encoding="utf-8")
        helper = _section(source, "forbid_text() {\n", "\n}\n", False) + "\n}\n"
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "alvo.sh"
            target.write_text("ENABLE_SCANNER_RELEASE=true\n", encoding="utf-8")
            script = (f"set -euo pipefail\n{helper}"
                      f"forbid_text 'scanner_release_enabled: true' '{target}'\n"
                      "echo LIMPO_PASSOU\n"
                      f"forbid_text 'ENABLE_SCANNER_RELEASE=true' '{target}'\n"
                      "echo PROIBIDO_PASSOU\n")
            result = subprocess.run([BASH, "-c", script], capture_output=True, text=True)
        self.assertIn("LIMPO_PASSOU", result.stdout)
        self.assertNotIn("PROIBIDO_PASSOU", result.stdout)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("texto proibido presente", result.stderr)

    def test_the_pending_list_only_holds_digest_roots(self) -> None:
        roots = lint._ui_digest_roots(REPO_ROOT)
        pending = json.loads(PENDING_PATH.read_text(encoding="utf-8"))
        self.assertEqual(pending["schema_version"], "manaloom_errexit_lint_pending_v1")
        for item in pending["pending"]:
            self.assertIn(item["file"], roots)

    def test_cli_exit_codes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            bad = Path(tmp) / "ruim.sh"
            bad.write_text("#!/bin/bash\nset -e\n[[ -f x ]]\n", encoding="utf-8")
            good = Path(tmp) / "bom.sh"
            good.write_text("#!/bin/bash\nset -e\n[[ -f x ]] || exit 1\n", encoding="utf-8")
            run = lambda path: subprocess.run(  # noqa: E731
                [sys.executable, str(LINT_PATH), str(path)], capture_output=True, text=True)
            flagged, clean = run(bad), run(good)
        self.assertEqual(flagged.returncode, 1)
        self.assertIn("ruim.sh:3: checagem solta, não barra sob set -e: [[ -f x ]]",
                      flagged.stdout)
        self.assertEqual(clean.returncode, 0)
        self.assertEqual(clean.stdout, "")
        for result in (flagged, clean):
            self.assertNotIn("Traceback", result.stderr)


# ------------------------------------------------------------ trechos pós-deploy

FAKE_CURL = r'''#!/usr/bin/env python3
import json
import os
import sys

args = sys.argv[1:]
responses = json.loads(os.environ["FAKE_HTTP"])
output = header_file = fmt = None
fail = False
url = args[-1]
index = 0
while index < len(args) - 1:
    arg = args[index]
    if arg == "-o":
        output = args[index + 1]; index += 2; continue
    if arg == "-D":
        header_file = args[index + 1]; index += 2; continue
    if arg == "-w":
        fmt = args[index + 1]; index += 2; continue
    if arg == "--max-time":
        index += 2; continue
    if arg.startswith("-") and not arg.startswith("--") and "f" in arg:
        fail = True
    index += 1
path = "/" + url.split("://", 1)[1].split("/", 1)[1] if url.count("/") >= 3 else "/"
status, body, headers = responses.get(path, [404, "not found", {}])
if header_file:
    with open(header_file, "w") as handle:
        handle.write(f"HTTP/1.1 {status}\r\n")
        for key, value in headers.items():
            handle.write(f"{key}: {value}\r\n")
if fail and status >= 400:
    sys.exit(22)
if output and output != "/dev/null":
    with open(output, "w") as handle:
        handle.write(body)
elif not output:
    sys.stdout.write(body)
if fmt:
    sys.stdout.write(str(status))
'''

APP_INDEX = '<html><head><base href="/app/"></head></html>'


def _section(source: str, start: str, end: str, include_end: bool) -> str:
    begin = source.index(start)
    stop = source.index(end, begin)
    if include_end:
        stop = source.index("\n", stop) + 1
    return source[begin:stop]


def web_section(source: str) -> str:
    """Da função que barra, pelo laço que espera o `/app`, até o `grep` do deep link."""
    section = _section(source, "postdeploy_fail() {\n", "manaloom_app_web_deep.html\n", True)
    if "for _ in $(seq 1 30); do\n" not in section or 'DEEP_LINK_CODE="$(curl' not in section:
        raise AssertionError("trecho pós-deploy do /app mudou de forma")
    return section


def site_section(source: str) -> str:
    """Do `healthz` até a identidade pública do site (BT-REL-002)."""
    return _section(source, 'HEALTH_BODY="$(curl -fsS --max-time 20 "$PUBLIC_BASE_URL/healthz")"',
                    'PROBE_DIR="$(mktemp -d /tmp/manaloom-public-web-probe.XXXXXX)"', False)


def run_section(section: str, responses: dict, work: Path) -> subprocess.CompletedProcess:
    """Roda o trecho sob o /bin/bash de verdade, com set -euo pipefail e o curl falso."""
    shims = work / "bin"
    shims.mkdir(exist_ok=True)
    curl = shims / "curl"
    curl.write_text(FAKE_CURL.replace("/usr/bin/env python3", sys.executable), encoding="utf-8")
    curl.chmod(0o755)
    sleep = shims / "sleep"
    sleep.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
    sleep.chmod(0o755)
    body = section.replace("/tmp/manaloom_app", f"{work}/manaloom_app")
    harness = work / "trecho.sh"
    harness.write_text(
        "set -euo pipefail\n"
        'PUBLIC_BASE_URL="https://publico.exemplo.invalid"\n'
        f'SHA="{SHA}"\n' + body + '\necho "CHECAGENS_PASSARAM"\n', encoding="utf-8")
    env = {"PATH": f"{shims}:/usr/bin:/bin", "FAKE_HTTP": json.dumps(responses),
           "HOME": str(work), "TMPDIR": str(work), "LC_ALL": "C"}
    return subprocess.run([BASH, str(harness)], capture_output=True, text=True, env=env,
                          check=False, timeout=120)


def web_responses(**overrides) -> dict:
    responses = {
        "/app/": [200, APP_INDEX, {}],
        "/app/flutter_bootstrap.js": [200, "// bootstrap", {}],
        "/app/release.json": [200, "{}", {"cache-control": "no-cache, no-store, must-revalidate"}],
        "/app/decks": [200, APP_INDEX, {}],
        "/": [200, "<html>site</html>", {}],
    }
    responses.update(overrides)
    return responses


def site_responses(**overrides) -> dict:
    responses = {
        "/healthz": [200, "ok", {}],
        "/release.json": [200, json.dumps({"product": "brewtact", "surface": "site",
                                           "git_sha": SHA}), {}],
    }
    responses.update(overrides)
    return responses


class PostDeployTest(unittest.TestCase):
    """As checagens pós-deploy sob o /bin/bash 3.2, com divergência injetada."""

    def setUp(self) -> None:
        self.work = Path(tempfile.mkdtemp(prefix="errexit-"))

    def tearDown(self) -> None:
        shutil.rmtree(self.work, ignore_errors=True)

    def _passes(self, result: subprocess.CompletedProcess) -> bool:
        return result.returncode == 0 and "CHECAGENS_PASSARAM" in result.stdout

    def test_the_mac_bash_really_is_the_old_one(self) -> None:
        # Sem isto a prova não prova nada: no bash 4.1+ o [[ ]] solto já barraria.
        version = subprocess.run([BASH, "-c", "echo ${BASH_VERSINFO[0]}"],
                                 capture_output=True, text=True).stdout.strip()
        if version != "3":
            self.skipTest(f"SKIP inventariado: /bin/bash {version} não é o 3.2 do macOS; "
                          "a prova do 3.2 só vale no Mac da coordenação")
        result = subprocess.run([BASH, "-c", 'set -e; [[ 1 == 2 ]]; echo seguiu'],
                                capture_output=True, text=True)
        self.assertIn("seguiu", result.stdout)

    def test_web_postdeploy_checks_stop_every_divergence(self) -> None:
        section = web_section(WEB_DEPLOY.read_text(encoding="utf-8"))
        self.assertTrue(self._passes(run_section(section, web_responses(), self.work)))
        divergences = {
            "bootstrap 500": ({"/app/flutter_bootstrap.js": [500, "// erro", {}]},
                              "/app/flutter_bootstrap.js respondeu HTTP 500"),
            "release.json 404": ({"/app/release.json": [404, "{}", {}]},
                                 "/app/release.json respondeu HTTP 404"),
            "deep link 502 com o shell em cache": ({"/app/decks": [502, APP_INDEX, {}]},
                                                   "/app/decks respondeu HTTP 502"),
            "raiz 503": ({"/": [503, "manutenção", {}]}, "/ respondeu HTTP 503"),
            "/app 503 com o shell em cache": ({"/app/": [503, APP_INDEX, {}]},
                                              "/app/ respondeu HTTP 503"),
        }
        for label, (override, message) in divergences.items():
            with self.subTest(divergencia=label):
                result = run_section(section, web_responses(**override), self.work)
                self.assertFalse(self._passes(result), result.stdout + result.stderr)
                # Barrou pela checagem, não por acidente (comando ausente, curl etc.).
                self.assertIn(f"checagem pos-deploy do /app falhou: {message}", result.stderr)
                self.assertNotIn("command not found", result.stderr)

    def test_site_postdeploy_checks_stop_a_bad_healthz(self) -> None:
        section = site_section(SITE_DEPLOY.read_text(encoding="utf-8"))
        self.assertTrue(self._passes(run_section(section, site_responses(), self.work)))
        result = run_section(section, site_responses(**{"/healthz": [200, "degraded", {}]}),
                             self.work)
        self.assertFalse(self._passes(result), result.stdout + result.stderr)
        self.assertIn("healthz publico do site nao respondeu ok", result.stderr)


if __name__ == "__main__":
    unittest.main()
