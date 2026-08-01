#!/usr/bin/env python3
"""Hermetic SQLite fixture helpers for battle-rule runtime tests.

The production runtime may use an ignored Hermes ``knowledge.db`` cache, but
tests must not inherit that workstation-only state.  This helper materializes
only the requested, tracked canonical snapshot rows into a temporary registry
and restores the battle module's configured database afterwards.
"""

from __future__ import annotations

import json
import sqlite3
import tempfile
from contextlib import closing, contextmanager
from functools import lru_cache
from pathlib import Path
from typing import Any, Iterable, Iterator


SCRIPT_DIR = Path(__file__).resolve().parent
CANONICAL_SNAPSHOT_PATH = SCRIPT_DIR / "known_cards_canonical_snapshot.json"


@lru_cache(maxsize=1)
def _canonical_snapshot() -> dict[str, dict[str, Any]]:
    decoded = json.loads(CANONICAL_SNAPSHOT_PATH.read_text(encoding="utf-8"))
    if not isinstance(decoded, dict):
        raise AssertionError(
            f"Canonical battle-rule snapshot must be an object: {CANONICAL_SNAPSHOT_PATH}"
        )
    return {
        str(card_name): dict(entry)
        for card_name, entry in decoded.items()
        if isinstance(card_name, str) and isinstance(entry, dict)
    }


@contextmanager
def temporary_canonical_battle_rule_db(
    battle_module: Any,
    card_names: Iterable[str],
) -> Iterator[Path]:
    """Point ``battle_module`` at a temporary SQLite seeded from tracked rows."""

    requested_names = tuple(dict.fromkeys(str(name) for name in card_names))
    if not requested_names:
        raise AssertionError("At least one canonical battle-rule fixture card is required")

    snapshot = _canonical_snapshot()
    missing_names = [name for name in requested_names if name not in snapshot]
    if missing_names:
        raise AssertionError(
            "Canonical battle-rule fixture is missing tracked cards: "
            + ", ".join(sorted(missing_names))
        )

    with tempfile.TemporaryDirectory(prefix="manaloom-battle-rules-") as tmpdir:
        sqlite_db = Path(tmpdir) / "knowledge.db"
        with closing(sqlite3.connect(sqlite_db)) as conn:
            battle_module.battle_rule_registry.ensure_battle_card_rules(conn)
            for card_name in requested_names:
                effect_json, metadata = (
                    battle_module.extract_snapshot_effect_and_metadata(
                        snapshot[card_name]
                    )
                )
                required_metadata = {
                    "battle_rule_source",
                    "battle_rule_review_status",
                    "battle_rule_execution_status",
                    "battle_rule_confidence",
                    "battle_rule_version",
                    "battle_rule_logical_key",
                }
                missing_metadata = sorted(
                    key
                    for key in required_metadata
                    if key not in metadata or metadata[key] in (None, "")
                )
                if missing_metadata:
                    raise AssertionError(
                        f"Canonical fixture rule has incomplete provenance for {card_name}: "
                        + ", ".join(missing_metadata)
                    )
                battle_module.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    card_name,
                    effect_json,
                    source=str(metadata["battle_rule_source"]),
                    confidence=float(metadata["battle_rule_confidence"]),
                    review_status=str(metadata["battle_rule_review_status"]),
                    execution_status=str(metadata["battle_rule_execution_status"]),
                    oracle_hash=metadata.get("battle_rule_oracle_hash"),
                    logical_rule_key_value=str(metadata["battle_rule_logical_key"]),
                    rule_version=int(metadata["battle_rule_version"]),
                    notes="Hermetic test fixture from tracked canonical snapshot",
                )
            conn.commit()

        original_db = battle_module.DB
        try:
            battle_module.DB = str(sqlite_db)
            yield sqlite_db
        finally:
            battle_module.DB = original_db
