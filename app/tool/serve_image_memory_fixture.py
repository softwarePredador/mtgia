#!/usr/bin/env python3
"""Serve one cacheable image fixture on an explicit loopback listener."""

from __future__ import annotations

import argparse
import hashlib
import http.server
import ipaddress
import json
import struct
import threading
import zlib
from pathlib import Path
from urllib.parse import urlparse


FIXTURE_PATH = "/assets/symbols/logo.png"
FIXTURE_WIDTH = 488
FIXTURE_HEIGHT = 680


def _png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    payload = chunk_type + data
    return (
        struct.pack(">I", len(data))
        + payload
        + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF)
    )


def generate_fixture_png(
    width: int = FIXTURE_WIDTH,
    height: int = FIXTURE_HEIGHT,
) -> bytes:
    """Build a deterministic RGBA PNG with representative card dimensions."""
    if width <= 0 or height <= 0:
        raise ValueError("PNG dimensions must be positive")

    scanlines = bytearray()
    for y in range(height):
        scanlines.append(0)
        for x in range(width):
            scanlines.extend(
                (
                    ((x // 4) * 37 + (y // 4) * 19) % 256,
                    ((x // 4) * 11 + (y // 4) * 29) % 256,
                    ((x // 4) * 23 + (y // 4) * 7) % 256,
                    255,
                )
            )

    signature = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return (
        signature
        + _png_chunk(b"IHDR", ihdr)
        + _png_chunk(b"IDAT", zlib.compress(bytes(scanlines), level=9))
        + _png_chunk(b"IEND", b"")
    )


def is_loopback_host(host: str) -> bool:
    if host == "localhost":
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def fixture_headers(data: bytes) -> dict[str, str]:
    return {
        "Access-Control-Allow-Origin": "*",
        "Cache-Control": "public, max-age=3600, immutable",
        "Content-Length": str(len(data)),
        "Content-Type": "image/png",
        "Cross-Origin-Resource-Policy": "cross-origin",
        "ETag": f'"{hashlib.sha256(data).hexdigest()}"',
        "Timing-Allow-Origin": "*",
        "X-Content-Type-Options": "nosniff",
    }


class FixtureStats:
    def __init__(self, payload_bytes: int) -> None:
        self.payload_bytes = payload_bytes
        self._request_count = 0
        self._sample_counts: dict[int, int] = {}
        self._lock = threading.Lock()

    def record(self, sample_index: int | None) -> None:
        with self._lock:
            self._request_count += 1
            if sample_index is not None:
                self._sample_counts[sample_index] = (
                    self._sample_counts.get(sample_index, 0) + 1
                )

    def snapshot(self) -> dict[str, int | None]:
        with self._lock:
            indices = set(self._sample_counts)
            return {
                "request_count": self._request_count,
                "bytes_sent": self._request_count * self.payload_bytes,
                "unique_sample_count": len(indices),
                "duplicate_request_count": sum(
                    max(0, count - 1) for count in self._sample_counts.values()
                ),
                "minimum_sample_index": min(indices) if indices else None,
                "maximum_sample_index": max(indices) if indices else None,
            }


class ImageMemoryFixtureHandler(http.server.BaseHTTPRequestHandler):
    fixture_data: bytes
    headers: dict[str, str]
    stats: FixtureStats

    server_version = "ManaLoomImageMemoryFixture/1.0"
    protocol_version = "HTTP/1.1"

    def do_GET(self) -> None:
        self._serve(head_only=False)

    def do_HEAD(self) -> None:
        self._serve(head_only=True)

    def _serve(self, *, head_only: bool) -> None:
        path = urlparse(self.path).path
        if path == "/healthz":
            body = json.dumps(
                {"status": "ok", "fixture_path": FIXTURE_PATH},
                sort_keys=True,
            ).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            if not head_only:
                self.wfile.write(body)
            return

        if path == "/stats":
            body = json.dumps(self.stats.snapshot(), sort_keys=True).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            if not head_only:
                self.wfile.write(body)
            return

        if path != FIXTURE_PATH:
            self.send_error(404, "Only the controlled image fixture is served")
            return

        query = urlparse(self.path).query
        sample_index: int | None = None
        for part in query.split("&"):
            if part.startswith("memory_sample="):
                try:
                    sample_index = int(part.split("=", 1)[1])
                except ValueError:
                    sample_index = None
                break
        if not head_only:
            self.stats.record(sample_index)

        self.send_response(200)
        for name, value in self.headers.items():
            self.send_header(name, value)
        self.end_headers()
        if not head_only:
            self.wfile.write(self.fixture_data)

    def log_message(self, format: str, *args: object) -> None:
        return


class ConcurrentFixtureServer(http.server.ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True
    request_queue_size = 256


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8091)
    parser.add_argument(
        "--image",
        type=Path,
        help="Optional PNG override; the default is a generated 488x680 fixture.",
    )
    args = parser.parse_args()
    if not is_loopback_host(args.host):
        parser.error("--host must resolve to an explicit loopback address")
    if not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    return args


def main() -> int:
    args = parse_args()
    if args.image is None:
        data = generate_fixture_png()
        fixture_source = (
            f"generated deterministic {FIXTURE_WIDTH}x{FIXTURE_HEIGHT} RGBA PNG"
        )
    else:
        image_path = args.image.resolve()
        if not image_path.is_file():
            raise SystemExit(f"Image fixture does not exist: {image_path}")
        data = image_path.read_bytes()
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise SystemExit(f"Image fixture is not a PNG: {image_path}")
        fixture_source = str(image_path)

    ImageMemoryFixtureHandler.fixture_data = data
    ImageMemoryFixtureHandler.headers = fixture_headers(data)
    ImageMemoryFixtureHandler.stats = FixtureStats(len(data))
    server = ConcurrentFixtureServer(
        (args.host, args.port),
        ImageMemoryFixtureHandler,
    )
    print(
        f"Serving cacheable image fixture at "
        f"http://{args.host}:{args.port}{FIXTURE_PATH} "
        f"({len(data)} bytes; {fixture_source})",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
