#!/usr/bin/env python3
"""Load versioned reviewed battle-card rules for Hermes sync flows.

This layer is the repo-versioned place for card-specific semantics that were
manually reviewed and should override weak generated guesses without requiring
runtime hardcoded waivers inside battle_analyst_v9.py.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_REVIEWED_RULES_PATH = SCRIPT_DIR / "reviewed_battle_card_rules.json"


def _as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def load_reviewed_rule_rows(
    path: str | Path = DEFAULT_REVIEWED_RULES_PATH,
) -> list[dict[str, Any]]:
    reviewed_path = Path(path)
    if not reviewed_path.exists():
        return []
    try:
        decoded = json.loads(reviewed_path.read_text(encoding="utf-8"))
    except Exception:
        return []
    if not isinstance(decoded, dict):
        return []

    rows: list[dict[str, Any]] = []
    for card_name, payload in sorted(decoded.items()):
        if not isinstance(card_name, str) or not card_name.strip():
            continue
        payload_dict = _as_dict(payload)
        effect_json = _as_dict(payload_dict.get("effect_json"))
        if not effect_json:
            continue
        row = {
            "card_name": card_name.strip(),
            "effect_json": effect_json,
            "deck_role_json": _as_dict(payload_dict.get("deck_role_json")) or None,
            "source": str(payload_dict.get("source") or "curated"),
            "confidence": float(payload_dict.get("confidence") or 1.0),
            "review_status": str(payload_dict.get("review_status") or "verified"),
            "notes": str(payload_dict.get("notes") or "").strip(),
            "oracle_hash": payload_dict.get("oracle_hash"),
        }
        rows.append(row)
    return rows
