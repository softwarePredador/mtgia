#!/usr/bin/env python3
"""Loopback-only email webhook fixture that never stores reset credentials."""

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


PORT = int(os.environ["MANALOOM_EMAIL_FIXTURE_PORT"])
LOG_PATH = Path(os.environ["MANALOOM_EMAIL_FIXTURE_LOG"])


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        return

    def do_GET(self):
        if self.path != "/health":
            self.send_error(404)
            return
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def do_POST(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length))
            template = payload.get("template")
            recipient = payload.get("recipient", "")
            link_key = (
                "reset_url" if template == "password_reset" else "verification_url"
            )
            valid = (
                template in {"password_reset", "email_verification"}
                and isinstance(recipient, str)
                and "@" in recipient
                and isinstance(payload.get(link_key), str)
                and "token=" in payload[link_key]
            )
            if not valid:
                self.send_error(400)
                return
            # Deliberately retain only non-secret delivery evidence.
            evidence = {
                "template": template,
                "recipient_domain": recipient.rsplit("@", 1)[-1].lower(),
                "link_present": True,
            }
            with LOG_PATH.open("a", encoding="utf-8") as stream:
                stream.write(json.dumps(evidence, sort_keys=True) + "\n")
            self.send_response(202)
            self.end_headers()
            self.wfile.write(b'{"accepted":true}')
        except Exception:
            self.send_error(400)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    server.serve_forever()
