#!/usr/bin/env python3
"""Tests for global Commander forced focus-access scope."""

from __future__ import annotations

import os
import unittest

import battle_analyst_v9 as battle


def card(name: str, cmc: int = 1) -> dict[str, object]:
    return {"name": name, "cmc": cmc, "type_line": "Artifact"}


class GlobalCommanderForceFocusAccessScopeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.previous_target = os.environ.get(battle.EVALUATION_TARGET_ENV)

    def tearDown(self) -> None:
        if self.previous_target is None:
            os.environ.pop(battle.EVALUATION_TARGET_ENV, None)
        else:
            os.environ[battle.EVALUATION_TARGET_ENV] = self.previous_target

    def test_forced_focus_access_applies_to_current_evaluation_target(self) -> None:
        os.environ[battle.EVALUATION_TARGET_ENV] = "Kaalia of the Vast"
        active = battle.Player("Kaalia of the Vast", card("Kaalia of the Vast"), [])
        active.hand = [card(f"Filler {index}", index % 3) for index in range(7)]
        active.library = [card("Dark Ritual"), card("Library Filler")]

        applied = battle.apply_forced_focus_access_to_opening_keep(
            active,
            mode="opening_hand",
            focus_cards=["Dark Ritual"],
        )

        self.assertEqual(applied[0]["status"], "moved")
        self.assertTrue(any(row.get("name") == "Dark Ritual" for row in active.hand))
        self.assertFalse(any(row.get("name") == "Dark Ritual" for row in active.library))

    def test_forced_focus_access_does_not_apply_to_non_target_player(self) -> None:
        os.environ[battle.EVALUATION_TARGET_ENV] = "Kaalia of the Vast"
        opponent = battle.Player("Opponent", card("Opponent Commander"), [])
        opponent.hand = [card(f"Filler {index}", index % 3) for index in range(7)]
        opponent.library = [card("Dark Ritual"), card("Library Filler")]

        applied = battle.apply_forced_focus_access_to_opening_keep(
            opponent,
            mode="opening_hand",
            focus_cards=["Dark Ritual"],
        )

        self.assertEqual(applied, [])
        self.assertFalse(any(row.get("name") == "Dark Ritual" for row in opponent.hand))
        self.assertTrue(any(row.get("name") == "Dark Ritual" for row in opponent.library))


if __name__ == "__main__":
    unittest.main()
