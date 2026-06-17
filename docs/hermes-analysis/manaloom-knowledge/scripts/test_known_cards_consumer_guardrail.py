#!/usr/bin/env python3
"""Guardrails for active consumers of legacy known-cards fallback assets.

The canonical runtime order is:
1. battle_card_rules / SQLite / PostgreSQL-backed registry
2. known_cards_canonical_snapshot.json
3. explicit functional/effect/type heuristics

This test prevents active battle runtime from quietly treating the legacy JSON
as executable truth again.
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

FORBIDDEN_LEGACY_ENGINES = {
    SCRIPT_DIR / "battle_analyst.py",
    SCRIPT_DIR / "battle_analyst_v6.py",
    SCRIPT_DIR / "battle_analyst_v7.py",
    SCRIPT_DIR / "battle_analyst_v8.py",
}

FORBIDDEN_LEGACY_PATCHER_DIR = REPO_ROOT / "server" / "bin" / "legacy" / "hermes_battle_patchers"

FORBIDDEN_ONE_SHOT_RULE_PATCHERS = {
    SCRIPT_DIR / "_mulligan_exec15.py",
    SCRIPT_DIR / "_prepend_mulligan.py",
    SCRIPT_DIR / "compare_snapshots.py",
    SCRIPT_DIR / "debug_card_list.py",
    SCRIPT_DIR / "find_dina_profile.py",
    SCRIPT_DIR / "find_thassa.py",
    SCRIPT_DIR / "seed_cyclonic_rift.py",
    SCRIPT_DIR / "update_ad_nauseam.py",
    SCRIPT_DIR / "update_ad_nauseam_real_sources.py",
    SCRIPT_DIR / "update_ancient_tomb.py",
    SCRIPT_DIR / "update_cyclonic_rift.py",
    SCRIPT_DIR / "update_cyclonic_rift_20260527.py",
    SCRIPT_DIR / "update_index.py",
    SCRIPT_DIR / "update_index2.py",
    SCRIPT_DIR / "update_log.py",
    SCRIPT_DIR / "update_rhystic_study.py",
    SCRIPT_DIR / "update_smothering_tithe.py",
    SCRIPT_DIR / "update_thassa_oracle.py",
    SCRIPT_DIR / "update_thassa_oracle2.py",
    SCRIPT_DIR / "update_thassa_oracle_20260527.py",
    SCRIPT_DIR / "update_underworld_breach.py",
    SCRIPT_DIR / "verify_thassa_update.py",
    SCRIPT_DIR / "verify_update.py",
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
            self.assertNotIn(
                "generated_path=",
                source,
                msg=f"{repo_rel(path)} must not opt into generated known-cards fallback",
            )
            self.assertNotIn(
                "include_generated=True",
                source,
                msg=f"{repo_rel(path)} must not opt into generated known-cards fallback",
            )
            self.assertNotIn(
                "MANALOOM_KNOWN_CARDS_JSON",
                source,
                msg=f"{repo_rel(path)} must not read generated known-cards env",
            )

    def test_battle_runtime_keeps_registry_then_snapshot_and_no_legacy_generated(self) -> None:
        path = SCRIPT_DIR / "battle_analyst_v9.py"
        source = path.read_text(encoding="utf-8")
        registry_idx = source.index("battle_rule_registry.lookup_battle_card_rule")
        handcrafted_idx = source.index("if name in HANDCRAFTED_KNOWN_CARDS")
        canonical_idx = source.index("if name in CANONICAL_FALLBACK_KNOWN_CARDS")
        functional_idx = source.index("for tag in card_functional_tags(card):")
        self.assertLess(registry_idx, handcrafted_idx)
        self.assertLess(handcrafted_idx, canonical_idx)
        self.assertLess(canonical_idx, functional_idx)
        self.assertNotIn('source="known_cards_generated"', source)
        self.assertNotIn("MANALOOM_KNOWN_CARDS_JSON", source)

    def test_battle_runtime_does_not_embed_manual_known_cards_snapshot(self) -> None:
        path = SCRIPT_DIR / "battle_analyst_v9.py"
        source = path.read_text(encoding="utf-8")
        self.assertIn("KNOWN_CARDS = {}", source)
        self.assertNotIn("\"Teferi's Protection\":", source)
        self.assertNotIn('"Sol Ring": {"effect": "ramp_permanent"', source)

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

    def test_legacy_battle_engines_and_patchers_are_not_restored(self) -> None:
        restored = [repo_rel(path) for path in sorted(FORBIDDEN_LEGACY_ENGINES) if path.exists()]
        restored += [
            repo_rel(path)
            for path in sorted(FORBIDDEN_ONE_SHOT_RULE_PATCHERS)
            if path.exists()
        ]
        if FORBIDDEN_LEGACY_PATCHER_DIR.exists():
            restored.append(repo_rel(FORBIDDEN_LEGACY_PATCHER_DIR))

        self.assertEqual(
            restored,
            [],
            msg=(
                "Legacy battle engines, v8 patchers or one-shot card rule "
                "patchers were restored into the operational tree. Use "
                "battle_analyst_v9.py, reviewed_battle_card_rules.json, "
                "sync_battle_card_rules*.py and focused tests instead: "
                + ", ".join(restored)
            ),
        )


if __name__ == "__main__":
    unittest.main()
