import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_settings_adapter.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';

void main() {
  group('LotusLifeCounterSettingsAdapter', () {
    test('derives typed settings from Lotus gameSettings', () {
      final snapshot = LotusStorageSnapshot(
        values: {
          'gameSettings': jsonEncode({
            'autoKO': false,
            'lifeLossOnCommanderDamage': false,
            'showCountersOnPlayerCard': true,
            'showRegularCounters': false,
            'showCommanderDamageCounters': true,
            'clickableCommanderDamageCounters': true,
            'keepZeroCountersOnPlayerCard': true,
            'saltyDefeatMessages': false,
            'cycleSaltyDefeatMessages': false,
            'gameTimer': true,
            'gameTimerMainScreen': true,
            'showClockOnMainScreen': true,
            'randomPlayerColors': true,
            'preserveBackgroundImagesOnShuffle': false,
            'setLifeByTappingNumber': false,
            'verticalTapAreas': true,
            'cleanLook': true,
            'criticalDamageWarning': false,
            'customLongTapEnabled': true,
            'customLongTapValue': 25,
            'whitelabelIcon': 'mana',
          }),
        },
      );

      final settings =
          LotusLifeCounterSettingsAdapter.tryBuildSettings(snapshot);

      expect(settings, isNotNull);
      expect(settings!.autoKill, isFalse);
      expect(settings.lifeLossOnCommanderDamage, isFalse);
      expect(settings.showRegularCounters, isFalse);
      expect(settings.showCommanderDamageCounters, isTrue);
      expect(settings.gameTimer, isTrue);
      expect(settings.customLongTapEnabled, isTrue);
      expect(settings.customLongTapValue, 25);
      expect(settings.whitelabelIcon, 'mana');
    });

    test('returns null when gameSettings are missing', () {
      const snapshot = LotusStorageSnapshot(values: {});

      expect(
        LotusLifeCounterSettingsAdapter.tryBuildSettings(snapshot),
        isNull,
      );
    });

    test('serializes canonical settings back into Lotus-compatible storage', () {
      final values = LotusLifeCounterSettingsAdapter.buildSnapshotValues(
        const LifeCounterSettings(
          autoKill: false,
          lifeLossOnCommanderDamage: false,
          showCountersOnPlayerCard: true,
          showRegularCounters: false,
          showCommanderDamageCounters: true,
          clickableCommanderDamageCounters: true,
          keepZeroCountersOnPlayerCard: true,
          saltyDefeatMessages: false,
          cycleSaltyDefeatMessages: false,
          gameTimer: true,
          gameTimerMainScreen: true,
          showClockOnMainScreen: true,
          randomPlayerColors: true,
          preserveBackgroundImagesOnShuffle: false,
          setLifeByTappingNumber: false,
          verticalTapAreas: true,
          cleanLook: true,
          criticalDamageWarning: false,
          customLongTapEnabled: true,
          customLongTapValue: 25,
          whitelabelIcon: 'mana',
        ),
      );

      final decoded = jsonDecode(values['gameSettings']!) as Map<String, dynamic>;

      expect(decoded['autoKO'], isFalse);
      expect(decoded['showCountersOnPlayerCard'], isTrue);
      expect(decoded['gameTimer'], isTrue);
      expect(decoded['customLongTapValue'], 25);
      expect(decoded['whitelabelIcon'], 'mana');
    });
  });
}
