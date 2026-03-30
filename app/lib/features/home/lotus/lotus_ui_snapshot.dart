import 'dart:convert';

import 'package:flutter/foundation.dart';

const String lotusUiSnapshotPrefsKey = 'lotus_ui_snapshot_v1';

@immutable
class LotusUiSnapshot {
  const LotusUiSnapshot({
    required this.capturedAtEpochMs,
    required this.bodyClassName,
    required this.setLifeByTapEnabled,
    required this.verticalTapAreasEnabled,
    required this.cleanLookEnabled,
    required this.regularCounterCount,
    required this.commanderDamageCounterCount,
    required this.clockCount,
    required this.clockWithGameTimerCount,
    required this.playerCardCount,
  });

  final int capturedAtEpochMs;
  final String bodyClassName;
  final bool setLifeByTapEnabled;
  final bool verticalTapAreasEnabled;
  final bool cleanLookEnabled;
  final int regularCounterCount;
  final int commanderDamageCounterCount;
  final int clockCount;
  final int clockWithGameTimerCount;
  final int playerCardCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'captured_at_epoch_ms': capturedAtEpochMs,
      'body_class_name': bodyClassName,
      'set_life_by_tap_enabled': setLifeByTapEnabled,
      'vertical_tap_areas_enabled': verticalTapAreasEnabled,
      'clean_look_enabled': cleanLookEnabled,
      'regular_counter_count': regularCounterCount,
      'commander_damage_counter_count': commanderDamageCounterCount,
      'clock_count': clockCount,
      'clock_with_game_timer_count': clockWithGameTimerCount,
      'player_card_count': playerCardCount,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static LotusUiSnapshot? tryParse(String? raw) {
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

  static LotusUiSnapshot? tryFromJson(Map<String, dynamic> payload) {
    final capturedAtEpochMs = (payload['captured_at_epoch_ms'] as num?)?.toInt();
    final bodyClassName = payload['body_class_name'];
    final setLifeByTapEnabled = payload['set_life_by_tap_enabled'];
    final verticalTapAreasEnabled = payload['vertical_tap_areas_enabled'];
    final cleanLookEnabled = payload['clean_look_enabled'];
    final regularCounterCount =
        (payload['regular_counter_count'] as num?)?.toInt();
    final commanderDamageCounterCount =
        (payload['commander_damage_counter_count'] as num?)?.toInt();
    final clockCount = (payload['clock_count'] as num?)?.toInt();
    final clockWithGameTimerCount =
        (payload['clock_with_game_timer_count'] as num?)?.toInt();
    final playerCardCount = (payload['player_card_count'] as num?)?.toInt();

    if (capturedAtEpochMs == null ||
        bodyClassName is! String ||
        setLifeByTapEnabled is! bool ||
        verticalTapAreasEnabled is! bool ||
        cleanLookEnabled is! bool ||
        regularCounterCount == null ||
        commanderDamageCounterCount == null ||
        clockCount == null ||
        clockWithGameTimerCount == null ||
        playerCardCount == null) {
      return null;
    }

    return LotusUiSnapshot(
      capturedAtEpochMs: capturedAtEpochMs,
      bodyClassName: bodyClassName,
      setLifeByTapEnabled: setLifeByTapEnabled,
      verticalTapAreasEnabled: verticalTapAreasEnabled,
      cleanLookEnabled: cleanLookEnabled,
      regularCounterCount: regularCounterCount,
      commanderDamageCounterCount: commanderDamageCounterCount,
      clockCount: clockCount,
      clockWithGameTimerCount: clockWithGameTimerCount,
      playerCardCount: playerCardCount,
    );
  }
}
