import 'dart:convert';

import 'package:flutter/foundation.dart';

const String lifeCounterDayNightStatePrefsKey =
    'life_counter_day_night_state_v1';

@immutable
class LifeCounterDayNightState {
  const LifeCounterDayNightState({required this.isNight});

  final bool isNight;

  String get mode => isNight ? 'night' : 'day';

  LifeCounterDayNightState copyWith({bool? isNight}) {
    return LifeCounterDayNightState(isNight: isNight ?? this.isNight);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'is_night': isNight};
  }

  String toJsonString() => jsonEncode(toJson());

  static LifeCounterDayNightState? tryParse(String? raw) {
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

  static LifeCounterDayNightState? tryFromJson(Map<String, dynamic> payload) {
    final isNight = payload['is_night'];
    if (isNight is! bool) {
      return null;
    }

    return LifeCounterDayNightState(isNight: isNight);
  }
}
