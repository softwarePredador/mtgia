from __future__ import annotations

import os
from urllib.parse import urlparse


APPROVAL_ENV = "MANALOOM_CONFIRM_LIVE_MUTATIONS"
APPROVAL_TOKEN = "I_HAVE_EXPLICIT_APPROVAL"
BLOCKED_PRODUCTION_HOSTS = frozenset(
    {
        "137.184.5.11",
        "evolution-cartinhas.2ta7qx.easypanel.host",
    }
)


def require_legacy_live_e2e_approval(base_url: str) -> str:
    normalized = str(base_url or "").strip().rstrip("/")
    parsed = urlparse(normalized)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise SystemExit("Legacy live E2E requires an explicit http(s) API URL.")
    normalized_host = (parsed.hostname or "").lower().rstrip(".")
    if normalized_host in BLOCKED_PRODUCTION_HOSTS:
        raise SystemExit(
            "Legacy live E2E is restricted to local or staging targets; "
            "the production API target is blocked."
        )
    if os.environ.get(APPROVAL_ENV) != APPROVAL_TOKEN:
        raise SystemExit(
            f"Legacy live E2E writes test data. Set {APPROVAL_ENV}="
            f"{APPROVAL_TOKEN} only after approving the target API."
        )
    return normalized
