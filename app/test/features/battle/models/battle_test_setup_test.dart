import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/battle/models/battle_test_setup.dart';

void main() {
  group('BattleTestSetup', () {
    test('normalizes at most three unique focus cards', () {
      final setup = BattleTestSetup(
        opponentDeckId: ' opponent ',
        objective: BattleTestObjective.focusCards,
        seriesSize: BattleSeriesSize.ten,
        focusCards: const [
          ' Sol Ring ',
          'sol ring',
          '',
          'Arcane Signet',
          'Rhystic Study',
          'Cyclonic Rift',
        ],
      );

      expect(setup.focusCards, const [
        'Sol Ring',
        'Arcane Signet',
        'Rhystic Study',
      ]);
      expect(setup.seriesSize.count, 10);
      expect(setup.launchMode, BattleTestLaunchMode.automatic);
      expect(setup.toRequestJson(), {
        'opponent_deck_id': 'opponent',
        'test_objective': 'focus_cards',
        'focus_cards': const ['Sol Ring', 'Arcane Signet', 'Rhystic Study'],
      });
    });

    test('keeps the interactive launch choice out of the API payload', () {
      final setup = BattleTestSetup(
        opponentDeckId: 'opponent',
        launchMode: BattleTestLaunchMode.interactive,
      );

      expect(setup.launchMode, BattleTestLaunchMode.interactive);
      expect(setup.toRequestJson(), {
        'opponent_deck_id': 'opponent',
        'test_objective': 'general',
      });
    });

    test('offers only the supported independent sample sizes', () {
      expect(BattleSeriesSize.values.map((value) => value.count), const [
        1,
        3,
        5,
        10,
      ]);
      expect(BattleSeriesSize.single.isSeries, isFalse);
      expect(BattleSeriesSize.three.isSeries, isTrue);
    });
  });

  group('BattlePreflight', () {
    test('keeps unknown coverage explicit and exposes blockers', () {
      final preflight = BattlePreflight.fromJson(const {
        'status': 'blocked',
        'card_count': 99,
        'commander_count': 1,
        'validation_state': 'draft',
        'available_opponent_count': 4,
        'engine_coverage': {'xmage': 'partial', 'forge': null},
        'blockers': ['deck_requires_100_cards'],
        'unsupported_cards': [
          {'engine': 'xmage', 'deck_key': 'deck_a', 'name': 'Lorehold'},
          {'engine': 'forge', 'deck_key': 'deck_a', 'name': 'lorehold'},
          {'engine': 'xmage', 'deck_key': 'deck_b', 'name': 'Molecule Man'},
        ],
        'deck_snapshot_hash': 'hash-1',
      });

      expect(preflight.canStart, isFalse);
      expect(preflight.engineCoverage['forge'], 'unknown');
      expect(preflight.blockers, ['deck_requires_100_cards']);
      expect(preflight.unsupportedCardNames, ['Lorehold', 'Molecule Man']);
      expect(preflight.deckSnapshotHash, 'hash-1');
    });

    test('interactive readiness requires an explicit XMage selection', () {
      final forge = BattlePreflight.fromJson(const {
        'status': 'ready',
        'mode': 'interactive',
        'selected_engine': 'forge',
        'engine_coverage': {'forge': 'ready'},
        'blockers': <String>[],
      }, requestedMode: 'interactive');
      final xmage = BattlePreflight.fromJson(const {
        'status': 'ready',
        'mode': 'interactive',
        'selected_engine': 'xmage',
        'engine_coverage': {'xmage': 'ready'},
        'blockers': <String>[],
      }, requestedMode: 'interactive');

      expect(forge.canStart, isTrue);
      expect(forge.canStartInteractive, isFalse);
      expect(xmage.canStartInteractive, isTrue);
    });
  });
}
