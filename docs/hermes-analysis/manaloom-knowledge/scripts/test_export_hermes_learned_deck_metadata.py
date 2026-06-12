#!/usr/bin/env python3
"""Tests for Hermes learned deck export metadata aggregation."""

from __future__ import annotations

import sqlite3
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


if __name__ == "__main__":
    unittest.main()
