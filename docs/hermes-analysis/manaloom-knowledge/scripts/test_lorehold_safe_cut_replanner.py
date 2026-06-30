import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

import lorehold_safe_cut_replanner as replanner


def write_json(path: Path, payload: dict):
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def build_source_db(path: Path):
    conn = sqlite3.connect(path)
    conn.execute(
        """
        CREATE TABLE deck_cards (
            deck_id INTEGER,
            card_name TEXT,
            quantity INTEGER,
            functional_tag TEXT,
            cmc REAL,
            type_line TEXT,
            is_commander INTEGER
        )
        """
    )
    conn.execute(
        """
        CREATE TABLE card_oracle_cache (
            normalized_name TEXT PRIMARY KEY,
            name TEXT
        )
        """
    )
    rows = [
        (6, "Lorehold, the Historian", 1, "engine", 5, "Legendary Creature", 1),
        (6, "Bender's Waterskin", 1, "ramp", 3, "Artifact", 0),
        (6, "Big Score", 1, "ramp", 4, "Instant", 0),
        (6, "Manual Flex", 1, "draw", 2, "Enchantment", 0),
        (6, "Unlisted Draw", 1, "draw", 2, "Enchantment", 0),
        (6, "Unexpected Windfall", 1, "ramp", 4, "Instant", 0),
        (6, "Command Tower", 1, "land", 0, "Land", 0),
    ]
    conn.executemany("INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)", rows)
    conn.execute(
        "INSERT INTO card_oracle_cache VALUES (?, ?)",
        ("past in flames", "Past in Flames"),
    )
    conn.commit()
    conn.close()


