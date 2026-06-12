#!/usr/bin/env python3
"""Tests for slot_optimizer real role aggregation."""

from __future__ import annotations

import sqlite3
import unittest

import slot_optimizer


class SlotOptimizerRealRolesTests(unittest.TestCase):
    def _conn(self, *, include_pg_roles: bool = True) -> sqlite3.Connection:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
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
        conn.execute(
            """
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_name TEXT,
                functional_tag TEXT,
                functional_tags_json TEXT,
                type_line TEXT
            )
            """
        )
        return conn

    def test_load_real_roles_aggregates_pg_roles_with_stable_priority(self) -> None:
        conn = self._conn()
        conn.executemany(
            """
            INSERT INTO card_deck_analysis
                (deck_id, card_name, role_in_deck, pg_roles)
            VALUES (?,?,?,?)
            """,
            [
                (6, "Flexible Charm", "draw", '["draw","removal"]'),
                (6, "Flexible Charm", "engine", '["engine"]'),
            ],
        )
        conn.execute(
            """
            INSERT INTO deck_cards
                (deck_id, card_name, functional_tag, functional_tags_json, type_line)
            VALUES (?,?,?,?,?)
            """,
            (6, "Flexible Charm", "draw", '["draw"]', "Instant"),
        )

        roles = slot_optimizer.load_real_roles(conn, 6)

        self.assertEqual(roles["flexible charm"], "removal")

    def test_load_real_roles_falls_back_without_pg_roles_column(self) -> None:
        conn = self._conn(include_pg_roles=False)
        conn.execute(
            """
            INSERT INTO card_deck_analysis (deck_id, card_name, role_in_deck)
            VALUES (?,?,?)
            """,
            (6, "Old Analysis", "protection"),
        )

        roles = slot_optimizer.load_real_roles(conn, 6)

        self.assertEqual(roles["old analysis"], "protection")

    def test_load_real_roles_uses_deck_cards_when_analysis_is_missing(self) -> None:
        conn = self._conn()
        conn.execute(
            """
            INSERT INTO deck_cards
                (deck_id, card_name, functional_tag, functional_tags_json, type_line)
            VALUES (?,?,?,?,?)
            """,
            (6, "Snapshot Only", "draw", '["draw","engine"]', "Enchantment"),
        )

        roles = slot_optimizer.load_real_roles(conn, 6)

        self.assertEqual(roles["snapshot only"], "draw")


if __name__ == "__main__":
    unittest.main()
