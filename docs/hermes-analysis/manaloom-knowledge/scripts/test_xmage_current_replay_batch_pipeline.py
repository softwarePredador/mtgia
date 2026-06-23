#!/usr/bin/env python3
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import deck_card_battle_rule_coherence_audit as coherence
import xmage_current_replay_batch_pipeline as pipeline


class XMageCurrentReplayBatchPipelineTests(unittest.TestCase):
    def test_parse_source_ref_accepts_expected_kinds(self) -> None:
        self.assertEqual(pipeline.parse_source_ref("deck_id:6"), ("deck_id", 6))
        self.assertEqual(pipeline.parse_source_ref("learned_deck:54"), ("learned_deck", 54))
        self.assertIsNone(pipeline.parse_source_ref("bad"))
        self.assertIsNone(pipeline.parse_source_ref("other:10"))

    def test_deck_targets_from_latest_artifact_collects_unique_current_refs(self) -> None:
        sample = {
            "decks": [
                {"source_ref": "deck_id:6", "name": "Lorehold"},
                {"source_ref": "learned_deck:54", "name": "Thrasios"},
                {"source_ref": "learned_deck:54", "name": "Thrasios"},
                {"source_ref": "learned_deck:105", "name": "Etali"},
            ]
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            artifact_dir = Path(tmp_dir)
            seed_dir = artifact_dir / "seed_123"
            seed_dir.mkdir(parents=True)
            (seed_dir / "deck_provenance.json").write_text(
                json.dumps(sample),
                encoding="utf-8",
            )
            targets = pipeline.deck_targets_from_latest_artifact(artifact_dir)

        self.assertEqual(targets["deck_ids"], [6])
        self.assertEqual(targets["learned_deck_ids"], [54, 105])
        self.assertEqual(targets["source_names"]["deck_id:6"], "Lorehold")
        self.assertEqual(targets["seed_map"]["seed_123"], ["deck_id:6", "learned_deck:105", "learned_deck:54"])

    def test_merge_usage_maps_unions_decks_and_sums_quantities(self) -> None:
        first = {
            "birds of paradise": coherence.DeckCardUsage(
                normalized_name="birds of paradise",
                display_name="Birds of Paradise",
                deck_ids=[31],
                total_quantity=1,
                deck_count=1,
                commander_count=0,
                type_lines=["Creature - Bird"],
                oracle_texts=["{T}: Add one mana of any color."],
                battle_rules_json_count=0,
            )
        }
        second = {
            "birds of paradise": coherence.DeckCardUsage(
                normalized_name="birds of paradise",
                display_name="Birds of Paradise",
                deck_ids=[54],
                total_quantity=1,
                deck_count=1,
                commander_count=0,
                type_lines=["Creature - Bird"],
                oracle_texts=["{T}: Add one mana of any color."],
                battle_rules_json_count=1,
            )
        }

        merged = pipeline.merge_usage_maps([first, second])
        birds = merged["birds of paradise"]

        self.assertEqual(birds.deck_ids, [31, 54])
        self.assertEqual(birds.deck_count, 2)
        self.assertEqual(birds.total_quantity, 2)
        self.assertEqual(birds.battle_rules_json_count, 1)


if __name__ == "__main__":
    unittest.main()
