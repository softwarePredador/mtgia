#!/usr/bin/env python3
"""Reject literal credentials in tooling that targets the production API."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


PRODUCTION_MARKER = "evolution-cartinhas.2ta7qx.easypanel.host"
SCOPED_PATH = re.compile(r"^(scripts/|server/(bin|test)/).+\.(dart|sh)$")
LITERAL_PASSWORD_PATTERNS = (
    re.compile(
        r"(?i)\b(password|passwd|senha)\b\s*[:=]\s*(['\"])([^'\"$<{\n]{6,})\2"
    ),
    re.compile(
        r"(?i)['\"](password|passwd|senha)['\"]\s*:\s*(['\"])([^'\"$<{\n]{6,})\2"
    ),
)


def tracked_paths(root: Path) -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=root,
        check=True,
        capture_output=True,
    )
    return [
        root / raw.decode("utf-8")
        for raw in result.stdout.split(b"\0")
        if raw and SCOPED_PATH.fullmatch(raw.decode("utf-8"))
    ]


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    findings: list[tuple[str, int]] = []
    for path in tracked_paths(root):
        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        if PRODUCTION_MARKER not in content:
            continue
        for line_number, line in enumerate(content.splitlines(), start=1):
            if any(pattern.search(line) for pattern in LITERAL_PASSWORD_PATTERNS):
                findings.append((str(path.relative_to(root)), line_number))

    if findings:
        for path, line_number in findings:
            print(
                f"literal credential rejected: {path}:{line_number}",
                file=sys.stderr,
            )
        return 1
    print('{"status":"passed","literal_live_credentials":0}')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
