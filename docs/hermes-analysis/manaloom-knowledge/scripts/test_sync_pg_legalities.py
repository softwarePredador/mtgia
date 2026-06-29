#!/usr/bin/env python3
from __future__ import annotations

import unittest

import sync_pg_legalities as sync


class SyncPgLegalitiesTests(unittest.TestCase):
    def test_local_aliases_include_front_faces_and_lorehold(self) -> None:
        rows = sync.add_local_legality_aliases(
            [
                (
                    "Emeria's Call // Emeria, Shattered Skyclave",
                    "commander",
                    "legal",
                    "00000000-0000-0000-0000-000000000001",
                ),
                ("Mana Crypt", "commander", "banned", None),
            ]
        )
        names = {(name, fmt): status for name, fmt, status, _sid in rows}

        self.assertEqual(names[("Emeria's Call", "commander")], "legal")
        self.assertEqual(names[("Lorehold, the Historian", "commander")], "legal")
        self.assertEqual(names[("Mana Crypt", "commander")], "banned")

    def test_status_lookup_is_case_insensitive(self) -> None:
        rows = [("Worldfire", "commander", "legal", None)]

        self.assertEqual(sync.status_lookup(rows, "worldfire"), "legal")
        self.assertEqual(sync.status_lookup(rows, "Unknown"), "missing")


if __name__ == "__main__":
    unittest.main()
