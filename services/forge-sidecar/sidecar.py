#!/usr/bin/env python3
"""Strict HTTP wrapper for Forge's official headless match simulator."""

from __future__ import annotations

import json
import math
import os
import re
import shlex
import signal
import subprocess
import threading
import time
import unicodedata
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


MAX_REQUEST_BYTES = 8 * 1024 * 1024
PROCESS_ID = str(uuid.uuid4())
STARTED_AT = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
MAX_LOG_EVENTS = 20_000
PROCESS_TIMEOUT_GRACE_SECONDS = 5
FORGE_VERSION = "2.0.14-SNAPSHOT"
SIMULATION_LOCK = threading.Lock()

GAME_RESULT_WIN = re.compile(
    r"Game Result: Game \d+ ended in (?P<duration>\d+) ms\. "
    r"Ai\((?P<slot>[12])\)-(?P<name>.+?) has won!"
)
GAME_RESULT_DRAW = re.compile(
    r"Game Result: Game \d+ ended in a Draw! Took (?P<duration>\d+) ms\."
)
FORGE_TIMEOUT_MARKER = "Stopping slow match as draw"
TURN_RESULT = re.compile(r"Game Outcome: Turn (?P<turn>\d+)")
UNSUPPORTED_CARD = re.compile(r'An unsupported card was requested: "(?P<name>.+?)"')
LIFE_CHANGE = re.compile(
    r"Life: Life: Ai\((?P<slot>[12])\)-.+? (?P<before>-?\d+) > (?P<after>-?\d+)$"
)


class InvalidRequest(ValueError):
    pass


class CoverageIncomplete(Exception):
    def __init__(self, unsupported_cards: list[dict[str, Any]]) -> None:
        super().__init__("Forge coverage is incomplete")
        self.unsupported_cards = unsupported_cards


class SimulationTimeout(Exception):
    pass


class SimulationFailed(Exception):
    pass


def run_isolated_process(
    command: list[str],
    *,
    cwd: Path,
    timeout: float,
    env: dict[str, str],
) -> subprocess.CompletedProcess[str]:
    process = subprocess.Popen(
        command,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
        start_new_session=True,
    )
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired as error:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
        raise subprocess.TimeoutExpired(
            error.cmd,
            error.timeout,
            output=stdout,
            stderr=stderr,
        ) from error
    return subprocess.CompletedProcess(
        command,
        process.returncode,
        stdout=stdout,
        stderr=stderr,
    )


def normalized_name(value: str) -> str:
    value = unicodedata.normalize("NFKC", value).strip().casefold()
    value = re.sub(r"\s+", " ", value)
    return value


def candidate_names(value: str) -> tuple[str, ...]:
    candidates = [value]
    if " // " in value:
        candidates.append(value.split(" // ", 1)[0])
    return tuple(dict.fromkeys(normalized_name(item) for item in candidates))


def load_card_index(root: Path) -> dict[str, str]:
    if not root.is_dir():
        raise RuntimeError(f"Forge card script directory is unavailable: {root}")
    result: dict[str, str] = {}
    for path in root.rglob("*.txt"):
        try:
            with path.open("r", encoding="utf-8", errors="replace") as handle:
                for line in handle:
                    if line.startswith("Name:"):
                        name = line[5:].strip()
                        if name:
                            result.setdefault(normalized_name(name), name)
                        break
        except OSError:
            continue
    if not result:
        raise RuntimeError(f"Forge card index is empty: {root}")
    return result


