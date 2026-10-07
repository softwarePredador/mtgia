#!/usr/bin/env python3
"""BT-GATE-007: confere e lista as trilhas dos integration_test do app.

O manifesto põe cada `app/integration_test/*_test.dart` em exatamente uma
trilha. A conferência falha fechado: arquivo sem trilha, entrada para arquivo
que sumiu, entrada duplicada, trilha desconhecida ou motivo vazio.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

MANIFEST_PATH = "server/config/integration_test_lanes.json"
SCHEMA = "manaloom.integration_test_lanes.v1"
TEST_DIR = "app/integration_test"
LANES = ("web_hermetic", "web_backend", "device", "ui_proof", "triage")


class LaneError(RuntimeError):
    pass


def load(repo: Path) -> dict:
    path = repo / MANIFEST_PATH
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise LaneError(f"manifesto ausente: {MANIFEST_PATH}") from error
    except json.JSONDecodeError as error:
        raise LaneError(f"manifesto inválido: {error}") from error
    if manifest.get("schema") != SCHEMA:
        raise LaneError(f"schema esperado {SCHEMA}")
    if sorted(manifest.get("lanes", {})) != sorted(LANES):
        raise LaneError(f"trilhas esperadas: {', '.join(LANES)}")
    return manifest


def check(repo: Path) -> dict:
    manifest = load(repo)
    on_disk = {
        f"{TEST_DIR}/{path.name}"
        for path in (repo / TEST_DIR).glob("*_test.dart")
        if path.is_file()
    }
    seen: dict[str, str] = {}
    problems: list[str] = []
    for entry in manifest.get("tests", []):
        path = entry.get("path", "")
        lane = entry.get("lane", "")
        if path in seen:
            problems.append(f"entrada duplicada: {path}")
        seen[path] = lane
        if lane not in LANES:
            problems.append(f"trilha desconhecida '{lane}': {path}")
        if not str(entry.get("reason", "")).strip():
            problems.append(f"sem motivo: {path}")
        if path not in on_disk:
            problems.append(f"arquivo não existe: {path}")
    for path in sorted(on_disk - seen.keys()):
        problems.append(f"sem trilha: {path}")
    if not any(lane == "web_hermetic" for lane in seen.values()):
        problems.append("a trilha web_hermetic está vazia")
    if problems:
        raise LaneError("\n".join(problems))
    return manifest


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("check", "list", "report"):
        command = sub.add_parser(name)
        command.add_argument("--repo", type=Path, default=Path.cwd())
        if name == "list":
            command.add_argument("--lane", choices=LANES, required=True)
    args = parser.parse_args(argv)

    try:
        manifest = check(args.repo)
    except LaneError as error:
        print(f"Manifesto de trilhas reprovado ({MANIFEST_PATH}):", file=sys.stderr)
        print(str(error), file=sys.stderr)
        return 1

    tests = manifest["tests"]
    if args.command == "list":
        for entry in sorted(tests, key=lambda item: item["path"]):
            if entry["lane"] == args.lane:
                print(entry["path"])
    elif args.command == "report":
        for lane in LANES:
            count = sum(1 for entry in tests if entry["lane"] == lane)
            print(f"{lane}: {count} — {manifest['lanes'][lane]}")
    else:
        print(f"Manifesto de trilhas OK: {len(tests)} integration_test.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
