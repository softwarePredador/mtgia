#!/usr/bin/env python3
"""D-83: o deploy do backend confere o teto de corpo do proxy (S-06).

A D-83 diz que "o teto do proxy é conferido no deploy": o backend aceita 5 MiB nas
rotas de import, e um proxy com teto menor (o `client_max_body_size` padrão do
nginx é 1m) para o import com um 413 que não é do backend. Três provas, sem
servidor real:

- a biblioteca `scripts/lib/manaloom_proxy_body_ceiling.sh` roda sob o `/bin/bash`
  de verdade contra servidores HTTP falsos em loopback: um backend passa; um proxy
  com teto de 1 MiB, um 502, uma página que não é do backend e uma conexão que cai
  barram; o corpo mandado tem exatamente o teto, e um backend com esse teto
  aceita; o 413 diz se veio do proxy ou do backend, pelo envelope; o curl 55
  (conexão fechada cedo) ganha uma retentativa curta, e só ele;
- o teto vem da constante do backend (`server/lib/request_body_limits.dart`);
- o deploy do backend calcula o teto do código que vai subir e chama a conferência
  no pré-voo, logo depois da topologia do proxy e antes de qualquer mutação.
"""

from __future__ import annotations

import http.server
import json
import os
import shutil
import socket
import stat
import subprocess
import tempfile
import threading
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
LIB = REPO_ROOT / "scripts" / "lib" / "manaloom_proxy_body_ceiling.sh"
LIMITS = REPO_ROOT / "server" / "lib" / "request_body_limits.dart"
DEPLOY = REPO_ROOT / "scripts" / "manaloom_deploy_backend_image.sh"
BASH = "/bin/bash"
MIB = 1024 * 1024


class _FakeServer:
    """HTTP em 127.0.0.1 que responde conforme [behaviour] e guarda o tamanho lido."""

    def __init__(self, behaviour: str, limit: int = 0) -> None:
        outer = self
        self.behaviour = behaviour
        self.limit = limit
        self.received: list[int] = []

        class Handler(http.server.BaseHTTPRequestHandler):
            protocol_version = "HTTP/1.1"

            def log_message(self, *_args) -> None:  # silencia o stderr do teste
                pass

            def _send(self, status: int, body: bytes, content_type: str) -> None:
                self.send_response(status)
                self.send_header("Content-Type", content_type)
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Connection", "close")
                self.end_headers()
                self.wfile.write(body)

            def do_POST(self) -> None:  # noqa: N802 (nome do http.server)
                length = int(self.headers.get("Content-Length", "0"))
                behaviour = outer.behaviour
                if behaviour == "cai":
                    # Fecha o socket sem resposta, como um proxy que corta.
                    self.close_connection = True
                    self.connection.shutdown(socket.SHUT_RDWR)
                    return
                outer.received.append(len(self.rfile.read(length)))
                if behaviour == "backend":
                    body = {"error": "capability_unavailable",
                            "message": "Recurso indisponível.", "request_id": "r1"}
                    self._send(404, json.dumps(body).encode(), "application/json")
                elif behaviour == "backend_com_teto":
                    if length > outer.limit:
                        body = {"error": "request_body_too_large", "limit": outer.limit}
                        self._send(413, json.dumps(body).encode(), "application/json")
                    else:
                        body = {"error": "Token de autenticação não fornecido"}
                        self._send(401, json.dumps(body).encode(), "application/json")
                elif behaviour == "nginx_1m":
                    if length > MIB:
                        self._send(413, b"<html><body>413 Request Entity Too Large"
                                        b"</body></html>", "text/html")
                    else:
                        self._send(401, b'{"error": "x"}', "application/json")
                elif behaviour == "proxy_502":
                    self._send(502, b"Bad Gateway", "text/plain")
                elif behaviour == "backend_503":
                    # Resposta inconclusiva: o deploy não segue com o backend fora.
                    self._send(503, b'{"error": "service_unavailable"}', "application/json")
                elif behaviour == "pagina_200":
                    self._send(200, b"<html>404 page not found</html>", "text/html")
                elif behaviour == "json_sem_error":
                    self._send(404, b'{"message": "not found"}', "application/json")
                else:
                    raise AssertionError(behaviour)

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.url = f"http://127.0.0.1:{self.server.server_address[1]}"
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    def __enter__(self) -> "_FakeServer":
        self.thread.start()
        return self

    def __exit__(self, *_exc) -> None:
        self.server.shutdown()
        self.server.server_close()