@dataclass(frozen=True)
class CardInput:
    name: str
    quantity: int
    is_commander: bool
    set_code: str | None = None
    collector_number: str | None = None
    card_id: str | None = None

    @classmethod
    def parse(cls, row: Any) -> "CardInput":
        if not isinstance(row, dict):
            raise InvalidRequest("every card must be an object")
        name = str(row.get("name") or "").strip()
        if not name or "\n" in name or "\r" in name or "|" in name:
            raise InvalidRequest("every card requires a safe name")
        quantity = row.get("quantity", 1)
        if not isinstance(quantity, int) or isinstance(quantity, bool) or quantity < 1:
            raise InvalidRequest(f"invalid quantity for {name}")
        return cls(
            name=name,
            quantity=quantity,
            is_commander=row.get("is_commander") is True,
            set_code=_optional_string(row.get("set_code")),
            collector_number=_optional_string(row.get("collector_number")),
            card_id=_optional_string(row.get("card_id")),
        )

    def resolve(self, card_index: dict[str, str]) -> str | None:
        for candidate in candidate_names(self.name):
            if candidate in card_index:
                return card_index[candidate]
        return None

    def unsupported(self, *, deck_key: str | None = None, index: int | None = None) -> dict[str, Any]:
        result: dict[str, Any] = {
            "name": self.name,
            "set_code": self.set_code,
            "collector_number": self.collector_number,
            "source": "forge",
            "reason": "card_script_not_found",
        }
        if self.card_id:
            result["card_id"] = self.card_id
        if deck_key:
            result["deck"] = deck_key
        if index is not None:
            result["input_index"] = index
        return result


@dataclass(frozen=True)
class DeckInput:
    deck_id: str
    name: str
    cards: tuple[CardInput, ...]

    @classmethod
    def parse(cls, row: Any, key: str) -> "DeckInput":
        if not isinstance(row, dict):
            raise InvalidRequest(f"{key} is required")
        raw_cards = row.get("cards")
        if not isinstance(raw_cards, list) or not raw_cards:
            raise InvalidRequest(f"{key}.cards is required")
        cards = tuple(CardInput.parse(card) for card in raw_cards)
        total = sum(card.quantity for card in cards)
        commanders = sum(card.quantity for card in cards if card.is_commander)
        if total != 100:
            raise InvalidRequest(f"{key} must contain exactly 100 cards; received {total}")
        if commanders != 1:
            raise InvalidRequest(f"{key} must contain exactly one commander; received {commanders}")
        return cls(
            deck_id=str(row.get("id") or key),
            name=str(row.get("name") or key).strip() or key,
            cards=cards,
        )

    def coverage(self, card_index: dict[str, str], key: str) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        unsupported = [
            card.unsupported(deck_key=key, index=index)
            for index, card in enumerate(self.cards)
            if card.resolve(card_index) is None
        ]
        return (
            {
                "deck": key,
                "deck_id": self.deck_id,
                "name": self.name,
                "card_count": sum(card.quantity for card in self.cards),
                "unique_card_count": len(self.cards),
                "ready": not unsupported,
            },
            unsupported,
        )

    def render(self, card_index: dict[str, str]) -> str:
        commander: list[str] = []
        main: list[str] = []
        for card in self.cards:
            resolved = card.resolve(card_index)
            if resolved is None:
                raise CoverageIncomplete([card.unsupported()])
            line = f"{card.quantity} {resolved}"
            (commander if card.is_commander else main).append(line)
        return "\n".join(
            [
                "[metadata]",
                f"Name={_safe_deck_name(self.name)}",
                "[Commander]",
                *commander,
                "[Main]",
                *main,
                "[Sideboard]",
                "",
            ]
        )


