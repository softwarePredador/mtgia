#!/usr/bin/env python3
"""Validate and canonicalize ManaLoom's production CORS origin allowlist."""

from __future__ import annotations

import argparse
import ipaddress
import os
import re
import sys
from typing import NoReturn
from urllib.parse import urlsplit


DEFAULT_REQUIRED_ORIGIN = (
    "https://evolution-manaloom-web-public.2ta7qx.easypanel.host"
)
NETLOC_RE = re.compile(r"[a-z0-9.-]+(?::[1-9][0-9]{0,4})?")


def _fail(message: str) -> NoReturn:
    raise ValueError(message)


def _validate_host(hostname: str) -> None:
    if hostname == "localhost" or hostname.endswith(".localhost"):
        _fail("localhost nao e permitido na allowlist de producao")
    if hostname.endswith(".local"):
        _fail("dominio .local nao e permitido na allowlist de producao")
    try:
        address = ipaddress.ip_address(hostname)
    except ValueError:
        labels = hostname.split(".")
        if len(labels) < 2 or any(
            not label
            or len(label) > 63
            or label.startswith("-")
            or label.endswith("-")
            for label in labels
        ):
            _fail("hostname invalido na allowlist de producao")
        return
    if not address.is_global:
        _fail("IP nao global nao e permitido na allowlist de producao")


def validate_origins(raw: str, required_origin: str) -> str:
    if not raw:
        _fail("MANALOOM_ALLOWED_ORIGINS ausente")
    if any(character in raw for character in ("\n", "\r", "\t", "*")):
        _fail("allowlist contem wildcard ou caractere de controle")

    origins = raw.split(",")
    if any(not origin or origin != origin.strip() for origin in origins):
        _fail("origens devem ser separadas por virgula, sem espacos")
    if len(origins) != len(set(origins)):
        _fail("allowlist contem origem duplicada")

    for origin in origins:
        parsed = urlsplit(origin)
        if (
            parsed.scheme != "https"
            or not parsed.netloc
            or parsed.username is not None
            or parsed.password is not None
            or parsed.path
            or parsed.query
            or parsed.fragment
            or not NETLOC_RE.fullmatch(parsed.netloc)
            or parsed.netloc != parsed.netloc.lower()
        ):
            _fail("cada item deve ser uma origem HTTPS exata, sem path ou credencial")
        try:
            port = parsed.port
        except ValueError as error:
            raise ValueError("porta invalida na allowlist de producao") from error
        if port is not None and port > 65535:
            _fail("porta invalida na allowlist de producao")
        assert parsed.hostname is not None
        _validate_host(parsed.hostname)

    if required_origin not in origins:
        _fail("allowlist nao inclui a origem web publica obrigatoria")
    return ",".join(origins)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--origins",
        default=os.environ.get("MANALOOM_ALLOWED_ORIGINS", ""),
        help="comma-separated exact HTTPS origins",
    )
    parser.add_argument("--required-origin", default=DEFAULT_REQUIRED_ORIGIN)
    args = parser.parse_args()
    try:
        print(validate_origins(args.origins, args.required_origin))
    except ValueError as error:
        print(f"CORS production allowlist invalid: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
