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
      expect(setup.toRequestJson(), {
        'opponent_deck_id': 'opponent',
        'test_objective': 'focus_cards',
        'focus_cards': const ['Sol Ring', 'Arcane Signet', 'Rhystic Study'],
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
        'deck_snapshot_hash': 'hash-1',
      });

      expect(preflight.canStart, isFalse);
      expect(preflight.engineCoverage['forge'], 'unknown');
      expect(preflight.blockers, ['deck_requires_100_cards']);
      expect(preflight.deckSnapshotHash, 'hash-1');
    });
  });
}
