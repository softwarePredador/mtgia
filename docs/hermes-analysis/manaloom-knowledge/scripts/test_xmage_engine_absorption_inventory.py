#!/usr/bin/env python3
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

import xmage_engine_absorption_inventory as inventory


class XMageEngineAbsorptionInventoryTests(unittest.TestCase):
    def _root(self) -> Path:
        tmpdir = tempfile.TemporaryDirectory()
        self.addCleanup(tmpdir.cleanup)
        root = Path(tmpdir.name)
        files = {
            "Mage.Sets/src/mage/cards/l/LightningBolt.java": "public final class LightningBolt extends CardImpl {}",
            "Mage/src/main/java/mage/abilities/effects/common/DamageTargetEffect.java": "public class DamageTargetEffect extends OneShotEffect {}",
            "Mage/src/main/java/mage/abilities/common/SimpleStaticAbility.java": "public class SimpleStaticAbility extends StaticAbility {}",
            "Mage/src/main/java/mage/target/common/TargetCreaturePermanent.java": "public class TargetCreaturePermanent extends TargetPermanent {}",
            "Mage/src/main/java/mage/filter/common/FilterCreaturePermanent.java": "public class FilterCreaturePermanent extends FilterPermanent {}",
            "Mage/src/main/java/mage/watchers/common/SpellsCastWatcher.java": "public class SpellsCastWatcher extends Watcher { public void watch(GameEvent event, Game game) {} }",
            "Mage/src/main/java/mage/game/GameImpl.java": "public class GameImpl { public boolean checkStateAndTriggered(){ return true; } public void applyEffects(){} }",
            "Mage/src/main/java/mage/game/GameState.java": "public class GameState { public boolean replaceEvent(GameEvent event, Game game){ return false; } }",
            "Mage/src/main/java/mage/game/events/GameEvent.java": "public class GameEvent { enum EventType { CAST_SPELL, DAMAGE_PLAYER, ZONE_CHANGE } }",
            "Mage/src/main/java/mage/game/turn/Step.java": "public class Step { public void priority(Game game, UUID id, boolean resuming){} }",
            "Mage/src/main/java/mage/game/stack/SpellStack.java": "public class SpellStack {}",
            "Mage/src/main/java/mage/players/PlayerImpl.java": "public class PlayerImpl { boolean passedUntilStackResolved; }",
            "Mage/src/main/java/mage/util/validation/CommanderValidator.java": "public class CommanderValidator {}",
            "Mage.Tests/src/test/java/org/mage/test/player/TestPlayer.java": "public class TestPlayer { void t(){ addCard(); castSpell(); setChoice(); waitStackResolved(); checkLife(); execute(); } }",
        }
        for relative_path, source in files.items():
            path = root / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(source, encoding="utf-8")
        return root

    def test_inventory_is_read_only_and_counts_core_sources(self) -> None:
        report = inventory.build_inventory(self._root())

        self.assertEqual(report["mutations_performed"], [])
        self.assertEqual(report["summary"]["card_implementation_files"], 1)
        self.assertEqual(report["summary"]["test_files"], 1)
        self.assertEqual(report["facets"]["effect_library"]["java_files"], 1)
        self.assertEqual(report["facets"]["test_scenario_corpus"]["java_files"], 1)
        self.assertEqual(report["effect_taxonomy"]["token_counts"]["targets"]["Target"], 1)
        self.assertEqual(report["effect_taxonomy"]["token_counts"]["filters"]["Filter"], 1)

    def test_extracts_event_and_test_corpus_taxonomy(self) -> None:
        report = inventory.build_inventory(self._root())

        self.assertEqual(report["game_event_taxonomy"]["event_type_count"], 3)
        self.assertIn("CAST_SPELL", report["game_event_taxonomy"]["event_type_sample"])
        self.assertEqual(report["test_corpus"]["test_command_usage"]["castSpell"], 1)
        self.assertEqual(report["test_corpus"]["test_command_usage"]["waitStackResolved"], 1)

    def test_markdown_contains_recommendations(self) -> None:
        report = inventory.build_inventory(self._root())
        markdown = inventory.render_markdown(report)

        self.assertIn("XMage Engine Absorption Inventory", markdown)
        self.assertIn("Execute catalog-covered cards", markdown)
        self.assertIn("priority_stack_turn_engine", markdown)

    @mock.patch.object(inventory.subprocess, "run")
    def test_source_pin_mismatch_blocks_inventory(self, run: mock.Mock) -> None:
        run.return_value = mock.Mock(
            returncode=0,
            stdout="0" * 40 + "\n",
            stderr="",
        )

        report = inventory.build_inventory(
            self._root(),
            expected_commit="1" * 40,
        )

        self.assertEqual(report["status"], "blocked_unpinned_source")
        self.assertEqual(report["source_pin"]["error"], "source_root_is_not_at_runtime_pin")


if __name__ == "__main__":
    unittest.main()
