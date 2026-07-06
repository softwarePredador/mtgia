#!/usr/bin/env python3
"""Tests for ramp cut trace/replacement gate."""

from __future__ import annotations

import json
import sqlite3
import subprocess
import tempfile
import unittest
from pathlib import Path

import global_commander_ramp_cut_trace_replacement_gate as gate


def write_json(root: Path, name: str, payload: dict[str, object]) -> Path:
    path = root / name
    path.write_text(json.dumps(payload), encoding="utf-8")
    return path


def create_db(path: Path) -> None:
    with sqlite3.connect(path) as conn:
        conn.executescript(
            """
            CREATE TABLE format_staples (
              card_name TEXT NOT NULL,
              format TEXT NOT NULL,
              archetype TEXT NOT NULL DEFAULT '',
              category TEXT NOT NULL DEFAULT '',
              color_identity TEXT,
              edhrec_rank INTEGER,
              scryfall_id TEXT,
              is_banned INTEGER DEFAULT 0,
              synced_at TEXT DEFAULT ''
            );
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
              source TEXT DEFAULT 'test',
              updated_at TEXT DEFAULT '',
              card_id TEXT
            );
            CREATE TABLE deck_cards (
              id INTEGER PRIMARY KEY,
              deck_id INTEGER,
              card_name TEXT NOT NULL
            );
            """
        )
        conn.executemany(
            "INSERT INTO format_staples(card_name, format, color_identity, edhrec_rank, is_banned) VALUES (?, 'commander', ?, ?, 0)",
            [
                ("Talisman of Conviction", "RW", 80),
                ("Smothering Tithe", "W", 57),
                ("Nature's Lore", "G", 70),
                ("Existing Ramp", "R", 10),
                ("Lightning Bolt", "R", 99),
            ],
        )
        conn.executemany(
            """
            INSERT INTO card_oracle_cache(normalized_name, name, color_identity_json, type_line, oracle_text)
            VALUES (?, ?, ?, ?, ?)
            """,
            [
                (
                    "talisman of conviction",
                    "Talisman of Conviction",
                    '["R","W"]',
                    "Artifact",
                    "{T}: Add {C}. {T}: Add {R} or {W}. Talisman of Conviction deals 1 damage to you.",
                ),
                (
                    "smothering tithe",
                    "Smothering Tithe",
                    '["W"]',
                    "Enchantment",
                    "Whenever an opponent draws a card, that player may pay {2}. If they don't, you create a Treasure token.",
                ),
                (
                    "nature's lore",
                    "Nature's Lore",
                    '["G"]',
                    "Sorcery",
                    "Search your library for a Forest card, put that card onto the battlefield, then shuffle.",
                ),
                (
                    "existing ramp",
                    "Existing Ramp",
                    '["R"]',
                    "Artifact",
                    "{T}: Add {R}.",
                ),
                (
                    "lightning bolt",
                    "Lightning Bolt",
                    '["R"]',
                    "Instant",
                    "Lightning Bolt deals 3 damage to any target.",
                ),
            ],
        )
        conn.execute("INSERT INTO deck_cards(deck_id, card_name) VALUES (619, 'Existing Ramp')")


def router_payload() -> dict[str, object]:
    return {
        "trace_plan_rows": [
            {
                "card_name": "Basalt Monolith",
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
            }
        ],
        "structured_review_rows": [
            {
                "card_name": "Grim Monolith",
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
            }
        ],
        "replacement_search_rows": [
            {
                "card_name": "Arcane Signet",
                "deck_id": "619",
                "commander": "Kaalia of the Vast",
                "required_replacement_roles": ["ramp"],
            }
        ],
        "cut_followup_rows": [],
    }


class GlobalCommanderRampCutTraceReplacementGateTests(unittest.TestCase):
    def test_replacement_candidates_filter_color_and_current_deck(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "knowledge.db"
            create_db(db_path)

            rows = gate.query_replacement_candidates(db_path=db_path, deck_id="619", limit=10)

        names = [row["card_name"] for row in rows]
        self.assertIn("Talisman of Conviction", names)
        self.assertIn("Smothering Tithe", names)
        self.assertNotIn("Nature's Lore", names)
        self.assertNotIn("Existing Ramp", names)
        self.assertNotIn("Lightning Bolt", names)

    def test_build_report_keeps_candidate_copy_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            db_path = root / "knowledge.db"
            create_db(db_path)
            router = write_json(root, "router.json", router_payload())
            policy = write_json(root, "policy.json", {"source_db": str(db_path)})
            scout = write_json(
                root,
                "scout.json",
                {
                    "cut_evidence_rows": [
                        {
                            "card_name": "Grim Monolith",
                            "structured_evidence_count": 2,
                            "text_usage_candidate_count": 1,
                        }
                    ]
                },
            )

            def runner(*args, **kwargs):  # type: ignore[no-untyped-def]
                return subprocess.CompletedProcess(args[0], 0, "", "")

            report = gate.build_report(
                router_report=router,
                ramp_policy_report=policy,
                scout_report=scout,
                battle_replay=root / "battle.py",
                replay_dir=root / "replays",
                seed_start=1,
                seed_count=1,
                timeout=1,
                replacement_limit=10,
                runner=runner,
            )

        self.assertFalse(report["candidate_copy_allowed_now"])
        self.assertTrue(report["battle_replay_performed"])
        self.assertEqual(report["summary"]["trace_no_exposure_count"], 1)
        self.assertEqual(report["summary"]["structured_manual_review_count"], 1)
        self.assertEqual(report["summary"]["replacement_candidate_count"], 2)
        self.assertEqual(report["summary"]["next_gate"], "run_forced_access_trace_for_unexposed_ramp_cut")
        self.assertIn("candidate_copy_closed_after_ramp_trace_replacement_gate", report["candidate_copy_blockers"])


if __name__ == "__main__":
    unittest.main()
