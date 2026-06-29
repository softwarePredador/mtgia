#!/usr/bin/env python3
"""Read-only MTG Arena Player.log parser for battle telemetry.

The parser extracts aggregate GRE/GameStateMessage signals from local logs
without persisting raw log lines or personal account identifiers.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


GRE_KEYWORDS = (
    "gre",
    "GreToClientEvent",
    "GREMessageType_GameStateMessage",
    "GameStateMessage",
    "ClientToGREMessage",
)
SENSITIVE_KEYS = {
    "authToken",
    "clientId",
    "email",
    "playerName",
    "screenName",
    "sessionId",
    "token",
    "transactionId",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def stable_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True)


def iter_json_values(text: str) -> Iterable[Any]:
    """Yield JSON objects/arrays embedded in noisy log text."""
    decoder = json.JSONDecoder()
    index = 0
    while index < len(text):
        start_candidates = [pos for pos in (text.find("{", index), text.find("[", index)) if pos >= 0]
        if not start_candidates:
            break
        start = min(start_candidates)
        try:
            value, end = decoder.raw_decode(text[start:])
        except json.JSONDecodeError:
            index = start + 1
            continue
        yield value
        index = start + max(end, 1)


def walk_json(value: Any) -> Iterable[Any]:
    yield value
    if isinstance(value, dict):
        for child in value.values():
            yield from walk_json(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk_json(child)


def key_lookup(value: Any, accepted_keys: set[str]) -> Any | None:
    if isinstance(value, dict):
        for key, child in value.items():
            if key in accepted_keys:
                return child
            found = key_lookup(child, accepted_keys)
            if found is not None:
                return found
    elif isinstance(value, list):
        for child in value:
            found = key_lookup(child, accepted_keys)
            if found is not None:
                return found
    return None


def coerce_text(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, (str, int, float, bool)):
        return str(value)
    return None


def count_list_field(value: Any, accepted_keys: set[str]) -> int:
    found = key_lookup(value, accepted_keys)
    if isinstance(found, list):
        return len(found)
    if isinstance(found, dict):
        return len(found)
    return 0


def contains_sensitive_key(value: Any) -> bool:
    if isinstance(value, dict):
        for key, child in value.items():
            if key in SENSITIVE_KEYS:
                return True
            if contains_sensitive_key(child):
                return True
    elif isinstance(value, list):
        return any(contains_sensitive_key(child) for child in value)
    return False


def classify_payload(value: Any, raw_line: str = "") -> str:
    payload_text = raw_line
    if not payload_text:
        try:
            payload_text = json.dumps(value, ensure_ascii=True, sort_keys=True)
        except TypeError:
            payload_text = str(value)

    if any(keyword in payload_text for keyword in ("GREMessageType_GameStateMessage", "GameStateMessage", "gameStateMessage")):
        return "game_state_message"

    for node in walk_json(value):
        if not isinstance(node, dict):
            continue
        keys = set(node)
        if "gameStateMessage" in keys:
            return "game_state_message"
        if {"turnInfo", "gameObjects"} <= keys or {"turnInfo", "annotations"} <= keys:
            return "game_state_message"
        if "clientToGreMessage" in keys:
            return "client_to_gre_message"
        if "greToClientEvent" in keys:
            return "gre_to_client_event"
    if "ClientToGREMessage" in payload_text or "clientToGreMessage" in payload_text:
        return "client_to_gre_message"
    if "GreToClientEvent" in payload_text or "greToClientEvent" in payload_text:
        return "gre_to_client_event"
    return "json_other"


def game_state_sample(value: Any, *, source_path: Path, line_number: int) -> dict[str, Any]:
    turn_info = key_lookup(value, {"turnInfo"})
    if not isinstance(turn_info, dict):
        turn_info = {}

    return {
        "source_file": source_path.name,
        "source_line": line_number,
        "game_state_id": coerce_text(key_lookup(value, {"gameStateId", "gameStateID"})),
        "turn_number": coerce_text(key_lookup(turn_info, {"turnNumber", "turn", "turnNum"})),
        "phase": coerce_text(key_lookup(turn_info, {"phase", "turnPhase", "phaseType"})),
        "step": coerce_text(key_lookup(turn_info, {"step", "phaseStep", "stepType"})),
        "active_player": coerce_text(
            key_lookup(turn_info, {"activePlayer", "activePlayerSystemSeatId"})
        ),
        "game_objects_count": count_list_field(value, {"gameObjects", "gameObjectsList"}),
        "annotations_count": count_list_field(value, {"annotations"}),
        "actions_count": count_list_field(value, {"actions", "availableActions"}),
        "zones_count": count_list_field(value, {"zones"}),
        "sensitive_payload_keys_seen": contains_sensitive_key(value),
    }


def parse_log_file(path: Path, *, max_state_samples: int = 25) -> dict[str, Any]:
    message_counts: Counter[str] = Counter()
    turn_counts: Counter[str] = Counter()
    phase_counts: Counter[str] = Counter()
    samples: list[dict[str, Any]] = []
    json_objects_seen = 0
    gre_hint_lines = 0

    with path.open("r", encoding="utf-8", errors="ignore") as handle:
        for line_number, line in enumerate(handle, start=1):
            if any(keyword in line for keyword in GRE_KEYWORDS):
                gre_hint_lines += 1
            for value in iter_json_values(line):
                json_objects_seen += 1
                classification = classify_payload(value, line)
                message_counts[classification] += 1
                if classification == "game_state_message":
                    sample = game_state_sample(
                        value,
                        source_path=path,
                        line_number=line_number,
                    )
                    turn = sample.get("turn_number")
                    phase = sample.get("phase")
                    if turn:
                        turn_counts[str(turn)] += 1
                    if phase:
                        phase_counts[str(phase)] += 1
                    if len(samples) < max_state_samples:
                        samples.append(sample)

    return {
        "path": str(path),
        "exists": path.exists(),
        "json_objects_seen": json_objects_seen,
        "gre_hint_lines": gre_hint_lines,
        "message_counts": dict(sorted(message_counts.items())),
        "turn_counts": dict(sorted(turn_counts.items(), key=lambda item: str(item[0]))),
        "phase_counts": dict(sorted(phase_counts.items())),
        "game_state_samples": samples,
    }


def build_report(paths: list[Path], *, max_state_samples: int = 25) -> dict[str, Any]:
    files = [
        parse_log_file(path, max_state_samples=max_state_samples)
        for path in paths
    ]
    aggregate_message_counts: Counter[str] = Counter()
    aggregate_turn_counts: Counter[str] = Counter()
    aggregate_phase_counts: Counter[str] = Counter()
    json_objects_seen = 0
    gre_hint_lines = 0
    samples: list[dict[str, Any]] = []

    for item in files:
        aggregate_message_counts.update(item["message_counts"])
        aggregate_turn_counts.update(item["turn_counts"])
        aggregate_phase_counts.update(item["phase_counts"])
        json_objects_seen += int(item["json_objects_seen"])
        gre_hint_lines += int(item["gre_hint_lines"])
        remaining = max(0, max_state_samples - len(samples))
        samples.extend(item["game_state_samples"][:remaining])

    return {
        "generated_at_utc": utc_now(),
        "postgres_writes": False,
        "privacy_policy": {
            "raw_log_lines_persisted": False,
            "raw_player_identifiers_persisted": False,
            "sample_payloads_are_aggregate_or_sanitized": True,
        },
        "summary": {
            "files_processed": len(files),
            "json_objects_seen": json_objects_seen,
            "gre_hint_lines": gre_hint_lines,
            "message_counts": dict(sorted(aggregate_message_counts.items())),
            "turn_counts": dict(sorted(aggregate_turn_counts.items(), key=lambda item: str(item[0]))),
            "phase_counts": dict(sorted(aggregate_phase_counts.items())),
            "game_state_sample_count": len(samples),
            "game_state_messages_seen": int(aggregate_message_counts.get("game_state_message", 0)),
            "parser_status": "ready_for_real_player_log"
            if files
            else "no_input_files_provided",
        },
        "files": files,
        "game_state_samples": samples,
        "method_notes": [
            "This parser treats Player.log as local telemetry, not rules authority.",
            "Use with explicit input paths; the script does not auto-scan user directories.",
            "Detailed Logs/GRE payload shapes can change, so parser tests use resilient JSON extraction and aggregate assertions.",
        ],
    }


def render_markdown(report: dict[str, Any]) -> str:
    summary = report["summary"]
    lines = [
        "# MTG Arena Player.log Battle Parser Report",
        "",
        f"- Generated UTC: `{report['generated_at_utc']}`",
        f"- PostgreSQL writes: `{report['postgres_writes']}`",
        f"- Files processed: `{summary['files_processed']}`",
        f"- JSON objects seen: `{summary['json_objects_seen']}`",
        f"- GRE hint lines: `{summary['gre_hint_lines']}`",
        f"- GameStateMessage count: `{summary['game_state_messages_seen']}`",
        f"- Parser status: `{summary['parser_status']}`",
        "",
        "## Message Counts",
        "",
        "| Message | Count |",
        "| --- | ---: |",
    ]
    for message, count in summary["message_counts"].items():
        lines.append(f"| `{message}` | `{count}` |")

    lines.extend(["", "## Game State Samples", ""])
    if report["game_state_samples"]:
        lines.extend(
            [
                "| File | Line | Game state | Turn | Phase | Step | Objects | Annotations | Actions |",
                "| --- | ---: | --- | --- | --- | --- | ---: | ---: | ---: |",
            ]
        )
        for sample in report["game_state_samples"]:
            lines.append(
                "| `{source_file}` | `{source_line}` | `{game_state_id}` | `{turn_number}` | `{phase}` | `{step}` | `{game_objects_count}` | `{annotations_count}` | `{actions_count}` |".format(
                    **sample
                )
            )
    else:
        lines.append("- No game state samples were extracted.")

    lines.extend(["", "## Method Notes", ""])
    for note in report["method_notes"]:
        lines.append(f"- {note}")
    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, action="append", default=[])
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--max-state-samples", type=int, default=25)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_report(args.input, max_state_samples=args.max_state_samples)
    markdown = render_markdown(report)

    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(stable_json(report) + "\n", encoding="utf-8")
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(markdown, encoding="utf-8")
    if not args.output and not args.json_output:
        print(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