class ForgeService:
    def __init__(
        self,
        *,
        forge_home: Path,
        forge_jar: Path,
        bootstrap_jar: Path | None,
        java_command: tuple[str, ...],
        deck_dir: Path,
        card_index: dict[str, str],
        forge_commit: str,
    ) -> None:
        self.forge_home = forge_home
        self.forge_jar = forge_jar
        self.bootstrap_jar = bootstrap_jar
        self.java_command = java_command
        self.deck_dir = deck_dir
        self.card_index = card_index
        self.forge_commit = forge_commit
        if not self.forge_jar.is_file():
            raise RuntimeError(f"Forge runtime jar is unavailable: {self.forge_jar}")
        if self.bootstrap_jar is not None and not self.bootstrap_jar.is_file():
            raise RuntimeError(f"Forge seed bootstrap is unavailable: {self.bootstrap_jar}")
        if not self.java_command:
            raise RuntimeError("FORGE_JAVA_COMMAND cannot be empty")
        self.deck_dir.mkdir(parents=True, exist_ok=True)

    @classmethod
    def from_environment(cls) -> "ForgeService":
        forge_home = Path(os.getenv("FORGE_HOME", Path.cwd())).resolve()
        commit_file = Path(os.getenv("FORGE_COMMIT_FILE", forge_home / "FORGE_COMMIT"))
        forge_commit = commit_file.read_text(encoding="ascii").strip()
        bootstrap_value = os.getenv("FORGE_BOOTSTRAP_JAR", "").strip()
        return cls(
            forge_home=forge_home,
            forge_jar=Path(os.getenv("FORGE_JAR", forge_home / "forge.jar")).resolve(),
            bootstrap_jar=Path(bootstrap_value).resolve() if bootstrap_value else None,
            java_command=tuple(shlex.split(os.getenv("FORGE_JAVA_COMMAND", "java"))),
            deck_dir=Path(os.getenv("FORGE_DECK_DIR", "/tmp/forge/decks/commander")).resolve(),
            card_index=load_card_index(
                Path(os.getenv("FORGE_CARD_SCRIPTS", forge_home / "res/cardsfolder")).resolve()
            ),
            forge_commit=forge_commit,
        )

    def health(self) -> dict[str, Any]:
        return {
            "status": "ok",
            "engine": "forge",
            "engine_version": FORGE_VERSION,
            "engine_commit": self.forge_commit,
            "indexed_cards": len(self.card_index),
            "sidecar_process_id": PROCESS_ID,
            "sidecar_started_at": STARTED_AT,
        }

    def coverage(self, request: dict[str, Any]) -> dict[str, Any]:
        deck_a = DeckInput.parse(request.get("deck_a"), "deck_a")
        deck_b = DeckInput.parse(request.get("deck_b"), "deck_b")
        deck_a_result, unsupported_a = deck_a.coverage(self.card_index, "deck_a")
        deck_b_result, unsupported_b = deck_b.coverage(self.card_index, "deck_b")
        unsupported = [*unsupported_a, *unsupported_b]
        return {
            "status": "ready" if not unsupported else "unsupported",
            "engine": "forge",
            "engine_version": FORGE_VERSION,
            "engine_commit": self.forge_commit,
            "ready": not unsupported,
            "decks": [deck_a_result, deck_b_result],
            "unsupported_cards": unsupported,
        }

    def card_coverage(self, request: dict[str, Any]) -> dict[str, Any]:
        rows = request.get("cards")
        if not isinstance(rows, list) or not rows:
            raise InvalidRequest("cards is required")
        unsupported: list[dict[str, Any]] = []
        for index, row in enumerate(rows):
            card = CardInput.parse(row)
            if card.resolve(self.card_index) is None:
                unsupported.append(card.unsupported(index=index))
        return {
            "status": "ready" if not unsupported else "unsupported",
            "engine": "forge",
            "engine_version": FORGE_VERSION,
            "engine_commit": self.forge_commit,
            "total": len(rows),
            "supported": len(rows) - len(unsupported),
            "unsupported": len(unsupported),
            "unsupported_cards": unsupported,
        }

    def simulate(self, request: dict[str, Any]) -> dict[str, Any]:
        deck_a = DeckInput.parse(request.get("deck_a"), "deck_a")
        deck_b = DeckInput.parse(request.get("deck_b"), "deck_b")
        coverage = self.coverage(request)
        if coverage["unsupported_cards"]:
            raise CoverageIncomplete(coverage["unsupported_cards"])

        timeout_ms = _clamp(_integer(request.get("timeout_ms"), 120_000), 1_000, 900_000)
        seed = _integer(request.get("seed"), int(time.time() * 1000))
        request_id = _safe_request_id(str(request.get("request_id") or uuid.uuid4()))
        deck_a_file = self.deck_dir / f"{request_id}-a.dck"
        deck_b_file = self.deck_dir / f"{request_id}-b.dck"
        deck_a_file.write_text(deck_a.render(self.card_index), encoding="utf-8")
        deck_b_file.write_text(deck_b.render(self.card_index), encoding="utf-8")

        classpath = str(self.forge_jar)
        main_class = "forge.view.Main"
        if self.bootstrap_jar is not None:
            classpath = f"{self.bootstrap_jar}{os.pathsep}{classpath}"
            main_class = "com.manaloom.forge.SeededForgeMain"
        command = [
            *self.java_command,
            f"-Dmanaloom.seed={seed}",
            "-cp",
            classpath,
            main_class,
            "sim",
            "-d",
            deck_a_file.name,
            deck_b_file.name,
            "-n",
            "1",
            "-f",
            "commander",
            "-c",
            str(max(1, math.ceil(timeout_ms / 1000))),
        ]
        started = time.monotonic()
        started_at = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        try:
            with SIMULATION_LOCK:
                completed = run_isolated_process(
                    command,
                    cwd=self.forge_home,
                    timeout=(timeout_ms / 1000) + PROCESS_TIMEOUT_GRACE_SECONDS,
                    env=os.environ.copy(),
                )
        except subprocess.TimeoutExpired as error:
            process_budget_ms = timeout_ms + PROCESS_TIMEOUT_GRACE_SECONDS * 1000
            raise SimulationTimeout(
                f"Forge battle exceeded {process_budget_ms} ms including startup"
            ) from error
        finally:
            deck_a_file.unlink(missing_ok=True)
            deck_b_file.unlink(missing_ok=True)

        duration_ms = round((time.monotonic() - started) * 1000)
        output = "\n".join(part for part in (completed.stdout, completed.stderr) if part)
        unsupported_runtime = [
            {
                "name": match.group("name"),
                "source": "forge",
                "reason": "forge_runtime_rejected_card",
            }
            for match in UNSUPPORTED_CARD.finditer(output)
        ]
        if unsupported_runtime:
            raise CoverageIncomplete(unsupported_runtime)
        if FORGE_TIMEOUT_MARKER in output:
            raise SimulationTimeout(f"Forge battle exceeded {timeout_ms} ms")
        if completed.returncode != 0:
            raise SimulationFailed(
                f"Forge exited with code {completed.returncode}: {_last_lines(output)}"
            )
        return parse_simulation_output(
            output,
            request_id=request_id,
            seed=seed,
            deck_a=deck_a,
            deck_b=deck_b,
            duration_ms=duration_ms,
            started_at=started_at,
            forge_commit=self.forge_commit,
        )


