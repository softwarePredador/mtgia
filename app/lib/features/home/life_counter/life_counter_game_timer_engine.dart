import 'life_counter_game_timer_state.dart';

class LifeCounterGameTimerEngine {
  LifeCounterGameTimerEngine._();

  static const LifeCounterGameTimerState inactive = LifeCounterGameTimerState(
    startTimeEpochMs: null,
    isPaused: false,
    pausedTimeEpochMs: null,
  );

  static LifeCounterGameTimerState start({required int nowEpochMs}) {
    return LifeCounterGameTimerState(
      startTimeEpochMs: nowEpochMs,
      isPaused: false,
      pausedTimeEpochMs: null,
    );
  }

  static LifeCounterGameTimerState reset() => inactive;

  static LifeCounterGameTimerState pause(
    LifeCounterGameTimerState state, {
    required int nowEpochMs,
  }) {
    if (!state.isActive || state.isPaused) {
      return state;
    }

    final startTimeEpochMs = state.startTimeEpochMs;
    if (startTimeEpochMs == null) {
      return inactive;
    }

    final safePausedTime =
        nowEpochMs < startTimeEpochMs ? startTimeEpochMs : nowEpochMs;

    return state.copyWith(isPaused: true, pausedTimeEpochMs: safePausedTime);
  }

  static LifeCounterGameTimerState resume(
    LifeCounterGameTimerState state, {
    required int nowEpochMs,
  }) {
    if (!state.isActive || !state.isPaused) {
      return state;
    }

    final elapsedMilliseconds = elapsedMillisecondsAt(
      state,
      nowEpochMs: nowEpochMs,
    );

    return LifeCounterGameTimerState(
      startTimeEpochMs: nowEpochMs - elapsedMilliseconds,
      isPaused: false,
      pausedTimeEpochMs: null,
    );
  }

  static int elapsedMillisecondsAt(
    LifeCounterGameTimerState state, {
    required int nowEpochMs,
  }) {
    final startTimeEpochMs = state.startTimeEpochMs;
    if (startTimeEpochMs == null) {
      return 0;
    }

    final endTimeEpochMs =
        state.isPaused
            ? (state.pausedTimeEpochMs ?? startTimeEpochMs)
            : nowEpochMs;

    if (endTimeEpochMs <= startTimeEpochMs) {
      return 0;
    }

    return endTimeEpochMs - startTimeEpochMs;
  }

  static int elapsedSecondsAt(
    LifeCounterGameTimerState state, {
    required int nowEpochMs,
  }) {
    return elapsedMillisecondsAt(state, nowEpochMs: nowEpochMs) ~/ 1000;
  }
}
