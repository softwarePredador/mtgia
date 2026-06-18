#!/usr/bin/env python3
"""Tests for Hermes learned deck export metadata aggregation."""

from __future__ import annotations

import contextlib
import io
import json
import sqlite3
import tempfile
import unittest

import export_hermes_learned_deck as exporter


class ExportHermesLearnedDeckMetadataTests(unittest.TestCase):
    def _conn(self, *, include_pg_roles: bool = True) -> sqlite3.Connection:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_name TEXT,
                type_line TEXT
            )
            """
        )
        pg_roles_column = ", pg_roles TEXT" if include_pg_roles else ""
        conn.execute(
            f"""
            CREATE TABLE card_deck_analysis (
                deck_id INTEGER,
                card_name TEXT,
                role_in_deck TEXT{pg_roles_column}
            )
            """
        )
        return conn

    def test_build_metadata_aggregates_roles_without_join_fanout(self) -> None:
        conn = self._conn()
        conn.executemany(
            "INSERT INTO deck_cards (deck_id, card_name, type_line) VALUES (?,?,?)",
            [
                (6, "Flexible Charm", "Instant"),
                (6, "Plains", "Basic Land — Plains"),
            ],
        )
        conn.executemany(
            """
            INSERT INTO card_deck_analysis
                (deck_id, card_name, role_in_deck, pg_roles)
            VALUES (?,?,?,?)
            """,
            [
                (6, "Flexible Charm", "draw", '["draw","removal"]'),
                (6, "Flexible Charm", "removal", '["removal","engine"]'),
            ],
        )

        metadata = exporter.build_metadata(
            conn,
            6,
            "1 Flexible Charm\n1 Plains",
            "Lorehold, the Historian",
        )

        self.assertEqual(metadata["total_lands"], 1)
        self.assertEqual(metadata["draw_count"], 1)
        self.assertEqual(metadata["removal_count"], 1)
        self.assertEqual(metadata["engine_count"], 1)

    def test_build_metadata_falls_back_when_pg_roles_column_is_missing(self) -> None:
        conn = self._conn(include_pg_roles=False)
        conn.execute(
            "INSERT INTO deck_cards (deck_id, card_name, type_line) VALUES (?,?,?)",
            (6, "Single Role Spell", "Instant"),
        )
        conn.execute(
            """
            INSERT INTO card_deck_analysis (deck_id, card_name, role_in_deck)
            VALUES (?,?,?)
            """,
            (6, "Single Role Spell", "protection"),
        )

        metadata = exporter.build_metadata(
            conn,
            6,
            "1 Single Role Spell",
            "Lorehold, the Historian",
        )

        self.assertEqual(metadata["protection_count"], 1)

    def test_export_prefers_card_list_over_stale_decks_summary(self) -> None:
        with tempfile.NamedTemporaryFile(suffix=".db") as tmp:
            conn = sqlite3.connect(tmp.name)
            conn.row_factory = sqlite3.Row
            try:
                conn.execute(
                    """
                    CREATE TABLE learned_decks (
                        id INTEGER PRIMARY KEY,
                        commander TEXT,
                        deck_name TEXT,
                        source TEXT,
                        source_url TEXT,
                        archetype TEXT,
                        notes TEXT,
                        card_list TEXT,
                        card_count INTEGER,
                        wincon_primary TEXT,
                        wincon_backup TEXT
                    )
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE deck_promotions (
                        id INTEGER PRIMARY KEY,
                        learned_deck_id INTEGER,
                        promoted_at TEXT,
                        target_deck_id INTEGER,
                        migration_verified INTEGER DEFAULT 1
                    )
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE decks (
                        id INTEGER PRIMARY KEY,
                        deck_name TEXT,
                        total_cards INTEGER,
                        total_lands INTEGER,
                        ramp_count INTEGER,
                        draw_count INTEGER,
                        removal_count INTEGER,
                        tutor_count INTEGER,
                        board_wipe_count INTEGER,
                        protection_count INTEGER,
                        recursion_count INTEGER,
                        wincon_count INTEGER,
                        engine_count INTEGER
                    )
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE deck_cards (
                        deck_id INTEGER,
                        card_name TEXT,
                        type_line TEXT
                    )
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE card_deck_analysis (
                        deck_id INTEGER,
                        card_name TEXT,
                        role_in_deck TEXT,
                        pg_roles TEXT
                    )
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE wincon_catalog (
                        wincon_name TEXT,
                        total_score REAL
                    )
                    """
                )

                filler_cards = "\n".join(
                    f"1 Filler Card {index}" for index in range(97)
                )
                conn.execute(
                    """
                    INSERT INTO learned_decks (
                        id, commander, deck_name, source, source_url, archetype,
                        notes, card_list, card_count, wincon_primary, wincon_backup
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        82,
                        "Lorehold, the Historian",
                        "Lorehold Learned",
                        "hermes",
                        "manual-import:test",
                        "spells",
                        "test row",
                        f"1 Lorehold, the Historian\n1 Plains\n1 Sol Ring\n{filler_cards}",
                        100,
                        "Approach of the Second Sun",
                        None,
                    ),
                )
                conn.execute(
                    """
                    INSERT INTO deck_promotions (
                        learned_deck_id, promoted_at, target_deck_id, migration_verified
                    ) VALUES (?, ?, ?, ?)
                    """,
                    (82, "2026-06-18T00:00:00Z", 6, 1),
                )
                conn.execute(
                    """
                    INSERT INTO decks (
                        id, deck_name, total_cards, total_lands, ramp_count,
                        draw_count, removal_count, tutor_count, board_wipe_count,
                        protection_count, recursion_count, wincon_count, engine_count
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        6,
                        "Stale Deck Summary",
                        100,
                        33,
                        7,
                        9,
                        8,
                        6,
                        4,
                        3,
                        2,
                        5,
                        4,
                    ),
                )
                conn.executemany(
                    "INSERT INTO deck_cards (deck_id, card_name, type_line) VALUES (?,?,?)",
                    [
                        (6, "Plains", "Basic Land — Plains"),
                        (6, "Sol Ring", "Artifact"),
                    ],
                )
                conn.execute(
                    """
                    INSERT INTO card_deck_analysis (
                        deck_id, card_name, role_in_deck, pg_roles
                    ) VALUES (?, ?, ?, ?)
                    """,
                    (6, "Sol Ring", "ramp", '["ramp"]'),
                )
                conn.execute(
                    "INSERT INTO wincon_catalog (wincon_name, total_score) VALUES (?, ?)",
                    ("Approach of the Second Sun", 100.0),
                )
                conn.commit()
            finally:
                conn.close()

            buffer = io.StringIO()
            with contextlib.redirect_stdout(buffer):
                exporter.export_learned_deck(
                    tmp.name,
                    None,
                    learned_id=82,
                    dry_run=True,
                )

            payload = json.loads(buffer.getvalue())
            self.assertEqual(payload["metadata"]["total_lands"], 1)
            self.assertEqual(payload["metadata"]["ramp_count"], 1)
            self.assertEqual(payload["metadata"]["draw_count"], 0)


if __name__ == "__main__":
    unittest.main()
