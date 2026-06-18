#!/usr/bin/env python3
"""Unit tests for focused Scryfall legality sync support."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


def _load_module():
    root = Path(__file__).resolve().parents[1]
    path = root / "bin/sync_card_legalities_from_scryfall.py"
    spec = importlib.util.spec_from_file_location("sync_card_legalities_from_scryfall", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class SyncCardLegalitiesFromScryfallTest(unittest.TestCase):
    def setUp(self) -> None:
        self.sync = _load_module()

    def test_collection_body_uses_oracle_ids(self) -> None:
        body = self.sync.build_collection_body([" oracle-1 ", "", "oracle-2"])
        self.assertIn(b'"oracle_id": "oracle-1"', body)
        self.assertIn(b'"oracle_id": "oracle-2"', body)
        self.assertNotIn(b'"id":', body)

    def test_parse_collection_response_maps_legalities_and_not_found(self) -> None:
        payload = self.sync.parse_collection_response(
            {
                "data": [
                    {
                        "oracle_id": "oracle-1",
                        "legalities": {
                            "commander": "not_legal",
                            "future": "legal",
                        },
                    }
                ],
                "not_found": [{"oracle_id": "oracle-3"}],
            },
            ["oracle-1", "oracle-2", "oracle-3"],
        )
        self.assertEqual(
            payload.legalities_by_oracle_id["oracle-1"]["commander"],
            "not_legal",
        )
        self.assertEqual(payload.legalities_by_oracle_id["oracle-1"]["future"], "legal")
        self.assertEqual(payload.not_found, ["oracle-2", "oracle-3"])

    def test_rows_for_upsert_preserves_all_formats_per_card(self) -> None:
        candidates = [
            self.sync.Candidate(
                card_id="card-1",
                oracle_id="oracle-1",
                name="Abomination",
                set_code="msh",
            )
        ]
        rows = self.sync.rows_for_upsert(
            candidates,
            {
                "oracle-1": {
                    "commander": "not_legal",
                    "future": "legal",
                }
            },
        )
        self.assertEqual(
            rows,
            [
                ("card-1", "commander", "not_legal"),
                ("card-1", "future", "legal"),
            ],
        )

    def test_chunked_caps_scryfall_batch_size(self) -> None:
        chunks = self.sync.chunked(list(range(151)), 1000)
        self.assertEqual([len(chunk) for chunk in chunks], [75, 75, 1])

    def test_normalize_sets_dedupes_lowercase(self) -> None:
        self.assertEqual(self.sync.normalize_sets("MSH, msc, msh,,MAR"), ["mar", "msc", "msh"])


if __name__ == "__main__":
    unittest.main()
