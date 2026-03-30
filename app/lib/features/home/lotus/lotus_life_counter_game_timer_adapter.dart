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
      return LifeCounterGameTimerState(
        startTimeEpochMs: (payload['startTime'] as num?)?.toInt(),
        isPaused: payload['isPaused'] == true,
        pausedTimeEpochMs: (payload['pausedTime'] as num?)?.toInt(),
      );
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
