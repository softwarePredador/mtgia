#!/usr/bin/env python3
"""BT-OBS-001 (D-47, D-51): SLOs e alertas de API, PostgreSQL, jobs, cache e catálogo.

Roda como job do daemon de ops a cada 5 minutos. Só lê:
- `GET /health/live` e `GET /health/ready` da API;
- `GET /health/metrics` (janelas de 5 e 60 minutos e o cache), com a chave de ops;
- o PostgreSQL numa transação READ ONLY (conexões e frescor do catálogo);
- o manifesto de jobs do próprio daemon.
Avalia as regras de `server/config/slo_alert_policy.json`, grava a observação
da janela e o estado dos alertas abertos no volume do ops e avisa o dono pelo
canal configurado: e-mail (Resend) ou Telegram. Sem receptor configurado, a
observação é gravada e o job para com erro, porque alerta sem receptor não é
alerta. As mensagens não levam e-mail, UUID, token nem caminho cru.

Subcomandos:
  run            avalia, grava a observação e notifica (padrão do job)
  test-alert     manda um alerta sintético pelo canal configurado
  report         SLO dos últimos 30 dias a partir das observações
  validate-policy

Ambiente: MANALOOM_SLO_API_BASE_URL, MANALOOM_OPS_API_KEY, DB_HOST, DB_PORT,
DB_NAME, DB_USER, DB_PASS, MANALOOM_OPS_DATA_DIR, MANALOOM_OPS_JOBS_JSON e o
receptor (MANALOOM_ALERT_CHANNEL e as variáveis do canal, na política).
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import secrets
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Callable

REPO_ROOT = Path(
    os.environ.get("MANALOOM_REPO") or Path(__file__).resolve().parents[2]
).resolve()
DEFAULT_POLICY = REPO_ROOT / "server" / "config" / "slo_alert_policy.json"
RUNBOOK = REPO_ROOT / "docs" / "runbooks" / "SLO_E_ALERTAS.md"
DECISION_SOURCE = REPO_ROOT / "docs" / "BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md"
OPS_HEADER = "x-manaloom-ops-key"
HTTP_TIMEOUT_SECONDS = 10
KNOWN_ALERTS = {
    "api_down",
    "api_not_ready",
    "postgres_unavailable",
    "api_5xx_fast_burn",
    "api_5xx_slow_burn",
    "api_read_latency_p95",
    "metrics_unavailable",
    "postgres_connections_high",
    "job_failed",
    "job_overdue",
    "catalog_stale",
    "endpoint_cache_large",
}
SEVERITIES = ("critical", "warning")
CATALOG_SYNC_TYPES = ("cards", "card_legalities")
EMAIL = re.compile(r"^[^@\s<>]+@[^@\s<>]+\.[^@\s<>]+$")
UUID = re.compile(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
EMAIL_ANYWHERE = re.compile(r"[^@\s<>()\"']+@[^@\s<>()\"']+\.[A-Za-z]{2,}")
# Token ou chave: 32+ caracteres com ao menos dois dígitos (nome de job não
# tem dígito, hash e chave de API têm).
LONG_TOKEN = re.compile(r"\b(?=[A-Za-z0-9_-]*\d[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{32,}\b")

Fetch = Callable[[str, dict[str, str]], tuple[int | None, bytes]]
Post = Callable[[str, dict[str, str], bytes], int]


class InvalidInput(ValueError):
    """Política ou configuração fora do contrato: código 2."""


class ReceiverMissing(InvalidInput):
    """Não há receptor humano configurado: código 2."""


# ----------------------------------------------------------------- política


def policy_problems(policy: dict[str, Any]) -> list[str]:
    """Estrutura da política: roda no job, sem depender de nada fora dela."""
    problems: list[str] = []
    if policy.get("schema_version") != 1:
        problems.append("schema_version deve ser 1")
    slos = policy.get("slos")
    if not isinstance(slos, dict):
        problems.append("slos ausente")
    else:
        availability = slos.get("api_availability", {})
        latency = slos.get("api_read_latency", {})
        if availability.get("objective") != 0.995:
            problems.append("slos.api_availability.objective deve ser 0.995 (D-47)")
        if latency.get("objective_p95_ms") != 800:
            problems.append("slos.api_read_latency.objective_p95_ms deve ser 800 (D-47)")
        for key in ("bad_slot_error_rate", "min_requests"):
            if not isinstance(availability.get(key), (int, float)):
                problems.append(f"slos.api_availability.{key} ausente")
        if not isinstance(latency.get("min_reads"), int):
            problems.append("slos.api_read_latency.min_reads ausente")
    alerts = policy.get("alerts")
    if not isinstance(alerts, dict):
        return problems + ["alerts ausente"]
    unknown = set(alerts) - KNOWN_ALERTS
    missing = KNOWN_ALERTS - set(alerts)
    if unknown:
        problems.append("alerta sem implementação: " + ", ".join(sorted(unknown)))
    if missing:
        problems.append("alerta implementado sem regra na política: " + ", ".join(sorted(missing)))
    for code, rule in alerts.items():
        if not isinstance(rule, dict):
            problems.append(f"alerts.{code} inválido")
            continue
        if rule.get("severity") not in SEVERITIES:
            problems.append(f"alerts.{code}.severity inválida")
        if not isinstance(rule.get("summary"), str) or not rule["summary"].strip():
            problems.append(f"alerts.{code}.summary ausente")
        if not isinstance(rule.get("runbook"), str) or not rule["runbook"]:
            problems.append(f"alerts.{code}.runbook ausente")
    receiver = policy.get("receiver")
    if not isinstance(receiver, dict) or set(receiver.get("channels", {})) != {"email", "telegram"}:
        problems.append("receiver.channels deve ter email e telegram (D-47)")
    rationale = policy.get("thresholds_rationale")
    if not isinstance(rationale, dict) or not rationale:
        problems.append("thresholds_rationale ausente")
    return problems


def provenance_problems(
    policy: dict[str, Any],
    runbook_text: str | None = None,
    decision_text: str | None = None,
) -> list[str]:
    """Os SLOs saem da D-47 e cada alerta tem seção no runbook (testes e CI)."""
    if runbook_text is None:
        runbook_text = RUNBOOK.read_text(encoding="utf-8") if RUNBOOK.is_file() else ""
    if decision_text is None:
        decision_text = (
            DECISION_SOURCE.read_text(encoding="utf-8") if DECISION_SOURCE.is_file() else ""
        )
    problems: list[str] = []
    for name, slo_rule in policy.get("slos", {}).items():
        evidence = slo_rule.get("evidence") if isinstance(slo_rule, dict) else None
        if not isinstance(evidence, str) or evidence not in decision_text:
            problems.append(f"slos.{name}.evidence não está na decisão D-47")
    for code, rule in policy.get("alerts", {}).items():
        anchor = rule.get("runbook") if isinstance(rule, dict) else None
        if not isinstance(anchor, str) or f"\n## {anchor}\n" not in runbook_text:
            problems.append(f"alerts.{code}.runbook sem seção no runbook")
    return problems


def load_policy(path: Path = DEFAULT_POLICY) -> dict[str, Any]:
    try:
        policy = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise InvalidInput(f"não li a política {path}: {error}") from error
    problems = policy_problems(policy)
    if problems:
        raise InvalidInput("política inválida: " + "; ".join(problems))
    return policy


# ---------------------------------------------------------------- receptor


def receiver_config(env: dict[str, str]) -> dict[str, str]:
    channel = env.get("MANALOOM_ALERT_CHANNEL", "").strip().lower()
    if channel == "email":
        to = env.get("MANALOOM_ALERT_EMAIL_TO", "").strip()
        key = env.get("RESEND_API_KEY", "").strip()
        sender = env.get("RESEND_FROM_EMAIL", "").strip()
        if not EMAIL.match(to):
            raise ReceiverMissing("MANALOOM_ALERT_EMAIL_TO não é um e-mail válido")
        if not key.startswith("re_") or len(key) < 16:
            raise ReceiverMissing("RESEND_API_KEY ausente ou fora do contrato do Resend")
        if not EMAIL.match(sender):
            raise ReceiverMissing("RESEND_FROM_EMAIL não é um e-mail válido")
        name = env.get("RESEND_FROM_NAME", "").strip() or "BrewTact"
        return {"channel": "email", "to": to, "key": key, "from": f"{name} <{sender}>"}
    if channel == "telegram":
        token = env.get("MANALOOM_ALERT_TELEGRAM_BOT_TOKEN", "").strip()
        chat = env.get("MANALOOM_ALERT_TELEGRAM_CHAT_ID", "").strip()
        if not re.fullmatch(r"\d{5,}:[A-Za-z0-9_-]{30,}", token):
            raise ReceiverMissing("MANALOOM_ALERT_TELEGRAM_BOT_TOKEN ausente ou inválido")
        if not re.fullmatch(r"-?\d{3,}", chat):
            raise ReceiverMissing("MANALOOM_ALERT_TELEGRAM_CHAT_ID ausente ou inválido")
        return {"channel": "telegram", "token": token, "chat": chat}
    raise ReceiverMissing(
        "receptor de alerta não configurado: defina MANALOOM_ALERT_CHANNEL como "
        "email ou telegram"
    )


def sanitize(text: str) -> str:
    """Nenhum e-mail, UUID ou token longo sai numa mensagem de alerta."""
    text = EMAIL_ANYWHERE.sub("[e-mail]", text)
    text = UUID.sub(":id", text)
    return LONG_TOKEN.sub("[token]", text)


def send(receiver: dict[str, str], subject: str, text: str, post: Post) -> None:
    subject = sanitize(subject)
    text = sanitize(text)
    if receiver["channel"] == "email":
        status = post(
            "https://api.resend.com/emails",
            {
                "Authorization": f"Bearer {receiver['key']}",
                "Content-Type": "application/json",
            },
            json.dumps(
                {
                    "from": receiver["from"],
                    "to": [receiver["to"]],
                    "subject": subject,
                    "text": text,
                }
            ).encode("utf-8"),
        )
    else:
        status = post(
            f"https://api.telegram.org/bot{receiver['token']}/sendMessage",
            {"Content-Type": "application/json"},
            json.dumps(
                {
                    "chat_id": receiver["chat"],
                    "text": f"{subject}\n\n{text}",
                    "disable_web_page_preview": True,
                }
            ).encode("utf-8"),
        )
    if status is None or not 200 <= status < 300:
        raise RuntimeError(f"o canal {receiver['channel']} recusou o alerta (HTTP {status})")


def http_post(url: str, headers: dict[str, str], body: bytes) -> int:
    request = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT_SECONDS) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code
    except (urllib.error.URLError, TimeoutError, OSError):
        return 0


def http_get(url: str, headers: dict[str, str]) -> tuple[int | None, bytes]:
    request = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=HTTP_TIMEOUT_SECONDS) as response:
            return response.status, response.read(2_000_000)
    except urllib.error.HTTPError as error:
        return error.code, b""
    except (urllib.error.URLError, TimeoutError, OSError):
        return None, b""


# ------------------------------------------------------------------ sinais


def read_postgres(env: dict[str, str]) -> dict[str, Any]:
    """Conexões e frescor do catálogo, numa transação READ ONLY."""
    import psycopg2  # disponível na imagem de ops (python3-psycopg2)

    connection = psycopg2.connect(
        host=env.get("DB_HOST", "127.0.0.1"),
        port=int(env.get("DB_PORT", "5432")),
        dbname=env.get("DB_NAME", ""),
        user=env.get("DB_USER", ""),
        password=env.get("DB_PASS", ""),
        connect_timeout=HTTP_TIMEOUT_SECONDS,
        options="-c default_transaction_read_only=on",
    )
    try:
        connection.set_session(readonly=True, autocommit=False)
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_setting('transaction_read_only')")
            read_only = cursor.fetchone()[0]
            if read_only != "on":
                raise RuntimeError("a leitura do PostgreSQL não ficou READ ONLY")
            cursor.execute(
                "SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()"
            )
            connections = int(cursor.fetchone()[0])
            cursor.execute("SELECT current_setting('max_connections')::int")
            max_connections = int(cursor.fetchone()[0])
            cursor.execute(
                "SELECT sync_type, max(finished_at) FROM sync_log "
                "WHERE status = 'success' AND sync_type = ANY(%s) GROUP BY sync_type",
                (list(CATALOG_SYNC_TYPES),),
            )
            catalog = {
                str(row[0]): row[1].astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                for row in cursor.fetchall()
                if row[1] is not None
            }
        connection.rollback()
    finally:
        connection.close()
    return {
        "transaction_read_only": read_only,
        "connections_total": connections,
        "max_connections": max_connections,
        "catalog_last_success": catalog,
    }


def collect_signals(
    env: dict[str, str],
    fetch: Fetch,
    postgres: Callable[[], dict[str, Any]],
    jobs_manifest: Path,
) -> dict[str, Any]:
    base = env.get("MANALOOM_SLO_API_BASE_URL", "").rstrip("/")
    if not re.fullmatch(r"https?://[A-Za-z0-9.\-_:]+", base):
        raise InvalidInput("MANALOOM_SLO_API_BASE_URL ausente ou inválida")
    signals: dict[str, Any] = {}
    live_status, _ = fetch(f"{base}/health/live", {})
    signals["live"] = {"ok": live_status == 200, "status": live_status}
    ready_status, ready_body = fetch(f"{base}/health/ready", {})
    database = None
    try:
        database = json.loads(ready_body or b"{}").get("checks", {}).get("database", {}).get("status")
    except (json.JSONDecodeError, AttributeError):
        database = None
    signals["ready"] = {"ok": ready_status == 200, "status": ready_status, "database": database}

    key = env.get("MANALOOM_OPS_API_KEY", "")
    metrics: dict[str, Any] = {"ok": False}
    if len(key) >= 32:
        status, body = fetch(f"{base}/health/metrics", {OPS_HEADER: key})
        if status == 200:
            try:
                payload = json.loads(body)
            except json.JSONDecodeError:
                payload = None
            if isinstance(payload, dict) and isinstance(payload.get("windows"), dict):
                cache = payload.get("cache")
                metrics = {
                    "ok": True,
                    "windows": payload["windows"],
                    "cache": cache if isinstance(cache, dict) else {},
                }
            else:
                metrics = {"ok": False, "status": "corpo_fora_do_formato"}
        else:
            metrics = {"ok": False, "status": status}
    else:
        metrics = {"ok": False, "status": "sem_chave_de_ops"}
    signals["metrics"] = metrics

    try:
        signals["postgres"] = {"ok": True, **postgres()}
    except Exception as error:  # noqa: BLE001 - qualquer falha vira sinal
        signals["postgres"] = {"ok": False, "error": type(error).__name__}

    jobs: list[dict[str, Any]] = []
    try:
        payload = json.loads(jobs_manifest.read_text(encoding="utf-8"))
        if isinstance(payload, list):
            jobs = [job for job in payload if isinstance(job, dict)]
    except (OSError, json.JSONDecodeError):
        jobs = []
    signals["jobs"] = jobs
    return signals


# ---------------------------------------------------------------- avaliação


def _matches(value: int, expression: str) -> bool:
    if expression == "*":
        return True
    if expression.startswith("*/"):
        step = int(expression[2:])
        return step > 0 and value % step == 0
    if "," in expression:
        return any(_matches(value, part) for part in expression.split(","))
    return value == int(expression)


def previous_run(schedule: str, before: dt.datetime) -> dt.datetime | None:
    """Último horário do cron (como o daemon o lê) em ou antes de [before]."""
    parts = schedule.split()
    if len(parts) != 5:
        return None
    minute, hour, day, month, weekday = parts
    moment = before.replace(second=0, microsecond=0)
    for _ in range(8 * 24 * 60):
        cron_weekday = (moment.weekday() + 1) % 7
        try:
            if (
                _matches(moment.minute, minute)
                and _matches(moment.hour, hour)
                and _matches(moment.day, day)
                and _matches(moment.month, month)
                and _matches(cron_weekday, weekday)
            ):
                return moment
        except ValueError:
            return None
        moment -= dt.timedelta(minutes=1)
    return None


def _number(value: Any) -> int | float:
    """Número de /health/metrics; qualquer outra coisa conta como zero."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return 0
    return value


