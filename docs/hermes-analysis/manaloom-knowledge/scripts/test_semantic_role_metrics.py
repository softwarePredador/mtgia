#!/usr/bin/env python3
"""Tests for Hermes multi-role deck metrics."""

from __future__ import annotations

import sqlite3
import unittest

from semantic_role_metrics import load_deck_metric_rows, role_sum, row_role_memberships


class SemanticRoleMetricsTests(unittest.TestCase):
    def _base_schema(self, *, include_multi_tags: bool = True) -> sqlite3.Connection:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        conn.execute(
            """
            CREATE TABLE decks (
                id INTEGER PRIMARY KEY,
                deck_name TEXT,
                commander_id INTEGER,
                archetype TEXT,
                notes TEXT,
                total_lands INTEGER,
                total_cards INTEGER,
                ramp_count INTEGER,
                draw_count INTEGER,
                removal_count INTEGER,
                protection_count INTEGER,
                wincon_count INTEGER
            )
            """
        )
        extra = ", functional_tags_json TEXT" if include_multi_tags else ""
        conn.execute(
            f"""
            CREATE TABLE deck_cards (
                deck_id INTEGER,
                card_name TEXT,
                quantity INTEGER,
                functional_tag TEXT{extra},
                type_line TEXT,
                cmc REAL
            )
            """
        )
        conn.execute(
            """
            INSERT INTO decks
              (id, deck_name, commander_id, archetype, notes, total_lands,
               total_cards, ramp_count, draw_count, removal_count,
               protection_count, wincon_count)
            VALUES (1, 'Semantic Test', 1, 'test', '', 0, 0, 0, 0, 0, 0, 0)
            """
        )
        return conn

    def test_multi_tag_membership_does_not_inflate_deck_cardinality(self) -> None:
        conn = self._base_schema()
        conn.executemany(
            """
            INSERT INTO deck_cards
              (deck_id, card_name, quantity, functional_tag,
               functional_tags_json, type_line, cmc)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (1, "Engine Rock", 1, "ramp", '["ramp", "engine"]', "Artifact", 2),
                (1, "Cantrip", 1, "draw", '["draw"]', "Instant", 1),
                (1, "Plains", 1, "land", '["land"]', "Basic Land — Plains", 0),
            ],
        )

        [deck] = load_deck_metric_rows(conn)

        self.assertEqual(deck["total_cards"], 3)
        self.assertEqual(deck["ramp_tag"], 1)
        self.assertEqual(deck["engine_tag"], 1)
        self.assertEqual(deck["draw_tag"], 1)
        self.assertEqual(deck["lands_tag"], 1)
        self.assertEqual(deck["unknown_tag"], 0)
        self.assertGreater(role_sum(deck), deck["total_cards"])
        conn.close()

    def test_legacy_functional_tag_fallback_still_works(self) -> None:
        conn = self._base_schema(include_multi_tags=False)
        conn.executemany(
            """
            INSERT INTO deck_cards
              (deck_id, card_name, quantity, functional_tag, type_line, cmc)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                (1, "Rock", 1, "ramp", "Artifact", 2),
                (1, "Wrath", 1, "board_wipe", "Sorcery", 4),
            ],
        )

        [deck] = load_deck_metric_rows(conn)

        self.assertEqual(deck["total_cards"], 2)
        self.assertEqual(deck["ramp_tag"], 1)
        self.assertEqual(deck["board_wipe_tag"], 1)
        self.assertEqual(deck["role_metric_source"], "functional_tag_legacy")
        conn.close()

    def test_type_fallback_tags_do_not_hide_unclassified_cards(self) -> None:
        conn = self._base_schema()
        conn.execute(
            """
            INSERT INTO deck_cards
              (deck_id, card_name, quantity, functional_tag,
               functional_tags_json, type_line, cmc)
            VALUES (1, 'Only Artifact', 1, 'artifact', '["artifact"]', 'Artifact', 2)
            """
        )

        row = conn.execute("SELECT * FROM deck_cards").fetchone()

        self.assertEqual(row_role_memberships(row), {"unknown"})
        conn.close()

    def test_extended_tags_do_not_become_core_validator_roles(self) -> None:
        conn = self._base_schema()
        conn.executemany(
            """
            INSERT INTO deck_cards
              (deck_id, card_name, quantity, functional_tag,
               functional_tags_json, type_line, cmc)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (1, "Fixing Land", 1, "land", '["land", "mana_fixing"]', "Land", 0),
                (1, "Payoff Only", 1, "payoff", '["payoff"]', "Enchantment", 3),
            ],
        )

        [deck] = load_deck_metric_rows(conn)

        self.assertEqual(deck["total_cards"], 2)
        self.assertEqual(deck["lands_tag"], 1)
        self.assertEqual(deck["ramp_tag"], 0)
        self.assertEqual(deck["engine_tag"], 0)
        self.assertEqual(deck["unknown_tag"], 1)
        conn.close()


if __name__ == "__main__":
    unittest.main()
