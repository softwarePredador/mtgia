import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_native_settings_sheet.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';

void main() {
  testWidgets('disables dependent controls until their parent is enabled', (
    tester,
  ) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final result = showLifeCounterNativeSettingsSheet(
      hostContext,
      initialSettings: LifeCounterSettings.defaults.copyWith(
        gameTimerMainScreen: true,
      ),
    );
    await tester.pumpAndSettle();

    const timerKey = Key('life-counter-setting-gameTimer');
    const mainScreenTimerKey = Key('life-counter-setting-gameTimerMainScreen');
    await tester.scrollUntilVisible(
      find.byKey(timerKey),
      180,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      tester.widget<SwitchListTile>(find.byKey(mainScreenTimerKey)).onChanged,
      isNull,
    );

    tester.widget<SwitchListTile>(find.byKey(timerKey)).onChanged!(true);
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byKey(mainScreenTimerKey)).onChanged,
      isNotNull,
    );

    tester
        .widget<SwitchListTile>(find.byKey(mainScreenTimerKey))
        .onChanged!(false);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('life-counter-native-settings-save')),
    );
    await tester.pumpAndSettle();

    final updated = await result;
    expect(updated, isNotNull);
    expect(updated!.gameTimer, isTrue);
    expect(updated.gameTimerMainScreen, isFalse);
  });

  testWidgets('keeps legacy white-label data out of the settings surface', (
    tester,
  ) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final result = showLifeCounterNativeSettingsSheet(
      hostContext,
      initialSettings: LifeCounterSettings.defaults.copyWith(
        whitelabelIcon: 'legacy-icon',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ícone personalizado'), findsNothing);

    await tester.tap(
      find.byKey(const Key('life-counter-native-settings-save')),
    );
    await tester.pumpAndSettle();
    expect((await result)?.whitelabelIcon, 'legacy-icon');
  });
}
