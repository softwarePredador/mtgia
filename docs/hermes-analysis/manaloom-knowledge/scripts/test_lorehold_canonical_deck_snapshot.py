#!/usr/bin/env python3
import importlib.util
import os
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("lorehold_canonical_deck_snapshot.py")
SPEC = importlib.util.spec_from_file_location("lorehold_canonical_deck_snapshot", MODULE_PATH)
snapshot = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(snapshot)


class LoreholdCanonicalDeckSnapshotTests(unittest.TestCase):
    def test_land_type_boundary_rejects_lander_and_island_subtypes(self) -> None:
        self.assertTrue(snapshot.is_land_type_line("Basic Land — Island"))
        self.assertTrue(snapshot.is_land_type_line("Legendary Land"))
        self.assertFalse(
            snapshot.is_land_type_line("Legendary Artifact Creature — Lander Rogue")
        )
        self.assertFalse(snapshot.is_land_type_line("Creature — Island Fish"))

    def test_backup_db_keeps_newest_backups_and_prunes_oldest(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            db_path = root / "knowledge.db"
            db_path.write_text("current-db", encoding="utf-8")
            backup_dir = root / "backups"
            backup_dir.mkdir()
            old_one = backup_dir / "knowledge.db.bak_lorehold_canonical_20260101_000000_000001"
            old_two = backup_dir / "knowledge.db.bak_lorehold_canonical_20260102_000000_000001"
            old_one.write_text("old-one", encoding="utf-8")
            old_two.write_text("old-two", encoding="utf-8")
            os.utime(old_one, (100, 100))
            os.utime(old_two, (200, 200))

            backup, pruned = snapshot.backup_db(db_path, backup_dir, keep=2)

            self.assertTrue(backup.exists())
            self.assertEqual(backup.read_text(encoding="utf-8"), "current-db")
            self.assertEqual(pruned, [old_one])
            self.assertFalse(old_one.exists())
            self.assertTrue(old_two.exists())
            remaining = sorted(backup_dir.glob("knowledge.db.bak_lorehold_canonical_*"))
            self.assertEqual(remaining, sorted([old_two, backup]))

    def test_default_backup_keep_accepts_manaloom_fallback_env(self) -> None:
        old_hermes = os.environ.pop("HERMES_KNOWLEDGE_BACKUP_KEEP", None)
        old_manaloom = os.environ.get("MANALOOM_KNOWLEDGE_BACKUP_KEEP")
        os.environ["MANALOOM_KNOWLEDGE_BACKUP_KEEP"] = "3"
        try:
            self.assertEqual(snapshot.default_backup_keep(), 3)
        finally:
            if old_hermes is not None:
                os.environ["HERMES_KNOWLEDGE_BACKUP_KEEP"] = old_hermes
            else:
                os.environ.pop("HERMES_KNOWLEDGE_BACKUP_KEEP", None)
            if old_manaloom is not None:
                os.environ["MANALOOM_KNOWLEDGE_BACKUP_KEEP"] = old_manaloom
            else:
                os.environ.pop("MANALOOM_KNOWLEDGE_BACKUP_KEEP", None)


if __name__ == "__main__":
    unittest.main()
