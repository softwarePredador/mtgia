import 'dart:convert';

import 'package:flutter/foundation.dart';

const String lifeCounterGameTimerStatePrefsKey =
    'life_counter_game_timer_state_v1';

@immutable
class LifeCounterGameTimerState {
  const LifeCounterGameTimerState({
    required this.startTimeEpochMs,
    required this.isPaused,
    required this.pausedTimeEpochMs,
  });

  final int? startTimeEpochMs;
  final bool isPaused;
  final int? pausedTimeEpochMs;

  bool get isActive => startTimeEpochMs != null;

  LifeCounterGameTimerState copyWith({
    Object? startTimeEpochMs = _unset,
    bool? isPaused,
    Object? pausedTimeEpochMs = _unset,
  }) {
    return LifeCounterGameTimerState(
      startTimeEpochMs:
          identical(startTimeEpochMs, _unset)
              ? this.startTimeEpochMs
              : startTimeEpochMs as int?,
      isPaused: isPaused ?? this.isPaused,
      pausedTimeEpochMs:
          identical(pausedTimeEpochMs, _unset)
              ? this.pausedTimeEpochMs
              : pausedTimeEpochMs as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'start_time_epoch_ms': startTimeEpochMs,
      'is_paused': isPaused,
      'paused_time_epoch_ms': pausedTimeEpochMs,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static LifeCounterGameTimerState? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return tryFromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static LifeCounterGameTimerState? tryFromJson(Map<String, dynamic> payload) {
    final startTimeEpochMs = (payload['start_time_epoch_ms'] as num?)?.toInt();
    final isPaused = payload['is_paused'];
    final pausedTimeEpochMs =
        (payload['paused_time_epoch_ms'] as num?)?.toInt();

    if (isPaused is! bool) {
      return null;
    }

    if (startTimeEpochMs == null && pausedTimeEpochMs != null) {
      return null;
    }

    return LifeCounterGameTimerState(
      startTimeEpochMs: startTimeEpochMs,
      isPaused: isPaused,
      pausedTimeEpochMs: pausedTimeEpochMs,
    );
  }

  static const Object _unset = Object();
}
