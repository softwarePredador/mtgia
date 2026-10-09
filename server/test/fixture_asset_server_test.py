#!/usr/bin/env python3
"""Servidor de assets das fixtures visuais (BT-UIEV-001).

`scripts/lib/manaloom_fixture_asset_server.py` serve a arte das cartas das
fixtures com CORS para o Flutter Web. Tres garantias:

- bind fora de loopback (`0.0.0.0`, IP de rede, `::`) e recusado com codigo 2 e
  mensagem clara, antes de abrir o socket;
- diretorio sem `index.html` responde 404, sem listar os arquivos da raiz;
- arquivo e servido com `Access-Control-Allow-Origin: *`, e `--directory`
  continua com o diretorio corrente como padrao.
"""

from __future__ import annotations

import importlib.util
import socket
import subprocess
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SERVER_PATH = REPO_ROOT / "scripts" / "lib" / "manaloom_fixture_asset_server.py"
ARTE = b"\x89PNG\r\n\x1a\nnao-e-uma-arte-de-verdade"


def _load():
    spec = importlib.util.spec_from_file_location(
        "manaloom_fixture_asset_server", SERVER_PATH
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


servidor_de_assets = _load()


def _ipv6_loopback_disponivel() -> bool:
    if not socket.has_ipv6:
        return False
    try:
        with socket.socket(socket.AF_INET6, socket.SOCK_STREAM) as sock:
            sock.bind(("::1", 0))
    except OSError:
        return False
    return True


class _ServidorEmThread:
    """Sobe o servidor de verdade numa thread, numa porta efemera."""

    def __init__(self, bind: str, diretorio: str) -> None:
        self.servidor = servidor_de_assets.criar_servidor(bind, 0, diretorio)
        self.thread = threading.Thread(
            target=self.servidor.serve_forever, daemon=True
        )

    def __enter__(self) -> "_ServidorEmThread":
        self.thread.start()
        return self

    def __exit__(self, *exc) -> None:
        self.servidor.shutdown()
        self.servidor.server_close()
        self.thread.join(timeout=5)

    def url(self, caminho: str) -> str:
        host, porta = self.servidor.server_address[:2]
        if ":" in host:
            host = f"[{host}]"
        return f"http://{host}:{porta}{caminho}"


def _get(url: str) -> tuple[int, dict[str, str], bytes]:
    try:
        with urllib.request.urlopen(url, timeout=10) as resposta:
            return resposta.status, dict(resposta.headers), resposta.read()
    except urllib.error.HTTPError as erro:
        corpo = erro.read()
        cabecalhos = dict(erro.headers)
        erro.close()
        return erro.code, cabecalhos, corpo


class BindTest(unittest.TestCase):
    def test_refuses_non_loopback_bind_before_opening_a_socket(self) -> None:
        for bind in ("0.0.0.0", "::", "192.168.0.10", "10.0.0.1", "", "127.0.0.2"):
            with self.subTest(bind=bind):
                resultado = subprocess.run(
                    [sys.executable, str(SERVER_PATH), "0", "--bind", bind],
                    capture_output=True,
                    text=True,
                    timeout=10,
                    check=False,
                )
                self.assertEqual(resultado.returncode, 2, resultado.stderr)
                self.assertIn("recusado", resultado.stderr)
                self.assertIn("loopback", resultado.stderr)
                self.assertNotIn("Traceback", resultado.stderr)

    def test_factory_refuses_non_loopback_bind_too(self) -> None:
        with tempfile.TemporaryDirectory() as raiz:
            with self.assertRaisesRegex(ValueError, "loopback"):
                servidor_de_assets.criar_servidor("0.0.0.0", 0, raiz)

    def test_accepts_the_three_loopback_spellings(self) -> None:
        for bind in ("127.0.0.1", "localhost"):
            with self.subTest(bind=bind):
                self.assertEqual(servidor_de_assets.validar_bind(bind), bind)
        self.assertEqual(servidor_de_assets.validar_bind("::1"), "::1")

    @unittest.skipUnless(_ipv6_loopback_disponivel(), "sem loopback IPv6")
    def test_serves_on_ipv6_loopback(self) -> None:
        with tempfile.TemporaryDirectory() as raiz:
            Path(raiz, "arte.png").write_bytes(ARTE)
            with _ServidorEmThread("::1", raiz) as srv:
                status, _, corpo = _get(srv.url("/arte.png"))
        self.assertEqual(status, 200)
        self.assertEqual(corpo, ARTE)


class ServeTest(unittest.TestCase):
    def setUp(self) -> None:
        self._raiz = tempfile.TemporaryDirectory()
        self.raiz = Path(self._raiz.name)
        (self.raiz / "arte.png").write_bytes(ARTE)
        (self.raiz / "segredo-da-raiz.txt").write_text("nao liste", "utf-8")
        (self.raiz / "sub").mkdir()
        (self.raiz / "sub" / "outra-arte.png").write_bytes(ARTE)
        (self.raiz / "com-index").mkdir()
        (self.raiz / "com-index" / "index.html").write_text("ok", "utf-8")

    def tearDown(self) -> None:
        self._raiz.cleanup()

    def test_serves_file_with_cors(self) -> None:
        with _ServidorEmThread("127.0.0.1", str(self.raiz)) as srv:
            status, cabecalhos, corpo = _get(srv.url("/arte.png"))
        self.assertEqual(status, 200)
        self.assertEqual(corpo, ARTE)
        self.assertEqual(cabecalhos.get("Access-Control-Allow-Origin"), "*")
        self.assertEqual(cabecalhos.get("Cache-Control"), "no-store")

    def test_refuses_directory_listing(self) -> None:
        with _ServidorEmThread("127.0.0.1", str(self.raiz)) as srv:
            for caminho in ("/", "/sub/"):
                with self.subTest(caminho=caminho):
                    status, cabecalhos, corpo = _get(srv.url(caminho))
                    self.assertEqual(status, 404)
                    self.assertNotIn(b"segredo-da-raiz", corpo)
                    self.assertNotIn(b"outra-arte", corpo)
                    self.assertNotIn(b"arte.png", corpo)
                    # O 404 tambem leva CORS: o app ve a falha, nao um erro
                    # de rede opaco.
                    self.assertEqual(
                        cabecalhos.get("Access-Control-Allow-Origin"), "*"
                    )

    def test_directory_with_index_still_serves_the_index(self) -> None:
        with _ServidorEmThread("127.0.0.1", str(self.raiz)) as srv:
            status, _, corpo = _get(srv.url("/com-index/"))
        self.assertEqual(status, 200)
        self.assertEqual(corpo, b"ok")

    def test_directory_defaults_to_the_working_directory(self) -> None:
        porta_livre = socket.socket()
        porta_livre.bind(("127.0.0.1", 0))
        porta = porta_livre.getsockname()[1]
        porta_livre.close()
        processo = subprocess.Popen(
            [sys.executable, str(SERVER_PATH), str(porta)],
            cwd=self.raiz,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )
        try:
            status, corpo = 0, b""
            for _ in range(50):
                try:
                    status, _, corpo = _get(f"http://127.0.0.1:{porta}/arte.png")
                    break
                except urllib.error.URLError:
                    if processo.poll() is not None:
                        break
                    threading.Event().wait(0.1)
        finally:
            processo.terminate()
            processo.wait(timeout=5)
            if processo.stderr is not None:
                processo.stderr.close()
        self.assertEqual(status, 200)
        self.assertEqual(corpo, ARTE)


if __name__ == "__main__":
    unittest.main(verbosity=2)