def parse_simulation_output(
    output: str,
    *,
    request_id: str,
    seed: int,
    deck_a: DeckInput,
    deck_b: DeckInput,
    duration_ms: int,
    started_at: str,
    forge_commit: str,
) -> dict[str, Any]:
    result_match = GAME_RESULT_WIN.search(output)
    draw_match = GAME_RESULT_DRAW.search(output)
    if result_match is None and draw_match is None:
        raise SimulationFailed(f"Forge returned no completed game result: {_last_lines(output)}")

    winner_key: str | None = None
    winner_deck: DeckInput | None = None
    engine_duration_ms: int
    if result_match is not None:
        winner_key = "deck_a" if result_match.group("slot") == "1" else "deck_b"
        winner_deck = deck_a if winner_key == "deck_a" else deck_b
        engine_duration_ms = int(result_match.group("duration"))
    else:
        engine_duration_ms = int(draw_match.group("duration"))

    turn_matches = list(TURN_RESULT.finditer(output))
    turns = int(turn_matches[-1].group("turn")) if turn_matches else 0
    events = _events_from_output(output)
    snapshots = _snapshots(events)
    errors = sum(
        1
        for line in output.splitlines()
        if "Exception" in line or "StackOverflowError" in line or line.startswith("Error:")
    )
    if errors:
        raise SimulationFailed(f"Forge completed with {errors} engine errors")
    return {
        "type": "battle",
        "status": "completed",
        "request_id": request_id,
        "engine": "forge",
        "engine_version": FORGE_VERSION,
        "engine_commit": forge_commit,
        "seed": seed,
        "started_at": started_at,
        "duration_ms": duration_ms,
        "engine_duration_ms": engine_duration_ms,
        "turns": turns,
        "winner": winner_deck.name if winner_deck else None,
        "winner_deck_key": winner_key,
        "winner_deck_id": winner_deck.deck_id if winner_deck else None,
        "game_log": events,
        "events": events,
        "visual_snapshots": snapshots,
        "final_state": snapshots[-1] if snapshots else {"turn": turns},
        "unsupported_cards": [],
        "decision_trace": [],
        "learning_contract": {
            "schema_version": "external_battle_learning_v1",
            "named_draw_identity_available": False,
            "visible_stack_activity_available": True,
            "combat_activity_available": False,
            "ai_decision_rationale_available": False,
            "seed_semantics": "engine_random_seed_not_event_replay",
            "event_stream_completeness": "best_effort_engine_log_lower_bound",
            "absence_proves_nonuse": False,
            "strategy_or_swap_proof": False,
        },
        "metrics": {
            "event_count": len(events),
            "snapshot_count": len(snapshots),
            "total_errors": errors,
            "cards_cast": sum(1 for event in events if event["type"] == "add_to_stack" and " cast " in event["message"]),
            "cards_activated": sum(1 for event in events if event["type"] == "add_to_stack" and " activated " in event["message"]),
        },
    }


