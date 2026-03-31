import 'dart:convert';

import 'package:flutter/foundation.dart';

const String lotusUiSnapshotPrefsKey = 'lotus_ui_snapshot_v1';

@immutable
class LotusUiSnapshot {
  const LotusUiSnapshot({
    required this.capturedAtEpochMs,
    required this.bodyClassName,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.screenWidth,
    required this.screenHeight,
    required this.setLifeByTapEnabled,
    required this.verticalTapAreasEnabled,
    required this.cleanLookEnabled,
    required this.firstPlayerCardWidth,
    required this.firstPlayerCardHeight,
    required this.regularCounterCount,
    required this.commanderDamageCounterCount,
    required this.gameTimerCount,
    required this.gameTimerPausedCount,
    required this.gameTimerText,
    required this.clockCount,
    required this.clockWithGameTimerCount,
    required this.playerCardCount,
  });

  final int capturedAtEpochMs;
  final String bodyClassName;
  final double viewportWidth;
  final double viewportHeight;
  final double screenWidth;
  final double screenHeight;
  final bool setLifeByTapEnabled;
  final bool verticalTapAreasEnabled;
  final bool cleanLookEnabled;
  final double firstPlayerCardWidth;
  final double firstPlayerCardHeight;
  final int regularCounterCount;
  final int commanderDamageCounterCount;
  final int gameTimerCount;
  final int gameTimerPausedCount;
  final String gameTimerText;
  final int clockCount;
  final int clockWithGameTimerCount;
  final int playerCardCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'captured_at_epoch_ms': capturedAtEpochMs,
      'body_class_name': bodyClassName,
      'viewport_width': viewportWidth,
      'viewport_height': viewportHeight,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'set_life_by_tap_enabled': setLifeByTapEnabled,
      'vertical_tap_areas_enabled': verticalTapAreasEnabled,
      'clean_look_enabled': cleanLookEnabled,
      'first_player_card_width': firstPlayerCardWidth,
      'first_player_card_height': firstPlayerCardHeight,
      'regular_counter_count': regularCounterCount,
      'commander_damage_counter_count': commanderDamageCounterCount,
      'game_timer_count': gameTimerCount,
      'game_timer_paused_count': gameTimerPausedCount,
      'game_timer_text': gameTimerText,
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
    final viewportWidth = (payload['viewport_width'] as num?)?.toDouble();
    final viewportHeight = (payload['viewport_height'] as num?)?.toDouble();
    final screenWidth = (payload['screen_width'] as num?)?.toDouble();
    final screenHeight = (payload['screen_height'] as num?)?.toDouble();
    final setLifeByTapEnabled = payload['set_life_by_tap_enabled'];
    final verticalTapAreasEnabled = payload['vertical_tap_areas_enabled'];
    final cleanLookEnabled = payload['clean_look_enabled'];
    final firstPlayerCardWidth =
        (payload['first_player_card_width'] as num?)?.toDouble();
    final firstPlayerCardHeight =
        (payload['first_player_card_height'] as num?)?.toDouble();
    final regularCounterCount =
        (payload['regular_counter_count'] as num?)?.toInt();
    final commanderDamageCounterCount =
        (payload['commander_damage_counter_count'] as num?)?.toInt();
    final gameTimerCount = (payload['game_timer_count'] as num?)?.toInt();
    final gameTimerPausedCount =
        (payload['game_timer_paused_count'] as num?)?.toInt();
    final gameTimerText = payload['game_timer_text'];
    final clockCount = (payload['clock_count'] as num?)?.toInt();
    final clockWithGameTimerCount =
        (payload['clock_with_game_timer_count'] as num?)?.toInt();
    final playerCardCount = (payload['player_card_count'] as num?)?.toInt();

    if (capturedAtEpochMs == null ||
        bodyClassName is! String ||
        viewportWidth == null ||
        viewportHeight == null ||
        screenWidth == null ||
        screenHeight == null ||
        setLifeByTapEnabled is! bool ||
        verticalTapAreasEnabled is! bool ||
        cleanLookEnabled is! bool ||
        firstPlayerCardWidth == null ||
        firstPlayerCardHeight == null ||
        regularCounterCount == null ||
        commanderDamageCounterCount == null ||
        gameTimerCount == null ||
        gameTimerPausedCount == null ||
        gameTimerText is! String ||
        clockCount == null ||
        clockWithGameTimerCount == null ||
        playerCardCount == null) {
      return null;
    }

    return LotusUiSnapshot(
      capturedAtEpochMs: capturedAtEpochMs,
      bodyClassName: bodyClassName,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      setLifeByTapEnabled: setLifeByTapEnabled,
      verticalTapAreasEnabled: verticalTapAreasEnabled,
      cleanLookEnabled: cleanLookEnabled,
      firstPlayerCardWidth: firstPlayerCardWidth,
      firstPlayerCardHeight: firstPlayerCardHeight,
      regularCounterCount: regularCounterCount,
      commanderDamageCounterCount: commanderDamageCounterCount,
      gameTimerCount: gameTimerCount,
      gameTimerPausedCount: gameTimerPausedCount,
      gameTimerText: gameTimerText,
      clockCount: clockCount,
      clockWithGameTimerCount: clockWithGameTimerCount,
      playerCardCount: playerCardCount,
    );
  }
}
