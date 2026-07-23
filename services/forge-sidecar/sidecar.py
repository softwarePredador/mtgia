#!/usr/bin/env python3
"""Strict HTTP wrapper for Forge's official headless match simulator."""

from __future__ import annotations

import base64
import hashlib
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
EXECUTION_SCHEMA = "external_battle_execution_v2"
REQUEST_SCHEMA = "external_battle_request_v2"
DECK_HASH_SCHEMA = "external_battle_deck_hash_v1"
SIDECAR_PROTOCOL = "external_battle_sidecar_v2"
AI_PROFILE = "forge_default_ai"
PARSER_VERSION = "forge_log_parser_v2"
SEED_SEMANTICS = "engine_rng_seeded_not_replay_guarantee"

GAME_RESULT_WIN = re.compile(
    r"Game Result: Game \d+ ended in (?P<duration>\d+) ms\. "
    r"Ai\((?P<slot>[12])\)-(?P<name>.+?) has won!"
)
GAME_RESULT_DRAW = re.compile(
    r"Game Result: Game \d+ ended in a Draw! Took (?P<duration>\d+) ms\."
)
FORGE_TIMEOUT_MARKER = "Stopping slow match as draw"
TURN_RESULT = re.compile(r"Game Outcome: Turn (?P<turn>\d+)")
TURN_EVENT = re.compile(r"^Turn: Turn (?P<turn>\d+)\b", re.MULTILINE)
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


def canonical_deck_hash(deck: DeckInput) -> str:
    records = sorted(
        "|".join(
            (
                "1" if card.is_commander else "0",
                str(card.quantity),
                _base64_field(card.name),
                _base64_field(card.set_code or ""),
                _base64_field(card.collector_number or ""),
            )
        )
        for card in deck.cards
    )
    material = f"{DECK_HASH_SCHEMA}\n" + "\n".join(records) + "\n"
    return hashlib.sha256(material.encode("utf-8")).hexdigest()


def canonical_request_hash(contract: dict[str, Any]) -> str:
    material = "\n".join(
        (
            REQUEST_SCHEMA,
            f"request_id={_base64_field(contract['request_id'])}",
            f"seed={contract['seed']}",
            f"timeout_ms={contract['timeout_ms']}",
            f"max_turns={contract['max_turns']}",
            "focus_cards=" + ",".join(_base64_field(card) for card in contract["focus_cards"]),
            f"force_focus_access_mode={contract['force_focus_access_mode']}",
            f"same_lane={1 if contract['same_lane'] else 0}",
            f"natural_sample={1 if contract['natural_sample'] else 0}",
            f"deck_a_id={_base64_field(contract['deck_a_id'])}",
            f"deck_b_id={_base64_field(contract['deck_b_id'])}",
            f"deck_a_hash={contract['deck_hashes']['deck_a']}",
            f"deck_b_hash={contract['deck_hashes']['deck_b']}",
            "engine=forge",
            f"engine_version={_base64_field(FORGE_VERSION)}",
            f"engine_commit={contract['forge_commit']}",
            f"ai_profile={_base64_field(AI_PROFILE)}",
        )
    )
    return hashlib.sha256(f"{material}\n".encode("utf-8")).hexdigest()


