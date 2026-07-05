#!/usr/bin/env python3
"""Tests for global Commander core role audit."""

from __future__ import annotations

import sqlite3
import unittest
from pathlib import Path

import global_commander_core_role_audit as audit


class GlobalCommanderCoreRoleAuditTests(unittest.TestCase):
    def test_card_roles_use_tags_and_text_without_losing_multi_role(self) -> None:
        row = {
            "functional_tag": "ramp",
            "functional_tags_json": '["ramp", "engine"]',
            "type_line": "Artifact",
            "oracle_text": "Whenever you cast an instant or sorcery spell, draw a card.",
        }

        roles, source = audit.card_roles(row)

        self.assertEqual(source, "tag_plus_text")
        self.assertIn("ramp", roles)
        self.assertIn("engine", roles)
        self.assertIn("draw", roles)

    def test_oracle_text_infers_roles_for_untagged_lab_cards(self) -> None:
        row = {
            "functional_tag": "",
            "functional_tags_json": "[]",
            "type_line": "Instant",
            "oracle_text": "Counter target spell. Draw a card.",
        }

        roles, source = audit.card_roles(row)

        self.assertEqual(source, "text_inferred")
        self.assertEqual(roles, {"draw", "removal"})

    def test_lands_that_tap_for_mana_do_not_count_as_ramp(self) -> None:
        row = {
            "functional_tag": "",
            "functional_tags_json": "[]",
            "type_line": "Land",
            "oracle_text": "{T}: Add one mana of any color in your commander's color identity.",
        }

        roles, source = audit.card_roles(row)

        self.assertEqual(source, "text_inferred")
        self.assertEqual(roles, {"land"})

    def test_numeric_damage_to_each_infers_board_wipe(self) -> None:
        row = {
            "functional_tag": "",
            "functional_tags_json": "[]",
            "type_line": "Sorcery",
            "oracle_text": "This spell deals 3 damage to each creature.",
        }

        roles, source = audit.card_roles(row)

        self.assertEqual(source, "text_inferred")
        self.assertIn("board_wipe", roles)

    def test_common_commander_oracle_patterns_reduce_unknown_roles(self) -> None:
        cases = [
            (
                "Dark Ritual",
                "Instant",
                "Add {B}{B}{B}.",
                {"ramp"},
            ),
            (
                "Windfall",
                "Sorcery",
                "Each player discards their hand, then draws cards equal to the greatest number discarded.",
                {"draw"},
            ),
            (
                "Dark Deal",
                "Sorcery",
                "Each player discards all the cards in their hand, then draws that many cards minus one.",
                {"draw"},
            ),
            (
                "Swan Song",
                "Instant",
                "Counter target enchantment, instant, or sorcery spell.",
                {"removal"},
            ),
            (
                "Lightning Greaves",
                "Artifact — Equipment",
                "Equipped creature has haste and shroud.",
                {"protection"},
            ),
            (
                "Animate Dead",
                "Enchantment — Aura",
                "Return enchanted creature card to the battlefield under your control.",
                {"recursion"},
            ),
            (
                "Karn's Sylex",
                "Legendary Artifact",
                "Exile Karn's Sylex: Destroy each nonland permanent with mana value X or less.",
                {"board_wipe"},
            ),
            (
                "Kayla's Music Box",
                "Legendary Artifact",
                "Until end of turn, you may play cards you own exiled with Kayla's Music Box.",
                {"draw"},
            ),
            (
                "Zirda, the Dawnwaker",
                "Legendary Creature — Elemental Fox",
                "Abilities you activate that aren't mana abilities cost {2} less to activate.",
                {"engine"},
            ),
        ]

        for name, type_line, oracle_text, expected_roles in cases:
            with self.subTest(name=name):
                roles, source = audit.card_roles(
                    {
                        "functional_tag": "",
                        "functional_tags_json": "[]",
                        "type_line": type_line,
                        "oracle_text": oracle_text,
                    }
                )

                self.assertEqual(source, "text_inferred")
                self.assertTrue(expected_roles.issubset(roles))

    def test_build_report_marks_role_data_incomplete_before_strategy_matrix(self) -> None:
        card_rows = []
        for index in range(35):
            card_rows.append(
                {
                    "deck_id": "607",
                    "card_name": f"Land {index}",
                    "quantity": 1,
                    "functional_tag": "land",
                    "functional_tags_json": '["land"]',
                    "type_line": "Land",
                    "oracle_text": "{T}: Add {R}.",
                }
            )
        for index in range(50):
            card_rows.append(
                {
                    "deck_id": "607",
                    "card_name": f"Unknown {index}",
                    "quantity": 1,
                    "functional_tag": "",
                    "functional_tags_json": "[]",
                    "type_line": "Artifact",
                    "oracle_text": "",
                }
            )
        for index in range(15):
            card_rows.append(
                {
                    "deck_id": "607",
                    "card_name": f"Draw {index}",
                    "quantity": 1,
                    "functional_tag": "draw",
                    "functional_tags_json": '["draw"]',
                    "type_line": "Sorcery",
                    "oracle_text": "Draw a card.",
                }
            )

        role_by_deck = audit.role_counts_by_deck(card_rows)
        counts = role_by_deck["607"]["role_counts"]
        role_rows = [audit.band_status(role, int(counts.get(role) or 0)) for role in audit.ROLE_ORDER]
        status = audit.deck_core_status(
            shape_status="structure_ready",
            total_cards=100,
            role_rows=role_rows,
            unknown_count=int(counts["unknown"]),
        )

        self.assertEqual(status, "role_data_incomplete")
        self.assertEqual(counts["unknown"], 50)

    def test_core_repair_plan_prioritizes_critical_floor_before_excess_review(self) -> None:
        role_rows = [
            audit.band_status("land", 32),
            audit.band_status("ramp", 18),
            audit.band_status("draw", 12),
            audit.band_status("removal", 5),
        ]

        plan = audit.core_repair_plan(role_rows, unknown_count=3)

        self.assertEqual(plan["first_action"], "fill_critical_role_floor")
        self.assertEqual(
            [(row["role"], row["missing"]) for row in plan["missing_role_slots"]],
            [("land", 2), ("removal", 1)],
        )
        self.assertEqual(
            [(row["role"], row["excess"]) for row in plan["excess_role_slots"]],
            [("ramp", 2)],
        )
        self.assertIn("not_auto_cuts", plan["mutation_policy"])

    def test_sqlite_report_routes_core_gap(self) -> None:
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        conn.execute("CREATE TABLE decks (id INTEGER PRIMARY KEY, deck_name TEXT, archetype TEXT)")
        conn.execute(
            """
            CREATE TABLE deck_cards (
              deck_id INTEGER,
              card_name TEXT,
              quantity INTEGER,
              functional_tag TEXT,
              functional_tags_json TEXT,
              type_line TEXT,
              oracle_text TEXT,
              is_commander INTEGER DEFAULT 0
            )
            """
        )
        conn.execute("INSERT INTO decks (id, deck_name, archetype) VALUES (607, 'VARIANT Lorehold', 'spells')")
        rows = []
        rows.append((607, "Lorehold, the Historian", 1, "engine", '["engine"]', "Legendary Creature", "Whenever you cast.", 1))
        for index in range(34):
            rows.append((607, f"Land {index}", 1, "land", '["land"]', "Land", "{T}: Add {R}.", 0))
        for index in range(65):
            rows.append((607, f"Ramp {index}", 1, "ramp", '["ramp"]', "Artifact", "{T}: Add one mana.", 0))
        conn.executemany(
            """
            INSERT INTO deck_cards (
              deck_id, card_name, quantity, functional_tag, functional_tags_json,
              type_line, oracle_text, is_commander
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            rows,
        )

        role_by_deck = audit.role_counts_by_deck(audit.load_role_rows(conn))
        counts = role_by_deck["607"]["role_counts"]
        role_rows = [audit.band_status(role, int(counts.get(role) or 0)) for role in audit.ROLE_ORDER]
        status = audit.deck_core_status(
            shape_status="structure_ready",
            total_cards=100,
            role_rows=role_rows,
            unknown_count=int(counts["unknown"]),
        )

        self.assertEqual(status, "core_role_gap")
        self.assertIn("repair_core_role_floor", audit.next_gate(status))
        conn.close()


if __name__ == "__main__":
    unittest.main()
