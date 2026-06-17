#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
AUDIT_PATH = SCRIPT_DIR / "audit_handcrafted_battle_rule_canonicalization.py"
SYNC_PG_PATH = SCRIPT_DIR / "sync_battle_card_rules_pg.py"


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_module(BATTLE_PATH, "battle_for_pg_fallback_test")
audit = load_module(AUDIT_PATH, "audit_for_pg_fallback_test")
sync_pg = load_module(SYNC_PG_PATH, "sync_pg_for_pg_fallback_test")

ADDITIONAL_CANONICAL_NAMES = {
    "Aether Spellbomb",
    "Crop Rotation",
    "Eldrazi Confluence",
    "Emerald Charm",
    "Feed the Swarm",
    "Harrow",
    "Hullbreaker Horror",
    "Momentary Blink",
    "Mox Diamond",
    "Rise of the Eldrazi",
    "Roiling Regrowth",
    "Scour for Scrap",
    "Sink into Stupor",
    "Snap",
    "Snapback",
    "Surge to Victory",
    "Turn to Mist",
}
PROMOTED_CANONICAL_NAMES = sorted(
    set(audit.TEMPORARY_HOTFIX_NAMES) | ADDITIONAL_CANONICAL_NAMES
)


class RuntimePgRuleFallbackForPromotedHotfixesTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.sqlite_db = Path(self._tmp.name) / "knowledge.db"
        if sync_pg.connect is None:
            raise unittest.SkipTest("PostgreSQL helper unavailable for runtime fallback guardrail")
        with sync_pg.connect() as pg_conn:
            with pg_conn.cursor() as cur:
                sync_pg.ensure_pg_table(cur)
                rows = sync_pg.load_pg_rules(cur, include_needs_review=True)
        rows = sync_pg.filter_rows_by_card_names(rows, PROMOTED_CANONICAL_NAMES)
        sync_pg.mirror_pg_rules_to_sqlite(str(self.sqlite_db), rows)
        self._old_db = battle.DB
        battle.DB = str(self.sqlite_db)

    def tearDown(self) -> None:
        battle.DB = self._old_db
        self._tmp.cleanup()

    def test_runtime_no_longer_has_active_handcrafted_inventory(self) -> None:
        self.assertEqual(battle.HANDCRAFTED_KNOWN_CARDS, set())

    def test_canonicalized_overrides_resolve_from_sqlite_without_manual_override(self) -> None:
        for card_name in PROMOTED_CANONICAL_NAMES:
            with self.subTest(card_name=card_name):
                self.assertNotIn(card_name, battle.MANUAL_RULE_RUNTIME_WAIVERS)
                self.assertNotIn(card_name, battle.HANDCRAFTED_KNOWN_CARDS)

                registry_rule = battle.battle_rule_registry.lookup_battle_card_rule(battle.DB, card_name)
                self.assertIsNotNone(registry_rule, msg=f"{card_name} missing from SQLite/PG registry")
                self.assertTrue(registry_rule.get("effect_json"), msg=f"{card_name} registry rule has empty effect_json")

                resolved = battle.get_card_effect({"name": card_name})
                self.assertIn(resolved.get("_rule_source"), {"manual", "curated"})
                self.assertIn(resolved.get("_rule_review_status"), {"verified", "active"})
                self.assertEqual(
                    resolved.get("_rule_logical_key"),
                    registry_rule.get("logical_rule_key"),
                    msg=f"{card_name} did not resolve from SQLite/PG canonical rule",
                )


if __name__ == "__main__":
    unittest.main()