def _events_from_output(output: str) -> list[dict[str, Any]]:
    lines = output.splitlines()
    start = next(
        (index + 1 for index, line in enumerate(lines) if " - one game of Commander" in line),
        len(lines),
    )
    events: list[dict[str, Any]] = []
    for line in lines[start:]:
        line = line.strip()
        if not line:
            continue
        if line.startswith("Game Result:"):
            break
        if len(events) >= MAX_LOG_EVENTS:
            break
        prefix, separator, _ = line.partition(":")
        event_type = re.sub(r"[^a-z0-9]+", "_", prefix.casefold()).strip("_") if separator else "message"
        event: dict[str, Any] = {
            "sequence": len(events) + 1,
            "type": event_type,
            "message": line,
        }
        turn = re.search(r"Turn (?P<turn>\d+)", line)
        if turn:
            event["turn"] = int(turn.group("turn"))
        card_name = _card_name_from_event(line)
        if card_name:
            event["card_name"] = card_name
        events.append(event)
    return events


def _card_name_from_event(line: str) -> str | None:
    patterns = (
        r"\bcast (?P<card>.+?)(?: targeting|$)",
        r"\bactivated (?P<card>.+?)(?: targeting|$)",
        r"\bplayed (?P<card>.+?)(?: \(\d+\)|$)",
    )
    for pattern in patterns:
        match = re.search(pattern, line)
        if match:
            return re.sub(r" \(\d+\)$", "", match.group("card")).strip()
    return None


