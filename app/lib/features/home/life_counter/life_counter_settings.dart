import 'dart:convert';

import 'package:flutter/foundation.dart';

const String lifeCounterSettingsPrefsKey = 'life_counter_settings_v1';

@immutable
class LifeCounterSettings {
  const LifeCounterSettings({
    required this.autoKill,
    required this.lifeLossOnCommanderDamage,
    required this.showCountersOnPlayerCard,
    required this.showRegularCounters,
    required this.showCommanderDamageCounters,
    required this.clickableCommanderDamageCounters,
    required this.keepZeroCountersOnPlayerCard,
    required this.saltyDefeatMessages,
    required this.cycleSaltyDefeatMessages,
    required this.gameTimer,
    required this.gameTimerMainScreen,
    required this.showClockOnMainScreen,
    required this.randomPlayerColors,
    required this.preserveBackgroundImagesOnShuffle,
    required this.setLifeByTappingNumber,
    required this.verticalTapAreas,
    required this.cleanLook,
    required this.criticalDamageWarning,
    required this.customLongTapEnabled,
    required this.customLongTapValue,
    required this.whitelabelIcon,
  });

  static const LifeCounterSettings defaults = LifeCounterSettings(
    autoKill: true,
    lifeLossOnCommanderDamage: true,
    showCountersOnPlayerCard: true,
    showRegularCounters: true,
    showCommanderDamageCounters: false,
    clickableCommanderDamageCounters: false,
    keepZeroCountersOnPlayerCard: false,
    saltyDefeatMessages: true,
    cycleSaltyDefeatMessages: true,
    gameTimer: false,
    gameTimerMainScreen: false,
    showClockOnMainScreen: false,
    randomPlayerColors: false,
    preserveBackgroundImagesOnShuffle: true,
    setLifeByTappingNumber: true,
    verticalTapAreas: false,
    cleanLook: false,
    criticalDamageWarning: true,
    customLongTapEnabled: false,
    customLongTapValue: 10,
    whitelabelIcon: null,
  );

  final bool autoKill;
  final bool lifeLossOnCommanderDamage;
  final bool showCountersOnPlayerCard;
  final bool showRegularCounters;
  final bool showCommanderDamageCounters;
  final bool clickableCommanderDamageCounters;
  final bool keepZeroCountersOnPlayerCard;
  final bool saltyDefeatMessages;
  final bool cycleSaltyDefeatMessages;
  final bool gameTimer;
  final bool gameTimerMainScreen;
  final bool showClockOnMainScreen;
  final bool randomPlayerColors;
  final bool preserveBackgroundImagesOnShuffle;
  final bool setLifeByTappingNumber;
  final bool verticalTapAreas;
  final bool cleanLook;
  final bool criticalDamageWarning;
  final bool customLongTapEnabled;
  final int customLongTapValue;
  final String? whitelabelIcon;

  static const Object _unset = Object();

