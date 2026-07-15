#!/usr/bin/env python3

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import global_residual_terminal_dispositions as dispositions


def row(name: str, scope: str, *, type_line: str = "Card") -> dict:
    return {
        "key": f"card:{name}",
        "card_id": f"id:{name}",
        "oracle_id": f"oracle:{name}",
        "name": name,
        "residual_execution_scope": scope,
        "type_line": type_line,
        "set_code": "test",
        "set_type": "test",
        "layout": "normal",
        "commander_legality": "not_legal",
        "oracle_text": "test oracle",
    }


class GlobalResidualTerminalDispositionsTest(unittest.TestCase):
    def test_all_allowed_scopes_receive_non_promotable_terminal_dispositions(self) -> None:
        payload = {
            "schema_version": "test_v1",
            "residual": [
                row("Sticker Sheet", "auxiliary_game_object", type_line="Stickers"),
                row("Playtest", "nonstandard_or_playtest_ruleset"),
                row("Physical", "physical_or_external_interaction"),
                row("Scenario", "scenario_or_challenge_deck_ruleset"),
            ],
        }
        raw = json.dumps(payload).encode()
        result = dispositions.build(payload, raw)
        self.assertEqual(result["status"], "pass")
        self.assertEqual(result["summary"]["terminal_dispositions"], 4)
        self.assertEqual(result["summary"]["actionable_residual"], 0)
        self.assertEqual(result["summary"]["promotion_allowed"], 0)
        self.assertTrue(all(item["terminal"] for item in result["dispositions"]))
        self.assertTrue(all(not item["promotion_allowed"] for item in result["dispositions"]))

    def test_auxiliary_subsystems_receive_specific_reasons(self) -> None:
        cases = {
            "Stickers": "supplemental_sticker_sheet",
            "Artifact - Attraction": "supplemental_attraction_deck_object",
            "Dungeon": "supplemental_dungeon_object",
            "Plane - Test": "supplemental_planar_deck_object",
            "Scheme": "supplemental_scheme_deck_object",
            "Token Creature": "derived_token_object",
        }
        for type_line, reason in cases.items():
            with self.subTest(type_line=type_line):
                result = dispositions.disposition_for(
                    row("Object", "auxiliary_game_object", type_line=type_line)
                )
                self.assertEqual(result["reason_code"], reason)

    def test_conventional_or_unknown_scope_cannot_be_hidden_as_an_exclusion(self) -> None:
        with self.assertRaisesRegex(ValueError, "cannot receive terminal exclusion"):
            dispositions.disposition_for(
                row("Normal Card", "conventional_magic_rules")
            )

    def test_duplicate_or_missing_keys_fail_the_gate(self) -> None:
        duplicate = row("Duplicate", "nonstandard_or_playtest_ruleset")
        payload = {"residual": [duplicate, dict(duplicate)]}
        with self.assertRaisesRegex(ValueError, "present and unique"):
            dispositions.build(payload, json.dumps(payload).encode())


if __name__ == "__main__":
    unittest.main()
