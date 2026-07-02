#!/usr/bin/env python3
"""Serve the Flutter Web bundle under the same /app prefix used in deploy.

This is a local QA helper, not a production server. It serves app/build/web
under /app/ and falls back unknown /app/* paths to index.html so GoRouter can
handle refresh/deep links.
"""

from __future__ import annotations

import argparse
import http.server
import mimetypes
import posixpath
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse


DEFAULT_PREFIX = "/app/"


class FlutterWebAppHandler(http.server.BaseHTTPRequestHandler):
    build_dir: Path
    prefix: str

    server_version = "ManaLoomFlutterWebQA/1.0"

    def do_GET(self) -> None:
        self._handle_request()

    def do_HEAD(self) -> None:
        self._handle_request(head_only=True)

    def _handle_request(self, *, head_only: bool = False) -> None:
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/":
            self._redirect(self.prefix)
            return

        if path == self.prefix.rstrip("/"):
            self._redirect(self.prefix)
            return

        if not path.startswith(self.prefix):
            self.send_error(404, "Only the Flutter Web /app prefix is served")
            return

        relative_path = self._relative_asset_path(path)
        target = self.build_dir / relative_path if relative_path else self.build_dir / "index.html"

        if not target.is_file():
            target = self.build_dir / "index.html"

        self._send_file(target, head_only=head_only)

    def _relative_asset_path(self, path: str) -> Path | None:
        raw_relative = unquote(path[len(self.prefix) :])
        normalized = posixpath.normpath(raw_relative)

        if normalized in ("", "."):
            return None

        parts = [part for part in normalized.split("/") if part not in ("", ".", "..")]
        if not parts:
            return None
        return Path(*parts)

    def _send_file(self, target: Path, *, head_only: bool) -> None:
        try:
            data = target.read_bytes()
        except OSError as error:
            self.send_error(404, str(error))
            return

        content_type = mimetypes.guess_type(target.name)[0] or "application/octet-stream"
        if target.suffix == ".wasm":
            content_type = "application/wasm"

        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

        if not head_only:
            self.wfile.write(data)

    def _redirect(self, location: str) -> None:
        self.send_response(302)
        self.send_header("Location", location)
        self.end_headers()

    def log_message(self, format: str, *args: object) -> None:
        sys.stderr.write("[%s] %s\n" % (self.log_date_time_string(), format % args))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default=8088, type=int)
    parser.add_argument("--prefix", default=DEFAULT_PREFIX)
    parser.add_argument(
        "--build-dir",
        default=str(Path(__file__).resolve().parents[1] / "build" / "web"),
    )
    return parser.parse_args()


def normalize_prefix(prefix: str) -> str:
    if not prefix.startswith("/"):
        prefix = f"/{prefix}"
    if not prefix.endswith("/"):
        prefix = f"{prefix}/"
    return prefix


def main() -> int:
    args = parse_args()
    build_dir = Path(args.build_dir).resolve()
    index_file = build_dir / "index.html"

    if not index_file.is_file():
        print(
            "Build not found. Run: flutter build web --base-href /app/",
            file=sys.stderr,
        )
        return 2

    FlutterWebAppHandler.build_dir = build_dir
    FlutterWebAppHandler.prefix = normalize_prefix(args.prefix)

    server = http.server.ThreadingHTTPServer(
        (args.host, args.port),
        FlutterWebAppHandler,
    )
    url = f"http://{args.host}:{args.port}{FlutterWebAppHandler.prefix}"
    print(f"Serving ManaLoom Flutter Web at {url}")
    print("Press Ctrl+C to stop.")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        server.server_close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