class LoreholdSafeCutReplannerTest(unittest.TestCase):
    def test_generates_safe_alternate_cut_from_positive_blocked_source(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            ledger = tmp / "ledger.json"
            registry = tmp / "registry.json"
            cut_safety = tmp / "cut_safety.json"
            source_db = tmp / "knowledge.db"
            build_source_db(source_db)
            write_json(
                ledger,
                {
                    "package_groups": [
                        {
                            "package_key": "past_in_flames_recast",
                            "classification": "preflight_blocked_protected_cut",
                            "families": ["graveyard_recast"],
                            "best_delta_pp": 50.0,
                            "critical_regression_count": 0,
                            "critical_improvement_count": 1,
                            "critical_tie_count": 1,
                            "latest_adds": ["Past in Flames"],
                            "latest_cuts": ["Bender's Waterskin"],
                        }
                    ]
                },
            )
            write_json(
                registry,
                {"protected_cards_until_same_function_replacement_wins": ["Bender's Waterskin"]},
            )
            write_json(
                cut_safety,
                {
                    "cut_safety_manifest": {
                        "cuts": [
                            {
                                "card_name": "Bender's Waterskin",
                                "status": "protected_until_same_function_replacement_wins",
                                "current_lane": "early_mana",
                            }
                        ],
                        "untested_flex_pool": [
                            {
                                "card_name": "Big Score",
                                "decision": "support_flex",
                                "status": "core_support",
                                "package_lane": "early_mana",
                            },
                            {
                                "card_name": "Manual Flex",
                                "decision": "engine_flex",
                                "status": "core_support",
                                "package_lane": "draw",
                            },
                        ],
                    }
                },
            )

            payload = replanner.build_report(
                ledger_path=ledger,
                registry_path=registry,
                cut_safety_path=cut_safety,
                source_db=source_db,
                deck_id=6,
                prior_reports=[],
                max_per_source=2,
                max_manifest_packages=2,
            )

        ready = payload["manifest_ready_packages"]
        self.assertEqual(payload["summary"]["manifest_ready_count"], 1)
        self.assertEqual(ready[0]["adds"], ["Past in Flames"])
        self.assertEqual(ready[0]["cuts"], ["Manual Flex"])
        self.assertEqual(ready[0]["status"], "manifest_ready")
        manifest = payload["manifest"]
        self.assertEqual(len(manifest["packages"]), 1)
        self.assertEqual(manifest["packages"][0]["package_key"], ready[0]["package_key"])
        blocked_big_score = [
            row
            for row in payload["followups"]
            if row["cuts"] == ["Big Score"]
        ][0]
        self.assertIn("cut_is_early_mana_floor_support", blocked_big_score["blockers"])

    def test_missing_cut_safety_row_is_not_manifest_ready(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            ledger = tmp / "ledger.json"
            registry = tmp / "registry.json"
            cut_safety = tmp / "cut_safety.json"
            source_db = tmp / "knowledge.db"
            build_source_db(source_db)
            write_json(
                ledger,
                {
                    "package_groups": [
                        {
                            "package_key": "past_in_flames_recast",
                            "classification": "preflight_blocked_protected_cut",
                            "families": ["graveyard_recast"],
                            "best_delta_pp": 50.0,
                            "critical_regression_count": 0,
                            "critical_improvement_count": 1,
                            "critical_tie_count": 1,
                            "latest_adds": ["Past in Flames"],
                            "latest_cuts": ["Bender's Waterskin"],
                        }
                    ]
                },
            )
            write_json(registry, {"protected_cards_until_same_function_replacement_wins": []})
            write_json(cut_safety, {"cut_safety_manifest": {"cuts": [], "untested_flex_pool": []}})

            payload = replanner.build_report(
                ledger_path=ledger,
                registry_path=registry,
                cut_safety_path=cut_safety,
                source_db=source_db,
                deck_id=6,
                prior_reports=[],
                max_per_source=4,
                max_manifest_packages=4,
            )

        unlisted_row = [
            row
            for row in payload["followups"]
            if row["cuts"] == ["Unlisted Draw"]
        ][0]
        self.assertEqual(unlisted_row["status"], "blocked")
        self.assertIn("missing_cut_safety_row", unlisted_row["blockers"])

    def test_rejected_signature_is_not_manifest_ready(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            ledger = tmp / "ledger.json"
            registry = tmp / "registry.json"
            cut_safety = tmp / "cut_safety.json"
            source_db = tmp / "knowledge.db"
            prior = tmp / "prior.json"
            build_source_db(source_db)
            write_json(
                ledger,
                {
                    "package_groups": [
                        {
                            "package_key": "past_in_flames_recast",
                            "classification": "preflight_blocked_protected_cut",
                            "families": ["graveyard_recast"],
                            "best_delta_pp": 50.0,
                            "critical_regression_count": 0,
                            "critical_improvement_count": 1,
                            "critical_tie_count": 1,
                            "latest_adds": ["Past in Flames"],
                            "latest_cuts": ["Bender's Waterskin"],
                        }
                    ]
                },
            )
            write_json(registry, {"protected_cards_until_same_function_replacement_wins": []})
            write_json(cut_safety, {"cut_safety_manifest": {"cuts": [], "untested_flex_pool": []}})
            write_json(
                prior,
                {
                    "packages": [
                        {
                            "package_key": "old_past_big_score",
                            "adds": ["Past in Flames"],
                            "cuts": ["Big Score"],
                            "decision": "reject_or_rework",
                        }
                    ]
                },
            )

            payload = replanner.build_report(
                ledger_path=ledger,
                registry_path=registry,
                cut_safety_path=cut_safety,
                source_db=source_db,
                deck_id=6,
                prior_reports=[prior],
                max_per_source=2,
                max_manifest_packages=2,
            )

        ready_cuts = [row["cuts"][0] for row in payload["manifest_ready_packages"]]
        self.assertNotIn("Big Score", ready_cuts)
        blocked = [
            row
            for row in payload["followups"]
            if row["cuts"] == ["Big Score"]
        ][0]
        self.assertIn("prior_rejected_signature", blocked["blockers"])
        self.assertIn("prior_rejected_cut", blocked["blockers"])

    def test_rejected_cut_from_different_add_is_not_safe_cut_ready(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            ledger = tmp / "ledger.json"
            registry = tmp / "registry.json"
            cut_safety = tmp / "cut_safety.json"
            source_db = tmp / "knowledge.db"
            prior = tmp / "prior.json"
            build_source_db(source_db)
            conn = sqlite3.connect(source_db)
            conn.execute(
                "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)",
                (6, "Artist's Talent", 1, "draw", 2, "Enchantment", 0),
            )
            conn.commit()
            conn.close()
            write_json(
                ledger,
                {
                    "package_groups": [
                        {
                            "package_key": "past_in_flames_recast",
                            "classification": "preflight_blocked_protected_cut",
                            "families": ["graveyard_recast"],
                            "best_delta_pp": 50.0,
                            "critical_regression_count": 0,
                            "critical_improvement_count": 1,
                            "critical_tie_count": 1,
                            "latest_adds": ["Past in Flames"],
                            "latest_cuts": ["Bender's Waterskin"],
                        }
                    ]
                },
            )
            write_json(registry, {"protected_cards_until_same_function_replacement_wins": []})
            write_json(cut_safety, {"cut_safety_manifest": {"cuts": [], "untested_flex_pool": []}})
            write_json(
                prior,
                {
                    "packages": [
                        {
                            "package_key": "old_draw_probe",
                            "adds": ["Borrowed Knowledge"],
                            "cuts": ["Artist's Talent"],
                            "decision": "reject_or_rework",
                        }
                    ]
                },
            )

            payload = replanner.build_report(
                ledger_path=ledger,
                registry_path=registry,
                cut_safety_path=cut_safety,
                source_db=source_db,
                deck_id=6,
                prior_reports=[prior],
                max_per_source=4,
                max_manifest_packages=4,
            )

        artist_row = [
            row
            for row in payload["followups"]
            if row["cuts"] == ["Artist's Talent"]
        ][0]
        self.assertEqual(artist_row["status"], "blocked")
        self.assertIn("prior_rejected_cut", artist_row["blockers"])

    def test_spellchain_mana_does_not_auto_cut_early_mana_floor(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            ledger = tmp / "ledger.json"
            registry = tmp / "registry.json"
            cut_safety = tmp / "cut_safety.json"
            source_db = tmp / "knowledge.db"
            build_source_db(source_db)
            conn = sqlite3.connect(source_db)
            conn.execute(
                "INSERT INTO deck_cards VALUES (?, ?, ?, ?, ?, ?, ?)",
                (6, "Arcane Signet", 1, "ramp", 2, "Artifact", 0),
            )
            conn.execute(
                "INSERT INTO card_oracle_cache VALUES (?, ?)",
                ("storm kiln artist", "Storm-Kiln Artist"),
            )
            conn.commit()
            conn.close()
            write_json(
                ledger,
                {
                    "package_groups": [
                        {
                            "package_key": "storm_kiln_artist_cut_protected_rock",
                            "classification": "preflight_blocked_protected_cut",
                            "families": ["spellchain_mana"],
                            "best_delta_pp": 25.0,
                            "critical_regression_count": 0,
                            "critical_improvement_count": 1,
                            "critical_tie_count": 0,
                            "latest_adds": ["Storm-Kiln Artist"],
                            "latest_cuts": ["Bender's Waterskin"],
                        }
                    ]
                },
            )
            write_json(registry, {"protected_cards_until_same_function_replacement_wins": []})
            write_json(
                cut_safety,
                {
                    "cut_safety_manifest": {
                        "cuts": [],
                        "untested_flex_pool": [
                            {
                                "card_name": "Arcane Signet",
                                "decision": "support_flex",
                                "status": "core_support",
                                "package_lane": "early_mana",
                            }
                        ],
                    }
                },
            )

            payload = replanner.build_report(
                ledger_path=ledger,
                registry_path=registry,
                cut_safety_path=cut_safety,
                source_db=source_db,
                deck_id=6,
                prior_reports=[],
                max_per_source=4,
                max_manifest_packages=4,
            )

        arcane_row = [
            row
            for row in payload["followups"]
            if row["cuts"] == ["Arcane Signet"]
        ][0]
        self.assertEqual(arcane_row["status"], "blocked")
        self.assertIn("incompatible_lane", arcane_row["blockers"])
        self.assertIn("cut_is_early_mana_floor_support", arcane_row["blockers"])
        manifest_cuts = [
            package["cuts"][0]
            for package in payload["manifest"]["packages"]
        ]
        self.assertNotIn("Arcane Signet", manifest_cuts)


if __name__ == "__main__":
    unittest.main()