def _ceiling(url: str, limit: int | str) -> subprocess.CompletedProcess:
    return subprocess.run(
        [BASH, "-c",
         'set -euo pipefail; source "$1"; manaloom_require_proxy_body_ceiling "$2" "$3"',
         "_", str(LIB), url, str(limit)],
        capture_output=True, text=True, timeout=120)


def _import_limit(path: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [BASH, "-c", 'set -euo pipefail; source "$1"; manaloom_import_body_limit_bytes "$2"',
         "_", str(LIB), str(path)],
        capture_output=True, text=True, timeout=30)


class ProxyCeilingTest(unittest.TestCase):
    def test_backend_answers_and_the_body_has_exactly_the_ceiling(self) -> None:
        with _FakeServer("backend") as server:
            result = _ceiling(server.url, 64 * 1024)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("proxy_body_ceiling_ok status=404 bytes=65536 path=/import/validate",
                      result.stdout)
        self.assertEqual(server.received, [64 * 1024])

    def test_a_backend_with_the_same_ceiling_accepts_the_probe(self) -> None:
        with _FakeServer("backend_com_teto", limit=64 * 1024) as server:
            result = _ceiling(server.url, 64 * 1024)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("status=401", result.stdout)

    def test_a_413_from_the_backend_itself_still_refuses(self) -> None:
        # Um teto do backend menor que o do import também barra o deploy, e a
        # mensagem diz que o 413 veio do backend (o envelope JSON dele).
        with _FakeServer("backend_com_teto", limit=32 * 1024) as server:
            result = _ceiling(server.url, 64 * 1024)
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("413 do backend (request_body_too_large, limite 32768 bytes)",
                      result.stderr)
        self.assertNotIn("413 do proxy", result.stderr)

    def test_the_real_import_ceiling_passes_a_backend(self) -> None:
        limit = int(_import_limit(LIMITS).stdout)
        with _FakeServer("backend") as server:
            result = _ceiling(server.url + "/", limit)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(server.received, [5 * MIB])

    def test_a_proxy_with_the_nginx_default_refuses_the_import(self) -> None:
        limit = int(_import_limit(LIMITS).stdout)
        with _FakeServer("nginx_1m") as server:
            result = _ceiling(server.url, limit)
        self.assertEqual(result.returncode, 2)
        self.assertIn("deploy recusado: teto de corpo do proxy (D-83)", result.stderr)
        self.assertIn("413 do proxy, sem o envelope JSON do backend", result.stderr)
        self.assertNotIn("413 do backend", result.stderr)

    def test_answers_that_are_not_the_backend_refuse(self) -> None:
        for behaviour, reason in (
            ("proxy_502", "status 502"),
            ("backend_503", "status 503"),
            ("pagina_200", "sem o envelope JSON do backend"),
            ("json_sem_error", "sem o envelope JSON do backend"),
            ("cai", "a conexao caiu antes da resposta"),
        ):
            with self.subTest(behaviour=behaviour), _FakeServer(behaviour) as server:
                result = _ceiling(server.url, 64 * 1024)
                self.assertEqual(result.returncode, 2, result.stdout)
                self.assertIn(reason, result.stderr)

    def test_an_invalid_ceiling_refuses_without_a_request(self) -> None:
        with _FakeServer("backend") as server:
            for limit in ("", "0", "5MiB", "-1"):
                with self.subTest(limit=limit):
                    result = _ceiling(server.url, limit)
                    self.assertEqual(result.returncode, 2)
                    self.assertIn("teto de corpo do import invalido", result.stderr)
        self.assertEqual(server.received, [])

    def test_no_temporary_file_is_left_behind(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, _FakeServer("nginx_1m") as server:
            result = subprocess.run(
                [BASH, "-c",
                 'set -euo pipefail; source "$1"; manaloom_require_proxy_body_ceiling "$2" "$3"',
                 "_", str(LIB), server.url, str(2 * MIB)],
                capture_output=True, text=True, timeout=120, env={"TMPDIR": tmp, "PATH": "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"})
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertEqual(list(Path(tmp).iterdir()), [])


class CurlRetryTest(unittest.TestCase):
    """O curl 55 ganha uma retentativa; os outros erros do curl, não. Um `curl`
    falso na frente do PATH falha as primeiras [fail] chamadas com [code] e depois
    chama o curl de verdade."""

    def run_with_flaky_curl(self, behaviour: str, code: int, fail: int):
        real = shutil.which("curl")
        assert real, "curl ausente"
        with tempfile.TemporaryDirectory() as folder, _FakeServer(behaviour) as server:
            shim = Path(folder) / "curl"
            counter = Path(folder) / "chamadas"
            counter.write_text("0")
            shim.write_text(
                "#!/bin/bash\n"
                f'n=$(( $(cat "{counter}") + 1 )); echo "$n" > "{counter}"\n'
                f'if (( n <= {fail} )); then exit {code}; fi\n'
                f'exec "{real}" "$@"\n')
            shim.chmod(shim.stat().st_mode | stat.S_IXUSR)
            result = subprocess.run(
                [BASH, "-c",
                 'set -euo pipefail; source "$1"; manaloom_require_proxy_body_ceiling "$2" "$3"',
                 "_", str(LIB), server.url, str(64 * 1024)],
                capture_output=True, text=True, timeout=120,
                env={**os.environ, "PATH": f"{folder}:{os.environ['PATH']}"})
            return result, int(counter.read_text()), list(server.received)

    def test_one_early_close_is_retried_once(self) -> None:
        result, calls, received = self.run_with_flaky_curl("backend", 55, 1)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("curl 55 (conexao fechada cedo); repetindo uma vez", result.stderr)
        self.assertEqual(calls, 2)
        self.assertEqual(received, [64 * 1024])

    def test_two_early_closes_refuse(self) -> None:
        result, calls, received = self.run_with_flaky_curl("backend", 55, 2)
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("a conexao caiu antes da resposta (curl 55, 2 tentativa(s))",
                      result.stderr)
        self.assertEqual(calls, 2)
        self.assertEqual(received, [])

    def test_other_curl_errors_are_not_retried(self) -> None:
        for code in (7, 28, 52, 56):
            with self.subTest(curl=code):
                result, calls, received = self.run_with_flaky_curl("backend", code, 1)
                self.assertEqual(result.returncode, 2, result.stdout)
                self.assertIn(f"(curl {code}, 1 tentativa(s))", result.stderr)
                self.assertNotIn("repetindo", result.stderr)
                self.assertEqual(calls, 1)
                self.assertEqual(received, [])


class ImportLimitTest(unittest.TestCase):
    def test_reads_the_backend_constant(self) -> None:
        result = _import_limit(LIMITS)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(5 * MIB))
        self.assertIn("const importRequestBodyLimitBytes = 5 * 1024 * 1024;",
                      LIMITS.read_text(encoding="utf-8"))

    def test_follows_the_constant_and_refuses_what_it_cannot_read(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "limits.dart"
            source.write_text("const importRequestBodyLimitBytes = 2 * 1024 * 1024;\n")
            self.assertEqual(_import_limit(source).stdout.strip(), str(2 * MIB))
            for broken in ("const importRequestBodyLimitBytes = 5 << 20;\n",
                           "const otherLimit = 5 * 1024 * 1024;\n"):
                source.write_text(broken)
                result = _import_limit(source)
                self.assertEqual(result.returncode, 2, broken)
                self.assertIn("ilegivel", result.stderr)


class DeployContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.source = DEPLOY.read_text(encoding="utf-8")

    def test_the_deploy_sources_the_library_and_reads_the_ceiling_from_the_code(self) -> None:
        self.assertIn('source "$ROOT_DIR/scripts/lib/manaloom_proxy_body_ceiling.sh"',
                      self.source)
        self.assertIn('IMPORT_BODY_LIMIT_BYTES="$(manaloom_import_body_limit_bytes '
                      '"$ROOT_DIR/server/lib/request_body_limits.dart")"', self.source)

    def test_the_check_runs_in_the_preflight_before_any_mutation(self) -> None:
        call = '\nmanaloom_require_proxy_body_ceiling "$API_BASE_URL" "$IMPORT_BODY_LIMIT_BYTES"\n'
        self.assertEqual(self.source.count(call), 1)
        position = self.source.index(call)
        topology = self.source.index("\nrequire_trusted_proxy_topology\n")
        limit = self.source.index('IMPORT_BODY_LIMIT_BYTES="$(')
        self.assertLess(limit, position)
        self.assertLess(topology, position)
        # A primeira escrita remota é o bootstrap da credencial de ops; depois vêm a
        # troca da spec e a da origem no EasyPanel.
        for mutation in ("ops_configured=", "\nDEPLOY_MUTATION_STARTED=1\n",
                         "\nSOURCE_MUTATED=1\n"):
            self.assertLess(position, self.source.index(mutation), mutation)


if __name__ == "__main__":
    unittest.main()
