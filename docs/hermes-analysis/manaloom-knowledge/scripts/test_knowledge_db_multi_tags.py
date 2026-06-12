#!/usr/bin/env python3
"""Tests for knowledge_db multi-tag snapshot helpers."""

from __future__ import annotations

import json
import unittest

import knowledge_db


class KnowledgeDbMultiTagsTests(unittest.TestCase):
    def test_functional_tags_json_prefers_explicit_array(self) -> None:
        payload = knowledge_db.functional_tags_json_for_card(
            {
                "functional_tag": "draw",
                "functional_tags_json": ["engine", "draw", "engine"],
            }
        )

        self.assertEqual(json.loads(payload), ["draw", "engine"])

    def test_functional_tags_json_uses_card_tags_then_legacy_fallback(self) -> None:
        from_card_tags = knowledge_db.functional_tags_json_for_card(
            {
                "functional_tag": "unknown",
                "tags": [
                    {"tag": "ramp", "confidence": 0.9},
                    {"tag": "engine", "confidence": 0.7},
                ],
            }
        )
        legacy = knowledge_db.functional_tags_json_for_card(
            {"functional_tag": "removal"}
        )
        unknown = knowledge_db.functional_tags_json_for_card(
            {"functional_tag": "unknown"}
        )

        self.assertEqual(json.loads(from_card_tags), ["engine", "ramp"])
        self.assertEqual(json.loads(legacy), ["removal"])
        self.assertEqual(json.loads(unknown), [])


if __name__ == "__main__":
    unittest.main()
