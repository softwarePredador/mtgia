#!/usr/bin/env python3
"""Regression tests for the fail-closed Battle target identity guard."""

from __future__ import annotations

import sqlite3
import tempfile
from pathlib import Path

import battle_target_deck_identity_guard as guard


EXPECTED_PG = "8938b746-1a9e-46ce-b0d9-c2ec932ddddd"


def test_protected_target_contract_is_shared_with_replay() -> None:
    assert guard.PROTECTED_HERMES_DECK_ID == 6


def fixture_db(path: Path, *, pg_deck_id: str = EXPECTED_PG, split_hash: bool = False) -> None:
    conn = sqlite3.connect(path)
    try:
        conn.executescript(
            """
            CREATE TABLE decks (
              id INTEGER PRIMARY KEY,
              deck_name TEXT,
              total_cards INTEGER,
              notes TEXT
            );
            CREATE TABLE deck_cards (
              deck_id INTEGER,
              card_id TEXT,
              card_name TEXT,
              quantity INTEGER,
              is_commander INTEGER,
              deck_hash TEXT,
              semantics_hash TEXT,
              ruleset_hash TEXT,
              sync_run_id TEXT,
              functional_tags_json TEXT,
              semantic_tags_v2_json TEXT,
              battle_rules_json TEXT
            );
            """
        )
        conn.execute(
            "INSERT INTO decks VALUES (6, 'Lorehold 607 - Current Champion', 100, ?)",
            (f"sync_pg_target_deck_to_hermes.py pg_deck_id={pg_deck_id}",),
        )
        for index in range(100):
            conn.execute(
                "INSERT INTO deck_cards VALUES (6, ?, ?, 1, ?, '', '', '', 'run-1', '[]', '[]', '[]')",
                (
                    f"00000000-0000-0000-0000-{index:012d}",
                    f"Card {index}",
                    1 if index == 0 else 0,
                ),
            )
        conn.row_factory = sqlite3.Row
        rows = conn.execute(
            "SELECT * FROM deck_cards WHERE deck_id=6"
        ).fetchall()
        deck_hash, semantics_hash, ruleset_hash = guard.compute_snapshot_hashes(rows)
        conn.execute(
            "UPDATE deck_cards SET deck_hash=?, semantics_hash=?, ruleset_hash=?",
            (deck_hash, semantics_hash, ruleset_hash),
        )
        if split_hash:
            conn.execute(
                "UPDATE deck_cards SET deck_hash='different' WHERE card_name='Card 99'"
            )
        conn.commit()
    finally:
        conn.close()


def test_guard_accepts_exact_protected_snapshot() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "knowledge.db"
        fixture_db(path)
        report = guard.inspect_target_identity(
            path,
            target_deck_id=6,
            expected_pg_deck_id=EXPECTED_PG,
        )
        assert report["status"] == "pass"
        assert report["actual"]["pg_deck_id"] == EXPECTED_PG
        assert len(report["actual"]["deck_hash"]) == 64
        assert report["actual"]["deck_hash"] == report["actual"]["computed_deck_hash"]


def test_guard_blocks_wrong_postgres_deck() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "knowledge.db"
        fixture_db(path, pg_deck_id="528c877f-f829-4207-95e6-73981776c323")
        report = guard.inspect_target_identity(
            path,
            target_deck_id=6,
            expected_pg_deck_id=EXPECTED_PG,
        )
        assert report["status"] == "blocked"
        assert "pg_deck_id_mismatch" in report["errors"]


def test_guard_blocks_nonuniform_snapshot_hash() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "knowledge.db"
        fixture_db(path, split_hash=True)
        report = guard.inspect_target_identity(
            path,
            target_deck_id=6,
            expected_pg_deck_id=EXPECTED_PG,
        )
        assert report["status"] == "blocked"
        assert "deck_hash_missing_or_nonuniform" in report["errors"]


def test_guard_blocks_partially_missing_snapshot_hash() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "knowledge.db"
        fixture_db(path)
        conn = sqlite3.connect(path)
        try:
            conn.execute(
                "UPDATE deck_cards SET deck_hash='' WHERE card_name='Card 99'"
            )
            conn.commit()
        finally:
            conn.close()
        report = guard.inspect_target_identity(
            path,
            target_deck_id=6,
            expected_pg_deck_id=EXPECTED_PG,
        )
        assert report["status"] == "blocked"
        assert "deck_hash_missing_or_nonuniform" in report["errors"]


def test_guard_blocks_content_drift_with_stale_hash() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "knowledge.db"
        fixture_db(path)
        conn = sqlite3.connect(path)
        try:
            conn.execute(
                "UPDATE deck_cards SET card_name='Mutated Card' WHERE card_name='Card 99'"
            )
            conn.commit()
        finally:
            conn.close()
        report = guard.inspect_target_identity(
            path,
            target_deck_id=6,
            expected_pg_deck_id=EXPECTED_PG,
        )
        assert report["status"] == "blocked"
        assert "deck_hash_content_mismatch" in report["errors"]


def test_guard_blocks_invalid_snapshot_json_instead_of_hashing_empty_value() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "knowledge.db"
        fixture_db(path)
        conn = sqlite3.connect(path)
        try:
            conn.execute(
                "UPDATE deck_cards SET functional_tags_json='{' WHERE card_name='Card 99'"
            )
            conn.commit()
        finally:
            conn.close()

        report = guard.inspect_target_identity(
            path,
            target_deck_id=6,
            expected_pg_deck_id=EXPECTED_PG,
        )
        assert report["status"] == "blocked"
        assert "snapshot_json_invalid" in report["errors"]
        assert report["actual"]["computed_deck_hash"] is None


def test_snapshot_hash_order_is_stable_for_duplicate_names() -> None:
    rows = [
        {
            "card_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            "card_name": "Same Name",
            "quantity": 1,
            "is_commander": 0,
            "functional_tags_json": '["draw"]',
            "semantic_tags_v2_json": "[]",
            "battle_rules_json": "[]",
        },
        {
            "card_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            "card_name": "Same Name",
            "quantity": 1,
            "is_commander": 0,
            "functional_tags_json": '["ramp"]',
            "semantic_tags_v2_json": "[]",
            "battle_rules_json": "[]",
        },
    ]

    assert guard.compute_snapshot_hashes(rows) == guard.compute_snapshot_hashes(
        list(reversed(rows))
    )


if __name__ == "__main__":
    test_protected_target_contract_is_shared_with_replay()
    test_guard_accepts_exact_protected_snapshot()
    test_guard_blocks_wrong_postgres_deck()
    test_guard_blocks_nonuniform_snapshot_hash()
    test_guard_blocks_partially_missing_snapshot_hash()
    test_guard_blocks_content_drift_with_stale_hash()
    test_guard_blocks_invalid_snapshot_json_instead_of_hashing_empty_value()
    test_snapshot_hash_order_is_stable_for_duplicate_names()
    print("test_battle_target_deck_identity_guard.py: ok")
