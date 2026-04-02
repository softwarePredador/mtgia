import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'renders Lotus clock-only tabletop state without the game timer',
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
          gameTimer: false,
          gameTimerMainScreen: false,
          showClockOnMainScreen: true,
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

      final snapshot = await _pumpUntilUiSnapshotAvailable(
        tester,
        uiSnapshotStore,
      );

      expect(snapshot.clockCount, 1);
      expect(snapshot.clockWithGameTimerCount, 0);
      expect(snapshot.gameTimerCount, 0);
      expect(snapshot.gameTimerPausedCount, 0);
    },
  );
}
