import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<void> _bootLiveLotus(WidgetTester tester) async {
  await LotusStorageSnapshotStore().clear();
  await LifeCounterSettingsStore().clear();
  await LifeCounterSessionStore().clear();
  await LifeCounterGameTimerStateStore().clear();
  await LifeCounterDayNightStateStore().clear();
  await LifeCounterPlayerAppearanceProfileStore().clear();

  await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
  await tester.pump();
  await tester.pump(const Duration(seconds: 8));
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 30,
}) async {
  for (
    var attempt = 0;
    attempt < attempts && finder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<Map<String, dynamic>> _readDayNightState(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_day_night_state';
  const nonceKey = '__manaloom_test_day_night_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const switcher = document.querySelector('.day-night-switcher');
    localStorage.setItem('$storageKey', JSON.stringify({
      mode: localStorage.getItem('__manaloom_day_night_mode'),
      switcher_present: !!switcher,
      switcher_has_night_class: !!(switcher && switcher.classList.contains('night'))
    }));
    localStorage.setItem('$nonceKey', '$nonce');
  } catch (_) {}
})()
''');

  String? encodedState;
  for (var attempt = 0; attempt < 20 && encodedState == null; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 300));
    final snapshot = await snapshotStore.load();
    if (snapshot == null) {
      continue;
    }
    if (snapshot.values[nonceKey] != nonce) {
      continue;
    }
    encodedState = snapshot.values[storageKey];
  }

  expect(encodedState, isNotNull);
  final decoded = jsonDecode(encodedState!);
  return Map<String, dynamic>.from(decoded as Map);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reapplies canonical day night preference over a stale Lotus snapshot on reopen',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final dayNightStateStore = LifeCounterDayNightStateStore();

      await _bootLiveLotus(tester);

      final dynamic screenState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );

      await screenState.debugHandleShellMessage(
        '{"type":"open-native-day-night","source":"day_night_surface_pressed"}',
      );
      await _pumpUntilVisible(tester, find.text('Day / Night'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Night'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('life-counter-native-day-night-apply')),
      );
      await tester.pumpAndSettle();

      final savedState = await dayNightStateStore.load();
      expect(savedState, isNotNull);
      expect(savedState!.isNight, isTrue);

      final liveState = await _readDayNightState(
        tester,
        snapshotStore,
        screenState,
      );
      expect(liveState['mode'], 'night');
      if (liveState['switcher_present'] == true) {
        expect(liveState['switcher_has_night_class'], isTrue);
      }

      final snapshot = await snapshotStore.load();
      expect(snapshot, isNotNull);
      await snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(<String, String>{
            ...snapshot!.values,
            '__manaloom_day_night_mode': 'day',
          }),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic reopenedState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final reopenedDayNightState = await _readDayNightState(
        tester,
        snapshotStore,
        reopenedState,
      );

      expect(reopenedDayNightState['mode'], 'night');
      if (reopenedDayNightState['switcher_present'] == true) {
        expect(reopenedDayNightState['switcher_has_night_class'], isTrue);
      }
    },
  );
}