  LifeCounterSettings copyWith({
    bool? autoKill,
    bool? lifeLossOnCommanderDamage,
    bool? showCountersOnPlayerCard,
    bool? showRegularCounters,
    bool? showCommanderDamageCounters,
    bool? clickableCommanderDamageCounters,
    bool? keepZeroCountersOnPlayerCard,
    bool? saltyDefeatMessages,
    bool? cycleSaltyDefeatMessages,
    bool? gameTimer,
    bool? gameTimerMainScreen,
    bool? showClockOnMainScreen,
    bool? randomPlayerColors,
    bool? preserveBackgroundImagesOnShuffle,
    bool? setLifeByTappingNumber,
    bool? verticalTapAreas,
    bool? cleanLook,
    bool? criticalDamageWarning,
    bool? customLongTapEnabled,
    int? customLongTapValue,
    Object? whitelabelIcon = _unset,
  }) {
    return LifeCounterSettings(
      autoKill: autoKill ?? this.autoKill,
      lifeLossOnCommanderDamage:
          lifeLossOnCommanderDamage ?? this.lifeLossOnCommanderDamage,
      showCountersOnPlayerCard:
          showCountersOnPlayerCard ?? this.showCountersOnPlayerCard,
      showRegularCounters: showRegularCounters ?? this.showRegularCounters,
      showCommanderDamageCounters:
          showCommanderDamageCounters ?? this.showCommanderDamageCounters,
      clickableCommanderDamageCounters:
          clickableCommanderDamageCounters ??
          this.clickableCommanderDamageCounters,
      keepZeroCountersOnPlayerCard:
          keepZeroCountersOnPlayerCard ?? this.keepZeroCountersOnPlayerCard,
      saltyDefeatMessages:
          saltyDefeatMessages ?? this.saltyDefeatMessages,
      cycleSaltyDefeatMessages:
          cycleSaltyDefeatMessages ?? this.cycleSaltyDefeatMessages,
      gameTimer: gameTimer ?? this.gameTimer,
      gameTimerMainScreen:
          gameTimerMainScreen ?? this.gameTimerMainScreen,
      showClockOnMainScreen:
          showClockOnMainScreen ?? this.showClockOnMainScreen,
      randomPlayerColors:
          randomPlayerColors ?? this.randomPlayerColors,
      preserveBackgroundImagesOnShuffle:
          preserveBackgroundImagesOnShuffle ??
          this.preserveBackgroundImagesOnShuffle,
      setLifeByTappingNumber:
          setLifeByTappingNumber ?? this.setLifeByTappingNumber,
      verticalTapAreas: verticalTapAreas ?? this.verticalTapAreas,
      cleanLook: cleanLook ?? this.cleanLook,
      criticalDamageWarning:
          criticalDamageWarning ?? this.criticalDamageWarning,
      customLongTapEnabled:
          customLongTapEnabled ?? this.customLongTapEnabled,
      customLongTapValue:
          customLongTapValue ?? this.customLongTapValue,
      whitelabelIcon: identical(whitelabelIcon, _unset)
          ? this.whitelabelIcon
          : whitelabelIcon as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'auto_kill': autoKill,
      'life_loss_on_commander_damage': lifeLossOnCommanderDamage,
      'show_counters_on_player_card': showCountersOnPlayerCard,
      'show_regular_counters': showRegularCounters,
      'show_commander_damage_counters': showCommanderDamageCounters,
      'clickable_commander_damage_counters': clickableCommanderDamageCounters,
      'keep_zero_counters_on_player_card': keepZeroCountersOnPlayerCard,
      'salty_defeat_messages': saltyDefeatMessages,
      'cycle_salty_defeat_messages': cycleSaltyDefeatMessages,
      'game_timer': gameTimer,
      'game_timer_main_screen': gameTimerMainScreen,
      'show_clock_on_main_screen': showClockOnMainScreen,
      'random_player_colors': randomPlayerColors,
      'preserve_background_images_on_shuffle':
          preserveBackgroundImagesOnShuffle,
      'set_life_by_tapping_number': setLifeByTappingNumber,
      'vertical_tap_areas': verticalTapAreas,
      'clean_look': cleanLook,
      'critical_damage_warning': criticalDamageWarning,
      'custom_long_tap_enabled': customLongTapEnabled,
      'custom_long_tap_value': customLongTapValue,
      'whitelabel_icon': whitelabelIcon,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static LifeCounterSettings? tryParse(String? raw) {
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

  static LifeCounterSettings? tryFromJson(Map<String, dynamic> payload) {
    bool readBool(String key, bool fallback) {
      final value = payload[key];
      return value is bool ? value : fallback;
    }

    int readInt(String key, int fallback) {
      final value = payload[key];
      return value is num ? value.toInt() : fallback;
    }

    final whitelabelIcon = payload['whitelabel_icon'];

    return LifeCounterSettings(
      autoKill: readBool('auto_kill', defaults.autoKill),
      lifeLossOnCommanderDamage: readBool(
        'life_loss_on_commander_damage',
        defaults.lifeLossOnCommanderDamage,
      ),
      showCountersOnPlayerCard: readBool(
        'show_counters_on_player_card',
        defaults.showCountersOnPlayerCard,
      ),
      showRegularCounters: readBool(
        'show_regular_counters',
        defaults.showRegularCounters,
      ),
      showCommanderDamageCounters: readBool(
        'show_commander_damage_counters',
        defaults.showCommanderDamageCounters,
      ),
      clickableCommanderDamageCounters: readBool(
        'clickable_commander_damage_counters',
        defaults.clickableCommanderDamageCounters,
      ),
      keepZeroCountersOnPlayerCard: readBool(
        'keep_zero_counters_on_player_card',
        defaults.keepZeroCountersOnPlayerCard,
      ),
      saltyDefeatMessages: readBool(
        'salty_defeat_messages',
        defaults.saltyDefeatMessages,
      ),
      cycleSaltyDefeatMessages: readBool(
        'cycle_salty_defeat_messages',
        defaults.cycleSaltyDefeatMessages,
      ),
      gameTimer: readBool('game_timer', defaults.gameTimer),
      gameTimerMainScreen: readBool(
        'game_timer_main_screen',
        defaults.gameTimerMainScreen,
      ),
      showClockOnMainScreen: readBool(
        'show_clock_on_main_screen',
        defaults.showClockOnMainScreen,
      ),
      randomPlayerColors: readBool(
        'random_player_colors',
        defaults.randomPlayerColors,
      ),
      preserveBackgroundImagesOnShuffle: readBool(
        'preserve_background_images_on_shuffle',
        defaults.preserveBackgroundImagesOnShuffle,
      ),
      setLifeByTappingNumber: readBool(
        'set_life_by_tapping_number',
        defaults.setLifeByTappingNumber,
      ),
      verticalTapAreas: readBool(
        'vertical_tap_areas',
        defaults.verticalTapAreas,
      ),
      cleanLook: readBool('clean_look', defaults.cleanLook),
      criticalDamageWarning: readBool(
        'critical_damage_warning',
        defaults.criticalDamageWarning,
      ),
      customLongTapEnabled: readBool(
        'custom_long_tap_enabled',
        defaults.customLongTapEnabled,
      ),
      customLongTapValue: readInt(
        'custom_long_tap_value',
        defaults.customLongTapValue,
      ),
      whitelabelIcon: whitelabelIcon is String ? whitelabelIcon : null,
    );
  }
}
