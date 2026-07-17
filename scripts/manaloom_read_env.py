#!/usr/bin/env python3
"""Read one dotenv value without executing the dotenv file as shell code."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


KEY_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
DANGEROUS_KEYS = {
    "BASH_ENV",
    "BASHOPTS",
    "CDPATH",
    "ENV",
    "GIT_CONFIG",
    "GIT_CONFIG_COUNT",
    "HOME",
    "IFS",
    "LD_PRELOAD",
    "PATH",
    "PYTHONPATH",
    "SHELLOPTS",
}
DANGEROUS_PREFIXES = ("BASH_FUNC_", "DYLD_", "LD_")


def _parse_value(raw: str, line_number: int) -> str:
    value = raw.strip()
    if not value:
        return ""
    if value[0] in {"'", '"'}:
        quote = value[0]
        if len(value) < 2 or value[-1] != quote:
            raise ValueError(f"linha {line_number}: aspas nao balanceadas")
        return value[1:-1]
    return value


def parse_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].lstrip()
        if "=" not in line:
            raise ValueError(f"linha {line_number}: atribuicao KEY=VALUE invalida")
        key, raw_value = line.split("=", 1)
        key = key.strip()
        if not KEY_RE.fullmatch(key):
            raise ValueError(f"linha {line_number}: chave dotenv invalida")
        if key in DANGEROUS_KEYS or key.startswith(DANGEROUS_PREFIXES):
            raise ValueError(f"linha {line_number}: chave perigosa recusada: {key}")
        if key in values:
            raise ValueError(f"linha {line_number}: chave duplicada: {key}")
        values[key] = _parse_value(raw_value, line_number)
    return values


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", type=Path, required=True)
    parser.add_argument("--key", required=True)
    args = parser.parse_args()
    if not KEY_RE.fullmatch(args.key):
        parser.error("key invalida")
    values = parse_env(args.file)
    if args.key not in values:
        return 3
    sys.stdout.write(values[args.key])
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"dotenv seguro recusado: {exc}", file=sys.stderr)
        raise SystemExit(2) from exc
