#!/usr/bin/env python3
"""Sync the SQLite game_changers table into edh_bracket_policy.dart.

Usage:
  python sync_game_changers_to_dart.py
  python sync_game_changers_to_dart.py --check
"""

from __future__ import annotations

import argparse
import re
import sqlite3
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
DEFAULT_DB = SCRIPT_DIR / "knowledge.db"
DEFAULT_DART = REPO_ROOT / "server" / "lib" / "edh_bracket_policy.dart"

BEGIN = "// BEGIN GENERATED GAME CHANGERS"
END = "// END GENERATED GAME CHANGERS"


def dart_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def read_game_changer_names(db_path: Path) -> list[str]:
    with sqlite3.connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT card_name
            FROM game_changers
            WHERE card_name IS NOT NULL AND TRIM(card_name) <> ''
            ORDER BY lower(card_name)
            """
        ).fetchall()

    names = [row[0].strip().lower() for row in rows]
    if len(names) != len(set(names)):
        duplicates = sorted({name for name in names if names.count(name) > 1})
        raise SystemExit(f"Duplicate game changer names in SQLite: {duplicates}")
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
    parser.add_argument("--db", type=Path, default=DEFAULT_DB)
    parser.add_argument("--dart", type=Path, default=DEFAULT_DART)
    args = parser.parse_args()

    names = read_game_changer_names(args.db)
    block = render_block(names)
    source = args.dart.read_text(encoding="utf-8")
    updated = replace_generated_block(source, block)

    if args.check:
        if updated != source:
            print("Game Changers Dart list is out of sync with SQLite", file=sys.stderr)
            return 1
        print("Game Changers Dart list matches SQLite")
        return 0

    args.dart.write_text(updated, encoding="utf-8")
    print(f"Synced {len(names)} Game Changers into {args.dart}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
