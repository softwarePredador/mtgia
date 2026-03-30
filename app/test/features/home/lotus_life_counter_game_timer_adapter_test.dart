import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_game_timer_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';

void main() {
  group('LotusLifeCounterGameTimerAdapter', () {
    test('derives canonical game timer state from Lotus snapshot', () {
      final snapshot = LotusStorageSnapshot(
        values: {
          'gameTimerState': jsonEncode({
            'startTime': 1711800000000,
            'isPaused': true,
            'pausedTime': 1711800005000,
          }),
        },
      );

      final state = LotusLifeCounterGameTimerAdapter.tryBuildState(snapshot);

      expect(state, isNotNull);
      expect(state!.startTimeEpochMs, 1711800000000);
      expect(state.isPaused, isTrue);
      expect(state.pausedTimeEpochMs, 1711800005000);
    });

    test('returns null when game timer state is missing', () {
      const snapshot = LotusStorageSnapshot(values: {});

      final state = LotusLifeCounterGameTimerAdapter.tryBuildState(snapshot);

      expect(state, isNull);
    });

    test('serializes canonical game timer state back into Lotus snapshot', () {
      const state = LifeCounterGameTimerState(
        startTimeEpochMs: 1711800000000,
        isPaused: false,
        pausedTimeEpochMs: null,
      );

      final values = LotusLifeCounterGameTimerAdapter.buildSnapshotValues(
        state,
      );
      final decoded =
          jsonDecode(values['gameTimerState']!) as Map<String, dynamic>;

      expect(decoded['startTime'], 1711800000000);
      expect(decoded['isPaused'], isFalse);
      expect(decoded['pausedTime'], 0);
    });

    test('omits Lotus game timer state when canonical state is inactive', () {
      const state = LifeCounterGameTimerState(
        startTimeEpochMs: null,
        isPaused: false,
        pausedTimeEpochMs: null,
      );

      final values = LotusLifeCounterGameTimerAdapter.buildSnapshotValues(
        state,
      );

      expect(values, isEmpty);
    });
  });
}
