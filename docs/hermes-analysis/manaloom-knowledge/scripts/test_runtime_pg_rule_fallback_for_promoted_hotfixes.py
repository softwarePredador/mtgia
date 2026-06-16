#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
BATTLE_PATH = SCRIPT_DIR / "battle_analyst_v9.py"
AUDIT_PATH = SCRIPT_DIR / "audit_handcrafted_battle_rule_canonicalization.py"


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


battle = load_module(BATTLE_PATH, "battle_for_pg_fallback_test")
audit = load_module(AUDIT_PATH, "audit_for_pg_fallback_test")

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


class RuntimePgRuleFallbackForPromotedHotfixesTests(unittest.TestCase):
    def test_runtime_no_longer_has_active_handcrafted_inventory(self) -> None:
        self.assertEqual(battle.HANDCRAFTED_KNOWN_CARDS, set())

    def test_canonicalized_overrides_resolve_from_sqlite_without_manual_override(self) -> None:
        promoted = sorted(set(audit.TEMPORARY_HOTFIX_NAMES) | ADDITIONAL_CANONICAL_NAMES)
        for card_name in promoted:
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