def parse_request_contract(
    request: dict[str, Any],
    *,
    deck_a: DeckInput,
    deck_b: DeckInput,
    forge_commit: str,
) -> dict[str, Any]:
    strict = request.get("request_schema_version") is not None
    if strict and request.get("request_schema_version") != REQUEST_SCHEMA:
        raise InvalidRequest("unsupported request_schema_version")

    request_id_raw = str(request.get("request_id") or uuid.uuid4())
    if strict and re.fullmatch(r"[A-Za-z0-9_-]{1,80}", request_id_raw) is None:
        raise InvalidRequest("request_id must use 1-80 safe characters")
    request_id = request_id_raw if strict else _safe_request_id(request_id_raw)
    seed = request.get("seed", int(time.time() * 1000))
    timeout_ms = request.get("timeout_ms", 120_000)
    max_turns = request.get("max_turns", 30)
    for key, value, minimum, maximum in (
        ("seed", seed, -(2**63), 2**63 - 1),
        ("timeout_ms", timeout_ms, 1_000, 900_000),
        ("max_turns", max_turns, 1, 100),
    ):
        if not isinstance(value, int) or isinstance(value, bool):
            raise InvalidRequest(f"{key} must be an integer")
        if value < minimum or value > maximum:
            raise InvalidRequest(f"{key} is outside the supported range")

    raw_focus = request.get("focus_cards", [])
    if not isinstance(raw_focus, list) or len(raw_focus) > 20:
        raise InvalidRequest("focus_cards must be a list with at most 20 entries")
    focus_cards: list[str] = []
    for value in raw_focus:
        if not isinstance(value, str) or len(value.strip()) > 300:
            raise InvalidRequest("focus_cards must contain bounded strings")
        if value.strip():
            focus_cards.append(value.strip())
    force_mode = str(request.get("force_focus_access_mode") or "none").lower()
    if force_mode != "none":
        raise InvalidRequest("Forge does not support forced card access")
    same_lane = request.get("same_lane", False)
    natural_sample = request.get("natural_sample", True)
    if not isinstance(same_lane, bool) or not isinstance(natural_sample, bool):
        raise InvalidRequest("same_lane and natural_sample must be booleans")

    deck_hashes = {
        "schema_version": DECK_HASH_SCHEMA,
        "algorithm": "sha256",
        "deck_a": canonical_deck_hash(deck_a),
        "deck_b": canonical_deck_hash(deck_b),
    }
    contract: dict[str, Any] = {
        "request_id": request_id,
        "seed": seed,
        "timeout_ms": timeout_ms,
        "max_turns": max_turns,
        "focus_cards": focus_cards,
        "force_focus_access_mode": force_mode,
        "same_lane": same_lane,
        "natural_sample": natural_sample,
        "deck_a_id": deck_a.deck_id,
        "deck_b_id": deck_b.deck_id,
        "deck_hashes": deck_hashes,
        "forge_commit": forge_commit,
        "legacy_compatibility": not strict,
    }
    contract["request_hash"] = canonical_request_hash(contract)
    if strict:
        expected_identity = {
            "expected_engine": "forge",
            "expected_engine_version": FORGE_VERSION,
            "expected_engine_commit": forge_commit,
            "ai_profile": AI_PROFILE,
        }
        for key, expected in expected_identity.items():
            if request.get(key) != expected:
                raise InvalidRequest(f"{key} does not match the running Forge identity")
        if request.get("deck_hashes") != deck_hashes:
            raise InvalidRequest("deck_hashes do not match the submitted decks")
        if request.get("request_hash") != contract["request_hash"]:
            raise InvalidRequest("request_hash does not match the canonical request")
    return contract


def request_metadata(
    contract: dict[str, Any],
    *,
    status: str,
    turns: int | None = None,
) -> dict[str, Any]:
    timed_out = status == "timeout"
    censored = timed_out or status == "censored"
    censor_reason = (
        "wall_clock_timeout"
        if timed_out
        else "max_turns_exceeded" if status == "censored" else None
    )
    return {
        "request_id": contract["request_id"],
        "seed": contract["seed"],
        "timeout_ms": contract["timeout_ms"],
        "max_turns": contract["max_turns"],
        "request_hash": contract["request_hash"],
        "deck_hashes": contract["deck_hashes"],
        "ai_profile": AI_PROFILE,
        "fallback_allowed": status == "coverage_incomplete",
        "fallback_reason": "none",
        "fallback_eligibility_reason": (
            "coverage_incomplete_eligible"
            if status == "coverage_incomplete"
            else (
                "operational_timeout_not_eligible"
                if timed_out
                else "operational_failure_not_eligible"
                if status == "failed"
                else "none"
            )
        ),
        "request_contract": {
            "schema_version": REQUEST_SCHEMA,
            "legacy_compatibility": contract["legacy_compatibility"],
            "controls": {
                "max_turns": {
                    "value": contract["max_turns"],
                    "semantics": "post_completion_right_censoring",
                    "engine_enforced": False,
                },
                "focus_cards": {
                    "value": contract["focus_cards"],
                    "semantics": "positive_evidence_observation_only",
                },
                "force_focus_access_mode": {
                    "value": contract["force_focus_access_mode"],
                    "semantics": "none_only_non_none_rejected",
                },
                "same_lane": {
                    "value": contract["same_lane"],
                    "semantics": "comparison_metadata_only",
                },
                "natural_sample": {
                    "value": contract["natural_sample"],
                    "semantics": "sample_provenance_metadata",
                },
            },
        },
        "execution_outcome": {
            "status": status,
            "timed_out": timed_out,
            "censored": censored,
            "censor_reason": censor_reason,
            "timeout_ms": contract["timeout_ms"],
            **({"turns": turns} if turns is not None else {}),
        },
    }


