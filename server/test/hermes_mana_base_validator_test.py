#!/usr/bin/env python3
"""Tests for deterministic Hermes mana-base validator."""

from __future__ import annotations

import importlib.util
import contextlib
import io
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin" / "hermes_mana_base_validator.py"
    spec = importlib.util.spec_from_file_location("hermes_mana_base_validator", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _make_db() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:")
    conn.execute("CREATE TABLE commanders (id INTEGER PRIMARY KEY, name TEXT)")
    conn.execute(
        """
        CREATE TABLE decks (
            id INTEGER PRIMARY KEY,
            deck_name TEXT,
            commander_id INTEGER,
            archetype TEXT
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            quantity INTEGER,
            functional_tag TEXT,
            functional_tags_json TEXT,
            type_line TEXT,
            cmc REAL
        )
        """
    )
    return conn


class HermesManaBaseValidatorTest(unittest.TestCase):
    def test_complete_deck_uses_profile_ranges(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            artifacts = Path(tmp) / "artifacts"
            profile_dir = artifacts / "commander_reference_profile_test" / "profiles"
            profile_dir.mkdir(parents=True)
            (profile_dir / "talrand_sky_summoner.json").write_text(
                json.dumps(
                    {
                        "role_targets": {
                            "lands": {"min": 34, "max": 38},
                            "ramp": {"min": 8, "max": 12},
                            "draw": {"min": 8, "max": 12},
                        }
                    }
                )
            )
            conn = _make_db()
            self.addCleanup(conn.close)
            conn.execute("INSERT INTO commanders VALUES (1, 'Talrand, Sky Summoner')")
            conn.execute("INSERT INTO decks VALUES (1, 'Talrand Test', 1, 'spellslinger')")
            rows = [
                (1, 36, "land", "[\"land\"]", "Land", 0),
                (1, 9, "ramp", "[\"ramp\"]", "Artifact", 2),
                (1, 10, "draw", "[\"draw\"]", "Instant", 2),
                (1, 45, "engine", "[\"engine\"]", "Sorcery", 3),
            ]
            conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?)", rows)

            results = module.validate(conn, artifacts)
            report = module.build_report(results)

            self.assertEqual(results[0].status, "OK")
            self.assertIn("status_counts", report)
            self.assertIn("Talrand Test", report)

    def test_incomplete_and_no_profile_are_not_false_criticals(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            conn = _make_db()
            self.addCleanup(conn.close)
            conn.execute("INSERT INTO commanders VALUES (1, 'Unknown Commander')")
            conn.execute("INSERT INTO decks VALUES (1, 'Seed', 1, 'unknown')")
            conn.execute("INSERT INTO deck_cards VALUES (1, 13, 'land', '[\"land\"]', 'Land', 0)")
            conn.execute("INSERT INTO decks VALUES (2, 'Full No Profile', 1, 'unknown')")
            conn.execute("INSERT INTO deck_cards VALUES (2, 100, 'land', '[\"land\"]', 'Land', 0)")

            results = module.validate(conn, Path(tmp))

            self.assertEqual(results[0].status, "INCOMPLETE")
            self.assertEqual(results[1].status, "NO_PROFILE")

    def test_schema_without_commander_id_infers_commander_from_deck_cards(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            artifacts = Path(tmp) / "artifacts"
            profile_dir = artifacts / "commander_reference_profile_test" / "profiles"
            profile_dir.mkdir(parents=True)
            (profile_dir / "lorehold_the_historian.json").write_text(
                json.dumps({"role_targets": {"lands": {"min": 30, "max": 34}}})
            )
            conn = sqlite3.connect(":memory:")
            self.addCleanup(conn.close)
            conn.execute(
                """
                CREATE TABLE decks (
                    id INTEGER PRIMARY KEY,
                    deck_name TEXT,
                    archetype TEXT
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE deck_cards (
                    id INTEGER PRIMARY KEY,
                    deck_id INTEGER,
                    card_name TEXT,
                    quantity INTEGER,
                    functional_tag TEXT,
                    functional_tags_json TEXT,
                    type_line TEXT,
                    is_commander INTEGER,
                    cmc REAL
                )
                """
            )
            conn.execute("INSERT INTO decks VALUES (1, 'Runtime Lorehold', 'unknown')")
            conn.executemany(
                """
                INSERT INTO deck_cards (
                    id, deck_id, card_name, quantity, functional_tag,
                    functional_tags_json, type_line, is_commander, cmc
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                [
                    (1, 1, "Lorehold, the Historian", 1, "draw", "[\"draw\"]", "Legendary Creature", 1, 5),
                    (2, 1, "Plains", 31, "land", "[\"land\"]", "Basic Land — Plains", 0, 0),
                    (3, 1, "Spell", 68, "engine", "[\"engine\"]", "Sorcery", 0, 2),
                ],
            )

            results = module.validate(conn, artifacts)

            self.assertEqual(results[0].commander, "Lorehold, the Historian")
            self.assertEqual(results[0].status, "OK")

    def test_overfull_deck_is_flagged_even_without_profile(self) -> None:
        module = _load_module()
        conn = sqlite3.connect(":memory:")
        self.addCleanup(conn.close)
        conn.execute("CREATE TABLE decks (id INTEGER PRIMARY KEY, deck_name TEXT, archetype TEXT)")
        conn.execute(
            """
            CREATE TABLE deck_cards (
                id INTEGER PRIMARY KEY,
                deck_id INTEGER,
                card_name TEXT,
                quantity INTEGER,
                functional_tag TEXT,
                functional_tags_json TEXT,
                type_line TEXT,
                is_commander INTEGER,
                cmc REAL
            )
            """
        )
        conn.execute("INSERT INTO decks VALUES (1, 'Overfull', 'unknown')")
        conn.executemany(
            """
            INSERT INTO deck_cards (
                id, deck_id, card_name, quantity, functional_tag,
                functional_tags_json, type_line, is_commander, cmc
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (1, 1, "Unknown Commander", 1, "engine", "[\"engine\"]", "Creature", 1, 4),
                (2, 1, "Plains", 104, "land", "[\"land\"]", "Basic Land — Plains", 0, 0),
            ],
        )

        results = module.validate(conn, Path("/tmp/no-profiles"))

        self.assertEqual(results[0].status, "OVERFULL")
        self.assertIn("cap at 100", results[0].notes[0])

    def test_main_emits_runtime_note_when_validator_tables_are_missing(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            sqlite3.connect(db_path).close()

            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                exit_code = module.main(
                    [
                        f"--db={db_path}",
                        f"--artifacts-dir={tmp}",
                        "--stdout-only",
                    ]
                )

            rendered = stdout.getvalue()
            self.assertEqual(exit_code, 0)
            self.assertIn("runtime_note", rendered)
            self.assertIn("missing required decks/deck_cards tables", rendered)

    def test_multitag_land_detection_and_profile_fallback_paths(self) -> None:
        module = _load_module()
        with tempfile.TemporaryDirectory() as tmp:
            tmp_root = Path(tmp)
            module.REPO_ROOT = tmp_root
            fallback_profile_dir = (
                tmp_root / "docs" / "qa" / "commander_reference_profiles_runtime"
            )
            fallback_profile_dir.mkdir(parents=True)
            (fallback_profile_dir / "lorehold_the_historian.json").write_text(
                json.dumps(
                    {
                        "role_targets": {
                            "lands": {"min": 33, "max": 35},
                            "mana_rocks_treasure_ramp": {"min": 8, "max": 12},
                            "draw_rummage_opponent_turn_draw": {"min": 8, "max": 12},
                            "spot_interaction": {"min": 4, "max": 8},
                        }
                    }
                )
            )
            conn = sqlite3.connect(":memory:")
            self.addCleanup(conn.close)
            conn.execute("CREATE TABLE decks (id INTEGER PRIMARY KEY, deck_name TEXT, archetype TEXT)")
            conn.execute(
                """
                CREATE TABLE deck_cards (
                    id INTEGER PRIMARY KEY,
                    deck_id INTEGER,
                    card_name TEXT,
                    quantity INTEGER,
                    functional_tag TEXT,
                    functional_tags_json TEXT,
                    type_line TEXT,
                    is_commander INTEGER,
                    cmc REAL
                )
                """
            )
            conn.execute("INSERT INTO decks VALUES (1, 'Runtime Lorehold Learned', 'miracle')")
            conn.executemany(
                "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                [
                    (1, 1, "Lorehold, the Historian", 1, "engine", "[\"engine\"]", "Legendary Creature — Elder Dragon", 1, 5),
                    (2, 1, "Ancient Tomb", 33, "ramp", "[\"ramp\",\"land\"]", "Land", 0, 0),
                    (3, 1, "Arcane Signet", 8, "ramp", "[\"ramp\"]", "Artifact", 0, 2),
                    (4, 1, "Faithless Looting", 9, "draw", "[\"draw\"]", "Sorcery", 0, 1),
                    (5, 1, "Swords to Plowshares", 5, "removal", "[\"removal\"]", "Instant", 0, 1),
                    (6, 1, "Engine Card", 44, "engine", "[\"engine\"]", "Enchantment", 0, 3),
                ],
            )

            results = module.validate(conn, tmp_root / "no-artifacts-here")

            self.assertTrue(results[0].profile_loaded)
            self.assertEqual(results[0].lands, 33)
            self.assertEqual(results[0].ramp, 8)
            self.assertEqual(results[0].draw, 9)
            self.assertEqual(results[0].status, "OK")


if __name__ == "__main__":
    unittest.main()
