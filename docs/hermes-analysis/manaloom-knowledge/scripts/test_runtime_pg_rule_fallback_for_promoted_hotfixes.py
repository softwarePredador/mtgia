#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from datetime import datetime, timezone
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
    "Aura of Silence",
    "Crop Rotation",
    "Eldrazi Confluence",
    "Emerald Charm",
    "Feed the Swarm",
    "Harrow",
    "Hullbreaker Horror",
    "Momentary Blink",
    "Mox Diamond",
    "Mental Misstep",
    "Nature's Claim",
    "Rise of the Eldrazi",
    "Roiling Regrowth",
    "Scour for Scrap",
    "Seal of Primordium",
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

    def test_runtime_handcrafted_inventory_is_limited_to_explicit_incident_waivers(self) -> None:
        self.assertEqual(
            battle.HANDCRAFTED_KNOWN_CARDS,
            battle.MANUAL_RULE_RUNTIME_WAIVERS,
        )
        self.assertEqual(
            set(battle.MANUAL_RULE_RUNTIME_WAIVER_METADATA),
            battle.MANUAL_RULE_RUNTIME_WAIVERS,
        )
        self.assertTrue(
            battle.HANDCRAFTED_KNOWN_CARDS.isdisjoint(PROMOTED_CANONICAL_NAMES)
        )

    def test_manual_runtime_waivers_have_owner_expiry_and_promotion_target(self) -> None:
        inventory = battle.manual_runtime_waiver_inventory()
        self.assertEqual(
            {entry["card"] for entry in inventory},
            battle.MANUAL_RULE_RUNTIME_WAIVERS,
        )
        for entry in inventory:
            with self.subTest(card=entry["card"]):
                opened_at = datetime.fromisoformat(
                    entry["opened_at_utc"].replace("Z", "+00:00")
                )
                expires_at = datetime.fromisoformat(
                    entry["expires_at_utc"].replace("Z", "+00:00")
                )
                self.assertEqual(entry["owner"], "battle-engine-data-governance")
                self.assertEqual(entry["promotion_target"], "card_battle_rules")
                self.assertEqual(opened_at.tzinfo, timezone.utc)
                self.assertGreater(expires_at, opened_at)
                self.assertLessEqual(opened_at, datetime(2026, 6, 19, 23, 59, 59, tzinfo=timezone.utc))
                self.assertTrue(entry["reason"])
                self.assertTrue(entry["source_runs"])
                self.assertTrue(entry["rule_logical_key"].startswith("battle_rule_v1:"))

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
