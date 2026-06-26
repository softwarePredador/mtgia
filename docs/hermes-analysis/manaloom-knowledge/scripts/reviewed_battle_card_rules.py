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
        rule_payloads = payload_dict.get("rules")
        if isinstance(rule_payloads, list):
            candidate_payloads = [
                _as_dict(rule_payload)
                for rule_payload in rule_payloads
                if isinstance(rule_payload, dict)
            ]
        else:
            candidate_payloads = [payload_dict]

        for rule_payload in candidate_payloads:
            effect_json = _as_dict(rule_payload.get("effect_json"))
            if not effect_json:
                continue
            row = {
                "card_name": card_name.strip(),
                "effect_json": effect_json,
                "deck_role_json": _as_dict(rule_payload.get("deck_role_json")) or None,
                "logical_rule_key": rule_payload.get("logical_rule_key")
                or payload_dict.get("logical_rule_key"),
                "source": str(rule_payload.get("source") or payload_dict.get("source") or "curated"),
                "confidence": float(
                    rule_payload.get("confidence")
                    or payload_dict.get("confidence")
                    or 1.0
                ),
                "review_status": str(
                    rule_payload.get("review_status")
                    or payload_dict.get("review_status")
                    or "verified"
                ),
                "execution_status": str(
                    rule_payload.get("execution_status")
                    or payload_dict.get("execution_status")
                    or "auto"
                ),
                "notes": str(
                    rule_payload.get("notes")
                    or payload_dict.get("notes")
                    or ""
                ).strip(),
                "oracle_hash": rule_payload.get("oracle_hash") or payload_dict.get("oracle_hash"),
            }
            rows.append(row)
    return rows