def _snapshots(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    snapshots: list[dict[str, Any]] = []
    life = {"deck_a": 40, "deck_b": 40}
    turn = 0
    for event in events:
        message = event["message"]
        turn_match = re.match(r"Turn: Turn (?P<turn>\d+)", message)
        if turn_match:
            turn = int(turn_match.group("turn"))
            snapshots.append({"turn": turn, "players": {key: {"life": value} for key, value in life.items()}})
        life_match = LIFE_CHANGE.match(message)
        if life_match:
            key = "deck_a" if life_match.group("slot") == "1" else "deck_b"
            life[key] = int(life_match.group("after"))
    if snapshots:
        snapshots.append({"turn": turn, "final": True, "players": {key: {"life": value} for key, value in life.items()}})
    return snapshots


def _optional_string(value: Any) -> str | None:
    if value is None:
        return None
    result = str(value).strip()
    return result or None


def _integer(value: Any, fallback: int) -> int:
    return value if isinstance(value, int) and not isinstance(value, bool) else fallback


def _clamp(value: int, minimum: int, maximum: int) -> int:
    return max(minimum, min(maximum, value))


def _safe_request_id(value: str) -> str:
    sanitized = re.sub(r"[^A-Za-z0-9_-]", "", value)[:80]
    return sanitized or uuid.uuid4().hex


def _safe_deck_name(value: str) -> str:
    return value.replace("\n", " ").replace("\r", " ").replace("=", "-").strip()[:160]


def _last_lines(value: str, count: int = 8) -> str:
    return " | ".join(line.strip() for line in value.splitlines()[-count:] if line.strip())[:1600]


class ForgeHandler(BaseHTTPRequestHandler):
    service: ForgeService

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/health":
            self._send(200, self.service.health())
        else:
            self._send(404, {"error": "not_found"})

    def do_POST(self) -> None:  # noqa: N802
        try:
            request = self._read_json()
            if self.path == "/coverage":
                self._send(200, self.service.coverage(request))
            elif self.path == "/cards/coverage":
                self._send(200, self.service.card_coverage(request))
            elif self.path == "/simulate":
                self._send(200, self.service.simulate(request))
            else:
                self._send(404, {"error": "not_found"})
        except CoverageIncomplete as error:
            self._send(
                422,
                {
                    "error": "forge_coverage_incomplete",
                    "message": str(error),
                    "unsupported_cards": error.unsupported_cards,
                },
            )
        except InvalidRequest as error:
            self._send(400, {"error": "invalid_request", "message": str(error)})
        except SimulationTimeout as error:
            self._send(504, {"error": "simulation_timeout", "message": str(error)})
        except SimulationFailed as error:
            self._send(500, {"error": "simulation_failed", "message": str(error)})
        except Exception as error:  # pragma: no cover - final process boundary
            self._send(500, {"error": "internal_error", "message": str(error)})

    def _read_json(self) -> dict[str, Any]:
        try:
            length = int(self.headers.get("content-length", "0"))
        except ValueError as error:
            raise InvalidRequest("invalid content-length") from error
        if length < 1 or length > MAX_REQUEST_BYTES:
            raise InvalidRequest("request body must be between 1 byte and 8 MiB")
        try:
            value = json.loads(self.rfile.read(length))
        except (json.JSONDecodeError, UnicodeDecodeError) as error:
            raise InvalidRequest("request body must be valid JSON") from error
        if not isinstance(value, dict):
            raise InvalidRequest("request body must be an object")
        return value

    def _send(self, status: int, body: dict[str, Any]) -> None:
        response = {
            **body,
            "sidecar_process_id": body.get("sidecar_process_id", PROCESS_ID),
            "sidecar_started_at": body.get("sidecar_started_at", STARTED_AT),
        }
        payload = json.dumps(response, ensure_ascii=True, separators=(",", ":")).encode("utf-8")
        try:
            self.send_response(status)
            self.send_header("content-type", "application/json; charset=utf-8")
            self.send_header("content-length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError):
            return

    def log_message(self, format: str, *args: Any) -> None:
        print(f"forge-sidecar {self.address_string()} {format % args}")


def main() -> None:
    service = ForgeService.from_environment()
    ForgeHandler.service = service
    port = int(os.getenv("PORT", "8080"))
    server = ThreadingHTTPServer(("0.0.0.0", port), ForgeHandler)
    print(
        f"ManaLoom Forge sidecar listening on port {port}; "
        f"commit={service.forge_commit}; indexed_cards={len(service.card_index)}",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
