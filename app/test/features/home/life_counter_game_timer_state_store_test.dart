import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LifeCounterGameTimerStateStore', () {
    late LifeCounterGameTimerStateStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = LifeCounterGameTimerStateStore();
    });

    test('saves and restores canonical game timer state', () async {
      const state = LifeCounterGameTimerState(
        startTimeEpochMs: 1711800000000,
        isPaused: true,
        pausedTimeEpochMs: 1711800005000,
      );

      await store.save(state);
      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.toJson(), state.toJson());
    });

    test('returns null for invalid payloads', () async {
      SharedPreferences.setMockInitialValues({
        lifeCounterGameTimerStatePrefsKey: '{"start_time_epoch_ms":"oops"}',
      });
      store = LifeCounterGameTimerStateStore();

      final restored = await store.load();

      expect(restored, isNull);
    });

    test('rejects internally inconsistent timer combinations', () {
      expect(
        LifeCounterGameTimerState.tryFromJson({
          'start_time_epoch_ms': null,
          'is_paused': true,
          'paused_time_epoch_ms': null,
        }),
        isNull,
      );
      expect(
        LifeCounterGameTimerState.tryFromJson({
          'start_time_epoch_ms': 1000,
          'is_paused': false,
          'paused_time_epoch_ms': 2000,
        }),
        isNull,
      );
      expect(
        LifeCounterGameTimerState.tryFromJson({
          'start_time_epoch_ms': 2000,
          'is_paused': true,
          'paused_time_epoch_ms': 1000,
        }),
        isNull,
      );
      expect(
        LifeCounterGameTimerState.tryFromJson({
          'start_time_epoch_ms': -1,
          'is_paused': false,
          'paused_time_epoch_ms': null,
        }),
        isNull,
      );
      expect(
        LifeCounterGameTimerState.tryFromJson({
          'start_time_epoch_ms': 'invalid',
          'is_paused': false,
          'paused_time_epoch_ms': null,
        }),
        isNull,
      );
    });

    test('clears persisted state', () async {
      await store.save(
        const LifeCounterGameTimerState(
          startTimeEpochMs: 1711800000000,
          isPaused: false,
          pausedTimeEpochMs: null,
        ),
      );

      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
