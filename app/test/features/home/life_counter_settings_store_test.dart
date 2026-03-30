import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LifeCounterSettingsStore', () {
    late LifeCounterSettingsStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = LifeCounterSettingsStore();
    });

    test('saves and restores a settings round-trip', () async {
      const settings = LifeCounterSettings(
        autoKill: false,
        lifeLossOnCommanderDamage: true,
        showCountersOnPlayerCard: false,
        showRegularCounters: true,
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
      );

      await store.save(settings);
      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.toJson(), settings.toJson());
    });

    test('clears the persisted settings', () async {
      await store.save(LifeCounterSettings.defaults);
      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
