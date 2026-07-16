import 'dart:convert';

import '../life_counter/life_counter_game_timer_state.dart';
import 'lotus_storage_snapshot.dart';

class LotusLifeCounterGameTimerAdapter {
  LotusLifeCounterGameTimerAdapter._();

  static const String gameTimerStateKey = 'gameTimerState';

  static LifeCounterGameTimerState? tryBuildState(
    LotusStorageSnapshot snapshot,
  ) {
    final raw = snapshot.values[gameTimerStateKey];
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final payload = decoded.cast<String, dynamic>();
      final isPaused = payload['isPaused'] == true;
      return LifeCounterGameTimerState.tryFromJson(<String, dynamic>{
        'start_time_epoch_ms': (payload['startTime'] as num?)?.toInt(),
        'is_paused': isPaused,
        // Lotus represents a running timer with pausedTime: 0. Canonical state
        // uses null while running, otherwise the persisted state is internally
        // inconsistent and is rejected on the next store load.
        'paused_time_epoch_ms':
            isPaused ? (payload['pausedTime'] as num?)?.toInt() : null,
      });
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> buildSnapshotValues(
    LifeCounterGameTimerState state,
  ) {
    if (!state.isActive) {
      return const <String, String>{};
    }

    return <String, String>{
      gameTimerStateKey: jsonEncode({
        'startTime': state.startTimeEpochMs,
        'isPaused': state.isPaused,
        'pausedTime': state.pausedTimeEpochMs ?? 0,
      }),
    };
  }
}
