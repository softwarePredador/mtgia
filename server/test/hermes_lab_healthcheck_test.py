#!/usr/bin/env python3
"""Tests for Hermes lab healthcheck behavior."""

from __future__ import annotations

import json
import os
import socketserver
import subprocess
import sys
import tempfile
import threading
import unittest
from pathlib import Path
from http.server import BaseHTTPRequestHandler


REPO_ROOT = Path(__file__).resolve().parents[1]
HEALTHCHECK = REPO_ROOT / "bin" / "hermes_lab_healthcheck.sh"


def _run_healthcheck(env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(HEALTHCHECK)],
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


class _HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802
        payload = b'{"status":"ok","platform":"hermes-agent"}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format: str, *args) -> None:  # noqa: A003
        return


class _ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True


class HermesLabHealthcheckTest(unittest.TestCase):
    def _start_gateway_server(self) -> tuple[_ThreadedTCPServer, str]:
        server = _ThreadedTCPServer(("127.0.0.1", 0), _HealthHandler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        url = f"http://127.0.0.1:{server.server_address[1]}/health"
        return server, url

    def test_passes_when_startup_succeeded_and_report_exists(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            server, url = self._start_gateway_server()
            root = Path(tmp)
            home = root / "home"
            status_path = home / "artifacts" / "hermes_lab_runtime" / "startup_status.json"
            status_path.parent.mkdir(parents=True, exist_ok=True)
            status_path.write_text(
                json.dumps(
                    {
                        "phase": "bootstrap",
                        "status": "succeeded",
                        "message": "ok",
                    }
                )
            )
            report_path = home / "artifacts" / "hermes_cron_bootstrap" / "latest_bootstrap_report.json"
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text("{}")
            jobs_json = home / "cron" / "jobs.json"
            jobs_json.parent.mkdir(parents=True, exist_ok=True)
            jobs_json.write_text(json.dumps({"jobs": [{"name": "x", "enabled": True}]}))
            env = {
                **os.environ,
                "HERMES_HOME": str(home),
                "HERMES_LAB_GATEWAY_HEALTH_URL": url,
            }
            try:
                result = _run_healthcheck(env)
                self.assertEqual(result.returncode, 0, msg=result.stderr)
                self.assertIn('"status": "succeeded"', result.stdout)
                self.assertIn('"gateway_health"', result.stdout)
            finally:
                server.shutdown()
                server.server_close()

    def test_fails_when_startup_status_is_failed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            status_path = home / "artifacts" / "hermes_lab_runtime" / "startup_status.json"
            status_path.parent.mkdir(parents=True, exist_ok=True)
            status_path.write_text(
                json.dumps(
                    {
                        "phase": "bootstrap",
                        "status": "failed",
                        "message": "boom",
                    }
                )
            )
            env = {
                **os.environ,
                "HERMES_HOME": str(home),
            }
            result = _run_healthcheck(env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("startup failed", result.stderr)

    def test_fails_when_bootstrap_report_is_missing_but_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            status_path = home / "artifacts" / "hermes_lab_runtime" / "startup_status.json"
            status_path.parent.mkdir(parents=True, exist_ok=True)
            status_path.write_text(
                json.dumps(
                    {
                        "phase": "gateway",
                        "status": "starting",
                        "message": "gateway up",
                    }
                )
            )
            env = {
                **os.environ,
                "HERMES_HOME": str(home),
                "HERMES_CRON_BOOTSTRAP": "1",
                "HERMES_CRON_BOOTSTRAP_REQUIRED": "1",
            }
            result = _run_healthcheck(env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("bootstrap report missing", result.stderr)

    def test_fails_when_gateway_health_endpoint_is_unreachable(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            status_path = home / "artifacts" / "hermes_lab_runtime" / "startup_status.json"
            status_path.parent.mkdir(parents=True, exist_ok=True)
            status_path.write_text(
                json.dumps(
                    {
                        "phase": "gateway",
                        "status": "starting",
                        "message": "gateway booting",
                    }
                )
            )
            report_path = home / "artifacts" / "hermes_cron_bootstrap" / "latest_bootstrap_report.json"
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text("{}")
            jobs_json = home / "cron" / "jobs.json"
            jobs_json.parent.mkdir(parents=True, exist_ok=True)
            jobs_json.write_text(json.dumps({"jobs": [{"name": "x", "enabled": True}]}))
            env = {
                **os.environ,
                "HERMES_HOME": str(home),
                "HERMES_LAB_GATEWAY_HEALTH_URL": "http://127.0.0.1:9/health",
            }
            result = _run_healthcheck(env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("gateway health probe failed", result.stderr)


if __name__ == "__main__":
    unittest.main()
