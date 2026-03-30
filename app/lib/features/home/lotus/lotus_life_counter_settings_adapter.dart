import 'dart:convert';

import '../life_counter/life_counter_settings.dart';
import 'lotus_storage_snapshot.dart';

class LotusLifeCounterSettingsAdapter {
  LotusLifeCounterSettingsAdapter._();

  static const String _gameSettingsKey = 'gameSettings';

  static LifeCounterSettings? tryBuildSettings(LotusStorageSnapshot snapshot) {
    final raw = snapshot.values[_gameSettingsKey];
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final settings = decoded.cast<String, dynamic>();
      return LifeCounterSettings(
        autoKill: _readBool(settings, 'autoKO', LifeCounterSettings.defaults.autoKill),
        lifeLossOnCommanderDamage: _readBool(
          settings,
          'lifeLossOnCommanderDamage',
          LifeCounterSettings.defaults.lifeLossOnCommanderDamage,
        ),
        showCountersOnPlayerCard: _readBool(
          settings,
          'showCountersOnPlayerCard',
          LifeCounterSettings.defaults.showCountersOnPlayerCard,
        ),
        showRegularCounters: _readBool(
          settings,
          'showRegularCounters',
          LifeCounterSettings.defaults.showRegularCounters,
        ),
        showCommanderDamageCounters: _readBool(
          settings,
          'showCommanderDamageCounters',
          LifeCounterSettings.defaults.showCommanderDamageCounters,
        ),
        clickableCommanderDamageCounters: _readBool(
          settings,
          'clickableCommanderDamageCounters',
          LifeCounterSettings.defaults.clickableCommanderDamageCounters,
        ),
        keepZeroCountersOnPlayerCard: _readBool(
          settings,
          'keepZeroCountersOnPlayerCard',
          LifeCounterSettings.defaults.keepZeroCountersOnPlayerCard,
        ),
        saltyDefeatMessages: _readBool(
          settings,
          'saltyDefeatMessages',
          LifeCounterSettings.defaults.saltyDefeatMessages,
        ),
        cycleSaltyDefeatMessages: _readBool(
          settings,
          'cycleSaltyDefeatMessages',
          LifeCounterSettings.defaults.cycleSaltyDefeatMessages,
        ),
        gameTimer: _readBool(
          settings,
          'gameTimer',
          LifeCounterSettings.defaults.gameTimer,
        ),
        gameTimerMainScreen: _readBool(
          settings,
          'gameTimerMainScreen',
          LifeCounterSettings.defaults.gameTimerMainScreen,
        ),
        showClockOnMainScreen: _readBool(
          settings,
          'showClockOnMainScreen',
          LifeCounterSettings.defaults.showClockOnMainScreen,
        ),
        randomPlayerColors: _readBool(
          settings,
          'randomPlayerColors',
          LifeCounterSettings.defaults.randomPlayerColors,
        ),
        preserveBackgroundImagesOnShuffle: _readBool(
          settings,
          'preserveBackgroundImagesOnShuffle',
          LifeCounterSettings.defaults.preserveBackgroundImagesOnShuffle,
        ),
        setLifeByTappingNumber: _readBool(
          settings,
          'setLifeByTappingNumber',
          LifeCounterSettings.defaults.setLifeByTappingNumber,
        ),
        verticalTapAreas: _readBool(
          settings,
          'verticalTapAreas',
          LifeCounterSettings.defaults.verticalTapAreas,
        ),
        cleanLook: _readBool(
          settings,
          'cleanLook',
          LifeCounterSettings.defaults.cleanLook,
        ),
        criticalDamageWarning: _readBool(
          settings,
          'criticalDamageWarning',
          LifeCounterSettings.defaults.criticalDamageWarning,
        ),
        customLongTapEnabled: _readBool(
          settings,
          'customLongTapEnabled',
          LifeCounterSettings.defaults.customLongTapEnabled,
        ),
        customLongTapValue: _readInt(
          settings,
          'customLongTapValue',
          LifeCounterSettings.defaults.customLongTapValue,
        ),
        whitelabelIcon: settings['whitelabelIcon'] is String
            ? settings['whitelabelIcon'] as String
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> buildSnapshotValues(LifeCounterSettings settings) {
    return <String, String>{
      _gameSettingsKey: jsonEncode({
        'autoKO': settings.autoKill,
        'lifeLossOnCommanderDamage': settings.lifeLossOnCommanderDamage,
        'showCountersOnPlayerCard': settings.showCountersOnPlayerCard,
        'showRegularCounters': settings.showRegularCounters,
        'showCommanderDamageCounters': settings.showCommanderDamageCounters,
        'clickableCommanderDamageCounters':
            settings.clickableCommanderDamageCounters,
        'keepZeroCountersOnPlayerCard': settings.keepZeroCountersOnPlayerCard,
        'whitelabelIcon': settings.whitelabelIcon,
        'saltyDefeatMessages': settings.saltyDefeatMessages,
        'cycleSaltyDefeatMessages': settings.cycleSaltyDefeatMessages,
        'gameTimer': settings.gameTimer,
        'gameTimerMainScreen': settings.gameTimerMainScreen,
        'showClockOnMainScreen': settings.showClockOnMainScreen,
        'randomPlayerColors': settings.randomPlayerColors,
        'preserveBackgroundImagesOnShuffle':
            settings.preserveBackgroundImagesOnShuffle,
        'setLifeByTappingNumber': settings.setLifeByTappingNumber,
        'verticalTapAreas': settings.verticalTapAreas,
        'cleanLook': settings.cleanLook,
        'criticalDamageWarning': settings.criticalDamageWarning,
        'customLongTapEnabled': settings.customLongTapEnabled,
        'customLongTapValue': settings.customLongTapValue,
      }),
    };
  }

  static bool _readBool(
    Map<String, dynamic> settings,
    String key,
    bool fallback,
  ) {
    final value = settings[key];
    return value is bool ? value : fallback;
  }

  static int _readInt(
    Map<String, dynamic> settings,
    String key,
    int fallback,
  ) {
    final value = settings[key];
    return value is num ? value.toInt() : fallback;
  }
}