def sidecar_identity(forge_commit: str) -> dict[str, Any]:
    return {
        "schema_version": EXECUTION_SCHEMA,
        "engine": "forge",
        "engine_version": FORGE_VERSION,
        "engine_commit": forge_commit,
        "sidecar_protocol_version": SIDECAR_PROTOCOL,
        "sidecar_build_identity": f"forge-sidecar-v2@{forge_commit}",
        "sidecar_process_id": PROCESS_ID,
        "sidecar_started_at": STARTED_AT,
        "ai_profile": AI_PROFILE,
        "parser_version": PARSER_VERSION,
        "seed_semantics": SEED_SEMANTICS,
        "deterministic": False,
    }


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
            **sidecar_identity(self.forge_commit),
            "status": "ok",
            "indexed_cards": len(self.card_index),
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
        contract = parse_request_contract(
            request,
            deck_a=deck_a,
            deck_b=deck_b,
            forge_commit=self.forge_commit,
        )
        coverage = self.coverage(request)
        if coverage["unsupported_cards"]:
            raise CoverageIncomplete(coverage["unsupported_cards"])

        timeout_ms = contract["timeout_ms"]
        seed = contract["seed"]
        request_id = contract["request_id"]
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
            request_contract=contract,
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
    request_contract: dict[str, Any] | None = None,
) -> dict[str, Any]:
    if request_contract is None:
        request_contract = parse_request_contract(
            {"request_id": request_id, "seed": seed},
            deck_a=deck_a,
            deck_b=deck_b,
            forge_commit=forge_commit,
        )
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
    if not turn_matches:
        turn_matches = list(TURN_EVENT.finditer(output))
    turns = int(turn_matches[-1].group("turn")) if turn_matches else 0
    if turns <= 0:
        raise SimulationFailed(
            "Forge returned a completed result without positive turn evidence"
        )
    events = _events_from_output(output)
    snapshots = _snapshots(events)
    errors = sum(
        1
        for line in output.splitlines()
        if "Exception" in line or "StackOverflowError" in line or line.startswith("Error:")
    )
    if errors:
        raise SimulationFailed(f"Forge completed with {errors} engine errors")
    status = (
        "censored" if turns > request_contract["max_turns"] else "completed"
    )
    return {
        **sidecar_identity(forge_commit),
        **request_metadata(request_contract, status=status, turns=turns),
        "type": "battle",
        "status": status,
        "started_at": started_at,
        "duration_ms": duration_ms,
        "engine_duration_ms": engine_duration_ms,
        "turns": turns,
        "winner": winner_deck.name if winner_deck and status == "completed" else None,
        "winner_deck_key": winner_key if status == "completed" else None,
        "winner_deck_id": (
            winner_deck.deck_id if winner_deck and status == "completed" else None
        ),
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
            "seed_semantics": SEED_SEMANTICS,
            "deterministic": False,
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


def _base64_field(value: str) -> str:
    return base64.urlsafe_b64encode(value.encode("utf-8")).decode("ascii").rstrip("=")


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
        request: dict[str, Any] | None = None
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
                    **self._request_metadata(request, "coverage_incomplete"),
                },
            )
        except InvalidRequest as error:
            self._send(400, {"error": "invalid_request", "message": str(error)})
        except SimulationTimeout as error:
            self._send(
                504,
                {
                    "error": "simulation_timeout",
                    "message": str(error),
                    **self._request_metadata(request, "timeout"),
                },
            )
        except SimulationFailed as error:
            self._send(
                500,
                {
                    "error": "simulation_failed",
                    "message": str(error),
                    **self._request_metadata(request, "failed"),
                },
            )
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
            **sidecar_identity(self.service.forge_commit),
            "fallback_reason": body.get("fallback_reason", "none"),
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

    def _request_metadata(
        self,
        request: dict[str, Any] | None,
        status: str,
    ) -> dict[str, Any]:
        if request is None or self.path != "/simulate":
            return {}
        try:
            deck_a = DeckInput.parse(request.get("deck_a"), "deck_a")
            deck_b = DeckInput.parse(request.get("deck_b"), "deck_b")
            contract = parse_request_contract(
                request,
                deck_a=deck_a,
                deck_b=deck_b,
                forge_commit=self.service.forge_commit,
            )
            return request_metadata(contract, status=status)
        except InvalidRequest:
            return {}

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
