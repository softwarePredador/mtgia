import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_history_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_host_controller.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('persistCanonicalMirrorFromLotusSnapshot', () {
    late LifeCounterDayNightStateStore dayNightStateStore;
    late LifeCounterGameTimerStateStore gameTimerStateStore;
    late LifeCounterHistoryStore historyStore;
    late LifeCounterSessionStore sessionStore;
    late LifeCounterSettingsStore settingsStore;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dayNightStateStore = LifeCounterDayNightStateStore();
      gameTimerStateStore = LifeCounterGameTimerStateStore();
      historyStore = LifeCounterHistoryStore();
      sessionStore = LifeCounterSessionStore();
      settingsStore = LifeCounterSettingsStore();
    });

    test('mirrors canonical day night state from Lotus snapshot', () async {
      final result = await persistCanonicalMirrorFromLotusSnapshot(
        dayNightStateStore: dayNightStateStore,
        gameTimerStateStore: gameTimerStateStore,
        historyStore: historyStore,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
        snapshot: const LotusStorageSnapshot(
          values: {'__manaloom_day_night_mode': 'night'},
        ),
      );

      final storedState = await dayNightStateStore.load();
      expect(result.dayNightState, isNotNull);
      expect(result.dayNightState!.isNight, isTrue);
      expect(storedState, isNotNull);
      expect(storedState!.isNight, isTrue);
    });

    test('clears stale canonical day night state when Lotus snapshot omits it', () async {
      await dayNightStateStore.save(const LifeCounterDayNightState(isNight: true));

      final result = await persistCanonicalMirrorFromLotusSnapshot(
        dayNightStateStore: dayNightStateStore,
        gameTimerStateStore: gameTimerStateStore,
        historyStore: historyStore,
        sessionStore: sessionStore,
        settingsStore: settingsStore,
        snapshot: const LotusStorageSnapshot(values: {}),
      );

      final storedState = await dayNightStateStore.load();
      expect(result.dayNightState, isNull);
      expect(storedState, isNull);
    });
  });
}
