import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_catalog.dart';

void main() {
  group('LifeCounterSettings.copyWith', () {
    test('overrides provided fields and preserves the rest', () {
      final updated = LifeCounterSettings.defaults.copyWith(
        gameTimer: true,
        showClockOnMainScreen: true,
        customLongTapEnabled: true,
        customLongTapValue: 25,
      );

      expect(updated.gameTimer, isTrue);
      expect(updated.showClockOnMainScreen, isTrue);
      expect(updated.customLongTapEnabled, isTrue);
      expect(updated.customLongTapValue, 25);
      expect(
        updated.showCountersOnPlayerCard,
        LifeCounterSettings.defaults.showCountersOnPlayerCard,
      );
      expect(
        updated.whitelabelIcon,
        LifeCounterSettings.defaults.whitelabelIcon,
      );
    });

    test('can explicitly clear the optional whitelabel icon', () {
      const base = LifeCounterSettings(
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
        whitelabelIcon: 'lotus-mark',
      );

      final updated = base.copyWith(whitelabelIcon: null);

      expect(updated.whitelabelIcon, isNull);
    });
  });

  group('buildLifeCounterSettingsCatalog', () {
    test('returns every settings field exactly once', () {
      final sections = buildLifeCounterSettingsCatalog(
        LifeCounterSettings.defaults,
      );

      final ids =
          sections
              .expand((section) => section.entries)
              .map((entry) => entry.id)
              .toList();

      expect(ids.length, LifeCounterSettingFieldId.values.length);
      expect(ids.toSet().length, LifeCounterSettingFieldId.values.length);
    });

    test('reflects current values inside the right sections', () {
      final settings = LifeCounterSettings.defaults.copyWith(
        gameTimer: true,
        gameTimerMainScreen: true,
        showClockOnMainScreen: true,
        cleanLook: true,
        customLongTapEnabled: true,
        customLongTapValue: 30,
      );

      final sections = buildLifeCounterSettingsCatalog(settings);
      final timers = sections.firstWhere(
        (section) => section.id == LifeCounterSettingsSectionId.timers,
      );
      final visuals = sections.firstWhere(
        (section) => section.id == LifeCounterSettingsSectionId.visuals,
      );
      final advanced = sections.firstWhere(
        (section) => section.id == LifeCounterSettingsSectionId.advanced,
      );

      expect(timers.title, 'Cronômetros');
      expect(
        timers.entries
            .firstWhere(
              (entry) => entry.id == LifeCounterSettingFieldId.gameTimer,
            )
            .toggleValue,
        isTrue,
      );
      expect(
        visuals.entries
            .firstWhere(
              (entry) => entry.id == LifeCounterSettingFieldId.cleanLook,
            )
            .toggleValue,
        isTrue,
      );
      expect(
        advanced.entries
            .firstWhere(
              (entry) =>
                  entry.id == LifeCounterSettingFieldId.customLongTapValue,
            )
            .numberValue,
        30,
      );
    });

    test('disables child controls while their parent feature is off', () {
      final settings = LifeCounterSettings.defaults.copyWith(
        showCountersOnPlayerCard: false,
        showCommanderDamageCounters: true,
        gameTimer: false,
        saltyDefeatMessages: false,
        customLongTapEnabled: false,
      );

      final entries = buildLifeCounterSettingsCatalog(
        settings,
      ).expand((section) => section.entries);
      LifeCounterSettingEntry entry(LifeCounterSettingFieldId id) =>
          entries.firstWhere((candidate) => candidate.id == id);

      expect(
        entry(LifeCounterSettingFieldId.showRegularCounters).enabled,
        false,
      );
      expect(
        entry(LifeCounterSettingFieldId.showCommanderDamageCounters).enabled,
        false,
      );
      expect(
        entry(
          LifeCounterSettingFieldId.clickableCommanderDamageCounters,
        ).enabled,
        false,
      );
      expect(
        entry(LifeCounterSettingFieldId.keepZeroCountersOnPlayerCard).enabled,
        false,
      );
      expect(
        entry(LifeCounterSettingFieldId.gameTimerMainScreen).enabled,
        false,
      );
      expect(
        entry(LifeCounterSettingFieldId.cycleSaltyDefeatMessages).enabled,
        false,
      );
      expect(
        entry(LifeCounterSettingFieldId.customLongTapValue).enabled,
        false,
      );
    });

    test('does not expose the legacy white-label icon setting', () {
      final labels = buildLifeCounterSettingsCatalog(
        LifeCounterSettings.defaults.copyWith(whitelabelIcon: 'legacy-icon'),
      ).expand((section) => section.entries).map((entry) => entry.label);

      expect(labels, isNot(contains('Ícone personalizado')));
    });
  });
}
