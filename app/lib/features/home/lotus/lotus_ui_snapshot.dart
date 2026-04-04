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
    required this.documentScrollWidth,
    required this.documentScrollHeight,
    required this.horizontalOverflowPx,
    required this.verticalOverflowPx,
    required this.visualSkinApplied,
    required this.uiFontFamily,
    required this.setLifeByTapEnabled,
    required this.verticalTapAreasEnabled,
    required this.cleanLookEnabled,
    required this.firstPlayerCardWidth,
    required this.firstPlayerCardHeight,
    required this.firstPlayerLifeBoxWidth,
    required this.firstPlayerLifeBoxHeight,
    required this.firstPlayerNameFontFamily,
    required this.firstPlayerNameFontSize,
    required this.firstLifeCountFontFamily,
    required this.firstLifeCountFontSize,
    required this.regularCounterCount,
    required this.commanderDamageCounterCount,
    required this.gameTimerCount,
    required this.gameTimerPausedCount,
    required this.gameTimerText,
    required this.gameTimerFontFamily,
    required this.gameTimerFontSize,
    required this.clockCount,
    required this.clockWithGameTimerCount,
    required this.turnTrackerFontFamily,
    required this.turnTrackerFontSize,
    required this.playerCardCount,
  });

  final int capturedAtEpochMs;
  final String bodyClassName;
  final double viewportWidth;
  final double viewportHeight;
  final double screenWidth;
  final double screenHeight;
  final double documentScrollWidth;
  final double documentScrollHeight;
  final double horizontalOverflowPx;
  final double verticalOverflowPx;
  final bool visualSkinApplied;
  final String uiFontFamily;
  final bool setLifeByTapEnabled;
  final bool verticalTapAreasEnabled;
  final bool cleanLookEnabled;
  final double firstPlayerCardWidth;
  final double firstPlayerCardHeight;
  final double firstPlayerLifeBoxWidth;
  final double firstPlayerLifeBoxHeight;
  final String firstPlayerNameFontFamily;
  final double firstPlayerNameFontSize;
  final String firstLifeCountFontFamily;
  final double firstLifeCountFontSize;
  final int regularCounterCount;
  final int commanderDamageCounterCount;
  final int gameTimerCount;
  final int gameTimerPausedCount;
  final String gameTimerText;
  final String gameTimerFontFamily;
  final double gameTimerFontSize;
  final int clockCount;
  final int clockWithGameTimerCount;
  final String turnTrackerFontFamily;
  final double turnTrackerFontSize;
  final int playerCardCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'captured_at_epoch_ms': capturedAtEpochMs,
      'body_class_name': bodyClassName,
      'viewport_width': viewportWidth,
      'viewport_height': viewportHeight,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'document_scroll_width': documentScrollWidth,
      'document_scroll_height': documentScrollHeight,
      'horizontal_overflow_px': horizontalOverflowPx,
      'vertical_overflow_px': verticalOverflowPx,
      'visual_skin_applied': visualSkinApplied,
      'ui_font_family': uiFontFamily,
      'set_life_by_tap_enabled': setLifeByTapEnabled,
      'vertical_tap_areas_enabled': verticalTapAreasEnabled,
      'clean_look_enabled': cleanLookEnabled,
      'first_player_card_width': firstPlayerCardWidth,
      'first_player_card_height': firstPlayerCardHeight,
      'first_player_life_box_width': firstPlayerLifeBoxWidth,
      'first_player_life_box_height': firstPlayerLifeBoxHeight,
      'first_player_name_font_family': firstPlayerNameFontFamily,
      'first_player_name_font_size': firstPlayerNameFontSize,
      'first_life_count_font_family': firstLifeCountFontFamily,
      'first_life_count_font_size': firstLifeCountFontSize,
      'regular_counter_count': regularCounterCount,
      'commander_damage_counter_count': commanderDamageCounterCount,
      'game_timer_count': gameTimerCount,
      'game_timer_paused_count': gameTimerPausedCount,
      'game_timer_text': gameTimerText,
      'game_timer_font_family': gameTimerFontFamily,
      'game_timer_font_size': gameTimerFontSize,
      'clock_count': clockCount,
      'clock_with_game_timer_count': clockWithGameTimerCount,
      'turn_tracker_font_family': turnTrackerFontFamily,
      'turn_tracker_font_size': turnTrackerFontSize,
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
    final capturedAtEpochMs =
        (payload['captured_at_epoch_ms'] as num?)?.toInt();
    final bodyClassName = payload['body_class_name'];
    final viewportWidth = (payload['viewport_width'] as num?)?.toDouble();
    final viewportHeight = (payload['viewport_height'] as num?)?.toDouble();
    final screenWidth = (payload['screen_width'] as num?)?.toDouble();
    final screenHeight = (payload['screen_height'] as num?)?.toDouble();
    final documentScrollWidth =
        (payload['document_scroll_width'] as num?)?.toDouble();
    final documentScrollHeight =
        (payload['document_scroll_height'] as num?)?.toDouble();
    final horizontalOverflowPx =
        (payload['horizontal_overflow_px'] as num?)?.toDouble();
    final verticalOverflowPx =
        (payload['vertical_overflow_px'] as num?)?.toDouble();
    final visualSkinApplied = payload['visual_skin_applied'];
    final uiFontFamily = payload['ui_font_family'];
    final setLifeByTapEnabled = payload['set_life_by_tap_enabled'];
    final verticalTapAreasEnabled = payload['vertical_tap_areas_enabled'];
    final cleanLookEnabled = payload['clean_look_enabled'];
    final firstPlayerCardWidth =
        (payload['first_player_card_width'] as num?)?.toDouble();
    final firstPlayerCardHeight =
        (payload['first_player_card_height'] as num?)?.toDouble();
    final firstPlayerLifeBoxWidth =
        (payload['first_player_life_box_width'] as num?)?.toDouble();
    final firstPlayerLifeBoxHeight =
        (payload['first_player_life_box_height'] as num?)?.toDouble();
    final firstPlayerNameFontFamily = payload['first_player_name_font_family'];
    final firstPlayerNameFontSize =
        (payload['first_player_name_font_size'] as num?)?.toDouble();
    final firstLifeCountFontFamily = payload['first_life_count_font_family'];
    final firstLifeCountFontSize =
        (payload['first_life_count_font_size'] as num?)?.toDouble();
    final regularCounterCount =
        (payload['regular_counter_count'] as num?)?.toInt();
    final commanderDamageCounterCount =
        (payload['commander_damage_counter_count'] as num?)?.toInt();
    final gameTimerCount = (payload['game_timer_count'] as num?)?.toInt();
    final gameTimerPausedCount =
        (payload['game_timer_paused_count'] as num?)?.toInt();
    final gameTimerText = payload['game_timer_text'];
    final gameTimerFontFamily = payload['game_timer_font_family'];
    final gameTimerFontSize =
        (payload['game_timer_font_size'] as num?)?.toDouble();
    final clockCount = (payload['clock_count'] as num?)?.toInt();
    final clockWithGameTimerCount =
        (payload['clock_with_game_timer_count'] as num?)?.toInt();
    final turnTrackerFontFamily = payload['turn_tracker_font_family'];
    final turnTrackerFontSize =
        (payload['turn_tracker_font_size'] as num?)?.toDouble();
    final playerCardCount = (payload['player_card_count'] as num?)?.toInt();

    if (capturedAtEpochMs == null ||
        bodyClassName is! String ||
        viewportWidth == null ||
        viewportHeight == null ||
        screenWidth == null ||
        screenHeight == null ||
        documentScrollWidth == null ||
        documentScrollHeight == null ||
        horizontalOverflowPx == null ||
        verticalOverflowPx == null ||
        visualSkinApplied is! bool ||
        uiFontFamily is! String ||
        setLifeByTapEnabled is! bool ||
        verticalTapAreasEnabled is! bool ||
        cleanLookEnabled is! bool ||
        firstPlayerCardWidth == null ||
        firstPlayerCardHeight == null ||
        firstPlayerLifeBoxWidth == null ||
        firstPlayerLifeBoxHeight == null ||
        firstPlayerNameFontFamily is! String ||
        firstPlayerNameFontSize == null ||
        firstLifeCountFontFamily is! String ||
        firstLifeCountFontSize == null ||
        regularCounterCount == null ||
        commanderDamageCounterCount == null ||
        gameTimerCount == null ||
        gameTimerPausedCount == null ||
        gameTimerText is! String ||
        gameTimerFontFamily is! String ||
        gameTimerFontSize == null ||
        clockCount == null ||
        clockWithGameTimerCount == null ||
        turnTrackerFontFamily is! String ||
        turnTrackerFontSize == null ||
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
      documentScrollWidth: documentScrollWidth,
      documentScrollHeight: documentScrollHeight,
      horizontalOverflowPx: horizontalOverflowPx,
      verticalOverflowPx: verticalOverflowPx,
      visualSkinApplied: visualSkinApplied,
      uiFontFamily: uiFontFamily,
      setLifeByTapEnabled: setLifeByTapEnabled,
      verticalTapAreasEnabled: verticalTapAreasEnabled,
      cleanLookEnabled: cleanLookEnabled,
      firstPlayerCardWidth: firstPlayerCardWidth,
      firstPlayerCardHeight: firstPlayerCardHeight,
      firstPlayerLifeBoxWidth: firstPlayerLifeBoxWidth,
      firstPlayerLifeBoxHeight: firstPlayerLifeBoxHeight,
      firstPlayerNameFontFamily: firstPlayerNameFontFamily,
      firstPlayerNameFontSize: firstPlayerNameFontSize,
      firstLifeCountFontFamily: firstLifeCountFontFamily,
      firstLifeCountFontSize: firstLifeCountFontSize,
      regularCounterCount: regularCounterCount,
      commanderDamageCounterCount: commanderDamageCounterCount,
      gameTimerCount: gameTimerCount,
      gameTimerPausedCount: gameTimerPausedCount,
      gameTimerText: gameTimerText,
      gameTimerFontFamily: gameTimerFontFamily,
      gameTimerFontSize: gameTimerFontSize,
      clockCount: clockCount,
      clockWithGameTimerCount: clockWithGameTimerCount,
      turnTrackerFontFamily: turnTrackerFontFamily,
      turnTrackerFontSize: turnTrackerFontSize,
      playerCardCount: playerCardCount,
    );
  }
}
