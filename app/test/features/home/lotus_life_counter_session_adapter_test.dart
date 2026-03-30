import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_session_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';

void main() {
  group('LotusLifeCounterSessionAdapter', () {
    test('derives a canonical session from a compatible Lotus snapshot', () {
      final snapshot = LotusStorageSnapshot(
        values: {
          'playerCount': '4',
          'startingLife2P': '20',
          'startingLifeMP': '40',
          'turnTracker': jsonEncode({
            'startingPlayerIndex': 2,
          }),
          'players': jsonEncode([
            {
              'name': 'Player 1',
              'life': 38,
              'alive': true,
              'partnerCommander': false,
              'counters': {
                'poison': 1,
                'energy': 5,
                'xp': 2,
                'tax-1': 4,
              },
              'commanderDamage': [
                {
                  'player': 'Player 2',
                  'damage': {
                    'commander1': 7,
                  },
                },
              ],
            },
            {
              'name': 'Player 2',
              'life': 31,
              'alive': true,
              'partnerCommander': true,
              'counters': {
                'poison': 0,
                'energy': 1,
                'xp': 0,
                'tax-1': 2,
                'tax-2': 6,
              },
              'commanderDamage': [],
            },
            {
              'name': 'Player 3',
              'life': 15,
              'alive': false,
              'partnerCommander': false,
              'counters': {
                'poison': 4,
                'energy': 0,
                'xp': 3,
              },
              'commanderDamage': [
                {
                  'player': 'Player 4',
                  'damage': {
                    'commander1': 3,
                    'commander2': 2,
                  },
                },
              ],
            },
            {
              'name': 'Player 4',
              'life': 22,
              'alive': true,
              'partnerCommander': false,
              'counters': {},
              'commanderDamage': [],
            },
          ]),
        },
      );

      final session = LotusLifeCounterSessionAdapter.tryBuildSession(snapshot);

      expect(session, isNotNull);
      expect(session!.playerCount, 4);
      expect(session.startingLifeTwoPlayer, 20);
      expect(session.startingLifeMultiPlayer, 40);
      expect(session.lives, const [38, 31, 15, 22]);
      expect(session.poison, const [1, 0, 4, 0]);
      expect(session.energy, const [5, 1, 0, 0]);
      expect(session.experience, const [2, 0, 3, 0]);
      expect(session.commanderCasts, const [2, 3, 0, 0]);
      expect(session.commanderDamage[0][1], 7);
      expect(session.commanderDamage[2][3], 5);
      expect(session.firstPlayerIndex, 2);
    });

    test('returns null for snapshots without players payload', () {
      const snapshot = LotusStorageSnapshot(
        values: {
          'playerCount': '4',
        },
      );

      final session = LotusLifeCounterSessionAdapter.tryBuildSession(snapshot);

      expect(session, isNull);
    });
  });
}
