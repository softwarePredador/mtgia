#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
MODULE_PATH = SCRIPT_DIR / "battle_package_end_to_end_validation.py"


def load_module():
    spec = importlib.util.spec_from_file_location("battle_package_end_to_end_validation_mod", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_module()


def manifest_with_expected_rule() -> dict:
    return {
        "expected_rules": [
            {
                "normalized_name": "verge rangers",
                "card_name": "Verge Rangers",
                "logical_rule_key": "battle_rule_v1:abc",
                "oracle_hash": "hash123",
                "review_status": "verified",
                "execution_status": "auto",
                "min_rule_version": 2,
                "required_effect_fields": {
                    "effect": "topdeck_play",
                    "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
                },
                "forbid_annotation_only": True,
            }
        ]
    }


def test_validate_snapshot_derives_checks_from_expected_rules(tmp_path) -> None:
    snapshot_path = tmp_path / "known_cards_canonical_snapshot.json"
    snapshot_path.write_text(
        json.dumps(
            {
                "Verge Rangers": {
                    "battle_rule_logical_key": "battle_rule_v1:abc",
                    "battle_rule_oracle_hash": "hash123",
                    "battle_rule_review_status": "verified",
                    "battle_rule_execution_status": "auto",
                    "battle_rule_version": 2,
                    "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
                }
            }
        ),
        encoding="utf-8",
    )
    manifest = manifest_with_expected_rule()

    results = validator.validate_snapshot(
        snapshot_path,
        manifest,
        validator.expected_rules_by_key(manifest),
    )

    assert len(results) == 1
    assert results[0]["card_name"] == "Verge Rangers"
    assert results[0]["battle_model_scope"] == "look_top_library_play_lands_from_top_if_opponent_more_lands_v1"


def test_validate_runtime_lookup_derives_checks_from_expected_rules() -> None:
    class FakeBattle:
        @staticmethod
        def get_card_effect(card):
            assert card == {"name": "Verge Rangers"}
            return {
                "effect": "topdeck_play",
                "_rule_logical_key": "battle_rule_v1:abc",
                "battle_model_scope": "look_top_library_play_lands_from_top_if_opponent_more_lands_v1",
            }

    results = validator.validate_runtime_lookup(FakeBattle, manifest_with_expected_rule())

    assert len(results) == 1
    assert results[0]["card_name"] == "Verge Rangers"
    assert results[0]["effect"] == "topdeck_play"
