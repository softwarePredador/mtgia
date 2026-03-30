import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_engine.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';

void main() {
  group('LifeCounterGameTimerEngine', () {
    test('start creates an active running timer', () {
      final state = LifeCounterGameTimerEngine.start(nowEpochMs: 1000);

      expect(state.startTimeEpochMs, 1000);
      expect(state.isPaused, isFalse);
      expect(state.pausedTimeEpochMs, isNull);
      expect(state.isActive, isTrue);
    });

    test('pause freezes elapsed time at the pause instant', () {
      final started = LifeCounterGameTimerEngine.start(nowEpochMs: 1000);
      final paused = LifeCounterGameTimerEngine.pause(
        started,
        nowEpochMs: 6100,
      );

      expect(paused.isPaused, isTrue);
      expect(paused.pausedTimeEpochMs, 6100);
      expect(
        LifeCounterGameTimerEngine.elapsedMillisecondsAt(
          paused,
          nowEpochMs: 9100,
        ),
        5100,
      );
      expect(
        LifeCounterGameTimerEngine.elapsedSecondsAt(paused, nowEpochMs: 9100),
        5,
      );
    });

    test('resume preserves elapsed time and clears paused marker', () {
      const paused = LifeCounterGameTimerState(
        startTimeEpochMs: 1000,
        isPaused: true,
        pausedTimeEpochMs: 6100,
      );

      final resumed = LifeCounterGameTimerEngine.resume(
        paused,
        nowEpochMs: 10_000,
      );

      expect(resumed.isPaused, isFalse);
      expect(resumed.pausedTimeEpochMs, isNull);
      expect(resumed.startTimeEpochMs, 4900);
      expect(
        LifeCounterGameTimerEngine.elapsedMillisecondsAt(
          resumed,
          nowEpochMs: 10_000,
        ),
        5100,
      );
    });

    test('reset clears the timer', () {
      final started = LifeCounterGameTimerEngine.start(nowEpochMs: 1000);
      final reset = LifeCounterGameTimerEngine.reset();

      expect(started.isActive, isTrue);
      expect(reset.isActive, isFalse);
      expect(reset.isPaused, isFalse);
      expect(reset.startTimeEpochMs, isNull);
      expect(reset.pausedTimeEpochMs, isNull);
    });

    test('pause and resume ignore incompatible states', () {
      const inactive = LifeCounterGameTimerState(
        startTimeEpochMs: null,
        isPaused: false,
        pausedTimeEpochMs: null,
      );
      const alreadyPaused = LifeCounterGameTimerState(
        startTimeEpochMs: 1000,
        isPaused: true,
        pausedTimeEpochMs: 2000,
      );
      const alreadyRunning = LifeCounterGameTimerState(
        startTimeEpochMs: 1000,
        isPaused: false,
        pausedTimeEpochMs: null,
      );

      expect(
        LifeCounterGameTimerEngine.pause(alreadyPaused, nowEpochMs: 3000),
        same(alreadyPaused),
      );
      expect(
        LifeCounterGameTimerEngine.pause(inactive, nowEpochMs: 3000),
        same(inactive),
      );
      expect(
        LifeCounterGameTimerEngine.resume(alreadyRunning, nowEpochMs: 3000),
        same(alreadyRunning),
      );
      expect(
        LifeCounterGameTimerEngine.resume(inactive, nowEpochMs: 3000),
        same(inactive),
      );
    });

    test('elapsed time never goes negative', () {
      const running = LifeCounterGameTimerState(
        startTimeEpochMs: 5000,
        isPaused: false,
        pausedTimeEpochMs: null,
      );
      const paused = LifeCounterGameTimerState(
        startTimeEpochMs: 5000,
        isPaused: true,
        pausedTimeEpochMs: 4000,
      );

      expect(
        LifeCounterGameTimerEngine.elapsedMillisecondsAt(
          running,
          nowEpochMs: 4000,
        ),
        0,
      );
      expect(
        LifeCounterGameTimerEngine.elapsedMillisecondsAt(
          paused,
          nowEpochMs: 6000,
        ),
        0,
      );
    });
  });
}
