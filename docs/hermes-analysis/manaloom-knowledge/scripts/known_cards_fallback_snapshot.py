#!/usr/bin/env python3
"""Helpers for canonical known-cards fallback snapshots.

These snapshots are generated from canonical `battle_card_rules` rows so the
runtime can degrade to a source-backed JSON snapshot instead of the older,
weaker `known_cards_generated.json`.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

from battle_rule_registry import normalize_card_name


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_CANONICAL_SNAPSHOT_PATH = Path(
    os.environ.get(
        "MANALOOM_CANONICAL_KNOWN_CARDS_JSON",
        SCRIPT_DIR / "known_cards_canonical_snapshot.json",
    )
)

SNAPSHOT_META_KEYS = {
    "battle_rule_source",
    "battle_rule_review_status",
    "battle_rule_confidence",
    "battle_rule_version",
    "battle_rule_logical_key",
    "battle_rule_oracle_hash",
}


def resolve_canonical_snapshot_path() -> Path:
    env_path = os.environ.get("MANALOOM_CANONICAL_KNOWN_CARDS_JSON")
    if env_path:
        return Path(env_path)
    return DEFAULT_CANONICAL_SNAPSHOT_PATH


def resolve_generated_known_cards_path() -> Path:
    env_path = os.environ.get("MANALOOM_KNOWN_CARDS_JSON")
    if env_path:
        return Path(env_path)
    return SCRIPT_DIR / "known_cards_generated.json"


def load_snapshot_file(path: str | Path) -> dict[str, dict[str, Any]]:
    snapshot_path = Path(path)
    if not snapshot_path.exists():
        return {}
    try:
        decoded = json.loads(snapshot_path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    if not isinstance(decoded, dict):
        return {}
    return {
        str(name): dict(entry)
        for name, entry in decoded.items()
        if isinstance(name, str) and isinstance(entry, dict)
    }


def load_layered_known_cards(
    *,
    canonical_path: str | Path | None = None,
    generated_path: str | Path | None = None,
) -> tuple[dict[str, dict[str, Any]], set[str], set[str]]:
    """Load canonical snapshot first, then legacy generated JSON as last fallback.

    Returns `(payload, canonical_names, generated_only_names)`.
    """

    layered: dict[str, dict[str, Any]] = {}

    canonical = load_snapshot_file(canonical_path or resolve_canonical_snapshot_path())
    canonical_names = set(canonical.keys())
    for name, entry in canonical.items():
        layered[name] = dict(entry)

    generated = load_snapshot_file(generated_path or resolve_generated_known_cards_path())
    generated_only_names: set[str] = set()
    for name, entry in generated.items():
        if name not in layered:
            layered[name] = dict(entry)
            generated_only_names.add(name)

    return layered, canonical_names, generated_only_names


def snapshot_entry(
    effect_json: dict[str, Any],
    *,
    rule_source: str,
    review_status: str,
    confidence: float,
    rule_version: int | None = None,
    logical_rule_key: str | None = None,
    oracle_hash: str | None = None,
) -> dict[str, Any]:
    payload = dict(effect_json or {})
    payload["battle_rule_source"] = str(rule_source or "unknown")
    payload["battle_rule_review_status"] = str(review_status or "unknown")
    payload["battle_rule_confidence"] = float(confidence or 0.0)
    if rule_version is not None:
        payload["battle_rule_version"] = int(rule_version)
    if logical_rule_key:
        payload["battle_rule_logical_key"] = str(logical_rule_key)
    if oracle_hash:
        payload["battle_rule_oracle_hash"] = str(oracle_hash)
    return payload


def extract_snapshot_effect_and_metadata(
    entry: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any]]:
    payload = dict(entry or {})
    metadata = {
        key: payload.pop(key)
        for key in list(payload.keys())
        if key in SNAPSHOT_META_KEYS
    }
    return payload, metadata


def build_snapshot_payload(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    payload: dict[str, dict[str, Any]] = {}
    for row in rows:
        card_name = str(row.get("card_name") or "").strip()
        effect_json = row.get("effect_json")
        if not card_name or not isinstance(effect_json, dict) or not effect_json:
            continue
        payload[card_name] = snapshot_entry(
            effect_json,
            rule_source=str(row.get("source") or "unknown"),
            review_status=str(row.get("review_status") or "unknown"),
            confidence=float(row.get("confidence") or 0.0),
            rule_version=(
                int(row["rule_version"])
                if row.get("rule_version") not in (None, "")
                else None
            ),
            logical_rule_key=(
                str(row.get("logical_rule_key"))
                if row.get("logical_rule_key")
                else None
            ),
            oracle_hash=(
                str(row.get("oracle_hash"))
                if row.get("oracle_hash")
                else None
            ),
        )
    return dict(sorted(payload.items(), key=lambda item: normalize_card_name(item[0])))


def write_snapshot_payload(path: str | Path, payload: dict[str, dict[str, Any]]) -> None:
    snapshot_path = Path(path)
    snapshot_path.parent.mkdir(parents=True, exist_ok=True)
    snapshot_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )
