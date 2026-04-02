import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state.dart';
import 'package:manaloom/features/home/life_counter/life_counter_game_timer_state_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings.dart';
import 'package:manaloom/features/home/life_counter/life_counter_settings_store.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot_store.dart';
import 'package:manaloom/features/home/lotus_life_counter_screen.dart';

Future<LotusUiSnapshot> _pumpUntilUiSnapshotAvailable(
  WidgetTester tester,
  LotusUiSnapshotStore uiSnapshotStore,
) async {
  LotusUiSnapshot? snapshot = await uiSnapshotStore.load();
  for (var attempt = 0; attempt < 20 && snapshot == null; attempt += 1) {
    await tester.pump(const Duration(seconds: 1));
    snapshot = await uiSnapshotStore.load();
  }
  expect(snapshot, isNotNull);
  return snapshot!;
}

Future<void> _stabilizeHarness(
  WidgetTester tester,
  LotusStorageSnapshotStore snapshotStore,
  LotusUiSnapshotStore uiSnapshotStore,
  LifeCounterGameTimerStateStore gameTimerStateStore,
  LifeCounterSessionStore sessionStore,
  LifeCounterSettingsStore settingsStore,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
  await snapshotStore.clear();
  await uiSnapshotStore.clear();
  await gameTimerStateStore.clear();
  await sessionStore.clear();
  await settingsStore.clear();
  await tester.pump(const Duration(milliseconds: 200));
}

Map<String, dynamic> _decodeGameTimerPayload(String raw) {
  final decoded = jsonDecode(raw);
  expect(decoded, isA<Map>());
  return (decoded as Map).cast<String, dynamic>();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reopens a paused game timer from the persisted Lotus snapshot',
    (tester) async {
      final snapshotStore = LotusStorageSnapshotStore();
      final uiSnapshotStore = LotusUiSnapshotStore();
      final gameTimerStateStore = LifeCounterGameTimerStateStore();
      final sessionStore = LifeCounterSessionStore();
      final settingsStore = LifeCounterSettingsStore();

      await _stabilizeHarness(
        tester,
        snapshotStore,
        uiSnapshotStore,
        gameTimerStateStore,
        sessionStore,
        settingsStore,
      );

      const startTimeEpochMs = 1711800000000;
      const pausedTimeEpochMs = startTimeEpochMs + 65000;

      await gameTimerStateStore.save(
        const LifeCounterGameTimerState(
          startTimeEpochMs: startTimeEpochMs,
          isPaused: true,
          pausedTimeEpochMs: pausedTimeEpochMs,
        ),
      );
      await sessionStore.save(LifeCounterSession.initial(playerCount: 4));
      await settingsStore.save(
        const LifeCounterSettings(
          autoKill: true,
          lifeLossOnCommanderDamage: true,
          showCountersOnPlayerCard: true,
          showRegularCounters: true,
          showCommanderDamageCounters: false,
          clickableCommanderDamageCounters: false,
          keepZeroCountersOnPlayerCard: false,
          saltyDefeatMessages: true,
          cycleSaltyDefeatMessages: true,
          gameTimer: true,
          gameTimerMainScreen: true,
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
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
      await tester.pump();

      final firstUiSnapshot = await _pumpUntilUiSnapshotAvailable(
        tester,
        uiSnapshotStore,
      );
      expect(firstUiSnapshot.gameTimerCount, 1);
      expect(firstUiSnapshot.gameTimerPausedCount, 1);
      expect(firstUiSnapshot.gameTimerText, '01:05');

      final firstRawSnapshot = await snapshotStore.load();
      expect(firstRawSnapshot, isNotNull);
      expect(firstRawSnapshot!.values['gameTimerState'], isNotNull);
      final firstTimerPayload = _decodeGameTimerPayload(
        firstRawSnapshot.values['gameTimerState']!,
      );
      expect((firstTimerPayload['startTime'] as num?)?.toInt(), startTimeEpochMs);
      expect(firstTimerPayload['isPaused'], isTrue);
      expect(
        (firstTimerPayload['pausedTime'] as num?)?.toInt(),
        pausedTimeEpochMs,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      await uiSnapshotStore.clear();
      await sessionStore.clear();
      await settingsStore.clear();
      await gameTimerStateStore.clear();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const MaterialApp(home: LotusLifeCounterScreen()));
      await tester.pump();

      final secondUiSnapshot = await _pumpUntilUiSnapshotAvailable(
        tester,
        uiSnapshotStore,
      );
      expect(secondUiSnapshot.gameTimerCount, 1);
      expect(secondUiSnapshot.gameTimerPausedCount, 1);
      expect(secondUiSnapshot.gameTimerText, '01:05');

      final restoredGameTimer = await gameTimerStateStore.load();
      expect(restoredGameTimer, isNotNull);
      expect(restoredGameTimer!.startTimeEpochMs, startTimeEpochMs);
      expect(restoredGameTimer.isPaused, isTrue);
      expect(restoredGameTimer.pausedTimeEpochMs, pausedTimeEpochMs);

      final reopenedRawSnapshot = await snapshotStore.load();
      expect(reopenedRawSnapshot, isNotNull);
      expect(reopenedRawSnapshot!.values['gameTimerState'], isNotNull);
    },
  );
}
