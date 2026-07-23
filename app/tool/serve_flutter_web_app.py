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
import ssl
import sys
from pathlib import Path
from urllib import error, request
from urllib.parse import unquote, urlparse


DEFAULT_PREFIX = "/app/"


class FlutterWebAppHandler(http.server.BaseHTTPRequestHandler):
    build_dir: Path
    prefix: str
    api_upstream: str | None = None
    api_ssl_context: ssl.SSLContext | None = None
    api_prefix = "/api"

    server_version = "ManaLoomFlutterWebQA/1.0"

    def do_GET(self) -> None:
        self._handle_request()

    def do_HEAD(self) -> None:
        self._handle_request(head_only=True)

    def do_POST(self) -> None:
        self._handle_request()

    def do_PUT(self) -> None:
        self._handle_request()

    def do_PATCH(self) -> None:
        self._handle_request()

    def do_DELETE(self) -> None:
        self._handle_request()

    def do_OPTIONS(self) -> None:
        self._handle_request()

    def _handle_request(self, *, head_only: bool = False) -> None:
        parsed = urlparse(self.path)
        path = parsed.path

        if self.api_upstream and (
            path == self.api_prefix or path.startswith(f"{self.api_prefix}/")
        ):
            self._proxy_api(head_only=head_only)
            return

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

    def _proxy_api(self, *, head_only: bool) -> None:
        parsed = urlparse(self.path)
        upstream_path = parsed.path[len(self.api_prefix) :] or "/"
        target = f"{self.api_upstream}{upstream_path}"
        if parsed.query:
            target = f"{target}?{parsed.query}"

        content_length = int(self.headers.get("Content-Length", "0") or "0")
        if content_length > 10 * 1024 * 1024:
            self.send_error(413, "QA proxy request body is too large")
            return
        body = self.rfile.read(content_length) if content_length else None
        forwarded_headers = {
            header: value
            for header, value in self.headers.items()
            if header.lower()
            in {"accept", "authorization", "content-type", "x-request-id"}
        }
        upstream_request = request.Request(
            target,
            data=body,
            headers=forwarded_headers,
            method=self.command,
        )

        try:
            response = request.urlopen(
                upstream_request,
                context=self.api_ssl_context,
                timeout=60,
            )
        except error.HTTPError as upstream_error:
            response = upstream_error
        except error.URLError:
            self.send_error(502, "QA API upstream is unavailable")
            return

        with response:
            response_body = response.read()
            self.send_response(response.status)
            for header in ("Content-Type", "X-Request-Id", "Retry-After"):
                value = response.headers.get(header)
                if value:
                    self.send_header(header, value)
            self.send_header("Content-Length", str(len(response_body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            if not head_only:
                self.wfile.write(response_body)

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
    parser.add_argument(
        "--api-upstream",
        help=(
            "Optional API origin proxied under /api for loopback-only "
            "authenticated QA. HTTPS is required unless the explicit "
            "disposable loopback fixture flag is enabled."
        ),
    )
    parser.add_argument(
        "--allow-loopback-http-api",
        action="store_true",
        help=(
            "Allow an HTTP API only when its hostname is loopback. Intended "
            "exclusively for disposable local PostgreSQL/API fixtures."
        ),
    )
    parser.add_argument(
        "--ca-file",
        default="/etc/ssl/cert.pem",
        help="Trusted CA bundle for the HTTPS QA proxy (never disables TLS verification).",
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
    if args.api_upstream:
        parsed_upstream = urlparse(args.api_upstream)
        is_origin_only = (
            parsed_upstream.path in ("", "/")
            and not parsed_upstream.query
            and not parsed_upstream.fragment
            and parsed_upstream.username is None
            and parsed_upstream.password is None
        )
        is_https_origin = parsed_upstream.scheme == "https"
        is_explicit_loopback_http = (
            args.allow_loopback_http_api
            and parsed_upstream.scheme == "http"
            and parsed_upstream.hostname in {"127.0.0.1", "::1", "localhost"}
        )
        if not parsed_upstream.netloc or not is_origin_only or not (
            is_https_origin or is_explicit_loopback_http
        ):
            print(
                "--api-upstream must be an absolute HTTPS origin, or an "
                "explicitly allowed loopback HTTP fixture",
                file=sys.stderr,
            )
            return 2
        if args.host not in {"127.0.0.1", "::1", "localhost"}:
            print("--api-upstream requires a loopback --host", file=sys.stderr)
            return 2
        FlutterWebAppHandler.api_upstream = args.api_upstream.rstrip("/")
        if is_https_origin:
            ca_file = Path(args.ca_file).expanduser()
            if not ca_file.is_file():
                print(f"trusted CA bundle not found: {ca_file}", file=sys.stderr)
                return 2
            FlutterWebAppHandler.api_ssl_context = ssl.create_default_context(
                cafile=str(ca_file)
            )
        else:
            FlutterWebAppHandler.api_ssl_context = None

    server = http.server.ThreadingHTTPServer(
        (args.host, args.port),
        FlutterWebAppHandler,
    )
    url = f"http://{args.host}:{args.port}{FlutterWebAppHandler.prefix}"
    print(f"Serving ManaLoom Flutter Web at {url}")
    if FlutterWebAppHandler.api_upstream:
        print("Loopback QA API proxy enabled under /api")
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