def _window_of(windows: Any, name: str) -> dict[str, int | float]:
    window = windows.get(name) if isinstance(windows, dict) else None
    if not isinstance(window, dict):
        return {}
    return {key: _number(value) for key, value in window.items()}


def _alert(code: str, rule: dict[str, Any], observed: Any, threshold: Any) -> dict[str, Any]:
    return {
        "code": code,
        "severity": rule["severity"],
        "summary": rule["summary"],
        "observed": observed,
        "threshold": threshold,
        "runbook": rule["runbook"],
    }


def evaluate(
    policy: dict[str, Any],
    signals: dict[str, Any],
    memory: dict[str, Any],
    now: dt.datetime,
    local_now: dt.datetime,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Alertas abertos agora e a memória nova do avaliador.

    A memória guarda as falhas seguidas por regra (`consecutive`) e quando
    cada job apareceu no manifesto pela primeira vez (`jobs_first_seen`).
    """
    rules = policy["alerts"]
    counters = dict(memory.get("consecutive", {}))
    first_seen = dict(memory.get("jobs_first_seen", {}))
    alerts: list[dict[str, Any]] = []

    def streak(code: str, failing: bool) -> bool:
        counters[code] = counters.get(code, 0) + 1 if failing else 0
        return counters[code] >= rules[code].get("consecutive", 1)

    live, ready = signals["live"], signals["ready"]
    if streak("api_down", not live["ok"]):
        alerts.append(_alert("api_down", rules["api_down"], live["status"], 200))
    if streak("api_not_ready", live["ok"] and not ready["ok"]):
        alerts.append(_alert("api_not_ready", rules["api_not_ready"], ready["status"], 200))
    postgres = signals["postgres"]
    database_down = ready.get("database") not in (None, "healthy") or not postgres["ok"]
    if streak("postgres_unavailable", database_down):
        alerts.append(
            _alert(
                "postgres_unavailable",
                rules["postgres_unavailable"],
                ready.get("database") or postgres.get("error"),
                "healthy",
            )
        )

    metrics = signals["metrics"]
    if streak("metrics_unavailable", live["ok"] and not metrics["ok"]):
        alerts.append(
            _alert("metrics_unavailable", rules["metrics_unavailable"], metrics.get("status"), 200)
        )
    windows = metrics.get("windows", {}) if metrics["ok"] else {}
    five = _window_of(windows, "5m")
    sixty = _window_of(windows, "60m")
    fast = rules["api_5xx_fast_burn"]
    if (
        five.get("request_count", 0) >= fast["min_requests"]
        and five.get("error_rate", 0) >= fast["error_rate_min"]
    ):
        alerts.append(
            _alert("api_5xx_fast_burn", fast, round(five["error_rate"], 4), fast["error_rate_min"])
        )
    slow = rules["api_5xx_slow_burn"]
    if (
        sixty.get("request_count", 0) >= slow["min_requests"]
        and sixty.get("error_rate", 0) >= slow["error_rate_min"]
    ):
        alerts.append(
            _alert("api_5xx_slow_burn", slow, round(sixty["error_rate"], 4), slow["error_rate_min"])
        )
    latency = rules["api_read_latency_p95"]
    slow_reads = (
        five.get("read_count", 0) >= latency["min_reads"]
        and five.get("read_p95_ms", 0) > latency["p95_ms_max"]
    )
    if streak("api_read_latency_p95", slow_reads):
        alerts.append(
            _alert(
                "api_read_latency_p95", latency, five.get("read_p95_ms"), latency["p95_ms_max"]
            )
        )
    cache_rule = rules["endpoint_cache_large"]
    entries = metrics.get("cache", {}).get("endpoint_cache_entries") if metrics["ok"] else None
    if isinstance(entries, int) and entries > cache_rule["max_entries"]:
        alerts.append(
            _alert("endpoint_cache_large", cache_rule, entries, cache_rule["max_entries"])
        )

    if postgres["ok"]:
        connections_rule = rules["postgres_connections_high"]
        ratio = postgres["connections_total"] / max(postgres["max_connections"], 1)
        if ratio >= connections_rule["used_ratio_max"]:
            alerts.append(
                _alert(
                    "postgres_connections_high",
                    connections_rule,
                    round(ratio, 3),
                    connections_rule["used_ratio_max"],
                )
            )
        stale_rule = rules["catalog_stale"]
        last_success = postgres.get("catalog_last_success", {})
        for sync_type in CATALOG_SYNC_TYPES:
            finished = last_success.get(sync_type)
            age_days = None
            if finished:
                finished_at = dt.datetime.strptime(finished, "%Y-%m-%dT%H:%M:%SZ").replace(
                    tzinfo=dt.timezone.utc
                )
                age_days = round((now - finished_at).total_seconds() / 86400, 1)
            if age_days is None or age_days > stale_rule["max_age_days"]:
                alerts.append(
                    _alert(
                        f"catalog_stale:{sync_type}",
                        stale_rule,
                        age_days if age_days is not None else "sem sync com sucesso",
                        stale_rule["max_age_days"],
                    )
                )

    failed_rule = rules["job_failed"]
    overdue_rule = rules["job_overdue"]
    for job in signals["jobs"]:
        name = str(job.get("name") or "")
        if not re.fullmatch(r"[a-z0-9_]+", name):
            continue
        if job.get("last_status") == "error":
            alerts.append(
                _alert(f"job_failed:{name}", failed_rule, job.get("last_exit_code"), 0)
            )
        seen_text = first_seen.setdefault(name, local_now.isoformat(timespec="minutes"))
        schedule = str(job.get("schedule") or "")
        expected = previous_run(
            schedule, local_now - dt.timedelta(minutes=overdue_rule["grace_minutes"])
        )
        # Só conta atraso de horário previsto depois que o job apareceu.
        if expected is None or expected < dt.datetime.fromisoformat(seen_text):
            continue
        started_text = job.get("last_started_at")
        try:
            started = dt.datetime.fromisoformat(str(started_text)) if started_text else None
        except ValueError:
            started = None
        if started is not None and started.tzinfo is not None:
            started = started.astimezone(dt.timezone.utc).replace(tzinfo=None)
        if started is None or started < expected:
            alerts.append(
                _alert(
                    f"job_overdue:{name}",
                    overdue_rule,
                    started_text or "nunca rodou",
                    expected.isoformat(timespec="minutes"),
                )
            )
    listed = {str(job.get("name") or "") for job in signals["jobs"]}
    first_seen = {name: seen for name, seen in first_seen.items() if name in listed}
    return alerts, {"consecutive": counters, "jobs_first_seen": first_seen}


# ------------------------------------------------------------ notificações


def plan_notifications(
    policy: dict[str, Any],
    alerts: list[dict[str, Any]],
    state: dict[str, Any],
    now: dt.datetime,
) -> tuple[str | None, str | None, dict[str, Any]]:
    """Uma mensagem por execução: novos, ainda abertos (a cada N min) e resolvidos."""
    receiver = policy["receiver"]
    repeat = dt.timedelta(minutes=receiver["repeat_after_minutes"])
    stamp = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    previous = state.get("open", {})
    opened, repeated, resolved = [], [], []
    open_now: dict[str, Any] = {}
    for alert in alerts:
        code = alert["code"]
        before = previous.get(code)
        entry = {
            "severity": alert["severity"],
            "first_seen": before["first_seen"] if before else stamp,
            "last_notified": before["last_notified"] if before else stamp,
        }
        if before is None:
            opened.append(alert)
        else:
            last = dt.datetime.strptime(before["last_notified"], "%Y-%m-%dT%H:%M:%SZ").replace(
                tzinfo=dt.timezone.utc
            )
            if now - last >= repeat:
                repeated.append(alert)
                entry["last_notified"] = stamp
        open_now[code] = entry
    if receiver.get("notify_resolved"):
        resolved = sorted(code for code in previous if code not in open_now)
    new_state = {**state, "open": open_now}
    if not (opened or repeated or resolved):
        return None, None, new_state

    worst = "critical" if any(a["severity"] == "critical" for a in opened + repeated) else None
    headline = (
        f"[BrewTact] {'CRÍTICO' if worst else 'Aviso'}: "
        f"{len(opened)} novo(s), {len(repeated)} aberto(s), {len(resolved)} resolvido(s)"
    )
    lines = [f"Avaliação de {stamp} (BT-OBS-001, política {policy.get('version')})."]
    for title, group in (("Novos", opened), ("Ainda abertos", repeated)):
        if group:
            lines.append("")
            lines.append(f"{title}:")
            for alert in group:
                lines.append(
                    f"- [{alert['severity']}] {alert['code']}: {alert['summary']} "
                    f"Observado: {alert['observed']}; limite: {alert['threshold']}. "
                    f"Runbook: docs/runbooks/SLO_E_ALERTAS.md#{alert['runbook']}"
                )
    if resolved:
        lines.append("")
        lines.append("Resolvidos:")
        lines.extend(f"- {code}" for code in resolved)
    return headline, "\n".join(lines), new_state


# ------------------------------------------------------------ observações


def observation(signals: dict[str, Any], now: dt.datetime) -> dict[str, Any]:
    five = (
        _window_of(signals["metrics"].get("windows"), "5m") if signals["metrics"]["ok"] else {}
    )
    return {
        "at": now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "live": signals["live"]["ok"],
        "ready": signals["ready"]["ok"],
        "metrics": signals["metrics"]["ok"],
        "requests": five.get("request_count"),
        "errors": five.get("error_count"),
        "reads": five.get("read_count"),
        "read_p95_ms": five.get("read_p95_ms"),
    }


def append_observation(path: Path, record: dict[str, Any], retention_days: int, now: dt.datetime) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    cutoff = now - dt.timedelta(days=retention_days)
    kept = []
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            try:
                item = json.loads(line)
                at = dt.datetime.strptime(item["at"], "%Y-%m-%dT%H:%M:%SZ").replace(
                    tzinfo=dt.timezone.utc
                )
            except (json.JSONDecodeError, KeyError, ValueError):
                continue
            if at >= cutoff:
                kept.append(line)
    kept.append(json.dumps(record, ensure_ascii=False))
    temporary = path.with_suffix(".tmp")
    temporary.write_text("\n".join(kept) + "\n", encoding="utf-8")
    temporary.replace(path)


def report(policy: dict[str, Any], observations: list[dict[str, Any]], now: dt.datetime) -> dict[str, Any]:
    availability = policy["slos"]["api_availability"]
    latency = policy["slos"]["api_read_latency"]
    window = dt.timedelta(days=availability["window_days"])
    slots = good = latency_slots = latency_good = 0
    for item in observations:
        at = dt.datetime.strptime(item["at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)
        if now - at > window or at > now:
            continue
        slots += 1
        requests = item.get("requests") or 0
        errors = item.get("errors") or 0
        traffic_ok = (
            requests < availability["min_requests"]
            or errors / requests < availability["bad_slot_error_rate"]
        )
        if item.get("live") and item.get("ready") and traffic_ok:
            good += 1
        if (item.get("reads") or 0) >= latency["min_reads"]:
            latency_slots += 1
            if (item.get("read_p95_ms") or 0) <= latency["objective_p95_ms"]:
                latency_good += 1
    expected_slots = int(window.total_seconds() // (policy["evaluation"]["slot_minutes"] * 60))
    measured = good / slots if slots else None
    budget = 1 - availability["objective"]
    return {
        "window_days": availability["window_days"],
        "slots_evaluated": slots,
        "coverage": round(slots / expected_slots, 4) if expected_slots else 0,
        "availability": round(measured, 5) if measured is not None else None,
        "availability_objective": availability["objective"],
        "error_budget_remaining": (
            round(1 - (1 - measured) / budget, 4) if measured is not None else None
        ),
        "read_latency_slots": latency_slots,
        "read_latency_compliance": (
            round(latency_good / latency_slots, 5) if latency_slots else None
        ),
        "read_latency_objective_p95_ms": latency["objective_p95_ms"],
    }


# ---------------------------------------------------------------------- CLI


def _state_dir(env: dict[str, str]) -> Path:
    return Path(env.get("MANALOOM_OPS_DATA_DIR", "/data/manaloom-ops")) / "slo"


def _load_state(path: Path) -> dict[str, Any]:
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
        return state if isinstance(state, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def _save_state(path: Path, state: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def run(
    env: dict[str, str],
    policy: dict[str, Any],
    fetch: Fetch = http_get,
    post: Post = http_post,
    postgres: Callable[[], dict[str, Any]] | None = None,
    now: dt.datetime | None = None,
    local_now: dt.datetime | None = None,
) -> dict[str, Any]:
    now = now or dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
    local_now = local_now or dt.datetime.now().replace(microsecond=0)
    state_dir = _state_dir(env)
    state_path = state_dir / "state.json"
    jobs_manifest = Path(
        env.get("MANALOOM_OPS_JOBS_JSON")
        or (Path(env.get("MANALOOM_OPS_DATA_DIR", "/data/manaloom-ops")) / "cron" / "jobs.json")
    )
    signals = collect_signals(
        env, fetch, postgres or (lambda: read_postgres(env)), jobs_manifest
    )
    state = _load_state(state_path)
    alerts, memory = evaluate(policy, signals, state, now, local_now)
    append_observation(
        state_dir / "observations.jsonl",
        observation(signals, now),
        policy["evaluation"]["observation_retention_days"],
        now,
    )
    open_codes = sorted(alert["code"] for alert in alerts)
    try:
        receiver = receiver_config(env)
    except ReceiverMissing:
        _save_state(state_path, {**state, **memory})
        raise
    subject, text, new_state = plan_notifications(policy, alerts, state, now)
    new_state.update(memory)
    if subject is not None:
        send(receiver, subject, text or "", post)
    _save_state(state_path, new_state)
    return {"status": "ok", "open": open_codes, "notified": subject is not None}


def test_alert(env: dict[str, str], post: Post = http_post, now: dt.datetime | None = None) -> dict[str, Any]:
    now = now or dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
    receiver = receiver_config(env)
    test_id = secrets.token_hex(4)
    stamp = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    send(
        receiver,
        f"[BrewTact] Teste de alerta {test_id}",
        f"Alerta sintético do BT-OBS-001, gerado em {stamp}. Nenhuma ação é "
        f"necessária além de confirmar à coordenação que o teste {test_id} chegou.",
        post,
    )
    state_path = _state_dir(env) / "state.json"
    state = _load_state(state_path)
    state["last_test"] = {"test_id": test_id, "channel": receiver["channel"], "sent_at": stamp}
    _save_state(state_path, state)
    return {"status": "sent", "test_id": test_id, "channel": receiver["channel"], "sent_at": stamp}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("command", nargs="?", default="run",
                        choices=("run", "test-alert", "report", "validate-policy"))
    parser.add_argument("--policy", type=Path, default=DEFAULT_POLICY)
    args = parser.parse_args(argv)
    env = dict(os.environ)
    try:
        policy = load_policy(args.policy)
        if args.command == "validate-policy":
            problems = provenance_problems(policy)
            if problems:
                raise InvalidInput("política sem procedência: " + "; ".join(problems))
            result: dict[str, Any] = {"status": "valid", "version": policy.get("version")}
        elif args.command == "test-alert":
            result = test_alert(env)
        elif args.command == "report":
            path = _state_dir(env) / "observations.jsonl"
            items = []
            if path.exists():
                for line in path.read_text(encoding="utf-8").splitlines():
                    try:
                        item = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if isinstance(item, dict) and isinstance(item.get("at"), str):
                        items.append(item)
            result = report(policy, items, dt.datetime.now(dt.timezone.utc))
        else:
            result = run(env, policy)
    except ReceiverMissing as error:
        print(json.dumps({"status": "BLOCKED", "error": str(error)}, ensure_ascii=False))
        return 2
    except InvalidInput as error:
        print(json.dumps({"status": "invalid", "error": str(error)}, ensure_ascii=False))
        return 2
    except RuntimeError as error:
        print(json.dumps({"status": "error", "error": sanitize(str(error))}, ensure_ascii=False))
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
