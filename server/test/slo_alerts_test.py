#!/usr/bin/env python3
"""BT-OBS-001 (D-47, D-51): SLOs e alertas de API, PostgreSQL, jobs, cache e catálogo.

O avaliador roda aqui contra sinais falsos (HTTP, PostgreSQL e manifesto de
jobs) e um canal falso: nenhuma requisição sai da máquina. Cobre a política
versionada, cada regra, a entrega ao humano com repetição e resolução, o
teste de alerta, o relatório do SLO e a exclusão de PII.
"""

from __future__ import annotations

import copy
import datetime as dt
import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "server" / "bin" / "manaloom_slo_alerts.py"
NOW = dt.datetime(2026, 9, 24, 12, 0, tzinfo=dt.timezone.utc)
LOCAL_NOW = dt.datetime(2026, 9, 24, 12, 0)
OPS_KEY = "k" * 40
USER_ID = "0f8fad5b-d9cb-469f-a165-70867728950e"


def _load_module():
    spec = importlib.util.spec_from_file_location("bt_obs_001_slo", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


slo = _load_module()


def _policy() -> dict:
    return slo.load_policy()


def _window(requests=100, errors=0, reads=80, p95=120) -> dict:
    return {
        "request_count": requests,
        "error_count": errors,
        "error_rate": errors / requests if requests else 0.0,
        "read_count": reads,
        "read_p95_ms": p95,
    }


class FakeHttp:
    """Responde /health/live, /health/ready e /health/metrics."""

    def __init__(self) -> None:
        self.live = 200
        self.ready = 200
        self.database = "healthy"
        self.metrics_status = 200
        self.five = _window()
        self.sixty = _window(requests=1200, errors=2, reads=900)
        self.cache_entries = 12
        self.calls: list[tuple[str, dict]] = []

    def __call__(self, url: str, headers: dict[str, str]) -> tuple[int | None, bytes]:
        self.calls.append((url, dict(headers)))
        if url.endswith("/health/live"):
            return self.live, b'{"status":"ok"}'
        if url.endswith("/health/ready"):
            body = {"checks": {"database": {"status": self.database}}}
            return self.ready, json.dumps(body).encode()
        if url.endswith("/health/metrics"):
            if headers.get(slo.OPS_HEADER) != OPS_KEY:
                return 401, b""
            if self.metrics_status != 200:
                return self.metrics_status, b""
            body = {
                "windows": {"5m": self.five, "60m": self.sixty},
                "cache": {"endpoint_cache_entries": self.cache_entries},
                "endpoints": {f"GET /users/{USER_ID}": {"request_count": 1}},
            }
            return 200, json.dumps(body).encode()
        return None, b""


class FakePost:
    def __init__(self, status: int = 200) -> None:
        self.status = status
        self.calls: list[tuple[str, dict, dict]] = []

    def __call__(self, url: str, headers: dict[str, str], body: bytes) -> int:
        self.calls.append((url, headers, json.loads(body)))
        return self.status


def _postgres(connections=10, max_connections=100, cards_days=1, legalities_days=1):
    def reader() -> dict:
        def stamp(days):
            return (NOW - dt.timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")

        catalog = {}
        if cards_days is not None:
            catalog["cards"] = stamp(cards_days)
        if legalities_days is not None:
            catalog["card_legalities"] = stamp(legalities_days)
        return {
            "transaction_read_only": "on",
            "connections_total": connections,
            "max_connections": max_connections,
            "catalog_last_success": catalog,
        }

    return reader


def _email_env(data_dir: Path, jobs: Path) -> dict[str, str]:
    return {
        "MANALOOM_SLO_API_BASE_URL": "http://evolution_cartinhas:8080",
        "MANALOOM_OPS_API_KEY": OPS_KEY,
        "MANALOOM_OPS_DATA_DIR": str(data_dir),
        "MANALOOM_OPS_JOBS_JSON": str(jobs),
        "MANALOOM_ALERT_CHANNEL": "email",
        "MANALOOM_ALERT_EMAIL_TO": "dono@example.invalid",
        "RESEND_API_KEY": "re_" + "a1" * 12,
        "RESEND_FROM_EMAIL": "alertas@example.invalid",
    }


class PolicyTest(unittest.TestCase):
    def test_versioned_policy_is_valid(self) -> None:
        policy = _policy()
        self.assertEqual(policy["slos"]["api_availability"]["objective"], 0.995)
        self.assertEqual(policy["slos"]["api_read_latency"]["objective_p95_ms"], 800)
        self.assertEqual(set(policy["alerts"]), slo.KNOWN_ALERTS)
        self.assertEqual(policy["thresholds_status"], "proposta_pendente_do_dono")

    def test_refuses_policy_out_of_sync_with_code_decision_or_runbook(self) -> None:
        base = json.loads(slo.DEFAULT_POLICY.read_text(encoding="utf-8"))
        cases = []
        policy = copy.deepcopy(base)
        policy["alerts"]["disk_full"] = dict(policy["alerts"]["api_down"])
        cases.append((policy, "sem implementação"))
        policy = copy.deepcopy(base)
        del policy["alerts"]["catalog_stale"]
        cases.append((policy, "sem regra na política"))
        policy = copy.deepcopy(base)
        policy["alerts"]["api_down"]["runbook"] = "secao_que_nao_existe"
        cases.append((policy, "runbook"))
        policy = copy.deepcopy(base)
        policy["slos"]["api_availability"]["objective"] = 0.99
        cases.append((policy, "0.995"))
        policy = copy.deepcopy(base)
        policy["slos"]["api_read_latency"]["evidence"] = "p95 abaixo de 2000 ms"
        cases.append((policy, "D-47"))
        policy = copy.deepcopy(base)
        del policy["receiver"]["channels"]["telegram"]
        cases.append((policy, "telegram"))
        policy = copy.deepcopy(base)
        policy["alerts"]["job_failed"]["severity"] = "info"
        cases.append((policy, "severity"))
        for policy, expected in cases:
            with self.subTest(expected=expected):
                problems = slo.policy_problems(policy) + slo.provenance_problems(policy)
                self.assertTrue(any(expected in p for p in problems), problems)

    def test_versioned_policy_has_provenance(self) -> None:
        self.assertEqual(slo.provenance_problems(_policy()), [])

    def test_the_job_does_not_depend_on_docs_in_the_image(self) -> None:
        missing = Path(tempfile.gettempdir()) / "nao-existe.md"
        with mock.patch.object(slo, "RUNBOOK", missing), mock.patch.object(
            slo, "DECISION_SOURCE", missing
        ):
            self.assertEqual(slo.load_policy()["version"], _policy()["version"])
            self.assertTrue(slo.provenance_problems(_policy()))


class ReceiverTest(unittest.TestCase):
    def test_without_channel_there_is_no_receiver(self) -> None:
        for env in (
            {},
            {"MANALOOM_ALERT_CHANNEL": "slack"},
            {"MANALOOM_ALERT_CHANNEL": "email", "MANALOOM_ALERT_EMAIL_TO": "x"},
            {"MANALOOM_ALERT_CHANNEL": "telegram", "MANALOOM_ALERT_TELEGRAM_CHAT_ID": "1"},
        ):
            with self.subTest(env=env):
                with self.assertRaises(slo.ReceiverMissing):
                    slo.receiver_config(env)

    def test_email_goes_through_resend_without_pii_in_the_body(self) -> None:
        receiver = slo.receiver_config(_email_env(Path("/nao-usado"), Path("/nao-usado")))
        post = FakePost()
        slo.send(
            receiver,
            "Assunto",
            f"conta {USER_ID} de pessoa@example.com com token "
            "abcdef0123456789abcdef0123456789abcdef; job manaloom_catalog_reference_refresh",
            post,
        )
        url, headers, body = post.calls[0]
        self.assertEqual(url, "https://api.resend.com/emails")
        self.assertTrue(headers["Authorization"].startswith("Bearer re_"))
        self.assertEqual(body["to"], ["dono@example.invalid"])
        self.assertNotIn(USER_ID, body["text"])
        self.assertNotIn("pessoa@example.com", body["text"])
        self.assertNotIn("abcdef0123456789abcdef0123456789abcdef", body["text"])
        self.assertIn("manaloom_catalog_reference_refresh", body["text"])

    def test_telegram_and_refused_delivery(self) -> None:
        receiver = slo.receiver_config(
            {
                "MANALOOM_ALERT_CHANNEL": "telegram",
                "MANALOOM_ALERT_TELEGRAM_BOT_TOKEN": "123456:" + "A" * 35,
                "MANALOOM_ALERT_TELEGRAM_CHAT_ID": "-100123",
            }
        )
        post = FakePost()
        slo.send(receiver, "Assunto", "texto", post)
        url, _headers, body = post.calls[0]
        self.assertEqual(url, "https://api.telegram.org/bot123456:" + "A" * 35 + "/sendMessage")
        self.assertEqual(body["chat_id"], "-100123")
        with self.assertRaises(RuntimeError) as refused:
            slo.send(receiver, "Assunto", "texto", FakePost(status=403))
        self.assertNotIn("A" * 35, str(refused.exception))


class EvaluateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.policy = _policy()
        self.http = FakeHttp()
        self.tmp = tempfile.TemporaryDirectory()
        self.jobs = Path(self.tmp.name) / "jobs.json"
        self.jobs.write_text("[]", encoding="utf-8")
        self.env = _email_env(Path(self.tmp.name), self.jobs)
        self.postgres = _postgres()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _signals(self) -> dict:
        return slo.collect_signals(self.env, self.http, self.postgres, self.jobs)

    def _codes(self, memory: dict | None = None, runs: int = 1) -> set[str]:
        memory = memory or {}
        alerts: list = []
        for _ in range(runs):
            alerts, memory = slo.evaluate(self.policy, self._signals(), memory, NOW, LOCAL_NOW)
        return {alert["code"] for alert in alerts}

    def test_healthy_signals_raise_nothing(self) -> None:
        self.assertEqual(self._codes(runs=2), set())
        urls = [url for url, _ in self.http.calls]
        self.assertIn("http://evolution_cartinhas:8080/health/metrics", urls)

    def test_down_and_not_ready_need_two_evaluations(self) -> None:
        self.http.live = None
        self.assertEqual(self._codes(runs=1), set())
        self.assertEqual(self._codes(runs=2), {"api_down"})
        self.http.live = 200
        self.http.ready = 503
        self.assertEqual(self._codes(runs=2), {"api_not_ready"})

    def test_postgres_unavailable_from_ready_or_direct_read(self) -> None:
        self.http.database = "unhealthy"
        self.http.ready = 503
        self.assertIn("postgres_unavailable", self._codes(runs=2))
        self.http.database = "healthy"
        self.http.ready = 200

        def broken() -> dict:
            raise ConnectionError("recusado")

        self.postgres = broken
        self.assertEqual(self._codes(runs=2), {"postgres_unavailable"})

    def test_error_budget_burn_and_latency(self) -> None:
        self.http.five = _window(requests=30, errors=3)
        self.assertEqual(self._codes(), {"api_5xx_fast_burn"})
        self.http.five = _window(requests=10, errors=10)
        self.assertEqual(self._codes(), set())
        self.http.five = _window()
        self.http.sixty = _window(requests=200, errors=8)
        self.assertEqual(self._codes(), {"api_5xx_slow_burn"})
        self.http.sixty = _window(requests=1200)
        self.http.five = _window(reads=25, p95=900)
        self.assertEqual(self._codes(runs=1), set())
        self.assertEqual(self._codes(runs=2), {"api_read_latency_p95"})

    def test_metrics_cache_connections_and_catalog(self) -> None:
        self.http.metrics_status = 401
        self.assertEqual(self._codes(runs=2), {"metrics_unavailable"})
        self.http.metrics_status = 200
        self.http.cache_entries = 6000
        self.assertEqual(self._codes(), {"endpoint_cache_large"})
        self.http.cache_entries = 12
        self.postgres = _postgres(connections=85)
        self.assertEqual(self._codes(), {"postgres_connections_high"})
        self.postgres = _postgres(cards_days=8, legalities_days=None)
        self.assertEqual(
            self._codes(), {"catalog_stale:cards", "catalog_stale:card_legalities"}
        )

    def test_numbers_out_of_format_do_not_break_the_evaluation(self) -> None:
        self.http.five = {"request_count": None, "error_rate": "alto", "read_count": "x"}
        self.assertEqual(self._codes(), set())

    def test_metrics_body_out_of_format_counts_as_unavailable(self) -> None:
        original = self.http

        def broken(url: str, headers: dict[str, str]) -> tuple[int | None, bytes]:
            if url.endswith("/health/metrics"):
                return 200, b"[1, 2]"
            return original(url, headers)

        self.http = broken
        self.assertEqual(self._codes(runs=2), {"metrics_unavailable"})

    def test_jobs_failed_and_overdue(self) -> None:
        long_ago = "2026-09-01T00:00"
        jobs = [
            {"name": "manaloom_account_deletion_outbox", "schedule": "*/15 * * * *",
             "last_status": "error", "last_exit_code": 1,
             "last_started_at": "2026-09-24T11:45:00"},
            {"name": "manaloom_catalog_reference_refresh", "schedule": "20 6 * * *",
             "last_status": "ok", "last_started_at": "2026-09-22T06:20:00"},
            {"name": "hermes_cron_governor_report", "schedule": "0 */12 * * *",
             "last_status": "ok", "last_started_at": "2026-09-24T00:00:02"},
            {"name": "manaloom_slo_alerts", "schedule": "*/5 * * * *",
             "last_status": "running", "last_started_at": "2026-09-24T12:00:00"},
        ]
        self.jobs.write_text(json.dumps(jobs), encoding="utf-8")
        seen = {"jobs_first_seen": {job["name"]: long_ago for job in jobs}}
        self.assertEqual(
            self._codes(seen),
            {
                "job_failed:manaloom_account_deletion_outbox",
                "job_overdue:manaloom_catalog_reference_refresh",
            },
        )
        # Recém-ligado: não conta atraso antes do primeiro horário dele.
        self.assertEqual(self._codes({}), {"job_failed:manaloom_account_deletion_outbox"})


class NotificationTest(unittest.TestCase):
    def setUp(self) -> None:
        self.policy = _policy()
        self.alert = {
            "code": "api_5xx_fast_burn",
            "severity": "critical",
            "summary": "resumo",
            "observed": 0.1,
            "threshold": 0.072,
            "runbook": "api_5xx",
        }

    def test_new_repeated_and_resolved(self) -> None:
        subject, text, state = slo.plan_notifications(self.policy, [self.alert], {}, NOW)
        self.assertIn("CRÍTICO", subject)
        self.assertIn("Novos:", text)
        self.assertIn("SLO_E_ALERTAS.md#api_5xx", text)

        later = NOW + dt.timedelta(minutes=30)
        subject, _text, state = slo.plan_notifications(self.policy, [self.alert], state, later)
        self.assertIsNone(subject)

        later = NOW + dt.timedelta(minutes=61)
        subject, text, state = slo.plan_notifications(self.policy, [self.alert], state, later)
        self.assertIn("Ainda abertos:", text)

        subject, text, state = slo.plan_notifications(self.policy, [], state, later)
        self.assertIn("Resolvidos:", text)
        self.assertIn("api_5xx_fast_burn", text)
        self.assertEqual(state["open"], {})


class RunTest(unittest.TestCase):
    def setUp(self) -> None:
        self.policy = _policy()
        self.tmp = tempfile.TemporaryDirectory()
        self.data = Path(self.tmp.name)
        self.jobs = self.data / "jobs.json"
        self.jobs.write_text("[]", encoding="utf-8")
        self.env = _email_env(self.data, self.jobs)
        self.http = FakeHttp()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _run(self, post: FakePost, env: dict | None = None, now: dt.datetime = NOW) -> dict:
        return slo.run(env or self.env, self.policy, fetch=self.http, post=post,
                       postgres=_postgres(), now=now, local_now=now.replace(tzinfo=None))

    def test_run_notifies_once_and_keeps_observations(self) -> None:
        self.http.five = _window(requests=40, errors=10)
        post = FakePost()
        result = self._run(post)
        self.assertEqual(result["open"], ["api_5xx_fast_burn"])
        self.assertEqual(len(post.calls), 1)
        self.assertEqual(len(self._run(post, now=NOW + dt.timedelta(minutes=5))["open"]), 1)
        self.assertEqual(len(post.calls), 1)
        lines = (self.data / "slo" / "observations.jsonl").read_text().splitlines()
        self.assertEqual(len(lines), 2)
        self.assertNotIn(USER_ID, "".join(lines))

    def test_failed_delivery_does_not_advance_the_state(self) -> None:
        self.http.five = _window(requests=40, errors=10)
        with self.assertRaises(RuntimeError):
            self._run(FakePost(status=500))
        post = FakePost()
        self._run(post, now=NOW + dt.timedelta(minutes=5))
        self.assertEqual(len(post.calls), 1)

    def test_without_receiver_it_records_and_stops(self) -> None:
        env = dict(self.env)
        del env["MANALOOM_ALERT_CHANNEL"]
        self.http.live = None
        with self.assertRaises(slo.ReceiverMissing):
            self._run(FakePost(), env=env)
        state = json.loads((self.data / "slo" / "state.json").read_text())
        self.assertEqual(state["consecutive"]["api_down"], 1)
        self.assertNotIn("open", state)
        self.assertTrue((self.data / "slo" / "observations.jsonl").exists())

    def test_test_alert_reaches_the_receiver(self) -> None:
        post = FakePost()
        receipt = slo.test_alert(self.env, post=post, now=NOW)
        self.assertEqual(receipt["status"], "sent")
        self.assertEqual(receipt["channel"], "email")
        _url, _headers, body = post.calls[0]
        self.assertIn(receipt["test_id"], body["subject"])
        state = json.loads((self.data / "slo" / "state.json").read_text())
        self.assertEqual(state["last_test"]["test_id"], receipt["test_id"])

    def test_cli_blocks_without_receiver(self) -> None:
        output = io.StringIO()
        with mock.patch.dict(os.environ, {}, clear=True), redirect_stdout(output):
            code = slo.main(["test-alert"])
        self.assertEqual(code, 2)
        self.assertEqual(json.loads(output.getvalue())["status"], "BLOCKED")


class ReportTest(unittest.TestCase):
    def test_availability_budget_and_latency(self) -> None:
        policy = _policy()
        observations = []
        for index in range(1000):
            at = (NOW - dt.timedelta(minutes=5 * index)).strftime("%Y-%m-%dT%H:%M:%SZ")
            item = {"at": at, "live": True, "ready": True, "metrics": True,
                    "requests": 100, "errors": 0, "reads": 50, "read_p95_ms": 200}
            if index < 3:
                item.update(live=False, metrics=False, requests=None, errors=None,
                            reads=None, read_p95_ms=None)
            elif index < 5:
                item["errors"] = 10
            elif index < 15:
                item["read_p95_ms"] = 1200
            observations.append(item)
        observations.append({"at": "2026-07-01T00:00:00Z", "live": False, "ready": False})
        result = slo.report(policy, observations, NOW)
        self.assertEqual(result["slots_evaluated"], 1000)
        self.assertEqual(result["availability"], 0.995)
        self.assertEqual(result["error_budget_remaining"], 0.0)
        self.assertEqual(result["read_latency_slots"], 997)
        self.assertEqual(result["read_latency_compliance"], round(987 / 997, 5))


if __name__ == "__main__":
    unittest.main()
