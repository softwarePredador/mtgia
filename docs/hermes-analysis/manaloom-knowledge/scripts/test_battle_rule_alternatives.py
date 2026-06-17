#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import random
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"


def load_battle_module():
    spec = importlib.util.spec_from_file_location(
        "battle_for_rule_alternatives_test",
        BATTLE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_battle_module()


class BattleRuleAlternativesTests(unittest.TestCase):
    def test_runtime_effect_exposes_alternative_rules_for_multi_rule_card(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                battle.battle_rule_registry.ensure_battle_card_rules(conn)
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "draw_cards", "amount": 2},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Modal Test Card",
                    {"effect": "remove_creature", "target": "creature"},
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                conn.commit()
            old_db = battle.DB
            try:
                battle.DB = str(sqlite_db)
                resolved = battle.get_card_effect(
                    {
                        "name": "Modal Test Card",
                        "type_line": "Instant",
                        "oracle_text": "",
                    }
                )
            finally:
                battle.DB = old_db

        alternatives = resolved.get("_rule_alternatives")
        self.assertEqual(resolved.get("_rule_source"), "curated")
        self.assertIsInstance(alternatives, list)
        self.assertEqual(len(alternatives), 2)
        self.assertEqual(
            {item["effect"] for item in alternatives},
            {"draw_cards", "remove_creature"},
        )
        self.assertEqual(
            battle.replay_rule_fields(resolved).get("rule_alternative_count"),
            2,
        )

    def test_runtime_composes_opt_in_resolution_rules(self) -> None:
        events: list[tuple[str, dict]] = []
        with tempfile.TemporaryDirectory() as tmpdir:
            sqlite_db = Path(tmpdir) / "knowledge.db"
            with closing(sqlite3.connect(sqlite_db)) as conn:
                battle.battle_rule_registry.ensure_battle_card_rules(conn)
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Composite Test Spell",
                    {
                        "effect": "draw_cards",
                        "count": 1,
                        "compose_on_resolution": True,
                    },
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                battle.battle_rule_registry.upsert_battle_card_rule(
                    conn,
                    "Composite Test Spell",
                    {
                        "effect": "remove_creature",
                        "target": "creature",
                        "compose_on_resolution": True,
                    },
                    source="curated",
                    confidence=0.95,
                    review_status="verified",
                )
                conn.commit()

            old_db = battle.DB
            old_handler = battle.REPLAY_EVENT_HANDLER
            try:
                battle.DB = str(sqlite_db)
                battle.REPLAY_EVENT_HANDLER = lambda event, data: events.append((event, data))
                player = battle.Player(
                    "Tester",
                    None,
                    [{"name": "Drawn Card", "type_line": "Instant", "cmc": 1}],
                )
                opponent = battle.Player("Opponent", None, [])
                opponent.battlefield.append(
                    {
                        "name": "Target Creature",
                        "type_line": "Creature",
                        "effect": "creature",
                        "power": 2,
                        "toughness": 2,
                    }
                )
                spell = {
                    "name": "Composite Test Spell",
                    "type_line": "Sorcery",
                    "oracle_text": "",
                    "cmc": 2,
                }

                resolved = battle.get_card_effect(spell)
                self.assertEqual(resolved.get("effect"), "composite_resolution")
                self.assertEqual(
                    battle.replay_rule_fields(resolved).get("composite_rule_component_count"),
                    2,
                )

                battle.apply_effect_immediate(
                    player,
                    [opponent],
                    spell,
                    turn=1,
                    rng=random.Random(7),
                )
            finally:
                battle.DB = old_db
                battle.REPLAY_EVENT_HANDLER = old_handler

        self.assertEqual([card["name"] for card in player.hand], ["Drawn Card"])
        self.assertEqual(opponent.battlefield, [])
        self.assertEqual([card["name"] for card in opponent.graveyard], ["Target Creature"])
        self.assertEqual(
            len([event for event, _ in events if event == "composite_rule_component_resolved"]),
            2,
        )
        self.assertTrue(any(event == "composite_rule_resolved" for event, _ in events))


if __name__ == "__main__":
    unittest.main()
