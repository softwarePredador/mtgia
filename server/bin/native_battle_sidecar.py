#!/usr/bin/env python3
"""Internal HTTP boundary for the reviewed ManaLoom-native battle runtime."""

from __future__ import annotations

import json
import os
import sqlite3
import subprocess
import sys
import threading
import uuid
from contextlib import closing
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
WORKER = Path(__file__).resolve().with_name("native_battle_worker.py")
KNOWLEDGE_DB = Path(
    os.environ.get("MANALOOM_KNOWLEDGE_DB", "/data/manaloom-ops/knowledge.db")
)
MAX_BODY_BYTES = 8 * 1024 * 1024
PROCESS_ID = str(uuid.uuid4())
STARTED_AT = datetime.now(timezone.utc).isoformat()
SIMULATION_LOCK = threading.Lock()


class InvalidRequest(ValueError):
    pass


def normalize_name(value: Any) -> str:
    return " ".join(str(value or "").strip().lower().split())


def _lookup_names(value: Any) -> list[str]:
    normalized = normalize_name(value)
    aliases = [normalized]
    if " // " in normalized:
        front = normalized.split(" // ", 1)[0].strip()
        if front and front not in aliases:
            aliases.append(front)
    return aliases


def _rule_rows(db_path: Path, card_rows: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    names = [str(row.get("name") or "").strip() for row in card_rows]
    if not names or any(not name for name in names):
        raise InvalidRequest("cards must contain non-empty names")
    normalized = sorted({alias for name in names for alias in _lookup_names(name)})
    if not db_path.is_file():
        raise RuntimeError(f"knowledge DB not found: {db_path}")
    placeholders = ",".join("?" for _ in normalized)
    with closing(sqlite3.connect(db_path)) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(
            f"""
            SELECT normalized_name, logical_rule_key, card_name, review_status,
                   execution_status, oracle_hash, effect_json
            FROM battle_card_rules
            WHERE normalized_name IN ({placeholders})
              AND review_status IN ('verified', 'active')
              AND execution_status IN ('auto', 'executable')
              AND COALESCE(oracle_hash, '') != ''
              AND json_valid(effect_json) = 1
              AND json_type(effect_json) = 'object'
              AND json(effect_json) != '{{}}'
            ORDER BY normalized_name, logical_rule_key
            """,
            normalized,
        ).fetchall()
        has_oracle_cache = connection.execute(
            """
            SELECT 1 FROM sqlite_master
            WHERE type = 'table' AND name = 'card_oracle_cache'
            """
        ).fetchone()
        oracle_rows = (
            connection.execute(
                f"""
                SELECT normalized_name, name, type_line
                FROM card_oracle_cache
                WHERE normalized_name IN ({placeholders})
                """,
                normalized,
            ).fetchall()
            if has_oracle_cache
            else []
        )
    by_name: dict[str, list[sqlite3.Row]] = {}
    for row in rows:
        by_name.setdefault(str(row["normalized_name"]), []).append(row)
    oracle_by_name = {str(row["normalized_name"]): row for row in oracle_rows}
    supported = []
    unsupported = []
    seen = set()
    for index, card in enumerate(card_rows):
        name = str(card.get("name") or "").strip()
        key = normalize_name(name)
        if key in seen:
            continue
        seen.add(key)
        aliases = _lookup_names(name)
        matching = [rule for alias in aliases for rule in by_name.get(alias, [])]
        if not matching:
            oracle = next(
                (oracle_by_name[alias] for alias in aliases if alias in oracle_by_name),
                None,
            )
            if oracle is not None and str(oracle["type_line"] or "").lower().startswith("basic land"):
                supported.append(
                    {
                        "name": name,
                        "normalized_name": key,
                        "matched_normalized_name": str(oracle["normalized_name"]),
                        "support_kind": "intrinsic_basic_land",
                        "logical_rule_keys": ["native_intrinsic_v1:basic_land"],
                        "oracle_hashes": [],
                    }
                )
                continue
            unsupported.append(
                {
                    "name": name,
                    "input_index": index,
                    "reason": "verified_native_rule_missing",
                }
            )
            continue
        supported.append(
            {
                "name": name,
                "normalized_name": key,
                "matched_normalized_name": str(matching[0]["normalized_name"]),
                "support_kind": "reviewed_card_rule",
                "logical_rule_keys": [str(row["logical_rule_key"]) for row in matching],
                "oracle_hashes": sorted({str(row["oracle_hash"]) for row in matching}),
            }
        )
    return supported, unsupported


def card_coverage(payload: dict[str, Any], *, db_path: Path = KNOWLEDGE_DB) -> dict[str, Any]:
    cards = payload.get("cards")
    if not isinstance(cards, list) or not cards:
        raise InvalidRequest("cards is required")
    card_rows = [row for row in cards if isinstance(row, dict)]
    if len(card_rows) != len(cards):
        raise InvalidRequest("every card row must be an object")
    supported, unsupported = _rule_rows(db_path, card_rows)
    return {
        "status": "ready" if not unsupported else "unsupported",
        "engine": "manaloom_native_reviewed",
        "engine_contract": "native_reviewed_rules_execution",
        "total": len({normalize_name(row.get("name")) for row in card_rows}),
        "supported": len(supported),
        "unsupported": len(unsupported),
        "supported_rules": supported,
        "unsupported_cards": unsupported,
        "sidecar_process_id": PROCESS_ID,
        "sidecar_started_at": STARTED_AT,
    }


def _runtime_health(db_path: Path = KNOWLEDGE_DB) -> tuple[int, dict[str, Any]]:
    rule_count = 0
    error = None
    try:
        with closing(sqlite3.connect(db_path)) as connection:
            rule_count = int(
                connection.execute(
                    """
                    SELECT COUNT(*) FROM battle_card_rules
                    WHERE review_status IN ('verified', 'active')
                      AND execution_status IN ('auto', 'executable')
                      AND COALESCE(oracle_hash, '') != ''
                      AND json_valid(effect_json) = 1
                      AND json_type(effect_json) = 'object'
                      AND json(effect_json) != '{}'
                    """
                ).fetchone()[0]
            )
    except (OSError, sqlite3.Error) as exc:
        error = str(exc)
    ready = rule_count > 0 and error is None
    return (
        200 if ready else 503,
        {
            "status": "ok" if ready else "not_ready",
            "engine": "manaloom_native_reviewed",
            "engine_contract": "native_reviewed_rules_execution",
            "git_sha": os.environ.get("GIT_SHA", "unknown"),
            "knowledge_db_ready": ready,
            "verified_rule_count": rule_count,
            "sidecar_process_id": PROCESS_ID,
            "sidecar_started_at": STARTED_AT,
            **({"error": error} if error else {}),
        },
    )


def _run_simulation(payload: dict[str, Any], *, db_path: Path = KNOWLEDGE_DB) -> tuple[int, dict[str, Any]]:
    required = payload.get("required_rule_cards")
    if not isinstance(required, list) or not required:
        raise InvalidRequest("required_rule_cards is required")
    coverage = card_coverage({"cards": required}, db_path=db_path)
    if coverage["unsupported_cards"]:
        return 422, {
            "error": "native_coverage_incomplete",
            "message": "Reviewed native coverage is incomplete",
            "unsupported_cards": coverage["unsupported_cards"],
        }
    timeout_ms = max(1000, min(40000, int(payload.get("timeout_ms") or 40000)))
    env = dict(os.environ)
    env["MANALOOM_KNOWLEDGE_DB"] = str(db_path)
    with SIMULATION_LOCK:
        try:
            completed = subprocess.run(
                [sys.executable, str(WORKER)],
                cwd=REPO_ROOT,
                env=env,
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                timeout=timeout_ms / 1000,
                check=False,
            )
        except subprocess.TimeoutExpired:
            return 504, {
                "error": "native_battle_timeout",
                "message": f"Native battle exceeded {timeout_ms} ms",
            }
    try:
        result = json.loads((completed.stdout or "").strip())
    except json.JSONDecodeError:
        result = {
            "error": "native_runtime_invalid_output",
            "message": (completed.stderr or completed.stdout or "native worker returned no JSON")[-2000:],
        }
    if completed.returncode != 0:
        return (400 if completed.returncode == 2 else 500), result
    if not isinstance(result, dict):
        return 500, {
            "error": "native_runtime_invalid_output",
            "message": "native worker result must be an object",
        }
    result.update(
        {
            "native_rule_coverage": coverage,
            "sidecar_process_id": PROCESS_ID,
            "sidecar_started_at": STARTED_AT,
            "engine_commit": os.environ.get("GIT_SHA", "unknown"),
        }
    )
    return 200, result


class NativeBattleHandler(BaseHTTPRequestHandler):
    server_version = "ManaLoomNativeBattle/1"

    def do_GET(self) -> None:  # noqa: N802
        if self.path != "/health":
            self._send(404, {"error": "not_found"})
            return
        status, body = _runtime_health()
        self._send(status, body)

    def do_POST(self) -> None:  # noqa: N802
        try:
            payload = self._read_json()
            if self.path == "/cards/coverage":
                self._send(200, card_coverage(payload))
                return
            if self.path == "/simulate":
                status, body = _run_simulation(payload)
                self._send(status, body)
                return
            self._send(404, {"error": "not_found"})
        except InvalidRequest as exc:
            self._send(400, {"error": "invalid_request", "message": str(exc)})
        except Exception as exc:
            self._send(500, {"error": "native_sidecar_failed", "message": str(exc)})

    def _read_json(self) -> dict[str, Any]:
        try:
            length = int(self.headers.get("content-length", "0"))
        except ValueError as exc:
            raise InvalidRequest("invalid content-length") from exc
        if length <= 0 or length > MAX_BODY_BYTES:
            raise InvalidRequest("request body is empty or too large")
        try:
            payload = json.loads(self.rfile.read(length))
        except json.JSONDecodeError as exc:
            raise InvalidRequest("request body must be valid JSON") from exc
        if not isinstance(payload, dict):
            raise InvalidRequest("request body must be an object")
        return payload

    def _send(self, status: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, ensure_ascii=True, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:
        return


def create_server(host: str | None = None, port: int | None = None) -> ThreadingHTTPServer:
    resolved_host = host or os.environ.get("MANALOOM_NATIVE_BATTLE_HOST", "0.0.0.0")
    resolved_port = port or int(os.environ.get("MANALOOM_NATIVE_BATTLE_PORT", "8080"))
    return ThreadingHTTPServer((resolved_host, resolved_port), NativeBattleHandler)


def main() -> int:
    server = create_server()
    print(
        json.dumps(
            {
                "status": "started",
                "host": server.server_address[0],
                "port": server.server_address[1],
                "sidecar_process_id": PROCESS_ID,
            }
        ),
        flush=True,
    )
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
