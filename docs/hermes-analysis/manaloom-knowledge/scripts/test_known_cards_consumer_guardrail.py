#!/usr/bin/env python3
"""Guardrails for active consumers of legacy known-cards fallback assets.

The canonical runtime order is:
1. battle_card_rules / SQLite / PostgreSQL-backed registry
2. known_cards_canonical_snapshot.json
3. known_cards_generated.json only as last legacy fallback

This test prevents new active consumers from quietly treating the legacy JSON
as primary truth again.
"""

from __future__ import annotations

import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]

ACTIVE_LAYERED_CONSUMERS = {
    SCRIPT_DIR / "slot_optimizer.py",
    SCRIPT_DIR / "universal_optimizer.py",
    SCRIPT_DIR / "battle_effect_coverage_audit.py",
    SCRIPT_DIR / "sync_pg_card_metadata_to_hermes.py",
}

ALLOWED_DIRECT_REFERENCES = {
    SCRIPT_DIR / "battle_analyst_v9.py",
    SCRIPT_DIR / "known_cards_fallback_snapshot.py",
    SCRIPT_DIR / "generate_known_cards.py",
    SCRIPT_DIR / "kc_validator.py",
    SCRIPT_DIR / "sync_battle_card_rules.py",
    SCRIPT_DIR / "audit_known_cards_runtime_environment.py",
    SCRIPT_DIR / "audit_known_cards_runtime_fallback.py",
}

ALLOWED_HISTORICAL_OR_TEST = {
    SCRIPT_DIR / "battle_analyst_v6.py",
    SCRIPT_DIR / "battle_analyst_v7.py",
    SCRIPT_DIR / "battle_analyst_v8.py",
}


def repo_rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


class KnownCardsConsumerGuardrailTests(unittest.TestCase):
    def test_active_layered_consumers_use_canonical_loader(self) -> None:
        for path in sorted(ACTIVE_LAYERED_CONSUMERS):
            source = path.read_text(encoding="utf-8")
            self.assertIn(
                "load_layered_known_cards",
                source,
                msg=f"{repo_rel(path)} must use load_layered_known_cards()",
            )

    def test_battle_runtime_keeps_registry_then_snapshot_then_legacy_order(self) -> None:
        path = SCRIPT_DIR / "battle_analyst_v9.py"
        source = path.read_text(encoding="utf-8")
        registry_idx = source.index("battle_rule_registry.lookup_battle_card_rule")
        handcrafted_idx = source.index("if name in HANDCRAFTED_KNOWN_CARDS")
        canonical_idx = source.index("if name in CANONICAL_FALLBACK_KNOWN_CARDS")
        legacy_idx = source.index('source="known_cards_generated"')
        self.assertLess(registry_idx, handcrafted_idx)
        self.assertLess(handcrafted_idx, canonical_idx)
        self.assertLess(canonical_idx, legacy_idx)

    def test_no_unclassified_active_python_consumer_reads_legacy_json(self) -> None:
        candidates = list((SCRIPT_DIR).glob("*.py")) + list((REPO_ROOT / "server" / "bin").glob("*.py"))
        unexpected: list[str] = []
        for path in candidates:
            if path.name.startswith("test_"):
                continue
            if path in ACTIVE_LAYERED_CONSUMERS:
                continue
            if path in ALLOWED_DIRECT_REFERENCES:
                continue
            if path in ALLOWED_HISTORICAL_OR_TEST:
                continue
            try:
                source = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if "known_cards_generated.json" in source:
                unexpected.append(repo_rel(path))

        self.assertEqual(
            unexpected,
            [],
            msg=(
                "Unexpected active consumers reference known_cards_generated.json "
                "without explicit guardrail classification: "
                + ", ".join(unexpected)
            ),
        )


if __name__ == "__main__":
    unittest.main()
