#!/usr/bin/env python3

from __future__ import annotations

import io
import ssl
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import serve_flutter_web_app as web_app


class PinnedHTTPSConnectionTest(unittest.TestCase):
    def test_connect_uses_override_socket_and_logical_tls_name(self) -> None:
        context = mock.Mock(spec=ssl.SSLContext)
        raw_socket = mock.Mock()
        wrapped_socket = mock.Mock()
        context.wrap_socket.return_value = wrapped_socket
        connection = web_app._PinnedHTTPSConnection(
            "api.example.test",
            443,
            connect_address="127.0.0.1",
            connect_port=18443,
            context=context,
            timeout=7,
        )
        connection._create_connection = mock.Mock(return_value=raw_socket)

        connection.connect()

        connection._create_connection.assert_called_once_with(
            ("127.0.0.1", 18443),
            7,
            None,
        )
        context.wrap_socket.assert_called_once_with(
            raw_socket,
            server_hostname="api.example.test",
        )
        self.assertIs(connection.sock, wrapped_socket)


class PinnedProxyRequestTest(unittest.TestCase):
    def test_proxy_preserves_logical_host_path_query_body_and_status(self) -> None:
        calls: dict[str, object] = {}

        class FakeResponse:
            status = 202

            @staticmethod
            def read() -> bytes:
                return b'{"ok":true}'

            @staticmethod
            def getheader(name: str) -> str | None:
                return "application/json" if name == "Content-Type" else None

        class FakeConnection:
            def __init__(self, host: str, port: int, **kwargs: object) -> None:
                calls["connection"] = (host, port, kwargs)

            def request(
                self,
                method: str,
                path: str,
                *,
                body: bytes | None,
                headers: dict[str, str],
            ) -> None:
                calls["request"] = (method, path, body, headers.copy())

            @staticmethod
            def getresponse() -> FakeResponse:
                return FakeResponse()

            @staticmethod
            def close() -> None:
                calls["closed"] = True

        handler = object.__new__(web_app.FlutterWebAppHandler)
        handler.api_connect_address = "127.0.0.1"
        handler.api_connect_port = 18443
        handler.api_ssl_context = ssl.create_default_context()
        handler.command = "POST"
        handler.wfile = io.BytesIO()
        handler.send_response = mock.Mock()
        handler.send_header = mock.Mock()
        handler.end_headers = mock.Mock()

        with mock.patch.object(web_app, "_PinnedHTTPSConnection", FakeConnection):
            handler._proxy_api_through_pinned_tls(
                target="https://api.example.test:9443/decks?limit=2",
                body=b"payload",
                forwarded_headers={"Content-Type": "application/json"},
                head_only=False,
            )

        host, port, kwargs = calls["connection"]
        self.assertEqual((host, port), ("api.example.test", 9443))
        self.assertEqual(kwargs["connect_address"], "127.0.0.1")
        self.assertEqual(kwargs["connect_port"], 18443)
        method, path, body, headers = calls["request"]
        self.assertEqual((method, path, body), ("POST", "/decks?limit=2", b"payload"))
        self.assertEqual(headers["Host"], "api.example.test:9443")
        handler.send_response.assert_called_once_with(202)
        self.assertEqual(handler.wfile.getvalue(), b'{"ok":true}')
        self.assertTrue(calls["closed"])


class ArgumentValidationTest(unittest.TestCase):
    def _run_main(self, *extra_args: str) -> int:
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, "index.html").write_text("ok", encoding="utf-8")
            argv = [
                "serve_flutter_web_app.py",
                "--build-dir",
                directory,
                "--api-upstream",
                "https://api.example.test",
                *extra_args,
            ]
            with mock.patch.object(sys, "argv", argv), mock.patch("sys.stderr", io.StringIO()):
                return web_app.main()

    def test_rejects_zero_connect_port(self) -> None:
        result = self._run_main(
            "--api-connect-address",
            "127.0.0.1",
            "--api-connect-port",
            "0",
        )
        self.assertEqual(result, 2)

    def test_rejects_non_loopback_connect_address(self) -> None:
        result = self._run_main(
            "--api-connect-address",
            "192.0.2.10",
            "--api-connect-port",
            "443",
        )
        self.assertEqual(result, 2)


if __name__ == "__main__":
    unittest.main()
