#!/usr/bin/env python3
"""Helpers for canonical known-cards fallback snapshots.

These snapshots are generated from canonical `battle_card_rules` rows so the
runtime can degrade to a source-backed JSON snapshot instead of the older,
weaker `known_cards_generated.json`.
"""

from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any

from battle_rule_registry import (
    EXECUTION_STATUS_PRIORITY,
    REVIEW_STATUS_PRIORITY,
    SOURCE_PRIORITY,
    normalize_card_name,
)


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
    "battle_rule_execution_status",
    "battle_rule_confidence",
    "battle_rule_version",
    "battle_rule_logical_key",
    "battle_rule_oracle_hash",
}

PRESERVED_RUNTIME_ANNOTATION_KEYS = {
    "battle_model_scope",
    "oracle_runtime_scope",
    "mana_color_status",
    "pg058_l3b_simple_red_ritual_family",
    "opponents_cant_win_this_turn",
    "split_second",
    "life_floor_on_damage",
    "damage_prevention_scope",
    "singleton_commander_baseline",
    "graveyard_named_copy_scaling_status",
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
    include_generated: bool = False,
) -> tuple[dict[str, dict[str, Any]], set[str], set[str]]:
    """Load canonical snapshot and optionally overlay legacy generated JSON.

    Returns `(payload, canonical_names, generated_only_names)`.

    Runtime consumers must keep `include_generated=False`. The legacy generated
    JSON is only for sync/audit tools that need drift measurement or historical
    bootstrap visibility.
    """

    layered: dict[str, dict[str, Any]] = {}

    canonical = load_snapshot_file(canonical_path or resolve_canonical_snapshot_path())
    canonical_names = set(canonical.keys())
    for name, entry in canonical.items():
        layered[name] = dict(entry)

    generated_only_names: set[str] = set()
    if include_generated:
        generated = load_snapshot_file(
            generated_path or resolve_generated_known_cards_path()
        )
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
    execution_status: str = "auto",
    confidence: float,
    rule_version: int | None = None,
    logical_rule_key: str | None = None,
    oracle_hash: str | None = None,
) -> dict[str, Any]:
    payload = dict(effect_json or {})
    payload["battle_rule_source"] = str(rule_source or "unknown")
    payload["battle_rule_review_status"] = str(review_status or "unknown")
    payload["battle_rule_execution_status"] = str(execution_status or "auto")
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
    def _timestamp_rank(value: Any) -> float:
        if value in (None, ""):
            return 0.0
        if isinstance(value, (int, float)):
            return float(value)
        text = str(value).strip()
        if not text:
            return 0.0
        try:
            return datetime.fromisoformat(text.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return 0.0

    def _snapshot_row_rank(row: dict[str, Any]) -> tuple[int, int, int, float, int, float, int, str]:
        effect_json = row.get("effect_json")
        effect_size = len(effect_json) if isinstance(effect_json, dict) else 0
        return (
            REVIEW_STATUS_PRIORITY.get(str(row.get("review_status") or "").lower(), 7),
            EXECUTION_STATUS_PRIORITY.get(str(row.get("execution_status") or "").lower(), 9),
            -SOURCE_PRIORITY.get(str(row.get("source") or "").lower(), 0),
            -float(row.get("confidence") or 0.0),
            -int(row.get("rule_version") or 1),
            -_timestamp_rank(row.get("updated_at") or row.get("last_seen_at")),
            -effect_size,
            str(row.get("logical_rule_key") or ""),
        )

    best_rows: dict[str, dict[str, Any]] = {}
    for row in rows:
        card_name = str(row.get("card_name") or "").strip()
        effect_json = row.get("effect_json")
        if not card_name or not isinstance(effect_json, dict) or not effect_json:
            continue
        previous = best_rows.get(card_name)
        if previous is None or _snapshot_row_rank(row) < _snapshot_row_rank(previous):
            best_rows[card_name] = row

    payload: dict[str, dict[str, Any]] = {}
    for card_name, row in best_rows.items():
        effect_json = row["effect_json"]
        payload[card_name] = snapshot_entry(
            effect_json,
            rule_source=str(row.get("source") or "unknown"),
            review_status=str(row.get("review_status") or "unknown"),
            execution_status=str(row.get("execution_status") or "auto"),
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


def merge_runtime_annotations_from_existing_snapshot(
    payload: dict[str, dict[str, Any]],
    existing_payload: dict[str, dict[str, Any]] | None,
) -> dict[str, dict[str, Any]]:
    if not existing_payload:
        return payload

    merged_payload: dict[str, dict[str, Any]] = {}
    for card_name, entry in payload.items():
        merged_entry = dict(entry)
        existing_entry = existing_payload.get(card_name)
        if not isinstance(existing_entry, dict):
            merged_payload[card_name] = merged_entry
            continue

        new_key = str(merged_entry.get("battle_rule_logical_key") or "")
        old_key = str(existing_entry.get("battle_rule_logical_key") or "")
        if new_key and old_key and new_key != old_key:
            merged_payload[card_name] = merged_entry
            continue

        new_hash = str(merged_entry.get("battle_rule_oracle_hash") or "")
        old_hash = str(existing_entry.get("battle_rule_oracle_hash") or "")
        if new_hash and old_hash and new_hash != old_hash:
            merged_payload[card_name] = merged_entry
            continue

        for key in PRESERVED_RUNTIME_ANNOTATION_KEYS:
            if merged_entry.get(key) in (None, "", [], {}):
                value = existing_entry.get(key)
                if value not in (None, "", [], {}):
                    merged_entry[key] = value
        merged_payload[card_name] = merged_entry
    return merged_payload


def write_snapshot_payload(path: str | Path, payload: dict[str, dict[str, Any]]) -> None:
    snapshot_path = Path(path)
    snapshot_path.parent.mkdir(parents=True, exist_ok=True)
    snapshot_path.write_text(
        json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )
