import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_day_night_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_life_counter_settings_adapter.dart';
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
}

Future<Map<String, dynamic>> _readGameSettings(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  dynamic screenState,
) async {
  const storageKey = '__manaloom_test_game_settings_state';
  const nonceKey = '__manaloom_test_game_settings_state_nonce';
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();

  await screenState.debugRunJavaScript('''
(() => {
  try {
    const raw = localStorage.getItem('gameSettings');
    localStorage.setItem('$storageKey', raw ?? '{}');
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
    'reapplies canonical settings over a stale Lotus snapshot on reopen',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final settingsStore = LifeCounterSettingsStore();
      final canonicalSettings = LifeCounterSettings.defaults.copyWith(
        autoKill: false,
        gameTimer: true,
        showClockOnMainScreen: true,
        randomPlayerColors: true,
        cleanLook: true,
        customLongTapEnabled: true,
        customLongTapValue: 17,
      );
      final staleSettings = LifeCounterSettings.defaults.copyWith(
        autoKill: true,
        gameTimer: false,
        showClockOnMainScreen: false,
        randomPlayerColors: false,
        cleanLook: false,
        customLongTapEnabled: false,
        customLongTapValue: 10,
      );

      await _bootLiveLotus(tester);
      await settingsStore.save(canonicalSettings);
      await snapshotStore.save(
        LotusStorageSnapshot(
          values: Map<String, String>.unmodifiable(
            LotusLifeCounterSettingsAdapter.buildSnapshotValues(staleSettings),
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic screenState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final liveSettings = await _readGameSettings(
        tester,
        snapshotStore,
        screenState,
      );

      expect(liveSettings['autoKO'], isFalse);
      expect(liveSettings['gameTimer'], isTrue);
      expect(liveSettings['showClockOnMainScreen'], isTrue);
      expect(liveSettings['randomPlayerColors'], isTrue);
      expect(liveSettings['cleanLook'], isTrue);
      expect(liveSettings['customLongTapEnabled'], isTrue);
      expect(liveSettings['customLongTapValue'], 17);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await settingsStore.clear();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        const MaterialApp(home: LotusLifeCounterScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));

      final dynamic reopenedState = tester.state(
        find.byType(LotusLifeCounterScreen),
      );
      final reopenedSettings = await _readGameSettings(
        tester,
        snapshotStore,
        reopenedState,
      );

      expect(reopenedSettings['autoKO'], isFalse);
      expect(reopenedSettings['gameTimer'], isTrue);
      expect(reopenedSettings['showClockOnMainScreen'], isTrue);
      expect(reopenedSettings['randomPlayerColors'], isTrue);
      expect(reopenedSettings['cleanLook'], isTrue);
      expect(reopenedSettings['customLongTapEnabled'], isTrue);
      expect(reopenedSettings['customLongTapValue'], 17);
    },
  );
}
