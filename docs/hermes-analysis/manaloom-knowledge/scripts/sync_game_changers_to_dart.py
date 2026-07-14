#!/usr/bin/env python3
"""Sync the reviewed Commander Game Changer source into Dart policy.

Usage:
  python sync_game_changers_to_dart.py
  python sync_game_changers_to_dart.py --check
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_SOURCE = REPO_ROOT / "server" / "config" / "commander_game_changers.json"
DEFAULT_DART = REPO_ROOT / "server" / "lib" / "edh_bracket_policy.dart"

BEGIN = "// BEGIN GENERATED GAME CHANGERS"
END = "// END GENERATED GAME CHANGERS"


def dart_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def read_game_changer_names(source_path: Path) -> list[str]:
    payload = json.loads(source_path.read_text(encoding="utf-8"))
    if payload.get("schema_version") != "commander_game_changers_v1":
        raise SystemExit("Unsupported Commander Game Changer source schema")
    if not str(payload.get("source_url") or "").startswith("https://magic.wizards.com/"):
        raise SystemExit("Game Changer source must cite an official Wizards URL")
    if not str(payload.get("source_checked_at") or "").strip():
        raise SystemExit("Game Changer source_checked_at is required")
    rows = payload.get("names")
    if not isinstance(rows, list):
        raise SystemExit("Game Changer names must be a JSON list")
    names = sorted(
        [str(value).strip().lower() for value in rows if str(value).strip()],
        key=str.casefold,
    )
    if len(names) != len(set(names)):
        duplicates = sorted({name for name in names if names.count(name) > 1})
        raise SystemExit(f"Duplicate game changer names in source: {duplicates}")
    if len(names) != 53:
        raise SystemExit(f"Expected 53 game changers, found {len(names)}")
    return names


def render_block(names: list[str]) -> str:
    lines = [
        BEGIN,
        "const officialGameChangerNamesForBracketPolicy = <String>{",
    ]
    lines.extend(f"  {dart_string(name)}," for name in names)
    lines.extend(["};", END])
    return "\n".join(lines)


def replace_generated_block(source: str, block: str) -> str:
    pattern = re.compile(
        rf"{re.escape(BEGIN)}.*?{re.escape(END)}",
        re.DOTALL,
    )
    updated, replacements = pattern.subn(block, source, count=1)
    if replacements != 1:
        raise SystemExit("Could not find generated Game Changers block in Dart file")
    return updated


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--dart", type=Path, default=DEFAULT_DART)
    args = parser.parse_args()

    names = read_game_changer_names(args.source)
    block = render_block(names)
    source = args.dart.read_text(encoding="utf-8")
    updated = replace_generated_block(source, block)

    if args.check:
        if updated != source:
            print("Game Changers Dart list is out of sync with SQLite", file=sys.stderr)
            return 1
        print("Game Changers Dart list matches reviewed JSON source")
        return 0

    args.dart.write_text(updated, encoding="utf-8")
    print(f"Synced {len(names)} Game Changers into {args.dart}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
