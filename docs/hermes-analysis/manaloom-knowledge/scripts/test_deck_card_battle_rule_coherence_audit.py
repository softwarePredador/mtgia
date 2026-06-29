#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "deck_card_battle_rule_coherence_audit.py"


def load_module():
    spec = importlib.util.spec_from_file_location("deck_card_battle_rule_coherence_audit", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


audit = load_module()


def create_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE deck_cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deck_id INTEGER,
            card_name TEXT NOT NULL,
            quantity INTEGER DEFAULT 1,
            is_commander INTEGER DEFAULT 0,
            type_line TEXT,
            oracle_text TEXT,
            battle_rules_json TEXT DEFAULT '[]'
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            mana_cost TEXT,
            colors_json TEXT,
            color_identity_json TEXT,
            type_line TEXT,
            oracle_text TEXT,
            cmc REAL,
            power TEXT,
            toughness TEXT,
            keywords_json TEXT,
            scryfall_id TEXT,
            source TEXT NOT NULL DEFAULT 'postgres_cards',
            updated_at TEXT NOT NULL
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE battle_card_rules (
            normalized_name TEXT NOT NULL,
            logical_rule_key TEXT NOT NULL,
            card_name TEXT NOT NULL,
            effect_json TEXT NOT NULL DEFAULT '{}',
            deck_role_json TEXT NOT NULL DEFAULT '{}',
            source TEXT NOT NULL DEFAULT 'curated',
            confidence REAL NOT NULL DEFAULT 1.0,
            review_status TEXT NOT NULL DEFAULT 'verified',
            execution_status TEXT NOT NULL DEFAULT 'auto',
            rule_version INTEGER NOT NULL DEFAULT 1,
            oracle_hash TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            last_seen_at TEXT,
            PRIMARY KEY (normalized_name, logical_rule_key)
        )
        """
    )


def insert_deck_card(
    conn: sqlite3.Connection,
    name: str,
    oracle_text: str = "text",
    type_line: str = "Instant",
    deck_id: int = 6,
) -> None:
    conn.execute(
        """
        INSERT INTO deck_cards (deck_id, card_name, quantity, type_line, oracle_text)
        VALUES (?, ?, 1, ?, ?)
        """,
        (deck_id, name, type_line, oracle_text),
    )
    conn.execute(
        """
        INSERT INTO card_oracle_cache (
            normalized_name, name, type_line, oracle_text, updated_at
        ) VALUES (?, ?, ?, ?, '2026-06-22T00:00:00Z')
        """,
        (audit.normalize_name(name), name, type_line, oracle_text),
    )


def insert_rule(
    conn: sqlite3.Connection,
    name: str,
    effect_json: dict,
    *,
    review_status: str = "verified",
    execution_status: str = "auto",
    source: str = "curated",
    oracle_hash: str = "hash",
    logical_rule_key: str | None = None,
) -> None:
    conn.execute(
        """
        INSERT INTO battle_card_rules (
            normalized_name, logical_rule_key, card_name, effect_json,
            deck_role_json, source, confidence, review_status, execution_status,
            oracle_hash, created_at, updated_at
        ) VALUES (?, ?, ?, ?, '{}', ?, 1.0, ?, ?, ?, 'now', 'now')
        """,
        (
            audit.normalize_name(name),
            logical_rule_key
            or "battle_rule_v1:" + audit.normalize_name(name).replace(" ", "_"),
            name,
            json.dumps(effect_json, sort_keys=True),
            source,
            review_status,
            execution_status,
            oracle_hash,
        ),
    )


class DeckCardBattleRuleCoherenceAuditTest(unittest.TestCase):
    def test_mdfc_front_face_uses_oracle_cache_and_rule_aliases(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(
                    conn,
                    "Sink into Stupor",
                    oracle_text="Return target spell or nonland permanent an opponent controls to its owner's hand.",
                    type_line="Instant",
                )
                conn.execute("DELETE FROM card_oracle_cache WHERE normalized_name = ?", ("sink into stupor",))
                conn.execute(
                    """
                    INSERT INTO card_oracle_cache (
                        normalized_name, name, type_line, oracle_text, updated_at
                    ) VALUES (?, ?, ?, ?, '2026-06-22T00:00:00Z')
                    """,
                    (
                        "sink into stupor // soporific springs",
                        "Sink into Stupor // Soporific Springs",
                        "Instant // Land",
                        "Return target spell or nonland permanent an opponent controls to its owner's hand.",
                    ),
                )
                insert_rule(
                    conn,
                    "Sink into Stupor // Soporific Springs",
                    {
                        "effect": "bounce",
                        "battle_model_scope": "return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1",
                    },
                )

                oracle_cache = audit.load_oracle_cache(conn)
                battle_rules = audit.load_battle_rules(conn)
                report = audit.build_report(conn)

        self.assertIn("sink into stupor", oracle_cache)
        self.assertIn("sink into stupor", battle_rules)
        self.assertEqual(report["cards"][0]["severity"], "pass")

    def test_mdfc_full_name_uses_front_face_canonical_rule_alias(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(
                    conn,
                    "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                    oracle_text="Whenever you cast a spell, add {R}.",
                    type_line="Legendary Creature // Legendary Artifact",
                )
                conn.execute(
                    """
                    INSERT INTO battle_card_rules (
                        normalized_name, logical_rule_key, card_name, effect_json,
                        deck_role_json, source, confidence, review_status,
                        execution_status, oracle_hash, notes, created_at, updated_at, last_seen_at
                    ) VALUES (?, ?, ?, ?, ?, 'curated', 0.94, 'verified', 'auto', 'hash', '', '2026-06-29T00:00:00Z', '2026-06-29T00:00:00Z', '2026-06-29T00:00:00Z')
                    """,
                    (
                        "birgi, god of storytelling",
                        "pg-short-key",
                        "Birgi, God of Storytelling // Harnfel, Horn of Bounty",
                        json.dumps(
                            {
                                "effect": "ramp_engine",
                                "battle_model_scope": "spell_cast_red_mana_trigger_boast_harnfel_annotation_v1",
                            },
                            sort_keys=True,
                        ),
                        json.dumps({"category": "ramp", "effect": "ramp_engine"}, sort_keys=True),
                    ),
                )
                battle_rules = audit.load_battle_rules(conn)
                report = audit.build_report(conn)

        full_name = "birgi, god of storytelling // harnfel, horn of bounty"
        self.assertIn(full_name, battle_rules)
        self.assertEqual(report["cards"][0]["severity"], "pass")

    def test_exact_scoped_rule_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(conn, "The One Ring", oracle_text="When The One Ring enters...")
                insert_rule(
                    conn,
                    "The One Ring",
                    {
                        "effect": "draw_engine",
                        "battle_model_scope": "the_one_ring_etb_protection_burden_draw_v1",
                    },
                )
                report = audit.build_report(conn)

        self.assertEqual(report["severity_counts"], {"pass": 1})
        self.assertEqual(report["cards"][0]["severity"], "pass")

    def test_generic_trusted_rule_without_scope_is_high(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(conn, "Broad Draw", oracle_text="Draw two cards.")
                insert_rule(conn, "Broad Draw", {"effect": "draw_cards"})
                report = audit.build_report(conn)

        card = report["cards"][0]
        self.assertEqual(card["severity"], "high")
        self.assertIn(
            "generic_effect_without_model_scope",
            {finding["code"] for finding in card["findings"]},
        )

    def test_needs_review_rule_is_high(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(conn, "Unreviewed Spell")
                insert_rule(
                    conn,
                    "Unreviewed Spell",
                    {"effect": "copy_spell", "battle_model_scope": "copy_spell_stack_target_v1"},
                    review_status="needs_review",
                    execution_status="review_only",
                )
                report = audit.build_report(conn)

        card = report["cards"][0]
        self.assertEqual(card["severity"], "high")
        self.assertIn(
            "no_trusted_executable_rule",
            {finding["code"] for finding in card["findings"]},
        )

    def test_land_only_review_backlog_is_medium(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(
                    conn,
                    "Arid Mesa",
                    oracle_text="{T}, Pay 1 life, Sacrifice Arid Mesa: Search your library...",
                    type_line="Land",
                )
                insert_rule(
                    conn,
                    "Arid Mesa",
                    {"effect": "land"},
                    review_status="needs_review",
                    execution_status="review_only",
                    oracle_hash=None,
                )
                report = audit.build_report(conn)

        card = report["cards"][0]
        self.assertEqual(card["severity"], "medium")
        self.assertEqual(card["impact_tier"], "land_or_mana_base")
        self.assertIn(
            "review_only_or_needs_review_rule",
            {finding["code"] for finding in card["findings"]},
        )

    def test_disabled_land_shadow_with_trusted_rule_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(
                    conn,
                    "Arid Mesa",
                    oracle_text="{T}, Pay 1 life, Sacrifice Arid Mesa: Search your library for a Mountain or Plains card, put it onto the battlefield, then shuffle.",
                    type_line="Land",
                )
                insert_rule(
                    conn,
                    "Arid Mesa",
                    {
                        "effect": "land",
                        "battle_model_scope": "fetchland_land_play_with_activation_annotation_v1",
                        "fetch_activation_status": "annotation_only",
                    },
                    oracle_hash="fetch-oracle-hash",
                    logical_rule_key="battle_rule_v1:trusted_fetchland",
                )
                insert_rule(
                    conn,
                    "Arid Mesa",
                    {"effect": "land"},
                    review_status="deprecated",
                    execution_status="disabled",
                    source="generated",
                    oracle_hash=None,
                    logical_rule_key="battle_rule_v1:generated_shadow",
                )
                report = audit.build_report(conn)

        card = report["cards"][0]
        self.assertEqual(card["severity"], "pass")
        self.assertEqual(card["trusted_executable_rule_count"], 1)
        self.assertEqual(card["review_only_rule_count"], 0)

    def test_review_only_shadow_with_trusted_rule_is_not_actionable(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(
                    conn,
                    "Purphoros, God of the Forge",
                    oracle_text="Whenever another creature enters the battlefield under your control, Purphoros deals 2 damage to each opponent.",
                    type_line="Legendary Enchantment Creature — God",
                )
                insert_rule(
                    conn,
                    "Purphoros, God of the Forge",
                    {
                        "effect": "passive",
                        "battle_model_scope": "controlled_creature_enters_damage_each_opponent_v1",
                    },
                    logical_rule_key="battle_rule_v1:trusted_purphoros",
                )
                insert_rule(
                    conn,
                    "Purphoros, God of the Forge",
                    {"effect": "pump_all"},
                    review_status="needs_review",
                    execution_status="review_only",
                    source="generated",
                    oracle_hash=None,
                    logical_rule_key="battle_rule_v1:generated_pump_shadow",
                )
                report = audit.build_report(conn)

        card = report["cards"][0]
        self.assertEqual(card["severity"], "pass")
        self.assertEqual(card["trusted_executable_rule_count"], 1)
        self.assertEqual(card["review_only_rule_count"], 1)
        self.assertIn(
            "shadow_rule_preserved_for_history",
            {finding["code"] for finding in card["findings"]},
        )

    def test_nonland_without_rule_is_high_but_basic_land_is_medium(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(conn, "Missing Rule Spell")
                insert_deck_card(conn, "Plains", oracle_text="", type_line="Basic Land - Plains")
                report = audit.build_report(conn)

        by_name = {card["card_name"]: card for card in report["cards"]}
        self.assertEqual(by_name["Missing Rule Spell"]["severity"], "high")
        self.assertEqual(by_name["Plains"]["severity"], "medium")

    def test_scoped_trusted_rules_require_oracle_hash(self) -> None:
        cases = [
            (
                None,
                {"medium": 2},
                {
                    "Silence": "trusted_rule_without_oracle_hash",
                    "Mana Vault": "trusted_rule_without_oracle_hash",
                },
            ),
            ("oracle-hash", {"pass": 2}, {}),
        ]
        for oracle_hash, expected_counts, expected_findings in cases:
            with self.subTest(oracle_hash=oracle_hash):
                with tempfile.TemporaryDirectory() as tmpdir:
                    db = Path(tmpdir) / "knowledge.db"
                    with sqlite3.connect(db) as conn:
                        conn.row_factory = sqlite3.Row
                        create_schema(conn)
                        insert_deck_card(conn, "Silence")
                        insert_rule(
                            conn,
                            "Silence",
                            {
                                "effect": "silence_spell",
                                "battle_model_scope": "silence_until_eot_v1",
                            },
                            oracle_hash=oracle_hash,
                        )
                        insert_deck_card(conn, "Mana Vault", type_line="Artifact")
                        insert_rule(
                            conn,
                            "Mana Vault",
                            {
                                "effect": "ramp_permanent",
                                "battle_model_scope": "fast_mana_artifact_partial_v1",
                                "mana_produced": 3,
                            },
                            oracle_hash=oracle_hash,
                        )
                        report = audit.build_report(conn)

                self.assertEqual(report["severity_counts"], expected_counts)
                by_name = {card["card_name"]: card for card in report["cards"]}
                for card_name, expected_code in expected_findings.items():
                    self.assertIn(
                        expected_code,
                        {finding["code"] for finding in by_name[card_name]["findings"]},
                    )

    def test_build_report_filters_by_deck_id(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            db = Path(tmpdir) / "knowledge.db"
            with sqlite3.connect(db) as conn:
                conn.row_factory = sqlite3.Row
                create_schema(conn)
                insert_deck_card(conn, "Deck Six Spell", deck_id=6)
                insert_rule(
                    conn,
                    "Deck Six Spell",
                    {"effect": "draw_cards", "battle_model_scope": "deck_six_spell_draw_v1"},
                )
                insert_deck_card(conn, "Deck Six Oh Six Spell", deck_id=606)
                insert_rule(
                    conn,
                    "Deck Six Oh Six Spell",
                    {"effect": "copy_spell", "battle_model_scope": "deck606_copy_v1"},
                )
                report = audit.build_report(conn, deck_id=6)

        self.assertEqual(report["deck_id"], 6)
        self.assertEqual(report["scope"], "distinct_cards_referenced_by_deck_cards_filtered_by_deck_id")
        self.assertEqual(report["total_cards"], 1)
        self.assertEqual(report["cards"][0]["card_name"], "Deck Six Spell")
        self.assertEqual(report["cards"][0]["deck_ids"], [6])


if __name__ == "__main__":
    unittest.main()
