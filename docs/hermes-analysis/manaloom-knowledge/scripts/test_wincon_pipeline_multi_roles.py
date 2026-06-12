#!/usr/bin/env python3
"""Tests for wincon pipeline multi-role compatibility."""

from __future__ import annotations

import sqlite3
import unittest

import wincon_pipeline


class WinconPipelineMultiRoleTests(unittest.TestCase):
    def _conn(self, *, include_pg_roles: bool = True) -> sqlite3.Connection:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        conn.execute(
            """
            CREATE TABLE learned_decks (
                id INTEGER PRIMARY KEY,
                commander TEXT
            )
            """
        )
        pg_roles_column = ", pg_roles TEXT" if include_pg_roles else ""
        conn.execute(
            f"""
            CREATE TABLE card_deck_analysis (
                deck_id INTEGER,
                card_name TEXT,
                role_in_deck TEXT,
                enriched INTEGER,
                speed_score INTEGER,
                resilience_score INTEGER,
                stealth_score INTEGER,
                wincon_total_score INTEGER{pg_roles_column}
            )
            """
        )
        conn.execute(
            "INSERT INTO learned_decks (id, commander) VALUES (?, ?)",
            (82, "Lorehold, the Historian"),
        )
        return conn

    def test_score_for_card_uses_pg_roles_wincon_membership(self) -> None:
        conn = self._conn()
        conn.execute(
            """
            INSERT INTO card_deck_analysis (
                deck_id, card_name, role_in_deck, enriched,
                speed_score, resilience_score, stealth_score, wincon_total_score,
                pg_roles
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (82, "Guttersnipe", "engine", 1, 6, 5, 8, 19, '["engine","wincon"]'),
        )

        self.assertEqual(wincon_pipeline.score_for_card(conn, "Guttersnipe"), (6, 5, 8, 19))

    def test_score_for_card_falls_back_to_role_in_deck_without_pg_roles(self) -> None:
        conn = self._conn(include_pg_roles=False)
        conn.execute(
            """
            INSERT INTO card_deck_analysis (
                deck_id, card_name, role_in_deck, enriched,
                speed_score, resilience_score, stealth_score, wincon_total_score
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (82, "Approach of the Second Sun", "wincon", 1, 5, 6, 2, 13),
        )

        self.assertEqual(
            wincon_pipeline.score_for_card(conn, "Approach of the Second Sun"),
            (5, 6, 2, 13),
        )


if __name__ == "__main__":
    unittest.main()
